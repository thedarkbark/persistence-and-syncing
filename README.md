Persistent and Syncable Objects
===============================

This project contains classes to help you persist objects and collections of objects as well as sync multiple copies of those objects and collections so they're all up to date.


##Persistent Objects


`NAPersistentObject`: a class that helps you persist data

`NAPersistentObject` makes it easy to persist an object of any subclass to disk (or a collection of those objects)
by automatically coding all properties defined in the subclass as long as they are **NSCoding** compliant (including
other objects that derive from `NAPersistentObject`).

***Example:***

	@interface MyObj : public NAPersistentObject
	@property (nonatomic, copy) NSString *myData;
	@end

	@implementation MyObj
	@end
	
	...
	
	MyObj *obj1 = [[MyObj alloc] init];
	obj1.myData = @"some data";
	
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"persistentTest.dat"];
    [obj1 writeToFile:path];
    
	MyObj *obj2 = [MyObj loadFromFile:path];
	
##Syncable Objects


`NASyncableObject` is a subclass of `NAPersistentObject`. A subclass of `NASyncableObject` is able to synchronize changes to any of its properties with another object of the same class by automatically tracking modification times. Syncing can go in one direction or both directions.

***Example:***

	@interface MyObj : public NASyncableObject
	@property (nonatomic, copy) NSString *d1;
	@property (nonatomic, copy) NSString *d2;
	@property (nonatomic, copy) NSString *d3;
	@end

	@implementation MyObj
	@end
	
	...
	
	MyObj *obj = [[MyObj alloc] init];
	obj1.d1 = @"1";
	obj1.d2 = @"2";
	obj1.d3 = @"3";
	
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"persistentTest.dat"];
    [obj1 writeToFile:path];
    
	MyObj *obj2 = [MyObj loadFromFile:path];
	obj2.d1 = @"5"; // obj2 now has d1=@"5", d2=@"2", d3=@"3"
	obj1.d3 = @"6"; // obj1 now has d1=@"1", d2=@"2", d3=@"6"

	[obj1 syncWith:obj2]; now both have d1=@"5", d2=@"2", d3=@"6"
	
##Syncable Collections

An `NASyncableCollection` object is a persistable container of `NASyncableObject` entities. The collection tracks additions, deletions and the latest modification date of any member entity and can sync with another `NASyncableCollection` object so both end up with the same entities and each of those entities have been synced with each other. 

Each entity is referenced in the collection by its unique identifier (its uid property). And of course, since the collection is an `NAPersistentObject` as well, the whole collection can be persisted to storage.

