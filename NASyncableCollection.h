//
//  NASyncableCollection.h
//
//  Created by Ken Worley
//  Copyright (c) 2012 Ken Worley. All rights reserved.
//

#import "NASyncableObject.h"

// When requesting changes from a sync via callback, you'll use a
// block of this type and compare the change type with one of these
// constants.
typedef NS_ENUM(NSInteger, SyncableCollectionChangeType)
{
  SyncableCollectionModifiedLocal = 1,
  SyncableCollectionAddToLocal,
  SyncableCollectionRemoveFromLocal,
  SyncableCollectionModifiedRemote,
  SyncableCollectionAddToRemote,
  SyncableCollectionRemoveFromRemote
};
typedef void(^SyncableCollectionChangeReportBlock)(SyncableCollectionChangeType changeType, NASyncableObject *entity);

@interface NASyncableCollection : NASyncableObject

- (id)entityWithID:(NSString*)entityID;
- (void)storeEntity:(NASyncableObject*)entity;
- (void)removeEntityWithID:(NSString*)entityID;
- (void)entityUpdated:(NASyncableObject*)entity;

- (NSArray*)allKeys;
- (NSArray*)allEntities;
- (NSInteger)entityCount;

// Clear/empty the collection. This should be rare. Does not track
// removed entity IDs - that is also cleared.
- (void)resetCollection;

// == Sync changes with change reports via callback block ==
// block is optional

// Updates both collections to latest
- (void)syncWithCollection:(NASyncableCollection*)syncCollection
               changeBlock:(SyncableCollectionChangeReportBlock)block;

// Updates this collection to latest - doesn't modify syncSource
// Remote changes will be reported even though the remote collection
// is not modified
- (void)syncFromCollection:(NASyncableCollection*)syncSource
               changeBlock:(SyncableCollectionChangeReportBlock)block;

// Updates syncDestination to latest - doesn't modify this collection
// Local changes will be reported even though the local collection
// is not modified
- (void)syncToCollection:(NASyncableCollection*)syncDestination
             changeBlock:(SyncableCollectionChangeReportBlock)block;

@end
