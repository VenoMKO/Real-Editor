//
//  SpeedTreeActor.m
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "SpeedTreeActor.h"
#import "UPackage.h"
#import "T3DUtils.h"

@implementation SpeedTreeActor
@dynamic component;

- (FIStream *)postProperties
{
  [super postProperties];
  FPropertyTag *ref = [self propertyForName:@"SpeedTreeComponent"];
  if (ref)
    self.component = [self.package objectForIndex:[ref.value intValue]];
  [self.component properties]; // Force read props
  return nil;
}

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index
{
  [self properties];
  
  if (!self.component)
  {
    return NO;
  }
  
  NSString *name = index < 0 ? self.displayName : [self.displayName stringByAppendingFormat:@"_%d",index];
  T3DAddLine(result, padding, T3DBeginObject(@"Actor", name, @"/Script/Engine.StaticMeshActor"));
  {
    padding++;
    T3DAddLine(result, padding, T3DBeginObject(@"Object", @"StaticMeshComponent0", nil));
    {
      padding++;
      NSMutableArray *targetPathComps = [[[[self.component speedTree] objectPath] componentsSeparatedByString:@"."] mutableCopy];
      [targetPathComps removeObjectAtIndex:0];
      NSString *targetPath = [targetPathComps componentsJoinedByString:@"/"];
      T3DAddLine(result, padding, @"StaticMesh=StaticMesh'\"%@\"'", [@"/Game/S1Data/" stringByAppendingString:targetPath]);
      
      GLKVector3 pos = [self absolutePostion];
      T3DAddLine(result, padding, @"RelativeLocation=(X=%.6f,Y=%.6f,Z=%.6f)", pos.x, pos.y, pos.z);
      
      GLKVector3 rot = [[[self absoluteRotator] euler] glkVector3];
      T3DAddLine(result, padding, @"RelativeRotation=(Pitch=%.6f,Yaw=%.6f,Roll=%.6f)", rot.y, rot.z, rot.x);
      
      GLKVector3 scale = [self absoluteDrawScale3D];
      scale = GLKVector3MultiplyScalar(scale, [self absoluteDrawScale]);
      T3DAddLine(result, padding, @"RelativeScale3D=(X=%.6f,Y=%.6f,Z=%.6f)", scale.x, scale.y, scale.z);
      T3DAddLine(result, padding, @"bCastStaticShadow=%@", self.component.castShadow ? @"True" : @"False");
      T3DAddLine(result, padding, @"bCastDynamicShadow=%@", self.component.castDynamicShadow ? @"True" : @"False");
      T3DAddLine(result, padding, @"Mobility=Static");
      T3DAddLine(result, padding, @"LightingChannels=(bChannel0=%@)", self.component.acceptsLights || self.component.acceptsDynamicLights ? @"True" : @"False");
      padding--;
    }
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, @"StaticMeshComponent=\"StaticMeshComponent0\"");
    T3DAddLine(result, padding, @"RootComponent=\"StaticMeshComponent0\"");
    T3DAddLine(result, padding, @"ActorLabel=\"%@\"", name);
    T3DAddLine(result, padding, @"FolderPath=\"%@\"", self.package.name);
  }
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Actor"));
  return YES;
}

@end
