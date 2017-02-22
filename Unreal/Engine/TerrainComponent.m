//
//  TerrainComponent.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 27/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "TerrainComponent.h"
#import "FVector.h"

@implementation TerrainComponent

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  /*
  self.collisionVertices = [FArray readFrom:s type:[FVector3 class]];
  self.BVTree = [FTerrainBVTree readFrom:s];
   */
  return s;
}

@end
