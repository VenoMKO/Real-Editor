//
//  FLightMap.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 26/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FArray.h"
#import "FBulkData.h"
#import "FVector.h"
#import "UObject.h"

enum
{
		LMT_None = 0,
		LMT_1D = 1,
		LMT_2D = 2,
};


@interface FLightMap : FReadable
@property (assign) uint32_t lightMapType;
@property (strong) FArray   *lightGuids;
@property (strong) NSMutableArray *scaleVectors;
@end

@interface FLightMap1D : FLightMap
@property (weak) UObject *owner;
@property (strong) FBulkData   *directionalSamples;
@property (strong) FBulkData   *simpleSamples;
@end

@interface FLightMap2D : FLightMap
@property (strong) NSMutableArray *textures;
@property (strong) FVector2D *coordinateScale;
@property (strong) FVector2D *coordinateBias;
@end

