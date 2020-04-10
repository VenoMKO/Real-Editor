//
//  MeshActor.h
//  Real Editor
//
//  Created by VenoMKO on 31.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "Actor.h"
@interface MeshActor : Actor
- (id)mesh;
@end

@interface StaticMeshActor : MeshActor
@end

@interface SkeletalMeshActor : MeshActor
@end

@interface InterpActor : MeshActor
@end
