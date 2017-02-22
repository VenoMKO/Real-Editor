//
//  Level.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "Level.h"
#import "Texture2D.h"

@implementation FKCachedConvexDataElement

+ (instancetype)readFrom:(FIStream *)stream
{
  FKCachedConvexDataElement *d = [super readFrom:stream];
  d.convexElementData = [FByteArray readFrom:stream];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.convexElementData cooked:offset];
}

@end

@implementation FKCachedPerTriData

+ (instancetype)readFrom:(FIStream *)stream
{
  FKCachedPerTriData *d = [super readFrom:stream];
  d.cachedPerTriData = [FByteArray readFrom:stream];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.cachedPerTriData cooked:offset];
}

@end

@implementation FKCachedConvexData

+ (instancetype)readFrom:(FIStream *)stream
{
  FKCachedConvexData *d = [super readFrom:stream];
  d.cachedConvexElements = [FArray readFrom:stream type:[FKCachedConvexDataElement class]];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.cachedConvexElements cooked:offset];
}

@end

@implementation FCachedPhysSMData

+ (instancetype)readFrom:(FIStream *)stream
{
  FCachedPhysSMData *d = [super readFrom:stream];
  d.scale3D = [FVector3 readFrom:stream];
  d.cachedDataIndex = [stream readInt:NULL];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.scale3D cooked:offset];
  [d writeInt:self.cachedDataIndex];
  return d;
}

@end

@implementation FCachedPerTriPhysSMData
@end

@implementation Level

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  self.actors = [TransFArray readFrom:s type:[UObject class]];
  self.url = [FURL readFrom:s];
  self.model = [UObject readFrom:s];
  [self.model properties];
  self.modelComponents = [FArray readFrom:s type:[UObject class]];
  self.gameSequences = [FArray readFrom:s type:[UObject class]];
  self.textureToInstancesMap = [FMap readFrom:s keyType:[Texture2D class] arrayType:[FStreamableTextureInstance class]];
  self.cachedPhysBSPData = [FByteArray readFrom:s];
  self.cachedPhysSMDataMap = [FMultiMap readFrom:s keyType:[UObject class] type:[FCachedPhysSMData class]]; // StaticMesh
  self.cachedPhysSMDataStore = [FArray readFrom:s type:[FKCachedConvexData class]];
  self.cachedPhysPerTriSMDataMap = [FMultiMap readFrom:s keyType:[UObject class] type:[FCachedPerTriPhysSMData class]]; // StaticMesh
  self.cachedPhysPerTriSMDataStore = [FArray readFrom:s type:[FKCachedPerTriData class]];
  self.cachedPhysBSPDataVersion = [s readInt:NULL];
  self.cachedPhysSMDataVersion = [s readInt:NULL];
  self.forceStreamTextures = [FMap readFrom:s keyType:[Texture2D class] type:[NSNumber class]];
  self.navListStart = [UObject readFrom:s];
  self.navListEnd = [UObject readFrom:s];
  
  self.coverListStart = [UObject readFrom:s];
  self.coverListEnd = [UObject readFrom:s];
  /*
  self.pylonListStart = [UObject readFrom:s];
  self.pylonListEnd = [UObject readFrom:s];
   */
  self.crossLevelActors = [FArray readFrom:s type:[UObject class]];
  self.unk = [s readInt:NULL];
  if (self.exportObject.originalOffset + self.exportObject.serialSize != s.position)
    DThrow(@"Found unexpected data!");
  return s;
}

@end
