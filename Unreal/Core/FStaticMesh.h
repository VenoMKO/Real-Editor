//
//  FStaticMesh.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 23/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FArray.h"
#import <GLKit/GLKit.h>
#import "FMesh.h"
#import "FLightMap.h"

struct _FFragmentRange
{
  int baseIndex;
  int numPrimitives;
};
typedef struct _FFragmentRange FFragmentRange;

struct _FUVFloat1
{
  FPackedNormal   normal[2];
  int             color;
  FMeshFloatUV    UVs;
};
typedef struct _FUVFloat1 FUVFloat1;

struct _FUVFloat2
{
  FPackedNormal   normal[2];
  int             color;
  FMeshFloatUV    UVs[2];
};
typedef struct _FUVFloat2 FUVFloat2;

struct _FUVFloat3
{
  FPackedNormal   normal[2];
  int             color;
  FMeshFloatUV    UVs[3];
};
typedef struct _FUVFloat3 FUVFloat3;

struct _FUVFloat4
{
  FPackedNormal   normal[2];
  int             color;
  FMeshFloatUV    UVs[4];
};
typedef struct _FUVFloat4 FUVFloat4;

struct _FUVHalf1
{
  FPackedNormal   normal[2];
  int             color;
  FMeshHalfUV     UVs;
};
typedef struct _FUVHalf1 FUVHalf1;

struct _FUVHalf2
{
  FPackedNormal   normal[2];
  int             color;
  FMeshHalfUV     UVs[2];
};
typedef struct _FUVHalf2 FUVHalf2;

struct _FUVHalf3
{
  FPackedNormal   normal[2];
  int             color;
  FMeshHalfUV     UVs[3];
};
typedef struct _FUVHalf3 FUVHalf3;

struct _FUVHalf4
{
  FPackedNormal   normal[2];
  int             color;
  FMeshHalfUV     UVs[4];
};
typedef struct _FUVHalf4 FUVHalf4;

@interface FVert : FReadable
@property (assign) int pVertex;
@property (assign) int iSide; // If shared, index of unique side. Otherwise INDEX_NONE.
@property (strong) FVector2D *shadowTexCoord;
@property (strong) FVector2D *backfaceShadowTexCoord;

@end

@interface FPositionVertexData : FReadable

@property (assign) GLKVector3 *data;
@property (assign) int  stride;
@property (assign) int  count;

@end

@interface FUVVertexData : FReadable
@property (assign) void *data;
@property (assign) int  numUVSets;
@property (assign) int  stride;
@property (assign) int  numUVs;
@property (assign) int  bUseFullUVs;
@property (assign) int  size;
@end

@interface FStaticMeshSection : FReadable

@property (assign) int      material;
@property (assign) int      enableCollision;
@property (assign) int      oldEnableCollision;
@property (assign) int      bEnableShadowCasting;
@property (assign) int      firstIndex;
@property (assign) int      faceCount;
@property (assign) int      minVertexIndex;
@property (assign) int      maxVertexIndex;
@property (assign) int      materialIndex;
@property (assign) int      fragmentCount;
@property (assign) FFragmentRange     *fragments;

@end

@interface FStaticColorData : FReadable
@property (assign) int stride;
@property (assign) int count;
@property (assign) int *data;
@end


@interface FStaticLodInfo : FReadable

@property (strong) FArray   *sections;
@property (strong) FPositionVertexData *positionBuffer;
@property (strong) FUVVertexData *textureBuffer;
@property (strong) FStaticColorData *colorBuffer;
@property (strong) FMuliSizeIndexContainer *indexContainer;
@property (strong) FMuliSizeIndexContainer *wireframeIndexBuffer;
@property (assign) int  legacyEdgeCount;
@property (assign) FEdge  *legacyEdges;
@property (assign) int numVerticies;

- (GenericVertex *)vertices;
- (NSArray *)materials;

@end

@interface FStaticMeshComponentLODInfo : FReadable

@property (strong) FArray   *shadowMaps;
@property (strong) FArray   *shadowVertexBuffers;
@property (strong) FLightMap *lightMap;
@property (strong) UObject  *unkShadowMap;

@end
