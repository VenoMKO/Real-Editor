//
//  FLightMap.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 26/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FLightMap.h"
#import "FGUID.h"

@implementation FLightMap

+ (instancetype)readFrom:(FIStream *)stream
{
  uint32_t type = [stream readInt:0];
  FLightMap *m = nil;
  
  switch (type) {
    case LMT_1D:
      m = [FLightMap1D readFrom:stream];
      break;
    case LMT_2D:
      m = [FLightMap2D readFrom:stream];
      break;
    default:
      m = [super readFrom:stream];
      break;
  }
  m.lightMapType = type;
  return m;
}

- (void)serializeFrom:(FIStream *)stream
{
  self.lightGuids = [FArray readFrom:stream type:[FGUID class]];
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.lightMapType];
  [d appendData:[self.lightGuids cooked:offset + d.length]];
  return d;
}

@end

@implementation FLightMap1D

+ (instancetype)readFrom:(FIStream *)stream
{
  FLightMap1D *m = [FLightMap1D newWithPackage:stream.package];// Don't call super
  [m serializeFrom:stream]; // Psuedo super serialize
  m.owner = [UObject readFrom:stream];
  m.directionalSamples = [FBulkData readFrom:stream];
  m.scaleVectors = [NSMutableArray readFrom:stream class:[FVector3 class] length:4];
  m.simpleSamples = [FBulkData readFrom:stream];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.owner cookedIndex]];
  [d appendData:[self.directionalSamples cooked:d.length + offset]];
  [d appendData:[self.scaleVectors cookedAt:d.length + offset]];
  [d appendData:[self.simpleSamples cooked:d.length + offset]];
  return d;
}

@end

@implementation FLightMap2D

+ (instancetype)readFrom:(FIStream *)stream
{
  DThrow(@"Untested!");
  FLightMap2D *m = [FLightMap2D newWithPackage:stream.package];// Don't call super
  [m serializeFrom:stream]; // Psuedo super serialize
  m.textures = [NSMutableArray new];
  m.scaleVectors = [NSMutableArray new];
  for (int idx = 0; idx < 4; ++idx)
  {
    UObject *o = [UObject readFrom:stream];
    if (!o)
    {
      DThrow(@"Failed to read lightmap!");
      return m;
    }
    [m.textures addObject:o];
    [m.scaleVectors addObject:[FVector3 readFrom:stream]];
  }
  m.coordinateScale = [FVector2D readFrom:stream];
  m.coordinateBias = [FVector2D readFrom:stream];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  for (int idx = 0; idx < 4; ++idx)
  {
    [d appendData:[self.textures[idx] cookedIndex]];
    [d appendData:[self.scaleVectors[idx] cooked:d.length + offset]];
  }
  [d appendData:[self.coordinateScale cooked:d.length + offset]];
  [d appendData:[self.coordinateBias cooked:d.length + offset]];
  return d;
}

@end
