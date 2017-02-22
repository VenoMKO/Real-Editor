//
//  FVector.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FVector.h"

@implementation FVector2D

+ (instancetype)readFrom:(FIStream *)stream
{
  FVector2D *v = [super readFrom:stream];
  v.x = [stream readFloat:0];
  v.y = [stream readFloat:0];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeFloat:self.x];
  [d writeFloat:self.y];
  return d;
}

- (id)copyWithZone:(NSZone *)zone
{
  FVector2D *v = [FVector2D newWithPackage:self.package];
  v.x = self.x;
  v.y = self.y;
  
  return v;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> %f, %f",self.className,self.x,self.y];
}

- (id)plist
{
  return @{@"x" : @(self.x), @"y" : @(self.y), @"type" : @"2"};
}


@end

@implementation FVector3

+ (instancetype)readFrom:(FIStream *)stream
{
  FVector3 *v = [super readFrom:stream];
  v.x = [stream readFloat:0];
  v.y = [stream readFloat:0];
  v.z = [stream readFloat:0];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeFloat:self.x];
  [d writeFloat:self.y];
  [d writeFloat:self.z];
  return d;
}

- (id)copyWithZone:(NSZone *)zone
{
  FVector3 *v = [FVector3 newWithPackage:self.package];
  v.x = self.x;
  v.y = self.y;
  v.z = self.z;
  
  return v;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> %f, %f, %f",self.className,self.x,self.y,self.z];
}

- (id)plist
{
  return @{@"x" : @(self.x), @"y" : @(self.y), @"z" : @(self.z), @"type" : @"3"};
}

- (GLKVector3)glkVector3
{
  return GLKVector3Make(self.x, self.y, self.z);
}


@end

@implementation FVector4

+ (instancetype)readFrom:(FIStream *)stream
{
  FVector4 *v = [super readFrom:stream];
  v.w = [stream readFloat:0];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeFloat:self.w];
  return d;
}

- (id)copyWithZone:(NSZone *)zone
{
  FVector4 *v = [FVector4 newWithPackage:self.package];
  v.x = self.x;
  v.y = self.y;
  v.z = self.z;
  v.w = self.w;
  
  return v;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> %f, %f, %f, %f",self.className,self.x,self.y,self.z,self.w];
}

- (id)plist
{
  return @{@"x" : @(self.x), @"y" : @(self.y), @"z" : @(self.z), @"w" : @(self.w), @"type" : @"4"};
}

- (GLKVector4)glkVector4
{
  return GLKVector4Make(self.x, self.y, self.z, self.w);
}

@end

@implementation FDVector3

+ (instancetype)readFrom:(FIStream *)stream
{
  FDVector3 *v = [super readFrom:stream];
  v.x = [stream readInt:0];
  v.y = [stream readInt:0];
  v.z = [stream readInt:0];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:self.x];
  [d writeInt:self.y];
  [d writeInt:self.z];
  return d;
}

- (id)copyWithZone:(NSZone *)zone
{
  FDVector3 *v = [FDVector3 newWithPackage:self.package];
  v.x = self.x;
  v.y = self.y;
  v.z = self.z;
  
  return v;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> %d, %d, %d",self.className,self.x,self.y,self.z];
}

- (id)plist
{
  return @{@"x" : @(self.x), @"y" : @(self.y), @"z" : @(self.z), @"type" : @"d3"};
}

@end

@implementation FPlane
@end

@implementation FDVector4

+ (instancetype)readFrom:(FIStream *)stream
{
  FDVector4 *v = [super readFrom:stream];
  v.w = [stream readInt:0];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:self.w];
  return d;
}

- (id)copyWithZone:(NSZone *)zone
{
  FDVector4 *v = [FDVector4 newWithPackage:self.package];
  v.x = self.x;
  v.y = self.y;
  v.z = self.z;
  v.w = self.w;
  
  return v;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> %d, %d, %d, %d",self.className,self.x,self.y,self.z,self.w];
}

- (id)plist
{
  return @{@"x" : @(self.x), @"y" : @(self.y), @"z" : @(self.z), @"w" : @(self.w), @"type" : @"d4"};
}

@end
