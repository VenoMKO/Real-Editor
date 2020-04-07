//
//  LightActor.h
//  Real Editor
//
//  Created by VenoMKO on 1.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "Actor.h"

@interface LightActor : Actor
@property (weak) LightComponent *lightComponent;
@end

@interface PointLight : LightActor
@end

@interface SpotLight : PointLight
@end
