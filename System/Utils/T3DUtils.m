//
//  T3DUtils.m
//  Real Editor
//
//  Created by VenoMKO on 19.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "T3DUtils.h"

void T3DAddLine(NSMutableString *source, unsigned padding, NSString *line, ...)
{
  if (!line.length) return;
  va_list args;
  va_start(args, line);
  NSString *fullLine = [[NSString alloc] initWithFormat:line arguments:args];
  va_end(args);
  NSMutableString *pad = [NSMutableString new];
  for (unsigned i = 0; i < padding; ++i)
  {
    [pad appendString:@"\t"];
  }
  [source appendFormat:@"\n%@%@", pad, fullLine];
}

NSString *T3DBeginObject(NSString *objectType, NSString *objectName, NSString *objectClass)
{
  NSMutableString *line = [NSMutableString stringWithFormat:@"Begin %@", objectType ? objectType : @"Object"];
  if (objectClass)
  {
    [line appendFormat:@" Class=%@", objectClass];
  }
  if (objectName)
  {
    [line appendFormat:@" Name=\"%@\"", objectName];
  }
  return line;
}

NSString *T3DEndObject(NSString *objectType)
{
  return [@"End " stringByAppendingString:objectType.length ? objectType : @"Object"];
}

@implementation T3DLandscapeComponent

- (void)t3d:(NSMutableString*)result padding:(unsigned)padding
{
  T3DAddLine(result, padding, T3DBeginObject(@"Object", [self objectName], @"/Script/Landscape.LandscapeComponent"));
  padding++;
  {
    T3DAddLine(result, padding, @"SectionBaseX=%d", self.baseX);
    T3DAddLine(result, padding, @"SectionBaseY=%d", self.baseY);
    T3DAddLine(result, padding, @"ComponentSizeQuads=%d", self.componentSizeQuads);
    T3DAddLine(result, padding, @"SubsectionSizeQuads=%d", self.subsectionSizeQuads);
    T3DAddLine(result, padding, @"NumSubsections=%d", self.numSubsections);
    T3DAddLine(result, padding, @"HeightmapScaleBias=(X=%.06f,Y=%.06f,Z=%.06f,W=%.06f)", self.HeightmapScaleBiasX, self.HeightmapScaleBiasY, self.HeightmapScaleBiasZ, self.HeightmapScaleBiasW);
    if (self.collisionComponent.collisionData.length)
    {
      T3DAddLine(result, padding, @"CollisionComponent=LandscapeHeightfieldCollisionComponent'\"%@\"'", [self.collisionComponent objectName]);
    }
    T3DAddLine(result, padding, @"AttachParent=\"RootComponent0\"");
    T3DAddLine(result, padding, @"RelativeLocation=(X=%d.000000,Y=%d.000000,Z=0.000000)", self.baseX, self.baseY);
    
    NSMutableString *landscapeHeightData = [NSMutableString new];
    uint8_t *data = (uint8_t*)[self.heightData bytes];
    for (NSUInteger idx = 0; idx < self.heightData.length; idx+=4)
    {
      [landscapeHeightData appendFormat:@"%x%02x%02x%02x ", data[idx+3], data[idx+2], data[idx+1], data[idx]];
    }
    
    NSMutableString *visiblityLayer = [NSMutableString new];
    [visiblityLayer appendFormat:@"LayerNum=1 LayerInfo=/Engine/EditorLandscapeResources/DataLayer.DataLayer "];
    data = (uint8_t*)[self.visibilityData bytes];
    BOOL hasData = NO;
    for (NSUInteger idx = 0; idx < self.visibilityData.length; ++idx)
    {
      if (data[idx])
      {
        hasData = YES;
      }
      [visiblityLayer appendFormat:@"%x ", (uint8_t)data[idx]];
    }
    
    [landscapeHeightData appendString:hasData ? visiblityLayer : @"LayerNum=0"];
    T3DAddLine(result, padding, @"CustomProperties LandscapeHeightData %@", landscapeHeightData);
  }
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Object"));
}

- (NSString *)objectName
{
  return [NSString stringWithFormat:@"LandscapeComponent_%d", self.index];
}

- (void)t3dForward:(NSMutableString*)result padding:(unsigned)padding
{
  T3DAddLine(result, padding, T3DBeginObject(@"Object", [self objectName], @"/Script/Landscape.LandscapeComponent"));
  T3DAddLine(result, padding, T3DEndObject(@"Object"));
}

@end

@implementation T3DLandscapeCollisionComponent

- (NSString *)objectName
{
  return [NSString stringWithFormat:@"LandscapeHeightfieldCollisionComponent_%d", self.index];
}

- (void)t3d:(NSMutableString*)result padding:(unsigned)padding
{
  if (!self.collisionData.length) return;
  T3DAddLine(result, padding, T3DBeginObject(@"Object", [self objectName], nil));
  padding++;
  {
    T3DAddLine(result, padding, @"ComponentLayerInfos(0)=LandscapeLayerInfoObject'\"/Engine/EditorLandscapeResources/DataLayer.DataLayer\"'");
    T3DAddLine(result, padding, @"SectionBaseX=%d", self.renderComponent.baseX);
    T3DAddLine(result, padding, @"SectionBaseY=%d", self.renderComponent.baseY);
    T3DAddLine(result, padding, @"CollisionSizeQuads=%d", self.renderComponent.componentSizeQuads);
    T3DAddLine(result, padding, @"CollisionScale=1.000000");
    T3DAddLine(result, padding, @"HeightfieldGuid=%@",[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]);
    T3DAddLine(result, padding, @"RenderComponent=LandscapeComponent'\"%@\"'", [self.renderComponent objectName]);
    T3DAddLine(result, padding, @"CookedPhysicalMaterials(0)=PhysicalMaterial'\"/Engine/EngineMaterials/DefaultPhysicalMaterial.DefaultPhysicalMaterial\"'");
    T3DAddLine(result, padding, @"AttachParent=\"RootComponent0\"");
    T3DAddLine(result, padding, @"RelativeLocation=(X=%d.000000,Y=%d.000000,Z=0.000000)", self.renderComponent.baseX, self.renderComponent.baseY);
    
    
    NSMutableString *collisionHeightData = [NSMutableString new];
    uint16_t *cdata = (uint16_t*)[self.collisionData bytes];
    for (NSUInteger idx = 0; idx < self.collisionData.length / sizeof(uint16_t); idx++)
    {
      uint16_t v = cdata[idx];
      [collisionHeightData appendFormat:@"%u ", v];
    }
    
    T3DAddLine(result, padding, @"CustomProperties CollisionHeightData %@", collisionHeightData);
    
    uint8_t *vdata = (uint8_t*)[self.visibilityData bytes];
    NSMutableString *visibilityData = [NSMutableString new];
    bool hasData = NO;
    for (NSUInteger idx = 0; idx < self.visibilityData.length; idx++)
    {
      if (vdata[idx])
      {
        hasData = YES;
      }
      [visibilityData appendString:vdata[idx] ? @"00" : @"ff"];
    }
    if (hasData)
    {
      T3DAddLine(result, padding, @"CustomProperties DominantLayerData %@", visibilityData);
    }
  }
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Object"));
}

- (void)t3dForward:(NSMutableString*)result padding:(unsigned)padding
{
  if (!self.collisionData.length) return;
  T3DAddLine(result, padding, T3DBeginObject(@"Object", [self objectName], @"/Script/Landscape.LandscapeHeightfieldCollisionComponent"));
  T3DAddLine(result, padding, T3DEndObject(@"Object"));
}

@end
