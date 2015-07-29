//
//  TestClasses.h
//  PersistenceAndSyncTest
//
//  Created by Ken Worley on 7/24/15.
//  Copyright (c) 2015 Ken Worley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NAPersistentObject.h"
#import "NASyncableObject.h"

// This is an example of an NSCoding compliant class for inclusion in the persistent test object
@interface TestCoding : NSObject<NSCoding, NSCopying>
@property (nonatomic, copy) NSString *string;
-(instancetype)initWithString:(NSString*)string;
@end


@interface TestPersistentObject : NAPersistentObject
// Any NSCoding compliant properties will get persisted
@property (nonatomic, copy) NSString *string;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, copy) NSArray *array;
@property (nonatomic, copy) NSDictionary *dict;
@property (nonatomic, strong) TestCoding *codedObj;
@end

@interface TestSyncableObject : NASyncableObject <NSCopying>
@property (nonatomic, copy) NSString *string;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, copy) NSArray *array;
@property (nonatomic, copy) NSDictionary *dict;
@property (nonatomic, strong) TestCoding *codedObj;
@end

@interface TestSimpleSyncable : NASyncableObject
@property (nonatomic, copy) NSString *string;
+(instancetype)withString:(NSString*)string;
-(instancetype)initWithString:(NSString*)string;
@end