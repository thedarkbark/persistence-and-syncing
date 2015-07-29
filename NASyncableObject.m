//
//  NASyncableObject.m
//
//  Created by Ken Worley
//  Copyright (c) 2012-2015 Ken Worley. All rights reserved.
//

#import "NASyncableObject.h"
#import "NASyncableCollection.h"

NSString* const NASyncableObjectSavedNotification = @"NASyncableObjectSavedNotification";
void* const propertyObsContext = "allPropertiesObserverContext";

@interface NAPersistentObject ()
-(void)encodePropertiesWithCoder:(NSCoder*)encoder;
-(void)decodePropertiesWithCoder:(NSCoder*)decoder;
@end

@interface NASyncableObject ()
{
  NSDate *saveTime;
  BOOL syncingValue;
}
@property (atomic, strong) NSMutableDictionary *modificationDates;
@property (atomic, strong) NSDate *readTime; // dynamic

@end

@implementation NASyncableObject

// These dynamic properties are not persisted in storage
DYNAMIC(filePath);
DYNAMIC(myCollection);
DYNAMIC(readTime);

-(void)dealloc
{
  [self stopObservingAllProperties];

}

-(id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self)
  {
    NSAssert([self isKindOfClass:[NASyncableObject class]],
             @"Loaded object is not an NASyncableObject");

    _latestModTime = _latestModTime ?: [NSDate distantPast];
    _modificationDates = _modificationDates ? [_modificationDates mutableCopy] : [NSMutableDictionary new];
    _readTime = [[NSDate alloc] init]; // now
    [self observeAllProperties];
  }
  return self;
}

-(id)init
{
  self = [super init];
  if (self)
  {
    _uid = [[NSUUID UUID] UUIDString];
    saveTime = [[NSDate alloc] init];
    _modificationDates = [NSMutableDictionary new];
    _latestModTime = [NSDate distantPast];
    _readTime = [[NSDate alloc] init]; // now
    [self observeAllProperties];
  }
  return self;
}

+(id)loadFromFile:(NSString*)file
{
  id obj = [super loadFromFile:file];
  ((NASyncableObject*)obj).filePath = file;
  return obj;
}

#pragma mark Archive/dearchive

-(void)save
{
  if ([self.readTime compare:self.latestModTime] != NSOrderedAscending)
  {
    // Not modified since read
    return;
  }
  
  // If this entity was obtained from a collection, then save the
  // collection rather than this particular entity.
  if (self.myCollection)
  {
    [self.myCollection entityUpdated:self];
    [self.myCollection save];
    [self entitySaved];
    return;
  }

  NSAssert(self.filePath, @"Trying to save object without file path.");
  if (self.filePath)
  {
    self.readTime = nil;
    self.readTime = [NSDate date];
    [self writeToFile:self.filePath];
    
    [self entitySaved];
  }
}

-(void)entitySaved
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NASyncableObjectSavedNotification object:self];
    });
}

-(void)saveToFile:(NSString*)path
{
  self.filePath = path;
  [self save];
}

#pragma mark Public methods

-(NSDate*)propertyModificationDate:(NSString*)propertyName
{
  NSDate *modDate = self.modificationDates[propertyName];
  if (modDate == nil)
  {
    modDate = [NSDate distantPast];
  }
  return modDate;
}

-(void)setAllPropertyModificationDatesToLongAgo
{
  NSArray *keys = self.modificationDates.allKeys;
  for (NSString *key in keys)
  {
    self.modificationDates[key] = [NSDate distantPast];
  }
}

-(BOOL)isDirty
{
  if (self.latestModTime == nil)
    return NO;
  return ([saveTime compare:self.latestModTime] == NSOrderedAscending);
}

-(void)touch
{
  self.latestModTime = [NSDate date];
}

-(void)syncWith:(NASyncableObject*)syncEntity
    modifyLocal:(BOOL)modifyLocal
   modifyRemote:(BOOL)modifyRemote
  localModified:(BOOL*)localModified
 remoteModified:(BOOL*)remoteModified
{
  NSAssert([self class] == [syncEntity class], @"Syncing object of class %@ with object of class %@", [self class], [syncEntity class]);

  // Compare overall latest mod time
  if ([self.latestModTime compare:syncEntity.latestModTime] == NSOrderedSame)
  {
    // No sync necessary
    return;
  }
  
  // Compare each non-dynamic property
  NSArray *propertyNames = [self getPropertyNames];
  for (NSString *property in propertyNames)
  {
    NSDate *myMod = [self propertyModificationDate:property];
    if (myMod == nil)
      myMod = [NSDate distantPast];
    NSDate *otherMod = [syncEntity propertyModificationDate:property];
    if (otherMod == nil)
      otherMod = [NSDate distantPast];
    switch ([myMod compare:otherMod])
    {
      case NSOrderedAscending:
        if (modifyLocal)
        {
          // Replace my property with the syncEntity's value
          [self syncProperty:property fromObject:syncEntity];
        }
        if (localModified)
        {
          *localModified = YES;
        }
        break;
        
      case NSOrderedDescending:
        if (modifyRemote)
        {
          // Replace syncEntity's value with mine
          [syncEntity syncProperty:property fromObject:self];
        }
        if (remoteModified)
        {
          *remoteModified = YES;
        }
        break;

      default:
      case NSOrderedSame:
        // Both modified at same time
        break;
    }
  }
  
  // Sync the latest mod time for the objects overall
  if ([self.latestModTime compare:syncEntity.latestModTime] == NSOrderedAscending)
  {
    if (modifyLocal)
    {
      self.latestModTime = syncEntity.latestModTime;
    }
  }
  else
  {
    if (modifyRemote)
    {
      syncEntity.latestModTime = self.latestModTime;
    }
  }
}

-(void)syncWith:(NASyncableObject*)syncEntity
{
  [self syncWith:syncEntity modifyLocal:YES modifyRemote:YES localModified:NULL remoteModified:NULL];
}

-(void)syncTo:(NASyncableObject*)syncDestination
{
  [self syncWith:syncDestination modifyLocal:NO modifyRemote:YES localModified:NULL remoteModified:NULL];
}

-(void)syncFrom:(NASyncableObject*)syncSource
{
  [self syncWith:syncSource modifyLocal:YES modifyRemote:NO localModified:NULL remoteModified:NULL];
}

#pragma mark KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context == propertyObsContext && object == self)
  {
    // Record a new modification date for this property
    NSDate *modDate = [[NSDate alloc] init];
    self.modificationDates[keyPath] = modDate;

    // Track latest modification date
    if ([self.latestModTime compare:modDate] == NSOrderedAscending)
    {
      self.latestModTime = modDate;
    }
    
    if (self.myCollection)
    {
      [self.myCollection entityUpdated:self];
    }
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark Private methods

-(void)encodePropertiesWithCoder:(NSCoder *)encoder
{
  [super encodePropertiesWithCoder:encoder];
  
  // Encoding happens when the object is being saved - update save time
  saveTime = [[NSDate alloc] init];
}

-(void)decodePropertiesWithCoder:(NSCoder *)decoder
{
  [super decodePropertiesWithCoder:decoder];
  
  // Decoding means we're reading this object from file - update save time
  saveTime = [[NSDate alloc] init];
}

-(void)observeAllProperties
{
  NSArray *propNames = [self getPropertyNames];
  for (NSString *p in propNames)
  {
    // Don't observe changes to the modificationDates property - that would be circular...
    if (![p isEqualToString:@"modificationDates"] && ![p isEqualToString:@"latestModTime"])
    {
      [self addObserver:self forKeyPath:p options:NSKeyValueObservingOptionNew context:propertyObsContext];
    }
  }
}

-(void)stopObservingAllProperties
{
  NSArray *propNames = [self getPropertyNames];
  for (NSString *p in propNames)
  {
    if (![p isEqualToString:@"modificationDates"] && ![p isEqualToString:@"latestModTime"])
    {
      [self removeObserver:self forKeyPath:p context:propertyObsContext];
    }
  }
}

-(void)syncProperty:(NSString*)propertyName fromObject:(NASyncableObject*)entity
{
  [self setValue:[entity valueForKey:propertyName] forKey:propertyName];
  
  // Reset modification date for this property to the same as the object
  // I'm getting the property from.
  NSDate *modDate = [entity propertyModificationDate:propertyName];
  self.modificationDates[propertyName] = modDate;
}

-(NSString*)debugDescription
{
  NSMutableString *d = [[NSMutableString alloc] init];
  NSArray *propNames = [self getPropertyNames];
  for (NSString *p in propNames)
  {
    [d appendFormat:@"  %@: %@\n", p, [self valueForKey:p]];
  }
  return d;
}

@end
