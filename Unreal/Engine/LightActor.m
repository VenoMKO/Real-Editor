//
//  LightActor.m
//  Real Editor
//
//  Created by VenoMKO on 1.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "LightActor.h"
#import "UPackage.h"
#import "T3DUtils.h"

@implementation LightActor

- (FIStream *)postProperties
{
  [super postProperties];
  self.lightComponent = [self.package objectForIndex:[[self propertyForName:@"LightComponent"].value intValue]];
  self.component = self.lightComponent;
  [self.lightComponent properties];
  return nil;
}

@end

@implementation PointLight

- (void)exportToT3D:(NSMutableString*)result padding:(unsigned)padding index:(int)index
{
  T3DAddLine(result, padding, T3DBeginObject(@"Actor", [NSString stringWithFormat:@"PointLight_%d", index], @"/Script/Engine.PointLight"));
  padding++;
  {
    T3DAddLine(result, padding, T3DBeginObject(@"Object", [NSString stringWithFormat:@"LightComponent%d", index], @"/Script/Engine.PointLightComponent"));
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, T3DBeginObject(@"Object", [NSString stringWithFormat:@"LightComponent%d", index], nil));
    padding++;
    {
      T3DAddLine(result, padding, @"LightFalloffExponent=%.06f",[(PointLightComponent*)self.lightComponent falloffExponent]);
      T3DAddLine(result, padding, @"LightGuid=%@", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]);
      T3DAddLine(result, padding, @"AttenuationRadius=%.06f", [(PointLightComponent*)self.lightComponent radius]);
      T3DAddLine(result, padding, @"SourceRadius=%.06f", [(PointLightComponent*)self.lightComponent radius]);
      T3DAddLine(result, padding, @"Intensity=%.06f", self.lightComponent.brightness);
      FColor *c = [self.lightComponent lightColor];
      T3DAddLine(result, padding, @"LightColor=(B=%d,G=%d,R=%d,A=%d)", c.b, c.g, c.r, 255);
      T3DAddLine(result, padding, @"IndirectLightingIntensity=%.06f", 1.);
      T3DAddLine(result, padding, @"VolumetricScatteringIntensity=%.06f", 1.);
      T3DAddLine(result, padding, @"bUseInverseSquaredFalloff=False");
      GLKVector3 p = [self absolutePostion];
      T3DAddLine(result, padding, @"RelativeLocation=(X=%.06f,Y=%.06f,Z=%.06f)", p.x, p.y, p.z);
    }
    padding--;
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, @"PointLightComponent=\"%@\"", [NSString stringWithFormat:@"LightComponent%d", index]);
    T3DAddLine(result, padding, @"LightComponent=\"%@\"", [NSString stringWithFormat:@"LightComponent%d", index]);
    T3DAddLine(result, padding, @"RootComponent=\"%@\"", [NSString stringWithFormat:@"LightComponent%d", index]);
    T3DAddLine(result, padding, @"ActorLabel=\"PointLight_%d\"", index);
    T3DAddLine(result, padding, @"FolderPath=\"%@\"", self.package.name);
  }
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Actor"));
}

@end

@implementation SpotLight

- (void)exportToT3D:(NSMutableString*)result padding:(unsigned)padding index:(int)index
{
  T3DAddLine(result, padding, T3DBeginObject(@"Actor", [NSString stringWithFormat:@"SpotLight_%d", index], @"/Script/Engine.SpotLight"));
  padding++;
  {
    T3DAddLine(result, padding, T3DBeginObject(@"Object", [NSString stringWithFormat:@"ArrowComponent%d", index], @"/Script/Engine.ArrowComponent"));
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, T3DBeginObject(@"Object", [NSString stringWithFormat:@"LightComponent%d", index], @"/Script/Engine.SpotLightComponent"));
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, T3DBeginObject(@"Object", [NSString stringWithFormat:@"ArrowComponent%d", index], nil));
    {
      padding++;
      T3DAddLine(result, padding, @"AttachParent=\"LightComponent%d\"", index);
      padding--;
    }
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, T3DBeginObject(@"Object", [NSString stringWithFormat:@"LightComponent%d", index], nil));
    {
      padding++;
      if (((SpotLightComponent*)self.lightComponent).innerConeAngle)
      {
        T3DAddLine(result, padding, @"InnerConeAngle=%.06f", ((SpotLightComponent*)self.lightComponent).innerConeAngle);
      }
      if (((SpotLightComponent*)self.lightComponent).renderLightShafts)
      {
        T3DAddLine(result, padding, @"InnerConeAngle=%.06f", ((SpotLightComponent*)self.lightComponent).innerConeAngle);
      }
      T3DAddLine(result, padding, @"OuterConeAngle=%.06f", ((SpotLightComponent*)self.lightComponent).outerConeAngle);
      T3DAddLine(result, padding, @"Intensity=%.06f", self.lightComponent.brightness);
      T3DAddLine(result, padding, @"AttenuationRadius=%.06f", self.lightComponent.radius);
      T3DAddLine(result, padding, @"SourceRadius=%.06f", self.lightComponent.radius);
      T3DAddLine(result, padding, @"bUseInverseSquaredFalloff=False");
      GLKVector3 p = [self absolutePostion];
      T3DAddLine(result, padding, @"RelativeLocation=(X=%.06f,Y=%.06f,Z=%.06f)", p.x, p.y, p.z);
      FRotator *r = [self absoluteRotator];
      GLKVector3 rot = GLKVector3Make(r.roll, r.pitch, r.yaw);
      GLKVector3 scale = [self drawScale3D];
      if (scale.x < 0 || scale.y < 0 || scale.z < 0)
      {
        if (scale.x < 0)
        {
          rot.x += 32768;
          rot.z += 32768;
        }
        
        if (scale.y < 0)
        {
          rot.y += 32768;
          rot.z += 32768;
        }
        
        if (scale.z < 0)
        {
          rot.x += 32768;
          rot.y += 32768;
        }
      }
      T3DAddLine(result, padding, @"RelativeRotation=(Pitch=%.6f,Yaw=%.6f,Roll=%.6f)", rot.y * (180.f / 32768.f), rot.z * (180.f / 32768.f), rot.x * (180.f / 32768.f));
      padding--;
    }
    T3DAddLine(result, padding, T3DEndObject(@"Object"));
    T3DAddLine(result, padding, @"SpotLightComponent=\"LightComponent%d\"", index);
    T3DAddLine(result, padding, @"ArrowComponent=\"ArrowComponent%d\"", index);
    T3DAddLine(result, padding, @"LightComponent=\"LightComponent%d\"", index);
    T3DAddLine(result, padding, @"ActorLabel=\"SpotLight_%d\"", index);
    T3DAddLine(result, padding, @"FolderPath=\"%@\"", self.package.name);
  }
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Actor"));
}

@end
