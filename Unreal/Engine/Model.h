//
//  Model.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 11/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FBoxSphereBounds.h"
#import "FArray.h"

@interface FBspNode : FReadable
@property (strong) FPlane *plane;
@property (assign) int iVertPool;
@property (assign) int iSurf;
@property (assign) int iVertexIndex;
@property (assign) short componentIndex;
@property (assign) short componentNodeIndex;
@property (assign) short componentElementIndex;
@end

@interface Model : UObject
@property (strong) FBoxSphereBounds *bounds;
@property (strong) TransFArray *vectors;
@property (strong) TransFArray *points;
@property (strong) TransFArray *nodes;
@property (strong) TransFArray *verts;
@end
