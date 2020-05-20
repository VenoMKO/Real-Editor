//
//  LevelStreaming.m
//  Real Editor
//
//  Created by VenoMKO on 11.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "LevelStreaming.h"
#import "UPackage.h"

@implementation LevelStreamingDistance

- (NSString *)packageName
{
  return [self.package nameForIndex:[[self propertyValue:@"PackageName"] intValue]];
}

- (int)zoneX
{
  return [[self propertyValue:@"ZoneNumberX"] intValue];
}

- (int)zoneY
{
  return [[self propertyValue:@"ZoneNumberY"] intValue];
}

- (float)streamingDistance
{
  id v = [self propertyValue:@"MaxDistance"];
  return v ? [v intValue] : 20000.;
}

- (NSString *)streamingPackageName
{
  int x = self.zoneX;
  int y = self.zoneY;
  if (x && y)
  {
    return [self.packageName stringByAppendingFormat:@"_%d%d", x, y];
  }
  return self.packageName;
}

@end

@implementation LevelStreamingKismet

@end


@implementation S1LevelStreamingBaseLevel

- (float)streamingDistance
{
  id v = [self propertyValue:@"DistanceVisible"];
  return v ? [v intValue] : 20000.;
}

@end

@implementation S1LevelStreamingVOID

@end

@implementation S1LevelStreamingSound

- (float)streamingDistance
{
  return -1.;
}

@end
