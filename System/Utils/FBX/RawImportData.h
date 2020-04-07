//
//  RawImportData.h
//  Package Manager
//
//  Created by Vladislav Skachkov on 03/01/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "FMesh.h"

struct _RawTriangle
{
    int         wedgeIndices[3];
    short       materialIndex;
    
    GLKVector3 tangentX[3];
    GLKVector3 tangentY[3];
    GLKVector3 tangentZ[3];
    float       basis[3];
};
typedef struct _RawTriangle RawTriangle;

struct _RawInfluence
{
    float       weight;
    int         vertexIndex;
    int         boneIndex;
};
typedef struct _RawInfluence RawInfluence;

struct _RawWedge
{
    int         pointIndex;
    int         materialIndex;
    GLKVector2  UV[4];
};
typedef struct _RawWedge RawWedge;

struct _RawBone
{
    const char  *boneName;
    int         boneIndex;
    int         parentIndex;
    GLKVector3  position;
    GLKVector4  orientation;
};
typedef struct _RawBone RawBone;

struct _RawMaterial
{
    const char  *materialName;
    int         materialIndex;
};
@interface RawImportData : NSObject
@property (assign) GLKVector3           *points;
@property (assign) RawTriangle          *faces;
@property (strong) NSArray<FMeshBone *> *bones;
@property (assign) RawInfluence         *influences;
@property (assign) RawWedge             *wedges;
@property (strong) NSMutableArray       *materials;

@property (assign) int                  pointCount;
@property (assign) int                  faceCount;
@property (assign) int                  boneCount;
@property (assign) int                  influenceCount;
@property (assign) int                  wedgeCount;
@property (assign) int                  uvSetCount;
@property (assign) BOOL                 overrideSkel;
@property (assign) BOOL                 flipTangents;

- (FLodInfo *)buildLod:(NSDictionary *)options;
@end
