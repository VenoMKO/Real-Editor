//
//  TerrainComponent.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 27/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UComponent.h"
#import "FTerrain.h"
#import "FArray.h"

@interface TerrainComponent : PrimitiveComponent

@property (strong) FArray *collisionVertices;
@property (strong) FTerrainBVTree *BVTree;

@end
