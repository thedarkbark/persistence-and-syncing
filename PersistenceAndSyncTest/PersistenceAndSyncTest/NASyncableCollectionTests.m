//
//  NASyncableCollectionTests.m
//  PersistenceAndSyncTest
//
//  Created by Ken Worley on 7/27/15.
//  Copyright (c) 2015 Ken Worley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NASyncableCollection.h"
#import "TestClasses.h"

@interface NASyncableCollectionTests : XCTestCase

@end

@implementation NASyncableCollectionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testCollectionSyncing
{
    NASyncableCollection *c1 = [NASyncableCollection new];
    
    TestSimpleSyncable *e1 = [TestSimpleSyncable withString:@"1"];
    TestSimpleSyncable *e2 = [TestSimpleSyncable withString:@"2"];
    TestSimpleSyncable *e3 = [TestSimpleSyncable withString:@"3"];
    TestSimpleSyncable *e4 = [TestSimpleSyncable withString:@"4"];
    TestSimpleSyncable *e5 = [TestSimpleSyncable withString:@"5"];

    [c1 storeEntity:e1];
    [c1 storeEntity:e2];
    [c1 storeEntity:e3];
    [c1 storeEntity:e4];
    [c1 storeEntity:e5];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"persistentCollection.dat"];
    [c1 writeToFile:path];
    NASyncableCollection *c2 = [NASyncableCollection loadFromFile:path];
    XCTAssertEqualObjects(c1, c2);
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    TestSimpleSyncable *e6 = [TestSimpleSyncable withString:@"6"];
    TestSimpleSyncable *e7 = [TestSimpleSyncable withString:@"7"];
    TestSimpleSyncable *e8 = [TestSimpleSyncable withString:@"8"];
    TestSimpleSyncable *e9 = [TestSimpleSyncable withString:@"9"];
    TestSimpleSyncable *e0 = [TestSimpleSyncable withString:@"0"];
    
    [c1 storeEntity:e6];
    [c2 storeEntity:e7];
    [c1 storeEntity:e8];
    [c2 storeEntity:e9];
    [c1 storeEntity:e0];
    
    [c1 removeEntityWithID:e3.uid];
    [c2 removeEntityWithID:e7.uid];
    
    XCTAssert([c1 entityCount] == 7);
    XCTAssert([c2 entityCount] == 6);
    
    [c1 syncWithCollection:c2 changeBlock:nil];
    
    XCTAssert([c1 entityCount] == 8);
    XCTAssert([c2 entityCount] == 8);
    XCTAssertEqualObjects(c1, c2);
    
    XCTAssert([c1 entityWithID:e3.uid] == nil);
    XCTAssert([c1 entityWithID:e7.uid] == nil);
    
    TestSimpleSyncable *e9a = [c1 entityWithID:e9.uid];
    e9a.string = @"updated9";
    [c1 storeEntity:e9a];
    TestSimpleSyncable *e2a = [c2 entityWithID:e2.uid];
    e2a.string = @"updated2";
    [c2 storeEntity:e2a];
    
    [c1 syncWithCollection:c2 changeBlock:NULL];
    
    XCTAssertEqualObjects(c1, c2);
    
    TestSimpleSyncable *e9test = [c2 entityWithID:e9.uid];
    XCTAssert([e9test.string isEqualToString:@"updated9"]);
    
    TestSimpleSyncable *e2test = [c1 entityWithID:e2.uid];
    XCTAssert([e2test.string isEqualToString:@"updated2"]);
}

@end
