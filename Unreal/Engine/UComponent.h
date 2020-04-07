//
//  UComponent.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 22/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import <GLKit/GLKit.h>

@class FColor, FRotator, UClass, FName;

@interface UComponent : UObject
@property (weak) UClass *templateOwnerClass;
@property (strong) FName *templateName;
@end

@interface ActorComponent : UComponent
- (GLKVector3)rotation;
- (GLKVector3)scale3D;
- (GLKVector3)translation;
- (CGFloat)scale;
- (FRotator *)rotator;
@end

@interface PrimitiveComponent : ActorComponent
@end

@interface DistributionFloat : UComponent
@end

@interface DistributionFloatConstant : DistributionFloat
@end

@interface DistributionFloatConstantCurve : DistributionFloat
@end

@interface DistributionFloatUniform : DistributionFloat
@end

@interface DistributionVector : UComponent
@end

@interface DistributionVectorConstant : DistributionVector
@end

@interface DistributionVectorConstantCurve : DistributionVector
@end

@interface DistributionVectorUniform : DistributionVector
@end

@interface LightComponent : ActorComponent
@property (strong) FColor *lightColor;
@property (assign) CGFloat brightness;
@property (assign) CGFloat radius;
@property (assign) CGFloat falloffExponent;
@property (strong) FArray *inclusionConvexVolumes;
@property (strong) FArray *exclusionConvexVolumes;
@end

@interface PointLightComponent : LightComponent
@end

@interface SpotLightComponent : PointLightComponent
@property BOOL             renderLightShafts;
@property (assign) CGFloat innerConeAngle;
@property (assign) CGFloat outerConeAngle;
@property (assign) CGFloat lightShaftConeAngle;
@end
