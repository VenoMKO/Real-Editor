//
//  Prefab.h
//  Real Editor
//
//  Created by VenoMKO on 29.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "UObject.h"
#import <SceneKit/SceneKit.h>

@interface Prefab : UObject

- (NSArray *)prefabArchetypes;
- (SCNNode *)renderNode:(NSUInteger)lodIndex;

@end
