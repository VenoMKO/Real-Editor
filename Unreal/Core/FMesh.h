//
//  FMesh.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 11/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "FBulkData.h"
#import "FReadable.h"
#import "FArray.h"
#import "FVector.h"

#pragma pack(push,1)

/**
 Preview vertex strucutre used with the scenekit
 */
struct _GPUVertex
{
  GLKVector3      position;
  GLKVector3      normal;
  float           u;
  float           v;
};
typedef struct _GPUVertex GPUVertex;

struct _FEdge {
  int iVertex[2];
  int iFace[2];
};
typedef struct _FEdge FEdge;
/**
 Full-precious uv structure
 */
struct _FMeshFloatUV {
  float           u;
  float           v;
};
typedef struct _FMeshFloatUV FMeshFloatUV;

/**
 Half-precious uv structure
 */
struct _FMeshHalfUV {
  unsigned short           u;
  unsigned short           v;
};
typedef struct _FMeshHalfUV FMeshHalfUV;

/**
 Packed normal
 */
struct _FPackedNormal {
  Byte            x;
  Byte            y;
  Byte            z;
  Byte            w;
};
typedef struct _FPackedNormal FPackedNormal;

/**
 CPU Skin vertex
 */
struct _FSoftVertex {
  GLKVector3      position;
  FPackedNormal   normal[3];
  FMeshFloatUV    uv;
  Byte            boneIndex[4];
  Byte            boneWeight[4];
};
typedef struct _FSoftVertex FSoftVertex;

/**
 CPU Skin vertex
 */
struct _FRigidVertex {
  GLKVector3      position;
  FPackedNormal   normal[3];
  FMeshFloatUV    uv;
  Byte            boneIndex;
};
typedef struct _FRigidVertex FRigidVertex;

/**
 GPU Skin structure
 */
struct _FGPUVert3Half {
  GLKVector3      position;
  FPackedNormal   normal[2];
  Byte            boneIndex[4];
  Byte            boneWeight[4];
  FMeshHalfUV     uv;
  
};
typedef struct _FGPUVert3Half FGPUVert3Half;

struct _GenericVertex
{
  GLKVector3      position;
  GLKVector3      normal;
  GLKVector3      binormal;
  GLKVector3      tangent;
  short           numUVs;
  FMeshFloatUV    uv[4];
  Byte            boneIndex[4];
  Byte            boneWeight[4];
};
typedef struct _GenericVertex GenericVertex;

#pragma pack(pop)

GLKVector3 UnpackNormal(FPackedNormal normal);
FPackedNormal PackNormal(float x, float y, float z);

@interface FMeshBone : FReadable
@property (strong) FVector4 *orientation;
@property (strong) FVector3 *position;
@property (assign) long     nameIdx;
@property (assign) int      childrenCnt;
@property (assign) int      parentIdx;
@property (assign) int      flags;
@property (assign) int      unk;
@end


@interface FMeshSection : FReadable
@property (assign) short    material;
@property (assign) short    chunkIndex;
@property (assign) int      firstIndex;
@property (assign) short    faceCount;
@end

@interface FMuliSizeIndexContainer : FReadable
@property (assign) int      elementSize;
@property (assign) int      elementCount;

- (uint8_t *)rawData;
- (void)setRawData:(uint8_t *)ptr;
- (void *)element:(int)index;

@end



@interface FSkeletalMeshChunk : FReadable
@property (assign) int                  firstIndex;
@property (assign) int                  rigidVerticiesCount;
@property (assign) FRigidVertex         *rigidVerticies;
@property (assign) int                  softVerticiesCount;
@property (assign) FSoftVertex          *softVerticies;
@property (assign) int                  boneMapCount;
@property (assign) unsigned short       *boneMap;
@property (assign) int                  maxBoneInfluences;
@end

@interface FGPUSkinBuffer : FReadable
@property (assign) BOOL                 useFullUV;
@property (assign) BOOL                 usePackedPosition;
@property (assign) int                  elementSize;
@property (assign) int                  elementCount;
@property (assign) FGPUVert3Half        *vertices;
@end

@interface FLodInfo : FReadable
@property (strong) FArray               *sections;
@property (strong) FMuliSizeIndexContainer *indexContainter;
@property (strong) FArray               *chunks;
@property (strong) FBulkData            *rawPoints;
@property (assign) int                  size;
@property (assign) int                  vertexCount;
@property (strong) FGPUSkinBuffer       *vertexBufferGPUSkin;

@property (assign) void                 *legacyShadowIndices;
@property (assign) int                  legacyShadowIndicesCount;
@property (assign) int                  legacyEdgeCount; // Unused
@property (assign) FEdge                *legacyEdge;
@property (assign) int                  activeBoneIndicesCount;//usedBonesCount;
@property (assign) unsigned short       *activeBoneIndices;//usedBones;
@property (assign) int                  legacyShadowTriangleDoubleSidedCount; // Dropped on cooking
@property (assign) Byte                 *legacyShadowTriangleDoubleSided;
@property (assign) int                  extraVertexInfluencesCount;
@property (assign) int                  requiredBonesCount;
@property (assign) Byte                 *requiredBones;

- (FSoftVertex *)vertices;

@end
