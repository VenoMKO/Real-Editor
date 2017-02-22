//
//  RawImportData.m
//  Package Manager
//
//  Created by Vladislav Skachkov on 03/01/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "RawImportData.h"
#import "SkeletalMesh.h"
#import "MeshUtils.h"
#import "UPackage.h"
#import "Extensions.h"
#import "FMesh.h"
#import "MeshUtils.h"

int cmp(const void *ac,const void *bc);

@implementation RawImportData

- (FLodInfo *)buildLod:(NSDictionary *)options
{
  SkeletalMesh *mesh = options[@"mesh"];
  UPackage *package = mesh.package;
  FLodInfo *model = [FLodInfo newWithPackage:package];
  FBulkData *rawPoints = [FBulkData emptyUnusedData];
  rawPoints.package = package;
  model.rawPoints = rawPoints;

  if (self.overrideSkel)
  {
    int maxDepth = 0;
    mesh.refSkeleton = nil;
    
    FArray *array = [FArray arrayWithArray:self.bones package:package];
    
    for (FMeshBone *bone in array)
    {
      int depth = 0;
      FMeshBone *b = bone;
      while (b.parentIdx)
      {
        b = array[b.parentIdx];
        depth++;
      }
      if (depth > maxDepth)
        maxDepth = depth;
    }
    mesh.skeletalDepth = maxDepth ? maxDepth + 2 : 1;
    mesh.refSkeleton = array;
  }

  FSoftVertex *softVerts = calloc(self.pointCount,sizeof(FSoftVertex));
  
  for (int i = 0; i < self.pointCount; i++)
  {
    softVerts[i].position.x = self.points[i].x;
    softVerts[i].position.y = self.points[i].y;
    softVerts[i].position.z = self.points[i].z;
  }
  
  int *indicies = calloc(sizeof(int), self.wedgeCount);
  int sectionCount = 0;
  int sectionFirstIndices[128];
  sectionFirstIndices[0] = 0;
  int sectionFaceCount[128];
  sectionFaceCount[0] = 0;
  int sectionMaterials[128];
  NSMutableArray *materialMap = options[@"mmap"];
  
  int materialIdx = self.wedges[self.faces[0].wedgeIndices[0]].materialIndex;
  if (materialMap)
    sectionMaterials[0] = [materialMap[materialIdx] intValue];
  else
    sectionMaterials[0] = 0;
  
  float basises[self.faceCount][3];
  for (int i = 0; i < self.faceCount; i++)
  {
    int idx;
    int cpIdx;
    
    for (int j = 0; j < 3; j++)
    {
      idx = self.faces[i].wedgeIndices[j];
      cpIdx = self.wedges[idx].pointIndex;
      indicies[i * 3 + j] = cpIdx;
      
      if (materialIdx != self.wedges[idx].materialIndex)
      {
        sectionCount++;
        sectionFirstIndices[sectionCount]=i*3+j;
        sectionFaceCount[sectionCount-1] = (i*3+j - sectionFirstIndices[sectionCount-1]) / 3;
        materialIdx = self.wedges[idx].materialIndex;
        if (materialMap)
        {
          sectionMaterials[sectionCount] = [materialMap[materialIdx] intValue];
        }
        else
        {
          sectionMaterials[sectionCount] = 0;
        }
      }
      basises[cpIdx][0] = self.faces[i].basis[0];
      basises[cpIdx][1] = self.faces[i].basis[1];
      basises[cpIdx][2] = self.faces[i].basis[2];
      softVerts[cpIdx].uv.u = self.wedges[idx].UV[0].x;
      softVerts[cpIdx].uv.v = self.wedges[idx].UV[0].y;
      
      softVerts[cpIdx].normal[0] = PackNormal(self.faces[i].tangentX[j].x,
                                              self.faces[i].tangentX[j].y,
                                              self.faces[i].tangentX[j].z);
      
      softVerts[cpIdx].normal[1] = PackNormal(self.faces[i].tangentY[j].x,
                                              self.faces[i].tangentY[j].y,
                                              self.faces[i].tangentY[j].z);
      
      softVerts[cpIdx].normal[2] = PackNormal(self.faces[i].tangentZ[j].x,
                                              self.faces[i].tangentZ[j].y,
                                              self.faces[i].tangentZ[j].z);
    }
  }
  sectionFaceCount[sectionCount] = (self.wedgeCount - sectionFirstIndices[sectionCount]) / 3;
  sectionCount++;
  
  
  unsigned short b[self.boneCount];
  int bcount = 0;
  qsort(self.influences, self.influenceCount, sizeof(RawInfluence), cmp);
  
  for (int i = 0; i < self.influenceCount - 1; i++)
  {
    unsigned short idx = self.influences[i].boneIndex;
    BOOL found = NO;
    for (int j = 0; j < bcount; j++)
    {
      if (idx == b[j])
      {
        found = YES;
        break;
      }
    }
    if (!found)
    {
      b[bcount] = idx;
      bcount++;
    }
  }
  
  for (int i = 0; i < self.influenceCount - 1; i++)
  {
    unsigned short idx = self.influences[i].boneIndex;
    for (int j = 0; j < bcount; j++)
    {
      if (idx == b[j])
      {
        self.influences[i].boneIndex = j;
        break;
      }
    }
  }
  
  for (int i = 0; i < self.influenceCount; i++)
  {
    int idx = self.influences[i].vertexIndex;
    Byte weight = self.influences[i].weight * 255;
    int infIdx = INT32_MAX;
    for (int j = 0; j < 4; j++)
    {
      if (!softVerts[idx].boneIndex[j] && !softVerts[idx].boneWeight[j] && infIdx > j)
      {
        infIdx = j;
      }
      if (softVerts[idx].boneIndex[j] == self.influences[i].boneIndex && softVerts[idx].boneWeight[j] == weight)
      {
        infIdx = INT32_MAX;
        break;
      }
    }
    if (infIdx != INT32_MAX)
    {
      softVerts[idx].boneIndex[infIdx] = self.influences[i].boneIndex;
      softVerts[idx].boneWeight[infIdx] = weight;
    }
  }
  
  
  model.activeBoneIndicesCount = bcount;
  model.requiredBonesCount = self.boneCount;
  unsigned short *activeBoneIndicies = malloc(sizeof(short) * bcount);
  unsigned short *boneMap = malloc(sizeof(short) * bcount);
  Byte  *requiredBones = malloc(sizeof(Byte) * mesh.refSkeleton.count);
  
  for (int i = 0; i < self.faceCount; i++) // Checking for 0-weighted wedges and fixing (Probably useless)
  {
    int idx;
    int cpIdx;
    for (int j = 0; j < 3; j++)
    {
      idx = self.faces[i].wedgeIndices[j];
      cpIdx = self.wedges[idx].pointIndex;
      
      BOOL hasW = NO;
      
      for(int w = 0; w < 4; w++)
      {
        if (softVerts[cpIdx].boneWeight[w])
        {
          hasW = YES;
          break;
        }
      }
      
      if (!hasW)
      {
        if (j)
        {
          softVerts[cpIdx].boneWeight[0] = 0xFF;
          softVerts[cpIdx].boneIndex[0] = softVerts[self.wedges[self.faces[i].wedgeIndices[j-1]].pointIndex].boneWeight[0];
        }
        else
        {
          softVerts[cpIdx].boneWeight[0] = 0xFF;
          softVerts[cpIdx].boneIndex[0] = softVerts[self.wedges[self.faces[i].wedgeIndices[j+1]].pointIndex].boneWeight[0];
        }
        
      }
    }
  }
  
  for (int i = 0; i < mesh.refSkeleton.count; i++)
    requiredBones[i]=i;
  
  for (int i = 0; i < bcount; i++)
  {
    int j;
    if (self.bones[b[i]].nameIdx < 0)
    {
      j = (int)self.bones[b[i]].nameIdx * -1;
      j--;
    }
    else
    {
      BOOL f = NO;
      for (j = 0; j < mesh.refSkeleton.count; j++)
      {
        if (([(FMeshBone *)mesh.refSkeleton[j] nameIdx]) == [self.bones[b[i]] nameIdx])
        {
          f = YES;
          break;
        }
      }
      if (!f)
      {
        NSAppError(mesh.package, @"Failed to import mesh! Imported skeleton doesn't match the original.");
        if (self.wedgeCount)
          free(self.wedges);
        if (self.points)
          free(self.points);
        if (self.influences)
          free(self.influences);
        free(self.faces);
        return nil;
      }
    }
    
    activeBoneIndicies[i]=j;
    boneMap[i]=j;
  }
  
  model.activeBoneIndices = activeBoneIndicies;
  model.requiredBones = requiredBones;
  
  NSMutableArray *sections = [NSMutableArray new];
  
  for (int i = 0; i < sectionCount; ++i)
  {
    FMeshSection *s = [FMeshSection newWithPackage:package];
    s.firstIndex = sectionFirstIndices[i];
    s.faceCount = sectionFaceCount[i];
    s.material = sectionMaterials[i];
    s.chunkIndex = 0;
    [sections addObject:s];
  }
  
  model.sections = [FArray arrayWithArray:sections package:package];
  
  FSkeletalMeshChunk *chunk = [FSkeletalMeshChunk newWithPackage:package];
  
  chunk.softVerticies = softVerts;
  chunk.rigidVerticies = NULL;
  chunk.softVerticiesCount = self.pointCount;
  chunk.rigidVerticiesCount = 0;
  chunk.maxBoneInfluences = 4;
  chunk.firstIndex = 0;
  chunk.boneMap = boneMap;
  chunk.boneMapCount = bcount;
  FArray *array = [FArray arrayWithArray:@[chunk] package:package];
  model.chunks = array;
  model.vertexCount = self.pointCount;
  
  FMuliSizeIndexContainer *indexContainer = [FMuliSizeIndexContainer newWithPackage:package];
  
  if (self.wedgeCount <= UINT16_MAX)
  {
    indexContainer.rawData = (uint8_t *)malloc(sizeof(short) * self.wedgeCount);
    indexContainer.elementSize = sizeof(short);
    indexContainer.elementCount = self.wedgeCount;
    short *ptr = (short *)indexContainer.rawData;
    for (int i = 0; i < self.wedgeCount; i++)
      ptr[i] = (unsigned short)indicies[i];
    
  }
  else
  {
    indexContainer.rawData = (uint8_t *)malloc(sizeof(int) * self.wedgeCount);
    indexContainer.elementSize = sizeof(int);
    indexContainer.elementCount = self.wedgeCount;
    memcpy(indexContainer.rawData, indicies, sizeof(int));
  }
  model.indexContainter = indexContainer;
  //model.numTexCoords = 1;
  free(indicies);
  
  FGPUSkinBuffer *gpuBuffer = [FGPUSkinBuffer newWithPackage:package];
  model.vertexBufferGPUSkin =  gpuBuffer;
  gpuBuffer.elementSize = 32;
  if(32!=sizeof(FGPUVert3Half))
    DLog(@"Warning! Incorrect lement size %lu",sizeof(FGPUVert3Half));
  gpuBuffer.elementCount = self.pointCount;
  gpuBuffer.useFullUV = NO;
  gpuBuffer.usePackedPosition = NO;
  
  FGPUVert3Half *V = calloc(self.pointCount,sizeof(FGPUVert3Half));
  FSoftVertex *nV = softVerts;
  
  for (int i = 0; i < model.vertexCount; i++)
  {
    
    V[i].position.x = nV[i].position.x;
    V[i].position.y = nV[i].position.y;
    V[i].position.z = nV[i].position.z;
    
    V[i].uv.u = float2half(nV[i].uv.u);
    V[i].uv.v = float2half(nV[i].uv.v);
    
    V[i].normal[0] = nV[i].normal[0];
    V[i].normal[1] = nV[i].normal[2];
    
    float sign = 0;
    
    if (!self.flipTangents)
    {
      sign = GetBasisDeterminantSignByte(nV[i].normal[0], nV[i].normal[1], nV[i].normal[2]);
    }
    else
    {
      sign = basises[i][0];
      if (!(int)floor(V[i].uv.u) % 2)
        sign *= -1.f;
    }
    /*
     //TODO: get valid basis for current point via pointIndex
     sign = basises[i][0];
     if (!(int)floor(V[i].uv.u) % 2 && self.flipTangents)
     sign *= -1.f;
     else if (!self.flipTangents)
     sign = GetBasisDeterminantSignByte(nV[i].normal[0], nV[i].normal[1], nV[i].normal[2]);
     */
    /*
     if (V[i].uv.u < 1.f && V[i].uv.u >= 0.f){
     sign = -basises[i][0];
     } else
     sign = basises[i][0];*/
    V[i].normal[1].w = (sign + 1.0f) * 127.5f;
    
    V[i].boneIndex[0] = nV[i].boneIndex[0];
    V[i].boneIndex[1] = nV[i].boneIndex[1];
    V[i].boneIndex[2] = nV[i].boneIndex[2];
    V[i].boneIndex[3] = nV[i].boneIndex[3];
    
    Byte sumWeight = nV[i].boneWeight[0] + nV[i].boneWeight[1] + nV[i].boneWeight[2] + nV[i].boneWeight[3];
    if (sumWeight != 255)
    {
      float oneOverTotal = 1.f / ((float)sumWeight / 255.0f);
      for (int j = 0; j < 4; j++)
      {
        float nw = ((float)nV[i].boneWeight[j] / 255.0f) * oneOverTotal;
        nV[i].boneWeight[j] = MIN(nw * 255, 255);
      }
    }
    
    sumWeight = nV[i].boneWeight[0] + nV[i].boneWeight[1] + nV[i].boneWeight[2] + nV[i].boneWeight[3];
    
    if (sumWeight < 255)
    {
      int idx = 0,max = 0;
      for (int j = 0; j < 4; j++)
      {
        if (nV[i].boneWeight[j] > max)
        {
          max = nV[i].boneWeight[j];
          idx = j;
        }
      }
      if (max)
        nV[i].boneWeight[idx]+= 255 - sumWeight;
    }
    
    V[i].boneWeight[0] = nV[i].boneWeight[0];
    V[i].boneWeight[1] = nV[i].boneWeight[1];
    V[i].boneWeight[2] = nV[i].boneWeight[2];
    V[i].boneWeight[3] = nV[i].boneWeight[3];
    
  }
  gpuBuffer.vertices = V;
  
  if (self.wedgeCount)
    free(self.wedges);
  if (self.points)
    free(self.points);
  if (self.influences)
    free(self.influences);
  
  return model;
}

@end

int cmp(const void *ac,const void *bc)
{
  RawInfluence *A = (RawInfluence *)ac;
  RawInfluence *B = (RawInfluence *)bc;
  if		( A->vertexIndex > B->vertexIndex ) return  1;
  else if ( A->vertexIndex < B->vertexIndex ) return -1;
  else if ( A->weight	     < B->weight	  ) return  1;
  else if ( A->weight	     > B->weight      ) return -1;
  else if ( A->boneIndex   > B->boneIndex	  ) return  1;
  else if ( A->boneIndex   < B->boneIndex	  ) return -1;
  else									    return  0;
}
