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

id EnsureValue(id value, id def)
{
  return value ? value : def;
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

- (CGImageRef)heightMap
{
  if (!self.properties)
    [self readProperties];
  int width = _numVerticesX;
  int height = _numVerticesY;
  
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, (Byte*)rawHeights, width * height * 2, NULL);
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrder16Little | kCGImageAlphaNone;
  CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
  
  CGImageRef imageRef = CGImageCreate(width,
                                      height,
                                      16 /*bitsPerComponent*/,
                                      16 /*bitsPerPixel*/,
                                      2 * width /*bytesPerRow*/,
                                      colorSpaceRef,
                                      bitmapInfo,
                                      provider,
                                      NULL /*decode*/,
                                      NO /*shouldInterpolate*/,
                                      renderingIntent);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpaceRef);
  return imageRef;
}

- (NSDictionary *)exp
{
  NSMutableDictionary *d = [NSMutableDictionary new];
  d[@"DrawScale"] = EnsureValue([self propertyValue:@"DrawScale"], @1);
  d[@"NumSectionsX"] = EnsureValue([self propertyValue:@"NumSectionsX"], @1);
  d[@"NumSectionsY"] = EnsureValue([self propertyValue:@"NumSectionsY"], @1);
  d[@"Location"] = EnsureValue([self propertyValue:@"Location"], [FVector3 vectorX:0 y:0 z:0]);
  d[@"DrawScale3D"] = EnsureValue([self propertyValue:@"DrawScale3D"], [FVector3 vectorX:1 y:1 z:1]);
  
  return d;
}

- (NSString *)info
{
  float drawScale = 1.;
  int sectionsX = 1;
  int sectionsY = 1;
  int x = 0;
  int y = 0;
  int z = 0;
  FPropertyTag *p = [self propertyForName:@"DrawScale"];
  if (p)
  {
    drawScale = [[p value] floatValue];
  }
  p = [self propertyForName:@"NumSectionsX"];
  if (p)
  {
    sectionsX = [[p value] intValue];
  }
  p = [self propertyForName:@"NumSectionsY"];
  if (p)
  {
    sectionsY = [[p value] intValue];
  }
  p = [self propertyForName:@"Location"];
  if (p)
  {
    FVector3 *v = [p value];
    x = (int)[v x];
    y = (int)[v y];
    z = (int)[v z];
  }
  
  NSString *terrainInfo = [NSString stringWithFormat:@"Scale: %f Sections: %d x %d\n", drawScale, sectionsX, sectionsY];
  terrainInfo = [terrainInfo stringByAppendingFormat:@"Position: %d %d %d", x, y, z];
  
  p = [self propertyForName:@"DrawScale3D"];
  if (p)
  {
    FVector3 *v = [p value];
    terrainInfo = [terrainInfo stringByAppendingFormat:@"\nScale3D: %f %f %f", v.x, v.y, v.z];
  }
  return terrainInfo;
}

@end
