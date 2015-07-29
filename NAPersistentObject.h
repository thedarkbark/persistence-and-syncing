//
//  NAPersistentObject.h
//
//  Created by Ken Worley 
//  Copyright (c) 2012-2015 Ken Worley. All rights reserved.
//
// An object of this class can be written to disk/data and recreated
// later. All properties of the object will be persisted as long as
// they are of a type that is NSCoding compliant (including other
// subclasses of NAPersistentObject). You could also persist an
// NSArray, NSSet, or NSDictionary containing objects that derive
// from NAPersistentObject.
//
// In order to mark properties as "runtime only" so they are not
// persisted, use the DYNAMIC macro inside the class implementation.
// For example, if your property is named runtimeCount, then include
// DYNAMIC(runtimeCount); in the class implementation.
//

#import <Foundation/Foundation.h>

// Use this macro to shield a property from being encoded/decoded when serializing/deserializing
#define DYNAMIC(propertyName) -(BOOL)noEncode##propertyName { return YES; }

@interface NAPersistentObject : NSObject <NSCoding>

// Initialize a new object
-(id)init;

// NSCoding compliance
-(id)initWithCoder:(NSCoder *)aDecoder;
-(void)encodeWithCoder:(NSCoder *)aCoder;

// Use when intializing from file or storing this object to file
+(id)loadFromFile:(NSString*)file;
-(BOOL)writeToFile:(NSString*)file;

// Use when initializing from NSData or encoding this object into NSData
+(id)loadFromData:(NSData*)data;
-(NSData*)objectAsData;

-(NSArray*)getPropertyNames;

@end
