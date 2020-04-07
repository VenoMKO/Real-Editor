//
//  Level.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FArray.h"
#import "UPackage.h"
#import "FString.h"
#import "FStreamableTextureInstance.h"
#import "FMap.h"
#import "FVector.h"

@interface FKCachedConvexDataElement : FReadable
@property (strong) FByteArray *convexElementData;
@end

@interface FKCachedPerTriData : FReadable
@property (strong) FByteArray *cachedPerTriData;
@end

@interface FKCachedConvexData : FReadable
@property (strong) FArray *cachedConvexElements;
@end

@interface FCachedPhysSMData : FReadable
@property (strong) FVector3 *scale3D;
@property (assign) int cachedDataIndex;
@end

@interface FCachedPerTriPhysSMData : FCachedPhysSMData
@end

@interface Level : UObject
@property (strong) TransFArray *actors;
@property (strong) FURL *url;

@property (weak) UObject *model;
@property (strong) FArray *modelComponents;
@property (strong) FArray *gameSequences;
@property (strong) FMap *textureToInstancesMap;
@property (strong) FByteArray *cachedPhysBSPData;
@property (strong) FMultiMap *cachedPhysSMDataMap;
@property (strong) FArray *cachedPhysSMDataStore;
@property (strong) FMultiMap *cachedPhysPerTriSMDataMap;
@property (strong) FArray *cachedPhysPerTriSMDataStore;
@property (assign) int cachedPhysBSPDataVersion;
@property (assign) int cachedPhysSMDataVersion;
@property (strong) FMap *forceStreamTextures;
@property (weak) UObject *navListStart;
@property (weak) UObject *navListEnd;
@property (weak) UObject *coverListStart;
@property (weak) UObject *coverListEnd;
@property (strong) FArray *crossLevelActors;
@property (assign) int unk;
- (void)exportT3D:(NSString *)path;
@end

@interface World : UObject
@property (weak) Level *persistentLevel;
@property (weak) UObject *gameSummary;
@property (strong) FArray *extraReferencedObjects;
@end
