//
//  FStaticMesh.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 23/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FStaticMesh.h"
#import "MeshUtils.h"
#import "UPackage.h"
#import "FGUID.h"

@interface FStaticLodInfo ()
@end

@implementation FStaticLodInfo

+ (instancetype)readFrom:(FIStream *)stream
{
  FStaticLodInfo *lod = [super readFrom:stream];
  int bulkDataCount,bulkDataSize;
  [stream readInt:NULL];
  bulkDataCount = [stream readInt:NULL];
  bulkDataSize = [stream readInt:NULL];
  [stream readInt:NULL];
  
  if (bulkDataSize && bulkDataCount)
  {
    DThrow(@"Unknown Data found!");
    return nil;
  }
  
  lod.sections = [FArray readFrom:stream type:[FStaticMeshSection class]];
  if (!lod.sections)
  {
    DThrow(@"Failed to read sections!");
    return nil;
  }
  lod.positionBuffer = [FPositionVertexData readFrom:stream];
  if (!lod.positionBuffer)
  {
    DThrow(@"Failed to read posbuff");
    return nil;
  }
  
  lod.textureBuffer = [FUVVertexData readFrom:stream];
  if (!lod.textureBuffer)
  {
    DThrow(@"Failed to red texbuff");
    return nil;
  }
  
  lod.colorBuffer = [FStaticColorData readFrom:stream];
  if (!lod.colorBuffer)
  {
    DThrow(@"Failed to red colbuff");
    return nil;
  }
  
  lod.numVerticies = [stream readInt:NULL];
  
  lod.indexContainer = [FMuliSizeIndexContainer readFrom:stream];
  if (!lod.indexContainer)
  {
    DThrow(@"Failed to read idxbuff");
    return nil;
  }
  
  lod.wireframeIndexBuffer = [FMuliSizeIndexContainer readFrom:stream];
  if (!lod.wireframeIndexBuffer)
  {
    DThrow(@"Failed to read wfbuff");
    return nil;
  }
  
  int test = [stream readInt:NULL];
  if (test != sizeof(FEdge))
  {
    DThrow(@"Incorrect edge size %d. Expected %lu",test,sizeof(FEdge));
    return nil;
  }
  lod.legacyEdgeCount = [stream readInt:NULL];
  if (lod.legacyEdgeCount)
    lod.legacyEdges = [stream readBytes:sizeof(FEdge) * lod.legacyEdgeCount error:NULL];
  
  if ((test = [stream readInt:NULL]))
  {
    DThrow(@"Unknown ending %d!",test);
    return nil;
  }
  
  return lod;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeLong:0];
  [d writeInt:0];
  [d writeInt:(int)offset + (int)d.length + 4];
  
  [d appendData:[self.sections cooked:offset + d.length]];
  [d appendData:[self.positionBuffer cooked:offset]];
  [d appendData:[self.textureBuffer cooked:offset + d.length]];
  [d appendData:[self.colorBuffer cooked:offset + d.length]];
  [d writeInt:self.numVerticies];
  [d appendData:[self.indexContainer cooked:offset + d.length]];
  [d appendData:[self.wireframeIndexBuffer cooked:offset + d.length]];
  [d writeInt:sizeof(FEdge)];
  [d writeInt:self.legacyEdgeCount];
  if (self.legacyEdges)
    [d appendBytes:self.legacyEdges length:sizeof(FEdge) * self.legacyEdgeCount];
  [d writeInt:0];
  
  return d;
}

- (GenericVertex *)vertices
{
  GenericVertex *V = calloc(sizeof(GenericVertex),self.numVerticies);
  GenericVertex *v = V;
  
  GLKVector3 *pos = self.positionBuffer.data;
  
  for (int i = 0; i < self.numVerticies; i++,pos++,V++)
  {
    V->position.x = pos->x;
    V->position.y = pos->y;
    V->position.z = pos->z;
    V->numUVs = self.textureBuffer.numUVSets;
    if (self.textureBuffer.bUseFullUVs)
    {
      if (self.textureBuffer.numUVSets == 2)
      {
        FUVFloat2 *cuvs = (FUVFloat2 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        
        for (int j = 0; j < self.textureBuffer.numUVSets; j++)
        {
          float fuv;
          fuv = cuvs[i].UVs[j].u;
          V->uv[j].u = fuv;
          fuv = cuvs[i].UVs[j].v;
          V->uv[j].v = fuv;
        }
      }
      else if (self.textureBuffer.numUVSets == 3)
      {
        FUVFloat3 *cuvs = (FUVFloat3 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        
        for (int j = 0; j < self.textureBuffer.numUVSets; j++)
        {
          float fuv;
          fuv = cuvs[i].UVs[j].u;
          V->uv[j].u = fuv;
          fuv = cuvs[i].UVs[j].v;
          V->uv[j].v = fuv;
        }
      }
      else if (self.textureBuffer.numUVSets == 4)
      {
        FUVFloat4 *cuvs = (FUVFloat4 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        
        for (int j = 0; j < self.textureBuffer.numUVSets; j++)
        {
          float fuv;
          fuv = cuvs[i].UVs[j].u;
          V->uv[j].u = fuv;
          fuv = cuvs[i].UVs[j].v;
          V->uv[j].v = fuv;
        }
      }
      else
      {
        if (self.textureBuffer.numUVSets != 1)
        {
          DThrow(@"Warning! Unexpected UV count %d!",self.textureBuffer.numUVSets);
        }
        FUVFloat1 *cuvs = (FUVFloat1 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        float fuv;
        fuv = cuvs[i].UVs.u;
        V->uv[0].u = fuv;
        fuv = cuvs[i].UVs.v;
        V->uv[0].v = fuv;
      }
    }
    else
    {
      if (self.textureBuffer.numUVSets == 2)
      {
        FUVHalf2 *cuvs = (FUVHalf2 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        
        for (int j = 0; j < self.textureBuffer.numUVSets; j++)
        {
          float fuv;
          fuv = half2float(cuvs[i].UVs[j].u);
          V->uv[j].u = fuv;
          fuv = half2float(cuvs[i].UVs[j].v);
          V->uv[j].v = fuv;
        }
      }
      else if (self.textureBuffer.numUVSets == 3)
      {
        FUVHalf3 *cuvs = (FUVHalf3 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        
        for (int j = 0; j < self.textureBuffer.numUVSets; j++)
        {
          float fuv;
          fuv = half2float(cuvs[i].UVs[j].u);
          V->uv[j].u = fuv;
          fuv = half2float(cuvs[i].UVs[j].v);
          V->uv[j].v = fuv;
        }
      }
      else if (self.textureBuffer.numUVSets == 4)
      {
        FUVHalf4 *cuvs = (FUVHalf4 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        
        for (int j = 0; j < self.textureBuffer.numUVSets; j++)
        {
          float fuv;
          fuv = half2float(cuvs[i].UVs[j].u);
          V->uv[j].u = fuv;
          fuv = half2float(cuvs[i].UVs[j].v);
          V->uv[j].v = fuv;
        }
      }
      else
      {
        if (self.textureBuffer.numUVSets != 1)
        {
          DThrow(@"Warning! Unexpected UV count %d!",self.textureBuffer.numUVSets);
        }
        FUVHalf1 *cuvs = (FUVHalf1 *)self.textureBuffer.data;
        V->binormal = UnpackNormal(cuvs[i].normal[0]);
        V->normal = UnpackNormal(cuvs[i].normal[1]);
        float fuv;
        fuv = half2float(cuvs[i].UVs.u);
        V->uv[0].u = fuv;
        fuv = half2float(cuvs[i].UVs.v);
        V->uv[0].v = fuv;
      }
    }
  }
  return v;
}

- (NSArray *)materials
{
  NSMutableArray *a = [NSMutableArray new];
  
  for (FStaticMeshSection *s in self.sections)
  {
    UObject *m = [self.package objectForIndex:s.material];
    if (m)
      [a addObject:m];
  }
  
  return a;
}

- (void)dealloc
{
  if (self.legacyEdges)
    free(_legacyEdges);
}

@end


@implementation FStaticMeshSection

+ (instancetype)readFrom:(FIStream *)s
{
  FStaticMeshSection *section = [super readFrom:s];
  BOOL err = NO;
  section.material = [s readInt:&err];
  section.enableCollision = [s readInt:&err];
  section.oldEnableCollision = [s readInt:&err];
  section.bEnableShadowCasting = [s readInt:&err];
  section.firstIndex = [s readInt:&err];
  section.faceCount = [s readInt:&err];
  section.minVertexIndex = [s readInt:&err];
  section.maxVertexIndex = [s readInt:&err];
  section.materialIndex = [s readInt:&err];
  section.fragmentCount = [s readInt:&err];
  
  if (section.fragmentCount)
  {
    section.fragments = [s readBytes:sizeof(FFragmentRange) * section.fragmentCount error:&err];
  }
  
  return section;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeInt:self.material];
  [d writeInt:self.enableCollision];
  [d writeInt:self.oldEnableCollision];
  [d writeInt:self.bEnableShadowCasting];
  [d writeInt:self.firstIndex];
  [d writeInt:self.faceCount];
  [d writeInt:self.minVertexIndex];
  [d writeInt:self.maxVertexIndex];
  [d writeInt:self.materialIndex];
  [d writeInt:self.fragmentCount];
  if (self.fragmentCount)
    [d appendBytes:self.fragments length:sizeof(FFragmentRange) * self.fragmentCount];
  
  return d;
}

- (void)dealloc
{
  if (self.fragments)
    free(_fragments);
}

@end

@implementation FPositionVertexData

+ (instancetype)readFrom:(FIStream *)stream
{
  int temp = 0;
  FPositionVertexData *d = [super readFrom:stream];
  d.stride = [stream readInt:NULL];
  d.count = [stream readInt:NULL];
  temp = [stream readInt:NULL];
  if (temp != d.stride)
  {
    DThrow(@"Error! Incorrect stride %d. Expected %d",temp,d.stride);
    return nil;
  }
  temp = [stream readInt:NULL];
  if (temp != d.count)
  {
    DThrow(@"Error! Incorrect count %d. Expected %d",temp,d.count);
    return nil;
  }
  if (d.stride && d.count)
    d.data = [stream readBytes:d.stride * d.count  error:NULL];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.stride];
  [d writeInt:self.count];
  [d writeInt:self.stride];
  [d writeInt:self.count];
  if (self.stride && self.count)
    [d appendBytes:self.data length:self.stride * self.count];
  return d;
}

- (void)dealloc
{
  if (self.data)
    free(_data);
}

@end

@implementation FUVVertexData

+ (instancetype)readFrom:(FIStream *)stream
{
  FUVVertexData *d = [super readFrom:stream];
  int temp = 0;
  d.numUVSets = [stream readInt:NULL];
  d.stride = [stream readInt:NULL];
  d.numUVs = [stream readInt:NULL];
  d.bUseFullUVs = [stream readInt:NULL];
  
  temp = [stream readInt:NULL];
  if (temp != d.stride)
  {
    DThrow(@"Error! Incorrect texstride %d. Expected %d",temp,d.stride);
    return nil;
  }
  temp = [stream readInt:NULL];
  if (temp != d.numUVs)
  {
    DThrow(@"Error! Incorrect texcount %d. Expected %d",temp,d.numUVs);
    return nil;
  }
  
  if (d.bUseFullUVs)
  {
    switch (d.numUVSets)
    {
      case 1:
        d.size = sizeof(FUVFloat1);
        break;
      case 2:
        d.size = sizeof(FUVFloat2);
        break;
      case 3:
        d.size = sizeof(FUVFloat3);
        break;
      case 4:
        d.size = sizeof(FUVFloat4);
        break;
        
      default:
        break;
    }
  }
  else
  {
    switch (d.numUVSets)
    {
      case 1:
        d.size = sizeof(FUVHalf1);
        break;
      case 2:
        d.size = sizeof(FUVHalf2);
        break;
      case 3:
        d.size = sizeof(FUVHalf3);
        break;
      case 4:
        d.size = sizeof(FUVHalf4);
        break;
        
      default:
        break;
    }
  }
  
  if (!d.size)
  {
    DThrow(@"Error! Invalid UVs count %d",d.numUVSets);
    return nil;
  }
  
  if (d.numUVs)
    d.data = [stream readBytes:d.size * d.numUVs error:NULL];
  
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.numUVSets];
  [d writeInt:self.stride];
  [d writeInt:self.numUVs];
  [d writeInt:self.bUseFullUVs];
  [d writeInt:self.stride];
  [d writeInt:self.numUVs];
  if (self.size && self.numUVs && self.data)
    [d appendBytes:self.data length:self.size * self.numUVs];
  return d;
}

- (void)dealloc
{
  if (self.data)
    free(_data);
}

@end

@implementation FStaticColorData

+ (instancetype)readFrom:(FIStream *)stream
{
  FStaticColorData *d = [super readFrom:stream];
  int temp = 0;
  d.stride = [stream readInt:NULL];
  d.count = [stream readInt:NULL];
  if (d.stride != 4)
  {
    DThrow(@"Error! Incorrect colorstride %d. Expected %d",d.stride,4);
    return nil;
  }
  temp = [stream readInt:NULL];
  if (temp != d.stride)
  {
    DThrow(@"Error! Incorrect colorstride %d. Expected %d",temp,d.stride);
    return nil;
  }
  temp = [stream readInt:NULL];
  if (temp != d.count)
  {
    DThrow(@"Error! Incorrect colorcount %d. Expected %d",temp,d.count);
    return nil;
  }
  if (d.stride && d.count)
    d.data = [stream readBytes:d.stride * d.count  error:NULL];
  
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.stride];
  [d writeInt:self.count];
  [d writeInt:self.stride];
  [d writeInt:self.count];
  if (self.stride && self.count)
    [d appendBytes:self.data length:self.stride * self.count];
  return d;
}

- (void)dealloc
{
  if (self.data)
    free(_data);
}

@end

@implementation FVert

+ (instancetype)readFrom:(FIStream *)stream
{
  FVert *v = [super readFrom:stream];
  v.pVertex = [stream readInt:0];
  v.iSide = [stream readInt:0];
  v.shadowTexCoord = [FVector2D readFrom:stream];
  v.backfaceShadowTexCoord = [FVector2D readFrom:stream];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.pVertex];
  [d writeInt:self.iSide];
  [d appendData:[self.shadowTexCoord cooked:offset + d.length]];
  [d appendData:[self.backfaceShadowTexCoord cooked:offset + d.length]];
  return d;
}

@end

@implementation FStaticMeshComponentLODInfo

+ (instancetype)readFrom:(FIStream *)stream
{
  FStaticMeshComponentLODInfo *lod = [super readFrom:stream];

  lod.shadowMaps = [FArray readFrom:stream type:[UObject class]];
  lod.shadowVertexBuffers = [FArray readFrom:stream type:[UObject class]];
  lod.lightMap = [FLightMap readFrom:stream];
  lod.unkShadowMap = [UObject readFrom:stream];

  return lod;
}

@end
