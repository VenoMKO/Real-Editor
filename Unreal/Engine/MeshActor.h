//
//  MeshActor.h
//  Real Editor
//
//  Created by VenoMKO on 31.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "Actor.h"
#import "MeshComponent.h"
@interface MeshActor : Actor
@property MeshComponent *component;
- (id)mesh;
- (BOOL)lockLockation;
- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index contentPath:(NSString *)contentPath;
@end

@interface StaticMeshActor : MeshActor
@property StaticMeshComponent *component;
@end

@interface SkeletalMeshActor : MeshActor
@property SkeletalMeshComponent *component;
@end

@interface InterpActor : MeshActor
@end
