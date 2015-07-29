//
//  NAPersistentObjectTests.m
//  PersistenceAndSyncTest
//
//  Created by Ken Worley on 7/24/15.
//  Copyright (c) 2015 Ken Worley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestClasses.h"

@interface NAPersistentObjectTests : XCTestCase

@end

@implementation NAPersistentObjectTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPersistence
{
    TestPersistentObject *obj = [TestPersistentObject new];
    obj.string = @"testString";
    obj.number = @(5);
    obj.array = @[@(1),@(2),@(3)];
    obj.dict = @{@"one":@(1), @"two":@(2), @"three":@(3)};
    obj.codedObj = [[TestCoding alloc] initWithString:@"testCodingObj"];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"persistentTest.dat"];
    [obj writeToFile:path];
    
    TestPersistentObject *obj2 = [TestPersistentObject loadFromFile:path];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    XCTAssertEqualObjects(obj, obj2);
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

@end
