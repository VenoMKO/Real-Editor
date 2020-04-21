//
//  Actor.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 09/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FRotator.h"
#import "FColor.h"
#import <GLKit/GLKit.h>
#import "UComponent.h"

@interface Actor : UObject
@property (assign, nonatomic) GLKVector3 position;
@property (assign, nonatomic) GLKVector3 drawScale3D;
@property (assign, nonatomic) CGFloat    drawScale;
@property (assign, nonatomic) GLKVector3 rotation;
@property (retain) ActorComponent *component;

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index;
- (NSString *)displayName;
- (FRotator *)rotator;
- (CGFloat)absoluteDrawScale;
- (GLKVector3)absolutePostion;
- (GLKVector3)absoluteDrawScale3D;
- (GLKVector3)absoluteRotation;
- (GLKVector3)absoluteSCNRotation;
- (FRotator *)absoluteRotator;
@end

@interface Emitter : Actor
@property ParticleSystemComponent *component;
@end
