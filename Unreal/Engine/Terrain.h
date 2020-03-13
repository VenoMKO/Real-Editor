//
//  Terrain.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FArray.h"
#import "FString.h"
#import "FTerrain.h"

@interface Terrain : UObject

@property (strong) FArray *heights;
@property (strong) FArray *infoData;
@property (strong) FArray *weightedTextureMaps;
@property (strong) NSData *alphaMaps;
@property (strong) FArray *cachedTerrainMaterials;
@property (strong) FArray *cachedMaterialsDummy;

@property (assign) int numVerticesX;
@property (assign) int numVerticesY;

- (CGImageRef)heightMap;
- (NSString *)info;

@end
