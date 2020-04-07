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
#import "T3DUtils.h"
#import "FTerrain.h"

#define TERRAIN_ZSCALE				(1.0f/128.0f)
#define MAX_HEIGHTMAP_TEXTURE_SIZE 512
#define HEIGHTDATA(X,Y) (heightData[ MIN(Y, MAX(0,vertsY)) * vertsX + MIN(X,MAX(0,vertsX)) ])

uint16_t *ExpandTerrainData(const uint16_t *Data, int OldMinX, int OldMinY, int OldMaxX, int OldMaxY, int NewMinX, int NewMinY, int NewMaxX, int NewMaxY, int *newWidth, int *newHeight);

@interface FHeightmapInfo : NSObject
@property float HeightmapSizeU;
@property float HeightmapSizeV;
@property NSMutableData *HeightmapTexture;
@end

@implementation FHeightmapInfo
@end

@interface FLandscapeCollisionSize : NSObject
@property int SubsectionSizeVerts;
@property int SubsectionSizeQuads;
@property int SizeVerts;
@property int SizeVertsSquare;
@end

@implementation FLandscapeCollisionSize

+ (instancetype)size:(int)numSubsections subsectionSize:(int)subsectionSizeQuads mip:(int)mipLevel
{
  FLandscapeCollisionSize *s = [FLandscapeCollisionSize new];
  s.SubsectionSizeVerts = (subsectionSizeQuads + 1) >> mipLevel;
  s.SubsectionSizeQuads = s.SubsectionSizeVerts - 1;
  s.SizeVerts = numSubsections * s.SubsectionSizeQuads + 1;
  s.SizeVertsSquare = s.SizeVerts * s.SizeVerts;
  return s;
}

@end



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
  return s;
}

- (void)exportToT3D:(NSMutableString*)result padding:(unsigned)padding index:(unsigned)index
{
  if (!self.properties)
  {
    [self readProperties];
  }
  if (!rawHeights)
  {
    rawHeights = calloc(self.heights.count, sizeof(short));
    for (FTerrainHeight *th in self.heights)
    {
      rawHeights[[self.heights indexOfObject:th]] = th.value;
    }
  }
  
  int sectionSizes[] = {7, 15, 31, 63, 127, 255};
  int numSections[] = {1, 2};
  const int sectionSizesCount = 6;
  const int numSectionsCount = 2;
  
  int quadsPerSection = 0;
  int sectionsPerComponent = 0;
  int componentCountX = 0;
  int componentCountY = 0;
  
  // Find matching size for UE4
  BOOL foundSize = NO;
  for (int sectionSizesIdx = sectionSizesCount - 1; sectionSizesIdx >= 0; --sectionSizesIdx)
  {
    for (int numSectionsIdx = numSectionsCount - 1; numSectionsIdx >= 0; --numSectionsIdx)
    {
      int ss = sectionSizes[sectionSizesIdx];
      int ns = numSections[numSectionsIdx];
      
      if(((_numVerticesX - 1) % (ss * ns)) == 0 && ((_numVerticesX - 1) / (ss * ns)) <= 32 &&
        ((_numVerticesY - 1) % (ss * ns)) == 0 && ((_numVerticesY - 1) / (ss * ns)) <= 32)
      {
        quadsPerSection = ss;
        sectionsPerComponent = ns;
        componentCountX = CLAMP((_numVerticesX - 1) / (ss * ns), 1, MIN(32, floor(8191. / (sectionsPerComponent * quadsPerSection))));
        componentCountY = CLAMP((_numVerticesY - 1) / (ss * ns), 1, MIN(32, floor(8191. / (sectionsPerComponent * quadsPerSection))));
        foundSize = YES;
        break;
      }
    }
    if (foundSize)
    {
      break;
    }
  }
  
  if (!foundSize)
  {
    const int CurrentSectionSize = 63;
    const int CurrentNumSections = 1;
    for(int SectionSizesIdx = 0; SectionSizesIdx < sectionSizesCount; SectionSizesIdx++)
    {
      if(sectionSizes[SectionSizesIdx] < CurrentSectionSize)
      {
        continue;
      }
      
      const int ComponentsX = DivideAndRoundUp((_numVerticesX - 1), sectionSizes[SectionSizesIdx] * CurrentNumSections);
      const int ComponentsY = DivideAndRoundUp((_numVerticesY - 1), sectionSizes[SectionSizesIdx] * CurrentNumSections);
      if(ComponentsX <= 32 && ComponentsY <= 32)
      {
        foundSize = true;
        quadsPerSection = sectionSizes[SectionSizesIdx];
        sectionsPerComponent = 1;
        componentCountX = CLAMP(ComponentsX, 1, MIN(32, floor(8191. / (sectionsPerComponent * quadsPerSection))));
        componentCountY = CLAMP(ComponentsY, 1, MIN(32, floor(8191. / (sectionsPerComponent * quadsPerSection))));
        break;
      }
    }
  }
  
  if (!foundSize)
  {
    const int MaxSectionSize = sectionSizes[sectionSizesCount - 1];
    const int MaxNumSubSections = numSections[numSectionsCount - 1];
    const int ComponentsX = DivideAndRoundUp((_numVerticesX - 1), MaxSectionSize * MaxNumSubSections);
    const int ComponentsY = DivideAndRoundUp((_numVerticesY - 1), MaxSectionSize * MaxNumSubSections);

    foundSize = true;
    quadsPerSection = MaxSectionSize;
    sectionsPerComponent = MaxNumSubSections;
    componentCountX = CLAMP(ComponentsX, 1, MIN(32, floor(8191. / (sectionsPerComponent * quadsPerSection))));
    componentCountY = CLAMP(ComponentsY, 1, MIN(32, floor(8191. / (sectionsPerComponent * quadsPerSection))));
  }
  
  if (!quadsPerSection)
  {
    DThrow(@"Failed to find correct size!");
    return;
  }
  
  // Resize rawHeights to new size(UE4 size)
  const int minX = 0;
  const int minY = 0;
  const int quadsPerComponent = quadsPerSection * sectionsPerComponent;
  const int sizeX = componentCountX * quadsPerComponent + 1;
  const int sizeY = componentCountY * quadsPerComponent + 1;
  const int offsetX = (int)(sizeX - _numVerticesX) / 2;
  const int offsetY = (int)(sizeY - _numVerticesY) / 2;
  
  int newWidth = 0;
  int newHeight = 0;
  uint16_t *heightData = calloc(sizeX * sizeY, sizeof(uint16_t));
  for(int i = 0; i < sizeX * sizeY; i++)
  {
    heightData[i] = 32768;
  }
  
  heightData = ExpandTerrainData((uint16_t *)rawHeights, minX, minY, _numVerticesX - 1, _numVerticesY - 1, -offsetX, -offsetY, sizeX - offsetX - 1, sizeY - offsetY - 1, &newWidth, &newHeight);
  
  const int vertsX = (sizeX - 1) - minX + 1;
  const int vertsY = (sizeY - 1) - minY + 1;
  const int componentSizeQuads = sectionsPerComponent * quadsPerSection;
  const int numSubsections = sectionsPerComponent;
  const int subsectionSizeQuads = quadsPerSection;
  const int numPatchesX = (vertsX - 1);
  const int numPatchesY = (vertsY - 1);
  const int numComponentsX = numPatchesX / componentSizeQuads;
  const int numComponentsY = numPatchesY / componentSizeQuads;
  
  GLKVector3 *vertexNormals = calloc(vertsX * vertsY, sizeof(GLKVector3));
  
  const int ComponentSizeVerts = numSubsections * (subsectionSizeQuads + 1);
  const int ComponentsPerHeightmap = MIN(MAX_HEIGHTMAP_TEXTURE_SIZE / ComponentSizeVerts, 1 << (5 - 2));

  // Count how many heightmaps we need and the X dimension of the final heightmap
  int NumHeightmapsX = 1;
  int FinalComponentsX = numComponentsX;
  while (FinalComponentsX > ComponentsPerHeightmap)
  {
    FinalComponentsX -= ComponentsPerHeightmap;
    NumHeightmapsX++;
  }
  // Count how many heightmaps we need and the Y dimension of the final heightmap
  int NumHeightmapsY = 1;
  int FinalComponentsY = numComponentsY;
  while (FinalComponentsY > ComponentsPerHeightmap)
  {
    FinalComponentsY -= ComponentsPerHeightmap;
    NumHeightmapsY++;
  }

  NSMutableArray *HeightmapInfos = [NSMutableArray new];

  for (int HmY = 0; HmY < NumHeightmapsY; HmY++)
  {
    for (int HmX = 0; HmX < NumHeightmapsX; HmX++)
    {
      [HeightmapInfos addObject:[FHeightmapInfo new]];
      FHeightmapInfo *HeightmapInfo = [HeightmapInfos lastObject];

      // make sure the heightmap UVs are powers of two.
      HeightmapInfo.HeightmapSizeU = ((HmX == NumHeightmapsX - 1) ? FinalComponentsX : ComponentsPerHeightmap) * ComponentSizeVerts;
      HeightmapInfo.HeightmapSizeV = ((HmY == NumHeightmapsY - 1) ? FinalComponentsY : ComponentsPerHeightmap) * ComponentSizeVerts;

      // Construct the heightmap textures
      //HeightmapInfo.HeightmapTexture = CreateLandscapeTexture(HeightmapInfo.HeightmapSizeU, HeightmapInfo.HeightmapSizeV, TEXTUREGROUP_Terrain_Heightmap, TSF_BGRA8);
      HeightmapInfo.HeightmapTexture = [NSMutableData dataWithLength:HeightmapInfo.HeightmapSizeU * HeightmapInfo.HeightmapSizeV * sizeof(int)];
    }
  }
  
  float scale = ((FVector3 *)EnsureValue([self propertyValue:@"DrawScale3D"], [FVector3 vectorX:256 y:256 z:256])).z * [EnsureValue([self propertyValue:@"DrawScale"], @1) floatValue];
  for (int quadY = 0; quadY < numPatchesY; quadY++)
  {
    for (int quadX = 0; quadX < numPatchesX; quadX++)
    {
      GLKVector3 v00 = GLKVector3MultiplyScalar(GLKVector3Make(0, 0, ((float)HEIGHTDATA(quadX + 0, quadY + 0) - 32768.) * TERRAIN_ZSCALE), scale);
      GLKVector3 v01 = GLKVector3MultiplyScalar(GLKVector3Make(0, 1, ((float)HEIGHTDATA(quadX + 0, quadY + 1) - 32768.) * TERRAIN_ZSCALE), scale);
      GLKVector3 v10 = GLKVector3MultiplyScalar(GLKVector3Make(1, 0, ((float)HEIGHTDATA(quadX + 1, quadY + 0) - 32768.) * TERRAIN_ZSCALE), scale);
      GLKVector3 v11 = GLKVector3MultiplyScalar(GLKVector3Make(1, 1, ((float)HEIGHTDATA(quadX + 1, quadY + 1) - 32768.) * TERRAIN_ZSCALE), scale);
      
      GLKVector3 faceNormal1 = GLKVector3CrossProduct(GLKVector3Subtract(v00, v10), GLKVector3Subtract(v10, v11));
      faceNormal1 = GLKVector3MultiplyScalar(faceNormal1,  1.0f / sqrtf((faceNormal1.x * faceNormal1.x) + (faceNormal1.y * faceNormal1.y) + (faceNormal1.z * faceNormal1.z)));
      
      GLKVector3 faceNormal2 = GLKVector3CrossProduct(GLKVector3Subtract(v11, v01), GLKVector3Subtract(v01, v00));
      faceNormal2 = GLKVector3MultiplyScalar(faceNormal2,  1.0f / sqrtf((faceNormal2.x * faceNormal2.x) + (faceNormal2.y * faceNormal2.y) + (faceNormal2.z * faceNormal2.z)));
      
      vertexNormals[(quadX + 1 + vertsX * (quadY + 0))] = GLKVector3Add(vertexNormals[(quadX + 1 + vertsX * (quadY + 0))], faceNormal1);
      vertexNormals[(quadX + 0 + vertsX * (quadY + 1))] = GLKVector3Add(vertexNormals[(quadX + 0 + vertsX * (quadY + 1))], faceNormal2);
      vertexNormals[(quadX + 0 + vertsX * (quadY + 0))] = GLKVector3Add(vertexNormals[(quadX + 0 + vertsX * (quadY + 0))], GLKVector3Add(faceNormal1, faceNormal2));
      vertexNormals[(quadX + 1 + vertsX * (quadY + 1))] = GLKVector3Add(vertexNormals[(quadX + 1 + vertsX * (quadY + 1))], GLKVector3Add(faceNormal1, faceNormal2));
    }
  }
  
  NSMutableArray<T3DLandscapeComponent*> *components = [NSMutableArray new];
  NSMutableArray<T3DLandscapeCollisionComponent*> *collisionComponents = [NSMutableArray new];
  for (int x = 0; x < componentCountX * componentCountY; ++x)
  {
    T3DLandscapeComponent *lc = [T3DLandscapeComponent new];
    T3DLandscapeCollisionComponent *lcc = [T3DLandscapeCollisionComponent new];
    [components addObject:lc];
    [collisionComponents addObject:lcc];
    lc.index = x;
    lcc.index = componentCountX * componentCountY + x;
    lcc.renderComponent = lc;
    lc.collisionComponent = lcc;
  }
  
  for (int componentY = 0; componentY < numComponentsY; componentY++)
  {
    const int baseY = minY + componentY * componentSizeQuads;
    const int HmY = componentY / ComponentsPerHeightmap;
    const int HeightmapOffsetY = (componentY - ComponentsPerHeightmap*HmY) * numSubsections * (subsectionSizeQuads + 1);
    
    for (int componentX = 0; componentX < numComponentsX; componentX++)
    {
      const int baseX = minX + componentX * componentSizeQuads;
      const int HmX = componentX / ComponentsPerHeightmap;
      const int HeightmapOffsetX = (componentX - ComponentsPerHeightmap*HmX) * numSubsections * (subsectionSizeQuads + 1);
      T3DLandscapeComponent *lc = components[componentX + componentY * numComponentsX];
      FHeightmapInfo *HeightmapInfo = HeightmapInfos[HmX + HmY * NumHeightmapsX];
      if (!lc.heightData)
      {
        lc.baseX = baseX;
        lc.baseY = baseY;
        lc.componentSizeQuads = componentSizeQuads;
        lc.subsectionSizeQuads = subsectionSizeQuads;
        lc.numSubsections = sectionsPerComponent;
        lc.HeightmapScaleBiasX = 1. / (float)HeightmapInfo.HeightmapSizeU;
        lc.HeightmapScaleBiasY = 1. / (float)HeightmapInfo.HeightmapSizeV;
        lc.HeightmapScaleBiasZ = ((float)(HeightmapOffsetX)) / (float)HeightmapInfo.HeightmapSizeU;
        lc.HeightmapScaleBiasW = ((float)(HeightmapOffsetY)) / (float)HeightmapInfo.HeightmapSizeV;
      }
      
      for (int subsectionY = 0; subsectionY < numSubsections; subsectionY++)
      {
        for (int subsectionX = 0; subsectionX < numSubsections; subsectionX++)
        {
          for (int SubY = 0; SubY <= subsectionSizeQuads; SubY++)
          {
            for (int SubX = 0; SubX <= subsectionSizeQuads; SubX++)
            {
              const int compX = subsectionSizeQuads * subsectionX + SubX;
              const int compY = subsectionSizeQuads * subsectionY + SubY;
              const int TexX = (subsectionSizeQuads + 1) * subsectionX + SubX;
              const int TexY = (subsectionSizeQuads + 1) * subsectionY + SubY;
              const int HeightTexDataIdx = ((HeightmapOffsetX + TexX) + (HeightmapOffsetY + TexY) * (HeightmapInfo.HeightmapSizeU)) * 4;
              
              const uint16_t heightValue = HEIGHTDATA(compX + baseX - minX, compY + baseY - minY);

              GLKVector3 normal = vertexNormals[compX + baseX - minX + vertsX * (compY + baseY - minY)];
              normal = GLKVector3MultiplyScalar(normal,  1.0f / sqrtf((normal.x * normal.x) + (normal.y * normal.y) + (normal.z * normal.z)));
              
              uint8_t r = heightValue >> 8;
              uint8_t g = heightValue & 255;
              uint8_t b = (int)round(127.5 * (normal.x + 1.));
              uint8_t a = (int)round(127.5 * (normal.y + 1.));
              
              [HeightmapInfo.HeightmapTexture replaceBytesInRange:NSMakeRange(HeightTexDataIdx+0, 1) withBytes:&b];
              [HeightmapInfo.HeightmapTexture replaceBytesInRange:NSMakeRange(HeightTexDataIdx+1, 1) withBytes:&g];
              [HeightmapInfo.HeightmapTexture replaceBytesInRange:NSMakeRange(HeightTexDataIdx+2, 1) withBytes:&r];
              [HeightmapInfo.HeightmapTexture replaceBytesInRange:NSMakeRange(HeightTexDataIdx+3, 1) withBytes:&a];
            }
          }
        }
      }
    }
  }
  
  for (int componentY = 0; componentY < numComponentsY; componentY++)
  {
    for (int componentX = 0; componentX < numComponentsX; componentX++)
    {
      T3DLandscapeComponent *lc = components[componentX + componentY * numComponentsX];
      const int HmX = componentX / ComponentsPerHeightmap;
      const int HmY = componentY / ComponentsPerHeightmap;
      FHeightmapInfo *HeightmapInfo = HeightmapInfos[HmX + HmY * NumHeightmapsX];

      int HeightmapSizeU = HeightmapInfo.HeightmapSizeU;
      int HeightmapSizeV = HeightmapInfo.HeightmapSizeV;
      int HeightmapOffsetX = round(lc.HeightmapScaleBiasZ * (float)HeightmapSizeU);
      int HeightmapOffsetY = round(lc.HeightmapScaleBiasW * (float)HeightmapSizeV);
      int HeightmapSize = ((lc.subsectionSizeQuads + 1) * lc.numSubsections);
      lc.heightData = [NSMutableData dataWithLength:HeightmapSize*HeightmapSize*4];
      for (int SubY = 0; SubY < HeightmapSize; SubY++)
      {
        int CompY = SubY;
        int TexV = SubY + HeightmapOffsetY;
        uint8_t *HeightData = (uint8_t*)HeightmapInfo.HeightmapTexture.bytes;
        [lc.heightData replaceBytesInRange:NSMakeRange(CompY * HeightmapSize * sizeof(int), HeightmapSize * sizeof(int)) withBytes:&HeightData[(HeightmapOffsetX + TexV * HeightmapSizeU) * sizeof(int)]];
      }
    }
  }
  
  for (int componentY = 0; componentY < numComponentsY; componentY++)
  {
    for (int componentX = 0; componentX < numComponentsX; componentX++)
    {
      T3DLandscapeComponent *lc = components[componentX + componentY * numComponentsX];
      T3DLandscapeCollisionComponent *lcc = lc.collisionComponent;
      
      const int HmX = componentX / ComponentsPerHeightmap;
      const int HmY = componentY / ComponentsPerHeightmap;
      FHeightmapInfo *HeightmapInfo = HeightmapInfos[HmX + HmY * NumHeightmapsX];
      
      int ComponentX1 = 0;
      int ComponentY1 = 0;
      int ComponentX2 = lc.componentSizeQuads;
      int ComponentY2 = lc.componentSizeQuads;
      
      FLandscapeCollisionSize *collisionSize = [FLandscapeCollisionSize size:numSubsections subsectionSize:lc.subsectionSizeQuads mip:0];
      if (!lcc.collisionData)
      {
        lcc.collisionData = [NSMutableData dataWithLength:collisionSize.SizeVertsSquare * sizeof(uint16_t)];
      }
      
      const float CollisionQuadRatio = (float)collisionSize.SubsectionSizeQuads / (float)lc.subsectionSizeQuads;
      
      const int SubSectionX1 = MAX(0, (int)((ComponentX1 - 1) / lc.subsectionSizeQuads));
      const int SubSectionY1 = MAX(0, (int)((ComponentY1 - 1) / lc.subsectionSizeQuads));
      const int SubSectionX2 = MIN((int)((ComponentX2 + 1)/ lc.subsectionSizeQuads), numSubsections);
      const int SubSectionY2 = MIN((int)((ComponentY2 + 1)/ lc.subsectionSizeQuads), numSubsections);
      int MipSizeU = HeightmapInfo.HeightmapSizeU;
      int MipSizeV = HeightmapInfo.HeightmapSizeV;
      
      const int HeightmapOffsetX = (lc.HeightmapScaleBiasZ * (float)MipSizeU);
      const int HeightmapOffsetY = (lc.HeightmapScaleBiasW * (float)MipSizeV);
      
      for (int SubsectionY = SubSectionY1; SubsectionY < SubSectionY2; ++SubsectionY)
      {
        for (int SubsectionX = SubSectionX1; SubsectionX < SubSectionX2; ++SubsectionX)
        {
          // Area to update in subsection coordinates
          const int SubX1 = ComponentX1 - subsectionSizeQuads * SubsectionX;
          const int SubY1 = ComponentY1 - subsectionSizeQuads * SubsectionY;
          const int SubX2 = ComponentX2 - subsectionSizeQuads * SubsectionX;
          const int SubY2 = ComponentY2 - subsectionSizeQuads * SubsectionY;

          // Area to update in collision mip level coords
          const int CollisionSubX1 = floor((float)SubX1 * CollisionQuadRatio);
          const int CollisionSubY1 = floor((float)SubY1 * CollisionQuadRatio);
          const int CollisionSubX2 = ceil((float)SubX2 * CollisionQuadRatio);
          const int CollisionSubY2 = ceil((float)SubY2 * CollisionQuadRatio);

          // Clamp area to update
          const int VertX1 = CLAMP(CollisionSubX1, 0, collisionSize.SubsectionSizeQuads);
          const int VertY1 = CLAMP(CollisionSubY1, 0, collisionSize.SubsectionSizeQuads);
          const int VertX2 = CLAMP(CollisionSubX2, 0, collisionSize.SubsectionSizeQuads);
          const int VertY2 = CLAMP(CollisionSubY2, 0, collisionSize.SubsectionSizeQuads);
          
          
          for (int VertY = VertY1; VertY <= VertY2; VertY++)
          {
            for (int VertX = VertX1; VertX <= VertX2; VertX++)
            {
              // this uses Quads as we don't want the duplicated vertices
              const int CompVertX = collisionSize.SubsectionSizeQuads * SubsectionX + VertX;
              const int CompVertY = collisionSize.SubsectionSizeQuads * SubsectionY + VertY;

              // X/Y of the vertex we're looking indexed into the texture data
              const int TexX = HeightmapOffsetX + collisionSize.SubsectionSizeVerts * SubsectionX + VertX;
              const int TexY = HeightmapOffsetY + collisionSize.SubsectionSizeVerts * SubsectionY + VertY;
              const uint8_t *texBytes = (const uint8_t *)[HeightmapInfo.HeightmapTexture bytes];
              uint16_t r = (uint16_t)texBytes[(TexX + TexY * MipSizeU) * sizeof(int) + 2];
              uint16_t g = (uint16_t)texBytes[(TexX + TexY * MipSizeU) * sizeof(int) + 1];
              const uint16_t NewHeight = r << 8 | g;
              NSUInteger pos = (CompVertX + CompVertY * collisionSize.SizeVerts) * sizeof(uint16_t);
              [lcc.collisionData replaceBytesInRange:NSMakeRange(pos, sizeof(uint16_t))
                                           withBytes:&NewHeight];
            }
          }
        }
      }
    }
  }
  
  free(heightData);
  free(vertexNormals);
  
  
  T3DAddLine(result, padding, T3DBeginObject(@"Actor", [NSString stringWithFormat:@"Landscape_%@",[self.package name]], @"/Script/Landscape.Landscape"));
  padding++;
  {
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"RootComponent0", @"/Script/Engine.SceneComponent"));
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"Texture2D_0", @"/Script/Engine.Texture2D"));
    padding++;
    {
      T3DAddLine(result, padding, T3DBeginObject(@"Object", @"AssetImportData", @"/Script/Engine.AssetImportData"));
      T3DAddLine(result, padding, T3DEndObject(@"Object"));
    }
    padding--;
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    
    for (T3DLandscapeComponent *lc in components)
    {
      [lc t3dForward:result padding:padding];
    }
    for (T3DLandscapeCollisionComponent *lcc in collisionComponents)
    {
      [lcc t3dForward:result padding:padding];
    }
    
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"Texture2D_0", nil));
    padding++;
    {
      T3DAddLine(result, padding, T3DBeginObject(@"Object", @"AssetImportData", nil));
      T3DAddLine(result, padding, T3DEndObject(@"Object"));
      T3DAddLine(result, padding, @"AddressX=TA_Clamp");
      T3DAddLine(result, padding, @"AddressY=TA_Clamp");
      T3DAddLine(result, padding, @"Source=(Id=D120ED20469622CA5F8009A18D6DAAB5,SizeX=512,SizeY=512,NumSlices=1,NumMips=10,Format=TSF_BGRA8,LayerFormat=(TSF_BGRA8))");
      T3DAddLine(result, padding, @"AssetImportData=AssetImportData'\"AssetImportData\"'");
      T3DAddLine(result, padding, @"CompressionNone=True");
      T3DAddLine(result, padding, @"MipGenSettings=TMGS_LeaveExistingMips");
      T3DAddLine(result, padding, @"LODGroup=TEXTUREGROUP_Terrain_Heightmap");
      T3DAddLine(result, padding, @"SRGB=False");
    }
    padding--;
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"RootComponent0", nil));
    padding++;
    {
      FVector3 *v = EnsureValue([self propertyValue:@"Location"], [FVector3 vectorX:0 y:0 z:0]);
      T3DAddLine(result, padding, @"RelativeLocation=(X=%.6f,Y=%.6f,Z=%.6f)", v.x, v.y, v.z);
      v = EnsureValue([self propertyValue:@"DrawScale3D"], [FVector3 vectorX:256 y:256 z:256]);
      float scale = [EnsureValue([self propertyValue:@"DrawScale"], @1) floatValue];
      T3DAddLine(result, padding, @"RelativeScale3D=(X=%.6f,Y=%.6f,Z=%.6f)", v.x * scale, v.y * scale, v.z * scale);
    }
    padding--;
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    
    
    for (T3DLandscapeComponent *lc in components)
    {
      [lc t3d:result padding:padding];
    }
    
    for (T3DLandscapeCollisionComponent *lcc in collisionComponents)
    {
      [lcc t3d:result padding:padding];
    }
    
    T3DAddLine(result, padding, @"LandscapeGuid=%@", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]);
    T3DAddLine(result, padding, @"TargetDisplayOrderList(0)=\"\"");
    T3DAddLine(result, padding, @"TargetDisplayOrderList(1)=\"DataLayer__\"");
    
    for (T3DLandscapeComponent *lc in components)
    {
      T3DAddLine(result, padding, @"LandscapeComponents(%d)=LandscapeComponent'\"LandscapeComponent_%d\"'", lc.index, lc.index);
    }
    
    int lccIdx = 0;
    for (T3DLandscapeCollisionComponent *lcc in collisionComponents)
    {
      if (!lcc.collisionData.length) continue;
      T3DAddLine(result, padding, @"CollisionComponents(%d)=LandscapeHeightfieldCollisionComponent'\"LandscapeHeightfieldCollisionComponent_%d\"'", lccIdx, lcc.index);
      lccIdx++;
    }
    T3DAddLine(result, padding, @"ComponentSizeQuads=%d", componentSizeQuads);
    T3DAddLine(result, padding, @"SubsectionSizeQuads=%d", subsectionSizeQuads);
    T3DAddLine(result, padding, @"NumSubsections=%d", numSubsections);
    T3DAddLine(result, padding, @"RootComponent=\"RootComponent0\"");
    T3DAddLine(result, padding, @"ActorLabel=\"%@\"", [NSString stringWithFormat:@"Landscape_%@",[self.package name]]);
  }
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Actor"));
}

- (CGImageRef)heightMap
{
  if (!self.properties)
    [self readProperties];
  if (!rawHeights)
  {
    rawHeights = calloc(self.heights.count, sizeof(short));
    for (FTerrainHeight *th in self.heights)
    {
      rawHeights[[self.heights indexOfObject:th]] = th.value;
    }
  }
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
  else
  {
    terrainInfo = [terrainInfo stringByAppendingString:@"\nScale3D: 256 256 256"];
  }
  return terrainInfo;
}

@end

void _ExpandTerrainData(uint16_t* OutData, const uint16_t* InData, int OldMinX, int OldMinY, int OldMaxX, int OldMaxY, int NewMinX, int NewMinY, int NewMaxX, int NewMaxY, int *newWidth, int *newHeight)
{
  const int OldWidth = OldMaxX - OldMinX + 1;
  const int OldHeight = OldMaxY - OldMinY + 1;
  const int NewWidth = NewMaxX - NewMinX + 1;
  const int NewHeight = NewMaxY - NewMinY + 1;
  const int OffsetX = NewMinX - OldMinX;
  const int OffsetY = NewMinY - OldMinY;
  *newWidth = NewWidth;
  *newHeight = NewHeight;
  
  for (int Y = 0; Y < NewHeight; ++Y)
  {
    const int OldY = MAX(0, MIN(Y + OffsetY, OldHeight - 1));
    // Pad anything to the left
    const uint16_t PadLeft = InData[OldY * OldWidth + 0];
    for (int X = 0; X < -OffsetX; ++X)
    {
      OutData[Y * NewWidth + X] = PadLeft;
    }

    // Copy one row of the old data
    {
      const int X = MAX(0, -OffsetX);
      const int OldX = MAX(0, MIN(X + OffsetX, OldWidth - 1));
      memcpy(&OutData[Y * NewWidth + X], &InData[OldY * OldWidth + OldX], MIN(OldWidth, NewWidth) * sizeof(uint16_t));
    }

    const uint16_t PadRight = InData[OldY * OldWidth + OldWidth - 1];
    for (int X = -OffsetX + OldWidth; X < NewWidth; ++X)
    {
      OutData[Y * NewWidth + X] = PadRight;
    }
  }
}

uint16_t *ExpandTerrainData(const uint16_t *Data, int OldMinX, int OldMinY, int OldMaxX, int OldMaxY, int NewMinX, int NewMinY, int NewMaxX, int NewMaxY, int *newWidth, int *newHeight)
{
  const int NewWidth = NewMaxX - NewMinX + 1;
  const int NewHeight = NewMaxY - NewMinY + 1;
  *newWidth = NewWidth;
  *newHeight = NewHeight;
  uint16_t *Result = calloc(NewWidth * NewHeight, sizeof(uint16_t));
  _ExpandTerrainData(Result, Data,
  OldMinX, OldMinY, OldMaxX, OldMaxY,
  NewMinX, NewMinY, NewMaxX, NewMaxY, newWidth, newHeight);
  return Result;
}
