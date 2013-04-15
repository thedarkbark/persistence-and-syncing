//
//  NAPersistentObject.m
//  Note All
//
//  Created by Ken Worley on 8/1/12.
//
//

#import "NAPersistentObject.h"
#import <objc/runtime.h>

static NSMutableDictionary *propertyMap = nil;

#define ISDYNAMIC(propertyName) ([self respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"noEncode", propertyName])])

@implementation NAPersistentObject

-(id)init
{
  self = [super init];
  return self;
}

#pragma mark NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self)
  {
    [self decodePropertiesWithCoder:aDecoder];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
  [self encodePropertiesWithCoder:aCoder];
}

+(id)loadFromFile:(NSString*)file
{
  id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
  NSAssert(obj == nil || [obj isKindOfClass:[NAPersistentObject class]], @"NAPersistentObject unarchived a different class from file than expected");
  return obj;
}

-(BOOL)writeToFile:(NSString*)file
{
  return [NSKeyedArchiver archiveRootObject:self toFile:file];
}

+(id)loadFromData:(NSData*)data
{
  id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  NSAssert(obj == nil || [obj isKindOfClass:[NAPersistentObject class]], @"NAPersistentObject unarchived a different class from data than expected");
  return obj;
}

-(NSData*)objectAsData
{
  return [NSKeyedArchiver archivedDataWithRootObject:self];
}

-(NSArray*)getPropertyNames
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    propertyMap = [[NSMutableDictionary alloc] init];
  });

  Class c = [self class];
  NSString *className = NSStringFromClass(c);
  NSMutableArray *propertyNames = [propertyMap objectForKey:className];
  if (propertyNames)
    return propertyNames;
  
  NSLog(@"Finding properties for class %@", className);
  propertyNames = [NSMutableArray new];
  while (c && c != [NSObject class])
  {
    [propertyNames addObjectsFromArray:[self introspectForPropertyNamesInClass:c]];
    c = [c superclass];
  }
  
  [propertyMap setObject:propertyNames forKey:className];
  
  NSLog(@"%@", propertyNames);
  
  return propertyNames;
}

#pragma mark Private methods

-(void)encodePropertiesWithCoder:(NSCoder *)encoder
{
  NSArray *propertyNames = [self getPropertyNames];
  for (NSString *propertyName in propertyNames)
  {
    [encoder encodeObject:[self valueForKey:propertyName] forKey:propertyName];
  }
}

-(void)decodePropertiesWithCoder:(NSCoder *)decoder
{
  NSArray *propertyNames = [self getPropertyNames];
  for (NSString *propertyName in propertyNames)
  {
    id obj = [decoder decodeObjectForKey:propertyName];
    if (obj)
      [self setValue:obj forKey:propertyName];
  }
}

-(NSArray*)introspectForPropertyNamesInClass:(Class)c
{
  NSMutableArray *propertyNames = nil;
  unsigned int propertyCount = 0;
  objc_property_t *classList = class_copyPropertyList(c, &propertyCount);
  if (classList)
  {
    propertyNames = [[NSMutableArray alloc] initWithCapacity:propertyCount];
    if (propertyCount > 0)
    {
      do
      {
        NSString *propName = [NSString stringWithUTF8String:property_getName(*classList)];
        if (!ISDYNAMIC(propName))
        {
          [propertyNames addObject:propName];
        }
        classList++;
      }
      while (*classList);
    }
  }
  return propertyNames;
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
