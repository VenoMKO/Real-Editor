//
//  FRotator.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FVector.h"
#import <SceneKit/SceneKit.h>

/*
 X= Roll
 Y= Pitch
 Z= Yaw
 */
@interface FRotator : FReadable <NSCopying>

@property (assign) int pitch; // Looking up and down (0=Straight Ahead, +Up, -Down).
@property (assign) int yaw; // Rotating around (running in circles), 0=East, +North, -South.
@property (assign) int roll; // Rotation about axis of screen, 0=Straight, +Clockwise, -CCW.

- (FVector3 *)euler;
- (void)setEuler:(FVector3 *)euler;
- (FRotator *)normalized;
- (FRotator *)denormalized;
- (SCNQuaternion)quaternion;

@end
