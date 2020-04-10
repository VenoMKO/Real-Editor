//
//  MeshActor.m
//  Real Editor
//
//  Created by VenoMKO on 31.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "MeshActor.h"
#import "MeshComponent.h"
#import "UPackage.h"
#import "T3DUtils.h"

@implementation MeshActor

- (id)mesh
{
  return [(MeshComponent *)self.component mesh];
}

- (NSString *)displayName
{
  NSString *name = [[self mesh] objectName];
  return name ? name : self.objectName;
}

@end

@implementation StaticMeshActor

- (FIStream *)postProperties
{
  [super postProperties];
  FPropertyTag *ref = [self propertyForName:@"StaticMeshComponent"];
  if (ref)
    self.component = [self.package objectForIndex:[ref.value intValue]];
  [self.component properties]; // Force read props
  return nil;
}

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index
{
  [self properties];
  
  if (![(MeshComponent *)self.component mesh])
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
      NSMutableArray *targetPathComps = [[[[(MeshComponent*)[self component] mesh] objectPath] componentsSeparatedByString:@"."] mutableCopy];
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

- (FIStream *)postProperties
{
  [super postProperties];
  FPropertyTag *ref = [self propertyForName:@"SkeletalMeshComponent"];
  if (ref)
    self.component = [self.package objectForIndex:[ref.value intValue]];
  [self.component properties]; // Force read props
  return nil;
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

- (BOOL)exportToT3D:(NSMutableString *)result padding:(unsigned)padding index:(int)index
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
        NSMutableArray *targetPathComps = [[[[(MeshComponent*)[self component] mesh] objectPath] componentsSeparatedByString:@"."] mutableCopy];
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
