//
//  PrefabInstance.m
//  Real Editor
//
//  Created by VenoMKO on 29.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "PrefabInstance.h"
#import "UPackage.h"

@implementation PrefabInstance

- (Prefab *)templatePrefab
{
  NSNumber *idx = [self propertyValue:@"TemplatePrefab"];
  return [self.package objectForIndex:idx.intValue];
}

@end
