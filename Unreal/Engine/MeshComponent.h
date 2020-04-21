//
//  MeshComponent.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 25/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UComponent.h"

@interface MeshComponent : PrimitiveComponent
@property (weak) UObject *mesh;
- (BOOL)castShadow;
- (BOOL)castDynamicShadow;
- (BOOL)acceptsLights;
- (BOOL)acceptsDynamicLights;
@end

@interface StaticMeshComponent : MeshComponent
@property (strong) FArray *lodInfo;
@end

@interface SkeletalMeshComponent : MeshComponent
@end
