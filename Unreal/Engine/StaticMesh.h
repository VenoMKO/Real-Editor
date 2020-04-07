//
//  StaticMesh.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 22/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "UObject.h"
#import "FBoxSphereBounds.h"
#import "FStaticMesh.h"
#import "FString.h"
#import "FArray.h"
#import "FRotator.h"

struct _kDOPNode
{
  GLKVector3  boundingVolumeMin;
  GLKVector3  boundingVolumeMax;
  int         bIsLeaf;
  union
  {
    // This structure contains the left and right child kDOP indices
    // These index values correspond to the array in the FkDOPTree
    struct
    {
      short LeftNode;
      short RightNode;
    } n;
    // This structure contains the list of enclosed triangles
    // These index values correspond to the triangle information in the
    // FkDOPTree using the start and count as the means of delineating
    // which triangles are involved
    struct
    {
      short NumTriangles;
      short StartIndex;
    } t;
  };
};
typedef struct _kDOPNode kDOPNode;

@interface StaticMesh : UObject

@property (strong) FBoxSphereBounds             *bounds;
@property (strong, nonatomic) FString           *sourceFile;
@property (strong, nonatomic) UObject           *bodySetup;

@property (assign) int                          kDOPNodeCount;
@property (assign) kDOPNode                     *kDOPNodes;
@property (assign) int                          kDOPTriangleCount;
@property (assign) long                         *kDOPTriangles;

@property (assign) int                          legacykDOPTreeFlags;
@property (assign) int                          legacykDOPTreeCount;
@property (assign) int                          legacykDOPTreeSize;
@property (assign) int                          legacykDOPTreeOffset;
@property (assign) int                          legaceKDOPTree;

@property (strong, nonatomic) FArray            *strings;
@property (assign) int                          version;

@property (strong, nonatomic) FArray            *lodInfo;
@property (assign) int                          lodInfoCount;
@property (strong) FRotator                     *thumbnailAngle;
@property (assign) int                          thumbnailDistance;
@property (strong) FArray                       *physMeshScale3D;
@property (assign) int                          unk;

- (SCNNode *)renderNode:(NSUInteger)lodIndex;
- (NSArray *)materials;

@end
