//
//  FMesh.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 11/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FMesh.h"
#import "UPackage.h"

GLKVector3 UnpackNormal(FPackedNormal normal)
{
  GLKVector3 vector;
  
  vector.x = normal.x / 127.5 - 1.f;
  vector.y = normal.y / 127.5 - 1.f;
  vector.z = normal.z / 127.5 - 1.f;
  
  return vector;
}

FPackedNormal PackNormal(float x, float y, float z)
{
  FPackedNormal normal;
  
  normal.x = (x + 1.0f) * 127.5f;
  normal.y = (y + 1.0f) * 127.5f;
  normal.z = (z + 1.0f) * 127.5f;
  normal.w = 0x7F;
  
  return normal;
}

@implementation FMeshBone

+ (instancetype)readFrom:(FIStream *)stream
{
  FMeshBone *bone = [super readFrom:stream];
  bone.nameIdx = [stream readLong:0];
  bone.flags = [stream readInt:0];
  bone.orientation = [FVector4 readFrom:stream];
  bone.position = [FVector3 readFrom:stream];
  bone.childrenCnt = [stream readInt:0];
  bone.parentIdx = [stream readInt:0];
  bone.unk = [stream readInt:0];
  return bone;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeLong:self.nameIdx];
  [d writeInt:self.flags];
  [d appendData:[self.orientation cooked:offset + d.length]];
  [d appendData:[self.position cooked:offset + d.length]];
  [d writeInt:self.childrenCnt];
  [d writeInt:self.parentIdx];
  [d writeInt:self.unk];
  
  return d;
}

- (NSString *)description
{
  return [self.package nameForIndex:self.nameIdx];
}

@end

@implementation FMeshSection

+ (instancetype)readFrom:(FIStream *)stream
{
  FMeshSection *s = [super readFrom:stream];
  
  s.material = [stream readShort:0];
  s.chunkIndex = [stream readShort:0];
  s.firstIndex = [stream readInt:0];
  s.faceCount = [stream readShort:0];
  
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeShort:self.material];
  [d writeShort:self.chunkIndex];
  [d writeInt:self.firstIndex];
  [d writeShort:self.faceCount];
  
  return d;
}

@end

@implementation FMuliSizeIndexContainer
{
  uint8_t *data;
}

- (uint8_t *)rawData
{
  return data;
}

- (void)setRawData:(uint8_t *)ptr
{
  if (data)
    free(data);
  data = ptr;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  FMuliSizeIndexContainer *c = [super readFrom:stream];
  c.elementSize = [stream readInt:0];
  c.elementCount = [stream readInt:0];
  int length = 0;
  if ((length = c.elementCount * c.elementSize))
  {
    c->data = (uint8_t *)[stream readBytes:length error:0];
  }
  return c;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeInt:self.elementSize];
  [d writeInt:self.elementCount];
  int length = 0;
  if ((length = self.elementSize * self.elementCount))
    [d appendBytes:(void *)data length:length];
  
  return d;
}

- (void *)element:(int)index
{
  if (index > self.elementCount)
  {
    DLog(@"Error! FMuliSizeIndexContainer index %d is out of range %d",index,self.elementCount);
    return NULL;
  }
  return &data + (sizeof(self.elementSize) * self.elementCount);
}

- (void)dealloc
{
  if (data)
    free(data);
}

@end

@implementation FSkeletalMeshChunk

+ (instancetype)readFrom:(FIStream *)stream
{
  FSkeletalMeshChunk *chunk = [super readFrom:stream];
  
  chunk.firstIndex = [stream readInt:0];
  chunk.rigidVerticiesCount = [stream readInt:0];
  
  if (chunk.rigidVerticiesCount)
    chunk.rigidVerticies = [stream readBytes:sizeof(FRigidVertex) * chunk.rigidVerticiesCount error:0];
  
  chunk.softVerticiesCount = [stream readInt:0];
  
  if (chunk.softVerticiesCount)
    chunk.softVerticies = [stream readBytes:sizeof(FSoftVertex) * chunk.softVerticiesCount error:0];
  
  chunk.boneMapCount = [stream readInt:0];
  
  if (chunk.boneMapCount)
    chunk.boneMap = [stream readBytes:sizeof(short) * chunk.boneMapCount error:0];
  
  int test = [stream readInt:0];
  if (test != chunk.rigidVerticiesCount)
  {
    DThrow(@"Error! Rigid verticies missmatch!");
    return nil;
  }
  
  test = [stream readInt:0];
  if (test != chunk.softVerticiesCount)
  {
    DThrow(@"Error! Soft verticies missmatch!");
    return nil;
  }
  
  chunk.maxBoneInfluences = [stream readInt:0];
  
  return chunk;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeInt:self.firstIndex];
  [d writeInt:self.rigidVerticiesCount];
  if (self.rigidVerticiesCount)
    [d appendBytes:self.rigidVerticies length:sizeof(FRigidVertex) * self.rigidVerticiesCount];
  [d writeInt:self.softVerticiesCount];
  if (self.softVerticiesCount)
    [d appendBytes:self.softVerticies length:sizeof(FSoftVertex) * self.softVerticiesCount];
  [d writeInt:self.boneMapCount];
  [d appendBytes:self.boneMap length:sizeof(short) * self.boneMapCount];
  [d writeInt:self.rigidVerticiesCount];
  [d writeInt:self.softVerticiesCount];
  [d writeInt:self.maxBoneInfluences];
  return d;
}

- (void)dealloc
{
  if (_rigidVerticies)
    free(_rigidVerticies);
  if (_softVerticies)
    free(_softVerticies);
  if (_boneMap)
    free(_boneMap);
}

@end

@implementation FGPUSkinBuffer

+ (instancetype)readFrom:(FIStream *)stream
{
  BOOL err = NO;
  FGPUSkinBuffer *buffer = [super readFrom:stream];
  buffer.useFullUV = [stream readShort:&err];
  buffer.usePackedPosition = [stream readShort:&err];
  buffer.elementSize = [stream readInt:&err];
  buffer.elementCount = [stream readInt:&err];
  
  if (err)
  {
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  
  buffer.vertices = [stream readBytes:sizeof(FGPUVert3Half) * buffer.elementCount error:&err];
  
  return err ? nil : buffer;
}

- (void)dealloc
{
  if (self.vertices)
    free(self.vertices);
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *data = [NSMutableData new];
  [data writeShort:(short)self.useFullUV];
  [data writeShort:(short)self.usePackedPosition];
  [data writeInt:self.elementSize];
  [data writeInt:self.elementCount];
  [data appendBytes:self.vertices length:self.elementSize * self.elementCount];
  return data;
}

@end

@implementation FLodInfo

+ (instancetype)readFrom:(FIStream *)stream
{
  FLodInfo *lod = [super readFrom:stream];
  void *ptr = NULL;
  BOOL err = NO;
  lod.sections = [FArray readFrom:stream type:[FMeshSection class]];
  lod.indexContainter = [FMuliSizeIndexContainer readFrom:stream];
  
  lod.legacyShadowIndicesCount = [stream readInt:&err];
  if (lod.legacyShadowIndicesCount) {
    ptr = NULL;
    ptr = [stream readBytes:lod.legacyShadowIndicesCount * sizeof(short) error:&err];
    lod.legacyShadowIndices = ptr;
  }
  
  lod.activeBoneIndicesCount = [stream readInt:&err];
  if (lod.activeBoneIndicesCount) {
    ptr = NULL;
    ptr = [stream readBytes:lod.activeBoneIndicesCount * sizeof(short) error:&err];
    if (err)
    {
      DThrow(kErrorUnexpectedEnd);
      return nil;
    }
    lod.activeBoneIndices = ptr;
  }
  
  lod.legacyShadowTriangleDoubleSidedCount = [stream readInt:&err];
  if (lod.legacyShadowTriangleDoubleSidedCount) {
    ptr = NULL;
    ptr = [stream readBytes:lod.legacyShadowTriangleDoubleSidedCount error:&err];
    if (err)
    {
      DThrow(kErrorUnexpectedEnd);
      return nil;
    }
    lod.legacyShadowTriangleDoubleSided = ptr;
  }
  
  lod.chunks = [FArray readFrom:stream type:[FSkeletalMeshChunk class]];
  lod.size = [stream readInt:&err];
  lod.vertexCount = [stream readInt:&err];
  
  lod.legacyEdgeCount = [stream readInt:&err];
  if (lod.legacyEdgeCount) {
    ptr = NULL;
    ptr = [stream readBytes:lod.legacyEdgeCount * sizeof(FEdge) error:&err];
    if (err)
    {
      DThrow(kErrorUnexpectedEnd);
      return nil;
    }
    lod.legacyEdge = ptr;
  }
  
  lod.requiredBonesCount = [stream readInt:&err];
  if (lod.requiredBonesCount) {
    ptr = NULL;
    ptr = [stream readBytes:lod.requiredBonesCount error:&err];
    if (err)
    {
      DThrow(kErrorUnexpectedEnd);
      return nil;
    }
    lod.requiredBones = ptr;
  }
  
  lod.rawPoints = [FBulkData readFrom:stream];
  
  lod.vertexBufferGPUSkin = [FGPUSkinBuffer readFrom:stream];
  lod.extraVertexInfluencesCount = [stream readInt:&err];
  return err ? nil : lod;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d appendData:[self.sections cooked:offset]];
  [d appendData:[self.indexContainter cooked:offset + d.length]];
  [d writeInt:self.legacyShadowIndicesCount];
  if (self.legacyShadowIndicesCount)
    [d appendBytes:self.legacyShadowIndices length:self.legacyShadowIndicesCount];
  [d writeInt:self.activeBoneIndicesCount];
  if (self.activeBoneIndicesCount)
    [d appendBytes:self.activeBoneIndices length:sizeof(short) * self.activeBoneIndicesCount];
  [d writeInt:self.legacyShadowTriangleDoubleSidedCount];
  if (self.legacyShadowTriangleDoubleSidedCount)
    [d appendBytes:self.legacyShadowTriangleDoubleSided length:self.legacyShadowTriangleDoubleSidedCount];
  
  [d appendData:[self.chunks cooked:offset + d.length]];
  [d writeInt:self.size];
  [d writeInt:self.vertexCount];
  [d writeInt:self.legacyEdgeCount];
  if (self.legacyEdgeCount)
    [d appendBytes:self.legacyEdge length:sizeof(FEdge) * self.legacyEdgeCount];
  [d writeInt:self.requiredBonesCount];
  if (self.requiredBonesCount)
    [d appendBytes:self.requiredBones length:self.requiredBonesCount];
  [d appendData:[self.rawPoints cooked:offset + d.length]];
  [d appendData:[self.vertexBufferGPUSkin cooked:offset + d.length]];
  [d writeInt:self.extraVertexInfluencesCount];
  
  return d;
}

- (FSoftVertex *)vertices
{
  FSoftVertex *V = calloc(sizeof(FSoftVertex),self.vertexCount);
  FSoftVertex *v = V;
  
  for (int chunkIndex = 0; chunkIndex < self.chunks.count; ++chunkIndex)
  {
    const FSkeletalMeshChunk *chunk = self.chunks[chunkIndex];
    for (int vertexIndex = 0; vertexIndex < chunk.rigidVerticiesCount; vertexIndex++,v++)
    {
      FRigidVertex sVertex = chunk.rigidVerticies[vertexIndex];
      v->position = sVertex.position;
      v->normal[0] = sVertex.normal[0];
      v->normal[1] = sVertex.normal[1];
      v->normal[2] = sVertex.normal[2];
      
      v->uv.u = sVertex.uv.u;
      v->uv.v = sVertex.uv.v;
      
      v->boneIndex[0] = sVertex.boneIndex;
      v->boneWeight[0] = 255;
    }
    
    memcpy(v, chunk.softVerticies, sizeof(FSoftVertex) * chunk.softVerticiesCount);
    v += chunk.softVerticiesCount;
  }
  
  return V;
}

- (void)dealloc
{
  if (_legacyShadowIndices)
    free(_legacyShadowIndices);
  if (_legacyEdge)
    free(_legacyEdge);
  if (_activeBoneIndices)
    free(_activeBoneIndices);
  if (_legacyShadowTriangleDoubleSided)
    free(_legacyShadowTriangleDoubleSided);
  if (_requiredBones)
    free(_requiredBones);
}

@end

