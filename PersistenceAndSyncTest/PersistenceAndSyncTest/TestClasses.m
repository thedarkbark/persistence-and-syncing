//
//  TestClasses.m
//  PersistenceAndSyncTest
//
//  Created by Ken Worley on 7/24/15.
//  Copyright (c) 2015 Ken Worley. All rights reserved.
//

#import "TestClasses.h"

@implementation TestCoding
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _string = [aDecoder decodeObjectForKey:@"string"];
    }
    return self;
}

-(instancetype)initWithString:(NSString*)string
{
    self = [super init];
    if (self)
    {
        self.string = [string copy];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.string forKey:@"string"];
}

-(BOOL)isEqual:(id)object
{
    return ([object isKindOfClass:[TestCoding class]]
            && [self.string isEqualToString:((TestCoding*)object).string]);
}

-(id)copyWithZone:(NSZone *)zone
{
    TestCoding *copy = [[TestCoding alloc] initWithString:self.string];
    return copy;
}

@end

@implementation TestPersistentObject

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[TestPersistentObject class]])
    {
        return NO;
    }
    TestPersistentObject *pobj = (TestPersistentObject*)object;
    return ([self.string isEqualToString:pobj.string]
            && [self.number isEqualToNumber:pobj.number]
            && [self.array isEqualToArray:pobj.array]
            && [self.dict isEqualToDictionary:pobj.dict]
            && [self.codedObj isEqual:pobj.codedObj]);
}

@end

@implementation TestSyncableObject

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[TestSyncableObject class]])
    {
        return NO;
    }
    TestSyncableObject *sobj = (TestSyncableObject*)object;
    return ([self.string isEqualToString:sobj.string]
            && [self.number isEqualToNumber:sobj.number]
            && [self.array isEqualToArray:sobj.array]
            && [self.dict isEqualToDictionary:sobj.dict]
            && [self.codedObj isEqual:sobj.codedObj]);
}

-(id)copyWithZone:(NSZone *)zone
{
    TestSyncableObject *copy = [TestSyncableObject new];
    [self syncTo:copy];
    return copy;
}

@end

@implementation TestSimpleSyncable

-(instancetype)initWithString:(NSString*)string
{
    self = [super init];
    if (self)
    {
        self.string = [string copy];
    }
    return self;
}

+(instancetype)withString:(NSString *)string
{
    TestSimpleSyncable *tss = [[TestSimpleSyncable alloc] initWithString:string];
    return tss;
}

-(BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[TestSimpleSyncable class]]
        && [self.string isEqualToString:((TestSimpleSyncable*)object).string];
}

@end
