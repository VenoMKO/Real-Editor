//
//  Terrain.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "Actor.h"
#import "FArray.h"
#import "FString.h"

@interface Terrain : Actor

@property (strong) FArray *heights;
@property (strong) FArray *infoData;
@property (strong) FArray *weightedTextureMaps;
@property (strong) NSData *alphaMaps;
@property (strong) FArray *cachedTerrainMaterials;
@property (strong) FArray *cachedMaterialsDummy;

- (void)exportToT3D:(NSMutableString*)result padding:(unsigned)padding index:(unsigned)index;
- (void)exportToT3D:(NSMutableString*)result padding:(unsigned)padding index:(unsigned)index resample:(BOOL)resample;
- (CGImageRef)heightMap;
- (CGImageRef)renderResampledHeightMap:(BOOL)resample;
- (CGImageRef)visibilityMap;
- (CGImageRef)renderResampledVisibilityMap:(BOOL)resample;
- (NSArray *)weightMaps;
- (NSArray *)renderResampledWeightMaps:(BOOL)resample;
- (NSString *)info;
- (NSArray *)layers;
- (int)numPatchesX;
- (int)numPatchesY;
- (int)numVerticesX;
- (int)numVerticesY;
- (int)numSectionsX;
- (int)numSectionsY;
- (int)maxTesselationLevel;
- (float)resampleScaleX;
- (float)resampleScaleY;

@end
