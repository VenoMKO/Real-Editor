//
//  Actor.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 09/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "Actor.h"
#import "UPackage.h"
#import "FPropertyTag.h"
#import "FVector.h"
#import "FRotator.h"
#import "MeshComponent.h"
#import "T3DUtils.h"

@interface Actor ()
@end

@implementation Actor

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index
{
  T3DAddLine(result, padding, T3DBeginObject(@"Actor", [[self displayName] stringByAppendingFormat:@"_%d",index], @"/Script/Engine.Actor"));
  {
    padding++;
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"DefaultSceneRoot", @"/Script/Engine.SceneComponent"));
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"DefaultSceneRoot", nil));
    {
      padding++;
      GLKVector3 pos = [self absolutePostion];
      T3DAddLine(result, padding, @"RelativeLocation=(X=%.6f,Y=%.6f,Z=%.6f)", pos.x, pos.y, pos.z);
      GLKVector3 rot = [[[self absoluteRotator] euler] glkVector3];
      T3DAddLine(result, padding, @"RelativeRotation=(Pitch=%.6f,Yaw=%.6f,Roll=%.6f)", rot.y, rot.z, rot.x);
      GLKVector3 scale = [self absoluteDrawScale3D];
      scale = GLKVector3MultiplyScalar(scale, [self absoluteDrawScale]);
      T3DAddLine(result, padding, @"RelativeScale3D=(X=%.6f,Y=%.6f,Z=%.6f)", scale.x, scale.y, scale.z);
      T3DAddLine(result, padding, @"bVisualizeComponent=True");
      T3DAddLine(result, padding, @"CreationMethod=Instance");
      padding--;
    }
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, @"RootComponent=SceneComponent'\"DefaultSceneRoot\"'");
    T3DAddLine(result, padding, @"ActorLabel=\"%@_%d\"", [self displayName], index);
    T3DAddLine(result, padding, @"InstanceComponents(0)=SceneComponent'\"DefaultSceneRoot\"'");
    padding--;
  }
  T3DEndObject(@"Actor");
  return YES;
}

- (FIStream *)postProperties
{
  FPropertyTag *prop = nil;
  prop = [self propertyForName:@"Location"];
  if (!prop)
    self.position = GLKVector3Make(0, 0, 0);
  else
  {
    FVector3 *v = (FVector3 *)prop.value;
    self.position = GLKVector3Make(v.x, v.y, v.z);
  }
  
  prop = [self propertyForName:@"DrawScale3D"];
  if (!prop)
    self.drawScale3D = GLKVector3Make(1, 1, 1);
  else
  {
    FVector3 *v = (FVector3 *)prop.value;
    self.drawScale3D = GLKVector3Make(v.x, v.y, v.z);
  }
  
  prop = [self propertyForName:@"Rotation"];
  if (!prop)
    self.rotation = GLKVector3Make(0, 0, 0);
  else
  {
    FVector3 *v = [(FRotator *)prop.value euler];
    self.rotation = GLKVector3Make(v.x, v.y, v.z);
  }
  
  prop = [self propertyForName:@"DrawScale"];
  if (!prop)
    self.drawScale = 1;
  else
  {
    self.drawScale = [prop.value doubleValue];
  }
  return nil;
}

- (NSString *)displayName
{
  return self.objectName;
}

- (FRotator *)rotator
{
  FPropertyTag *prop = [self propertyForName:@"Rotation"];
  if (!prop || !prop.value)
    return nil;
  
  return prop.value;
}

- (GLKVector3)absolutePostion
{
  if (!self.component)
    return self.position;
  
  GLKVector3 pos = self.position;
  pos = GLKVector3Add(pos, self.component.translation);
  return pos;
}
- (GLKVector3)absoluteDrawScale3D
{
  if (!self.component)
    return self.drawScale3D;
  
  GLKVector3 scl = self.drawScale3D;
  scl = GLKVector3Multiply(scl, self.component.scale3D);
  return scl;
}

- (CGFloat)absoluteDrawScale
{
  if (!self.component)
    return self.drawScale;
  
  CGFloat scl = self.drawScale;
  scl *= self.component.scale;
  return scl;
}

- (GLKVector3)absoluteRotation
{
  if (!self.component)
    return self.rotation;
  
  GLKVector3 scl = self.rotation;
  scl = GLKVector3Add(scl, self.component.rotation);
  return scl;
}

- (GLKVector3)absoluteSCNRotation
{
  GLKVector3 res = GLKVector3Make(-GLKMathDegreesToRadians(_rotation.y), -GLKMathDegreesToRadians(_rotation.z), GLKMathDegreesToRadians(_rotation.x));
  if (!self.component)
    return res;
  
  GLKVector3 scl = self.component.rotation;
  scl = GLKVector3Add(res, GLKVector3Make(-GLKMathDegreesToRadians(scl.y), -GLKMathDegreesToRadians(scl.z), GLKMathDegreesToRadians(scl.x)));
  return scl;
}

- (FRotator *)absoluteRotator
{
  FRotator *r = [FRotator newWithPackage:self.package];
  FRotator *selfRot = self.rotator;
  if (selfRot)
  {
    r.pitch = selfRot.pitch;
    r.yaw = selfRot.yaw;
    r.roll = selfRot.roll;
  }
  selfRot = self.component.rotator;
  if (selfRot)
  {
    r.pitch += selfRot.pitch;
    r.yaw += selfRot.yaw;
    r.roll += selfRot.roll;
  }
  return r;
}

@end

@implementation Emitter
@dynamic component;

- (FIStream *)postProperties
{
  [super postProperties];
  NSNumber *objIdex = [self propertyValue:@"ParticleSystemComponent"];
  if ([objIdex intValue])
  {
    self.component = [self.package objectForIndex:objIdex.intValue];
  }
  return nil;
}

- (NSString *)displayName
{
  NSString *name = [[self.component templateObject] objectName];
  return name ? name : super.displayName;
}

@end
