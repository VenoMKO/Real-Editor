//
//  SpeedTreeComponent.m
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "SpeedTreeComponent.h"
#import "UPackage.h"

@implementation SpeedTreeComponent

- (SpeedTree *)speedTree
{
  [self properties];
  NSNumber *objIndex = [self propertyValue:@"SpeedTree"];
  if (objIndex && [objIndex isKindOfClass:[NSNumber class]])
  {
    return [self.package objectForIndex:objIndex.intValue];
  }
  return (SpeedTree *)objIndex;
}

@end
