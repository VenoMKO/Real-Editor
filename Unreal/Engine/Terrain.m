//
//  Terrain.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "Terrain.h"
#import "UPackage.h"
#import "FStream.h"
#import <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>

const int MSP_MAX = 1;
#define TERRAIN_ZSCALE				(1.0f/128.0f)

short Height(int x, int y, int maxX, int maxY, short *height)
{
  x = MAX(MIN(x, maxX - 1),0);
  y = MAX(MIN(y, maxY - 1),0);
  return height[y * maxX + x];
}

@interface Terrain()
{
  short *rawHeights;
  SCNVector3 *verts;
}
@end

@implementation Terrain

- (void)dealloc
{
  if (rawHeights)
    free(rawHeights);
  if (verts)
    free(verts);
}

- (FIStream *)postProperties
{
  FPropertyTag *t = [self propertyForName:@"NumVerticesX"];
  self.numVerticesX = [t.value intValue];
  t = [self propertyForName:@"NumVerticesY"];
  self.numVerticesY = [t.value intValue];
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  self.heights = [FArray readFrom:s type:[FTerrainHeight class]];
  self.infoData = [FArray readFrom:s type:[FTerrainInfoData class]];
  self.alphaMaps = [s readData:[s readInt:0]];
  self.weightedTextureMaps = [FArray readFrom:s type:[UObject class]];
  rawHeights = calloc(self.heights.count, sizeof(short));
  
  for (FTerrainHeight *th in self.heights)
  {
    rawHeights[[self.heights indexOfObject:th]] = th.value;
  }
  
  verts = calloc(self.numVerticesX * self.numVerticesY, sizeof(SCNVector3));
  
  for (int x = 0; x < self.numVerticesX; ++x)
  {
    for (int y = 0; y < self.numVerticesY; ++y)
    {
      verts[x + y].x = (float)x;
      verts[x + y].y = (float)y;
      verts[x + y].z = (/*-32768.0 - */Height(x, y, _numVerticesX, _numVerticesY, rawHeights)) * TERRAIN_ZSCALE;
    }
  }
  /*
  self.cachedTerrainMaterials = [FArray readFrom:s type:[FTerrainMaterialResource class]];
  self.cachedMaterialsDummy = [FArray readFrom:s type:[FTerrainMaterialResource class]];
   */
  return s;
}

- (SCNNode *)renderNode:(NSUInteger)lod
{
  [self properties];
  SCNNode *n = [SCNNode new];
  const CGFloat scale = 130;
  for (int x = 0; x < _numVerticesX - 1; ++x)
  {
    for (int y = 0; y < _numVerticesY - 1; ++y)
    {
      SCNNode *spn = [SCNNode new];
      SCNVector3 pos = verts[x + y];
      pos.x *= scale;
      pos.y *= scale;
      pos.z *= scale;
      spn.position = pos;
      SCNSphere *sp =[SCNSphere sphereWithRadius:scale];
      spn.geometry = sp;
      [n addChildNode:spn];
    }
  }
  return n;
}

- (NSArray *)materials
{
  return nil;
}


- (NSString *)xib
{
  return @"StaticMesh";
}

@end
