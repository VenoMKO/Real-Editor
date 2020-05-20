//
//  SpeedTreeActor.h
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "Actor.h"
#import "SpeedTreeComponent.h"

@interface SpeedTreeActor : Actor
@property SpeedTreeComponent *component;

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index contentPath:(NSString *)contentPath;

@end
