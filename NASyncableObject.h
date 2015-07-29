//
//  NASyncableObject.h
//
//  Created by Ken Worley
//  Copyright (c) 2012-2015 Ken Worley. All rights reserved.
//
// Objects that derive from this class automatically keep track of when
// each (non-dynamic) property is modified. As a result, it's possible to
// "sync" objects of the same class so they end up with the same (most
// recent) property values and modification dates in both.
//

#import <Foundation/Foundation.h>
#import "NAPersistentObject.h"

extern NSString* const NASyncableObjectSavedNotification;

@class NASyncableCollection;

@interface NASyncableObject : NAPersistentObject

// Persistent properties
@property (nonatomic, copy) NSString *uid;
@property (atomic, strong) NSDate *latestModTime;

// These properties are dynamic (not persisted to storage)
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, weak) NASyncableCollection *myCollection;
@property (atomic, strong, readonly) NSDate *readTime;

// When was this property modified?
-(NSDate*)propertyModificationDate:(NSString*)propertyName;
-(void)setAllPropertyModificationDatesToLongAgo;

// Has this entity been modified since read from storage?
-(BOOL)isDirty;

// Used to save the root object in the object graph. Use parent class'
// loadFromFile to get from storage.
-(void)save;
-(void)saveToFile:(NSString*)path;

// Update the last modified date on this entity.
-(void)touch;

// Sync this object with another - this may modify one or both
// Check each object's isDirty method to see if modifications were made
-(void)syncWith:(NASyncableObject*)syncEntity;

// Sync this object to another - this will only modify the destination
// syncEntity object. Check its isDirty method to see if modifications
// were made. This object is not modified.
-(void)syncTo:(NASyncableObject*)syncDestination;

// Sync this object from another - this will only modify this object,
// not the sync source object. Check this object's isDirty method to
// see if any modifications were made.
-(void)syncFrom:(NASyncableObject*)syncSource;

@end
