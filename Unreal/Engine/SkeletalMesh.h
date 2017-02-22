//
//  SkeletalMesh.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 11/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "UObject.h"
#import "FArray.h"
#import "FRotator.h"
#import "FBoxSphereBounds.h"
#import "FMesh.h"

@interface SkeletalMesh : UObject
@property (strong) FBoxSphereBounds *bounds;
@property (strong) FArray           *materials;
@property (strong) FVector3         *origin;
@property (strong) FRotator         *rotaion;
@property (strong) FArray           *refSkeleton;
@property (assign) int              skeletalDepth;
@property (strong) FArray           *lodInfo;
@property (strong) FArray           *nameMap;
@property (strong) NSData           *perPolyBoneKDOPs;

- (SCNNode *)renderNode:(NSUInteger)lodIndex;

@end

@interface SkeletalMeshSocket : UObject
@end
