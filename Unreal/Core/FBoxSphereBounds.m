//
//  FBoxSphereBounds.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 11/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FBoxSphereBounds.h"
#import "FArray.h"

@implementation FBox

+ (instancetype)readFrom:(FIStream *)stream
{
  FBox *box = [super readFrom:stream];
  box.min = [FVector3 readFrom:stream];
  box.max = [FVector3 readFrom:stream];
  return box;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *cooked = [NSMutableData new];
  [cooked appendData:[self.min cooked:offset]];
  [cooked appendData:[self.min cooked:cooked.length + offset]];
  return cooked;
}

@end

@implementation FSphereBounds

+ (instancetype)readFrom:(FIStream *)stream
{
  FSphereBounds *bounds = [super readFrom:stream];
  bounds.w = [stream readFloat:0];
  bounds.center = [FVector3 readFrom:stream];
  return bounds;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *cooked = [self.center cooked:offset];
  [cooked writeFloat:self.w];
  return cooked;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> {\n\tCenter: %@\n\tw:%f\n}",self.className,self.center,self.w];
}

@end

@implementation FBoxSphereBounds

+ (instancetype)readFrom:(FIStream *)stream
{
  FBoxSphereBounds *bounds = [super readFrom:stream];
  bounds.origin = [FVector3 readFrom:stream];
  bounds.extent = [FVector3 readFrom:stream];
  bounds.radius = [stream readFloat:0];
  return bounds;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *cooked = [self.origin cooked:offset];
  [cooked appendData:[self.extent cooked:offset]];
  [cooked writeFloat:self.radius];
  return cooked;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@> {\n\tOrigin: %@\n\tExtent:%@\n\tRadius:%f\n}",self.className,self.origin,self.extent,self.radius];
}

- (FBox *)box
{
  FBox *box = [FBox newWithPackage:self.package];
  box.min = [FVector3 newWithPackage:self.package];
  box.min.x = self.origin.x - self.extent.x;
  box.min.y = self.origin.y - self.extent.y;
  box.min.z = self.origin.z - self.extent.z;
  
  box.max = [FVector3 newWithPackage:self.package];
  box.max.x = self.origin.x + self.extent.x;
  box.max.y = self.origin.y + self.extent.y;
  box.max.z = self.origin.z + self.extent.z;
  return box;
}

@end

@implementation FTerrainBV

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainBV *bounds = [super readFrom:stream];
  bounds.bounds = [FBox readFrom:stream];
  return bounds;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.bounds cooked:offset];
}

@end

@implementation FConvexVolume

+ (instancetype)readFrom:(FIStream *)stream
{
  FConvexVolume *v = [super readFrom:stream];
  v.planes = [FArray readFrom:stream type:[FPlane class]];
  v.permutedPlanes = [FArray readFrom:stream type:[FPlane class]];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.planes cooked:offset]];
  [d appendData:[self.permutedPlanes cooked:offset + d.length]];
  return d;
}

@end
