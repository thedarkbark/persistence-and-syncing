//
//  NASyncableObjectTests.m
//  PersistenceAndSyncTest
//
//  Created by Ken Worley on 7/24/15.
//  Copyright (c) 2015 Ken Worley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NASyncableObject.h"
#import "TestClasses.h"

@interface NASyncableObjectTests : XCTestCase

@end

@implementation NASyncableObjectTests

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

- (void)testSyncing
{
    TestSyncableObject *so1 = [TestSyncableObject new];
    so1.string = @"testString";
    so1.number = @(5);
    so1.array = @[@(1),@(2),@(3)];
    so1.dict = @{@"one":@(1), @"two":@(2), @"three":@(3)};
    so1.codedObj = [[TestCoding alloc] initWithString:@"testCodingObj"];
    
    TestSyncableObject *so2 = [so1 copy];
    TestSyncableObject *so3 = [so1 copy];
    TestSyncableObject *soFinal = [so1 copy];
    
    so1.string = @"modString";
    soFinal.string = @"modString";
    
    [NSThread sleepForTimeInterval:0.1];
    
    so2.number = @(10);
    soFinal.number = @(10);
    
    [NSThread sleepForTimeInterval:0.1];
    
    NSMutableDictionary *d = [so3.dict mutableCopy];
    d[@"one"] = @(111);
    so3.dict = d;
    soFinal.dict = d;
    
    [NSThread sleepForTimeInterval:0.1];
    
    NSArray *a = so2.array;
    so2.array = [a arrayByAddingObjectsFromArray:@[@(11),@(12),@(13)]];
    soFinal.array = [a arrayByAddingObjectsFromArray:@[@(11),@(12),@(13)]];

    [NSThread sleepForTimeInterval:0.1];
    
    TestCoding *tc = [[TestCoding alloc] initWithString:@"newTestCodingObj"];
    so3.codedObj = tc;
    soFinal.codedObj = tc;

    [NSThread sleepForTimeInterval:0.1];
    
    so1.string = @"finalString";
    soFinal.string = @"finalString";
    
    [NSThread sleepForTimeInterval:0.1];
    
    [so1 syncWith:so2];
    [so2 syncWith:so3];
    [so3 syncWith:so1];
    
    XCTAssertEqualObjects(so1, soFinal);
    XCTAssertEqualObjects(so2, soFinal);
    XCTAssertEqualObjects(so3, soFinal);
}

@end
