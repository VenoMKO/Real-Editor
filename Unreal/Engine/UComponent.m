//
//  UComponent.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 22/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UComponent.h"
#import "FColor.h"
#import "UPackage.h"
#import "FVector.h"
#import "FRotator.h"
#import "FString.h"
#import "UClass.h"
#import "FBoxSphereBounds.h"

@implementation UComponent

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  s.position = self.rawDataOffset;
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  if ([self.className isEqualToString:@"UComponent"]) // Some undefined components have data. Call super to save it as it was
    return [super cooked:offset];
  
  return [self cookedProperties]; // Otherwise handle cooking manually
}

@end

@implementation ActorComponent

- (GLKVector3)rotation
{
  FPropertyTag *prop = [self propertyForName:@"Rotation"];
  if (!prop || !prop.value)
    return GLKVector3Make(0, 0, 0);
  FVector3 *v = [(FRotator *)prop.value euler];
  return GLKVector3Make(v.x, v.y, v.z);
}

- (GLKVector3)scale3D
{
  FPropertyTag *prop = [self propertyForName:@"Scale3D"];
  if (!prop || !prop.value)
    return GLKVector3Make(1, 1, 1);
  FVector3 *v = (FVector3 *)prop.value;
  return GLKVector3Make(v.x, v.y, v.z);
}

- (GLKVector3)translation
{
  FPropertyTag *prop = [self propertyForName:@"Translation"];
  if (!prop || !prop.value)
    return GLKVector3Make(0, 0, 0);
  FVector3 *v = (FVector3 *)prop.value;
  return GLKVector3Make(v.x, v.y, v.z);
}

- (CGFloat)scale
{
  FPropertyTag *prop = [self propertyForName:@"Scale"];
  if (!prop || !prop.value)
    return 1.0;
  return [prop.value doubleValue];
}

- (FRotator *)rotator
{
  FPropertyTag *prop = [self propertyForName:@"Rotation"];
  if (!prop || !prop.value)
    return nil;
  
  return prop.value;
}

@end

@implementation PrimitiveComponent
@end

@implementation DistributionFloat
@end

@implementation DistributionFloatConstant
@end

@implementation DistributionFloatConstantCurve
@end

@implementation DistributionFloatUniform
@end

@implementation DistributionVector
@end

@implementation DistributionVectorConstant
@end

@implementation DistributionVectorConstantCurve
@end

@implementation DistributionVectorUniform
@end

@implementation LightComponent

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  FPropertyTag *tag = [self propertyForName:@"LightColor"];
  self.lightColor = tag ? tag.value : [FColor colorWithColor:[NSColor colorWithRed:1 green:1 blue:1 alpha:1] package:self.package];
  tag = [self propertyForName:@"Brightness"];
  self.brightness = tag.value ? [tag.value doubleValue] : 1.0;
  self.inclusionConvexVolumes = [FArray readFrom:s type:[FConvexVolume class]];
  self.exclusionConvexVolumes = [FArray readFrom:s type:[FConvexVolume class]];
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.inclusionConvexVolumes cooked:offset + d.length]];
  [d appendData:[self.exclusionConvexVolumes cooked:offset + d.length]];
  return d;
}

@end

@implementation PointLightComponent

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  FPropertyTag *tag = [self propertyForName:@"Radius"];
  self.radius = tag.value ? [tag.value doubleValue] : 100.0;
  tag = [self propertyForName:@"FalloffExponent"];
  self.falloffExponent = tag.value ? [tag.value doubleValue] : 3.0;
  tag = [self propertyForName:@"Translation"];
  self.translation = tag.value ? GLKVector3Make([(FVector3 *)tag.value x], [(FVector3 *)tag.value y], [(FVector3 *)tag.value z]) : GLKVector3Make(0, 0, 0);
  return s;
}

@end

@implementation SpotLightComponent

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  FPropertyTag *tag = [self propertyForName:@"InnerConeAngle"];
  self.innerConeAngle = tag.value ? [tag.value doubleValue] : 0.01;
  if (self.innerConeAngle < 0.01 && self.innerConeAngle > -0.01)
    self.innerConeAngle = 0.01;
  tag = [self propertyForName:@"OuterConeAngle"];
  self.outerConeAngle = tag.value ? [tag.value doubleValue] : 0.01;
  
  tag = [self propertyForName:@"LightShaftConeAngle"];
  self.lightShaftConeAngle = tag.value ? [tag.value doubleValue] : 0.01;
  return s;
}

@end
