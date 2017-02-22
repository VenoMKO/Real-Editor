//
//  FTerrain.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 12/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FTerrain.h"
#import "UObject.h"
#import "FGUID.h"

@implementation FTerrainHeight

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainHeight *h = [super readFrom:stream];
  h.value = [stream readShort:0];
  return h;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeShort:self.value];
  return d;
}

@end

@implementation FTerrainInfoData

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainInfoData *h = [super readFrom:stream];
  h.data = [stream readByte:0];
  return h;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeByte:self.data];
  return d;
}

@end

@implementation FAlphaMap

+ (instancetype)readFrom:(FIStream *)stream
{
  FAlphaMap *m = [super readFrom:stream];
  m.data = [FByteArray readFrom:stream];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.data cooked:0]];
  return d;
}

@end

@implementation FTerrainMaterialMask

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainMaterialMask *m = [super readFrom:stream];
  m.numBits = [stream readInt:0];
  m.bitMask = [stream readLong:0];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.numBits];
  [d writeLong:self.bitMask];
  return d;
}

@end

@implementation FTerrainMaterialResource

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainMaterialResource *r = [super readFrom:stream];
  r.terrain = [UObject readFrom:stream];
  r.materialMask = [FTerrainMaterialMask readFrom:stream];
  r.materialIds = [FArray readFrom:stream type:[FGUID class]];
  r.bEnableSpecular = [stream readInt:0];
  return r;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.terrain cookedIndex]];
  [d appendData:[self.materialMask cooked:offset + d.length]];
  [d appendData:[self.materialIds cooked:offset + d.length]];
  return d;
}

@end

@implementation FCachedTerrainMaterialArray

+ (instancetype)readFrom:(FIStream *)stream
{
  FCachedTerrainMaterialArray *m = [super readFrom:stream];
  m.cachedMaterials = [FArray readFrom:stream type:[FTerrainMaterialResource class]];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.cachedMaterials cooked:offset + d.length]];
  return d;
}

@end

@implementation FTerrainLayer

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainLayer *l = [super readFrom:stream];
  
  return l;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  
  return d;
}

@end

@implementation FTerrainBVNode

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainBVNode *l = [super readFrom:stream];
  l.boundingVolume = [FTerrainBV readFrom:stream];
  l.bIsLeaf = [stream readInt:0];
  l.nodeIndex1 = [stream readShort:0];
  l.nodeIndex2 = [stream readShort:0];
  l.nodeIndex3 = [stream readShort:0];
  l.nodeIndex4 = [stream readShort:0];
  return l;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.boundingVolume cooked:offset];
  [d writeInt:self.bIsLeaf];
  [d writeShort:self.nodeIndex1];
  [d writeShort:self.nodeIndex2];
  [d writeShort:self.nodeIndex3];
  [d writeShort:self.nodeIndex4];
  return d;
}

@end

@implementation FTerrainBVTree

+ (instancetype)readFrom:(FIStream *)stream
{
  FTerrainBVTree *t = [super readFrom:stream];
  t.nodes = [FArray readFrom:stream type:[FTerrainBVNode class]];
  return t;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.nodes cooked:offset];
}

@end
