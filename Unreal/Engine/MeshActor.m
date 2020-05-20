//
//  MeshActor.m
//  Real Editor
//
//  Created by VenoMKO on 31.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "MeshActor.h"
#import "UPackage.h"
#import "T3DUtils.h"

@implementation MeshActor
@dynamic component;

- (id)mesh
{
  if (!self.component)
  {
    [self properties];
  }
  return [(MeshComponent *)self.component mesh];
}

- (NSString *)displayName
{
  NSString *name = [[self mesh] displayName];
  return name ? name : [super displayName];
}

- (BOOL)lockLockation
{
  NSNumber *value = [self propertyValue:@"bLockLocation"];
  return value ? [value boolValue] : NO;
}

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index contentPath:(NSString *)contentPath
{
  return NO;
}

@end

@implementation StaticMeshActor
@dynamic component;

- (FIStream *)postProperties
{
  [super postProperties];
  FPropertyTag *ref = [self propertyForName:@"StaticMeshComponent"];
  if (ref)
    self.component = [self.package objectForIndex:[ref.value intValue]];
  [self.component properties]; // Force read props
  return nil;
}

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index contentPath:(NSString *)contentPath
{
  [self properties];
  
  if (!self.component.mesh)
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
      T3DAddLine(result, padding, @"StaticMesh=StaticMesh'\"%@\"'", contentPath);
      
      GLKVector3 pos = [self absolutePostion];
      T3DAddLine(result, padding, @"RelativeLocation=(X=%.6f,Y=%.6f,Z=%.6f)", pos.x, pos.y, pos.z);
      
      GLKVector3 rot = [[[self absoluteRotator] euler] glkVector3];
      T3DAddLine(result, padding, @"RelativeRotation=(Pitch=%.6f,Yaw=%.6f,Roll=%.6f)", rot.y, rot.z, rot.x);
      
      GLKVector3 scale = [self absoluteDrawScale3D];
      scale = GLKVector3MultiplyScalar(scale, [self absoluteDrawScale]);
      T3DAddLine(result, padding, @"RelativeScale3D=(X=%.6f,Y=%.6f,Z=%.6f)", scale.x, scale.y, scale.z);
      if (!self.component.castShadow)
      {
        T3DAddLine(result, padding, @"CastShadow=False");
      }
      if (!self.component.castDynamicShadow)
      {
        T3DAddLine(result, padding, @"bCastDynamicShadow=False");
      }
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

@implementation SkeletalMeshActor
@dynamic component;

- (FIStream *)postProperties
{
  [super postProperties];
  FPropertyTag *ref = [self propertyForName:@"SkeletalMeshComponent"];
  if (ref)
    self.component = [self.package objectForIndex:[ref.value intValue]];
  [self.component properties]; // Force read props
  return nil;
}

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index contentPath:(NSString *)contentPath
{
  [self properties];
  if (![self.component isKindOfClass:[MeshComponent class]])
  {
    return NO;
  }
  if ([self.component isKindOfClass:[SkeletalMeshComponent class]])
  {
    NSString *name = index < 0 ? self.displayName : [self.displayName stringByAppendingFormat:@"_%d",index];
    T3DAddLine(result, padding, T3DBeginObject(@"Actor", name, @"/Script/Engine.SkeletalMeshActor"));
    {
      padding++;
      T3DAddLine(result, padding, T3DBeginObject(@"Object", @"SkeletalMeshComponent0", nil));
      {
        padding++;
        T3DAddLine(result, padding, @"ClothingSimulationFactory=Class'\"/Script/ClothingSystemRuntimeNv.ClothingSimulationFactoryNv\"'");
        T3DAddLine(result, padding, @"SkeletalMesh=SkeletalMesh'\"%@\"'", contentPath);
        
        GLKVector3 pos = [self absolutePostion];
        T3DAddLine(result, padding, @"RelativeLocation=(X=%.6f,Y=%.6f,Z=%.6f)", pos.x, pos.y, pos.z);
        
        GLKVector3 rot = [[[self absoluteRotator] euler] glkVector3];
        T3DAddLine(result, padding, @"RelativeRotation=(Pitch=%.6f,Yaw=%.6f,Roll=%.6f)", rot.y, rot.z, rot.x);
        
        GLKVector3 scale = [self absoluteDrawScale3D];
        scale = GLKVector3MultiplyScalar(scale, [self absoluteDrawScale]);
        T3DAddLine(result, padding, @"RelativeScale3D=(X=%.6f,Y=%.6f,Z=%.6f)", scale.x, scale.y, scale.z);
        if (!self.component.castShadow)
        {
          T3DAddLine(result, padding, @"CastShadow=False");
        }
        if (!self.component.castDynamicShadow)
        {
          T3DAddLine(result, padding, @"bCastDynamicShadow=False");
        }
        T3DAddLine(result, padding, @"LightingChannels=(bChannel0=%@)", self.component.acceptsLights || self.component.acceptsDynamicLights ? @"True" : @"False");
        padding--;
      }
      T3DAddLine(result, padding, T3DEndObject(@"Object"));
      T3DAddLine(result, padding, @"SkeletalMeshComponent=\"SkeletalMeshComponent0\"");
      T3DAddLine(result, padding, @"RootComponent=\"SkeletalMeshComponent0\"");
      T3DAddLine(result, padding, @"ActorLabel=\"%@\"", name);
      T3DAddLine(result, padding, @"FolderPath=\"%@\"", self.package.name);
    }
    padding--;
    T3DAddLine(result, padding, T3DEndObject(@"Actor"));
    return YES;
  }
  return NO;
}

@end

@implementation InterpActor

- (FIStream *)postProperties
{
  [super postProperties];
  FPropertyTag *ref = [self propertyForName:@"SkeletalMeshComponent"];
  if (ref)
  {
    self.component = [self.package objectForIndex:[ref.value intValue]];
  }
  else
  {
    ref = [self propertyForName:@"StaticMeshComponent"];
    if (ref)
      self.component = [self.package objectForIndex:[ref.value intValue]];
  }
  [self.component properties]; // Force read props
  return nil;
}

- (NSString *)displayName
{
  NSString *name = [[(MeshComponent *)self.component mesh] objectName];
  return name ? name : self.objectName;
}

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index contentPath:(NSString *)contentPath
{
  [self properties];
  if (![self.component isKindOfClass:[MeshComponent class]])
  {
    return NO;
  }
  if ([self.component isKindOfClass:[StaticMeshComponent class]])
  {
    NSString *name = index < 0 ? self.displayName : [self.displayName stringByAppendingFormat:@"_%d",index];
    T3DAddLine(result, padding, T3DBeginObject(@"Actor", name, @"/Script/Engine.StaticMeshActor"));
    {
      padding++;
      T3DAddLine(result, padding, T3DBeginObject(@"Object", @"StaticMeshComponent0", nil));
      {
        padding++;
        T3DAddLine(result, padding, @"StaticMesh=StaticMesh'\"%@\"'", contentPath);
        
        GLKVector3 pos = [self absolutePostion];
        T3DAddLine(result, padding, @"RelativeLocation=(X=%.6f,Y=%.6f,Z=%.6f)", pos.x, pos.y, pos.z);
        
        GLKVector3 rot = [[[self absoluteRotator] euler] glkVector3];
        T3DAddLine(result, padding, @"RelativeRotation=(Pitch=%.6f,Yaw=%.6f,Roll=%.6f)", rot.y, rot.z, rot.x);
        
        GLKVector3 scale = [self absoluteDrawScale3D];
        scale = GLKVector3MultiplyScalar(scale, [self absoluteDrawScale]);
        T3DAddLine(result, padding, @"RelativeScale3D=(X=%.6f,Y=%.6f,Z=%.6f)", scale.x, scale.y, scale.z);
        if (!self.component.castShadow)
        {
          T3DAddLine(result, padding, @"CastShadow=False");
        }
        if (!self.component.castDynamicShadow)
        {
          T3DAddLine(result, padding, @"bCastDynamicShadow=False");
        }
        T3DAddLine(result, padding, @"LightingChannels=(bChannel0=%@)", self.component.acceptsLights || self.component.acceptsDynamicLights ? @"True" : @"False");
        T3DAddLine(result, padding, @"Mobility=Movable");
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
  return NO;
}

@end
