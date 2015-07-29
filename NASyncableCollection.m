//
//  NASyncableCollection.m
//
//  Created by Ken Worley
//  Copyright (c) 2012-2015 Ken Worley. All rights reserved.
//

#import "NASyncableCollection.h"

@interface NASyncableObject ()
-(void)syncWith:(NASyncableObject*)syncEntity
    modifyLocal:(BOOL)modifyLocal
   modifyRemote:(BOOL)modifyRemote
  localModified:(BOOL*)localModified
 remoteModified:(BOOL*)remoteModified;
@end

@interface NASyncableCollection ()
@property (nonatomic, strong) NSMutableDictionary *collection;
@property (atomic, strong) NSDate *collectionModTime;
@property (nonatomic, strong) NSMutableDictionary *removedIDs;
@end

@implementation NASyncableCollection

- (id)init
{
  self = [super init];
  if (self)
  {
    _removedIDs = [NSMutableDictionary new];
    _collection = [NSMutableDictionary new];
    _collectionModTime = [NSDate distantPast];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self)
  {
    NSAssert([self isKindOfClass:[NASyncableCollection class]],
             @"Loaded object is not an NASyncableCollection.");
    
    _removedIDs = _removedIDs ? [_removedIDs mutableCopy] : [NSMutableDictionary new];
    _collection = _collection ? [_collection mutableCopy] : [NSMutableDictionary new];
    _collectionModTime = _collectionModTime ?: [NSDate distantPast];
    
    [self registerAllEntities];
  }
  return self;
}

- (BOOL)isEqual:(id)object
{
    return ([object isKindOfClass:[NASyncableCollection class]]
        && [self.collection isEqualToDictionary:((NASyncableCollection*)object).collection]);
}

- (id)entityWithID:(NSString*)entityID
{
  NSParameterAssert(entityID.length > 0);
  if (entityID == nil) return nil;
  
  return self.collection[entityID];
}

- (void)storeEntity:(NASyncableObject *)entity
{
  NSParameterAssert(entity != nil);
  if (entity == nil)
  {
    return;
  }

  entity.myCollection = self;
  self.collection[entity.uid] = entity;
  
  // The collection's modification time is always equal to the latest of the
  // modification times of its members.
  if ([self.collectionModTime compare:entity.latestModTime] == NSOrderedAscending)
  {
    self.collectionModTime = entity.latestModTime;
  }
}

- (void)entityUpdated:(NASyncableObject*)entity
{
  NSParameterAssert(entity != nil);
  if (entity == nil)
  {
    return;
  }
  
  if (self.collection[entity.uid] == entity)
  {
    // The collection's modification time is always equal to the latest of the
    // modification times of its members.
    if ([self.collectionModTime compare:entity.latestModTime] == NSOrderedAscending)
    {
      self.collectionModTime = entity.latestModTime;
    }
  }
}

- (void)removeEntityWithID:(NSString*)entityID
{
  NSParameterAssert(entityID.length > 0);
  if (entityID == nil)
    return;
  
  [self.collection removeObjectForKey:entityID];
  NSDate *removeTime = [[NSDate alloc] init];
  self.collectionModTime = removeTime;
  
  self.removedIDs[entityID] = removeTime;
}

- (NSArray*)allKeys
{
  return [self.collection allKeys];
}

- (NSArray*)allEntities
{
  return [self.collection allValues];
}

- (NSInteger)entityCount
{
  return [self.collection count];
}

- (void)resetCollection
{
    self.collection = [NSMutableDictionary new];
    self.removedIDs = [NSMutableDictionary new];
    self.collectionModTime = [NSDate distantPast];
}

- (void)syncWithCollection:(NASyncableCollection*)syncCollection
               changeBlock:(SyncableCollectionChangeReportBlock)block
{
  [self syncWithCollection:syncCollection modifyLocal:YES modifyRemote:YES changeBlock:block];
}

- (void)syncFromCollection:(NASyncableCollection *)syncSource
               changeBlock:(SyncableCollectionChangeReportBlock)block
{
  [self syncWithCollection:syncSource modifyLocal:YES modifyRemote:NO changeBlock:block];
}

- (void)syncToCollection:(NASyncableCollection *)syncDestination
             changeBlock:(SyncableCollectionChangeReportBlock)block
{
  [self syncWithCollection:syncDestination modifyLocal:NO modifyRemote:YES changeBlock:block];
}

#pragma mark Private methods

- (void)syncWithCollection:(NASyncableCollection*)syncCollection
               modifyLocal:(BOOL)modifyLocal
              modifyRemote:(BOOL)modifyRemote
               changeBlock:(SyncableCollectionChangeReportBlock)block
{
  NSParameterAssert(syncCollection != nil);
  
  // Compare overall modification dates first.
  if ([self.collectionModTime compare:syncCollection.collectionModTime] == NSOrderedSame)
  {
    // Already synced.
    return;
  }
  
  // Iterate through my members and compare with syncCollection.
  NSDate *syncDate = [NSDate new];
  BOOL modified = NO;
  NSMutableDictionary *myMembers = [NSMutableDictionary dictionaryWithDictionary:self.collection];
  NSMutableDictionary *myRemovedIDs = [NSMutableDictionary dictionaryWithDictionary:self.removedIDs];
  NSMutableDictionary *syncMembers = [NSMutableDictionary dictionaryWithDictionary:syncCollection.collection];
  NSMutableDictionary *syncRemovedIDs = [NSMutableDictionary dictionaryWithDictionary:syncCollection.removedIDs];
  
  for (NASyncableObject *myMember in self.collection.allValues)
  {
    NASyncableObject *syncMember = syncMembers[myMember.uid];
    
    // If I didn't get syncMember, then that's one of 2 things:
    //   1. It's been removed on the other (sync) end
    //   2. It's been added on this end.
    if (syncMember == nil)
    {
      NSDate *removed = syncRemovedIDs[myMember.uid];
      if (removed)
      {
        // Check dates. Was this modified after removal on the other end? If so, keep it.
        NSComparisonResult removeDateCompare = [removed compare:myMember.latestModTime];
        switch (removeDateCompare)
        {
          default:
          case NSOrderedSame:
          case NSOrderedDescending:
            // Removed after modification - remove it.
            myRemovedIDs[myMember.uid] = removed;
            [myMembers removeObjectForKey:myMember.uid];
            if (block)
            {
              block(SyncableCollectionRemoveFromLocal, myMember);
            }
            break;
            
          case NSOrderedAscending:
            // Modified after removal - keep it. Log this somewhere or notify the user?
            [syncRemovedIDs removeObjectForKey:myMember.uid];
            if (block)
            {
              block(SyncableCollectionAddToRemote, myMember);
            }
            break;
        }
      }
      else
      {
        // Must have been added here. Nothing to do but keep it.
        if (block)
        {
          block(SyncableCollectionAddToRemote, myMember);
        }
      }
      modified = YES;
    }
    else
    {
      // Same record exists on both sides of the sync.
      // Compare dates.
      if ([myMember.latestModTime compare:syncMember.latestModTime] != NSOrderedSame)
      {
        // One or both modified. Sync records.
        BOOL localModified = NO;
        BOOL remoteModfified = NO;
        [myMember syncWith:syncMember modifyLocal:modifyLocal modifyRemote:modifyRemote localModified:&localModified remoteModified:&remoteModfified];
        if (block)
        {
          if (localModified)
          {
            block(SyncableCollectionModifiedLocal, myMember);
          }
          if (remoteModfified)
          {
            block(SyncableCollectionModifiedRemote, syncMember);
          }
        }
        myMember.myCollection = self;
        modified = YES;
        if (modifyRemote)
        {
          // Latest changes are in the remote record, so keep that one
          syncMember.myCollection = self;
          myMembers[myMember.uid] = syncMember;
        }
      }
      
      // Remove from syncMembers so I know I've seen it.
      [syncMembers removeObjectForKey:myMember.uid];
    }
  }
  
  // What's left in syncMembers?
  // They've either been added to the other end or were removed on this end.
  for (NASyncableObject *remainingSyncMember in [syncMembers allValues])
  {
    NSDate *removalDate = self.removedIDs[remainingSyncMember.uid];
    if (removalDate)
    {
      // Was removed on this end. Was it modified on the other end after that?
      // If so, keep it. Otherwise, lose it.
      NSComparisonResult removalCompare = [removalDate compare:remainingSyncMember.latestModTime];
      switch (removalCompare)
      {
        default:
        case NSOrderedSame:
        case NSOrderedDescending:
          // Removed after modification - nothing to do here.
          if (block)
          {
            block(SyncableCollectionRemoveFromRemote, remainingSyncMember);
          }
          break;
          
        case NSOrderedAscending:
          // Modified after removal - keep it by adding it back here.
          // Log this somewhere or notify the user?
          remainingSyncMember.myCollection = self;
          myMembers[remainingSyncMember.uid] = remainingSyncMember;
          [myRemovedIDs removeObjectForKey:remainingSyncMember.uid];
          if (block)
          {
            block(SyncableCollectionAddToLocal, remainingSyncMember);
          }
          break;
      }
    }
    else
    {
      // Not removed, so it must have been added on the other end. Add it here.
      remainingSyncMember.myCollection = self;
      myMembers[remainingSyncMember.uid] = remainingSyncMember;
      if (block)
      {
        block(SyncableCollectionAddToLocal, remainingSyncMember);
      }
    }
    
    modified = YES;
  }
  
  if (modified)
  {
    // Removed IDs should be a combination of both
    [myRemovedIDs addEntriesFromDictionary:syncRemovedIDs];
    
    if (modifyLocal)
    {
      self.collection = myMembers;
      self.removedIDs = myRemovedIDs;
      self.collectionModTime = syncDate;
    }
    
    if (modifyRemote)
    {
      syncCollection.collection = [myMembers mutableCopy];
      syncCollection.removedIDs = [myRemovedIDs mutableCopy];
      syncCollection.collectionModTime = syncDate;
    }
  }
}

- (void)registerAllEntities
{
  for (NASyncableObject *entity in [self allEntities])
  {
    entity.myCollection = self;
  }
}

@end
