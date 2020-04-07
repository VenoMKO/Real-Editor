//
//  FTerrain.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 12/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FArray.h"
#import "FString.h"
#import "FColor.h"
#import "FMaterial.h"
#import "FBoxSphereBounds.h"

enum InfoFlags
{
		/**	This flag indicates that the current terrain 'quad' is not visible...		*/
		TID_Visibility_Off		= 0x0001,
		/** This flag indicates that the 'quad' should have it's triangles 'flipped'	*/
		TID_OrientationFlip		= 0x0002,
		/** This flag indicates the patch is unreachable.
     Used to tag areas the player(s) should not be able to reach but are sitll
     visible (tops of mountains, etc.).											*/
		TID_Unreachable			= 0x0004,
		/** This flag indicates the patch is locked.
     *	The vertices can no longer be edited.
     */
		TID_Locked				= 0x0008,
  //		TID_	= 0x0010,
  //		TID_	= 0x0020,
  //		TID_	= 0x0040,
  //		TID_	= 0x0080,
  //		TID_	= 0x0100,
  //		TID_	= 0x0200,
  //		TID_	= 0x0400,
  //		TID_	= 0x0800,
  //		TID_	= 0x1000,
  //		TID_	= 0x2000,
  //		TID_	= 0x4000,
  //		TID_	= 0x8000,
};


@interface FTerrainHeight : FReadable
@property (assign) unsigned short value;
@end

@interface FTerrainInfoData : FReadable
@property (assign) Byte data;
@end

@interface FAlphaMap : FReadable
@property (strong) FByteArray *data;
@end

@interface FTerrainMaterialMask : FReadable
@property (assign) uint64_t bitMask;
@property (assign) int numBits;
@end

@interface FTerrainMaterialResource : FMaterial
@property (weak) UObject *terrain;
@property (strong) FTerrainMaterialMask *materialMask;
@property (strong) FArray *materialIds;
@property (assign) BOOL bEnableSpecular;
@end

@interface FCachedTerrainMaterialArray : FReadable
@property (strong) FArray *cachedMaterials;
@end

@interface FTerrainLayer : FReadable
{
  unsigned int highlighted : 1;
  unsigned int wireframeHighlighted : 1;
  unsigned int hidden : 1;
  unsigned int locked : 1;
}
@property (strong) FString *name;
@property (strong) FColor *highlightColor;
@property (assign) int minX;
@property (assign) int minY;
@property (assign) int maxX;
@property (assign) int maxY;
@end

@interface FTerrainBVNode : FReadable
@property (strong) FTerrainBV *boundingVolume;
@property (assign) BOOL bIsLeaf;
@property (assign) uint8_t nodeIndex1;
@property (assign) uint8_t nodeIndex2;
@property (assign) uint8_t nodeIndex3;
@property (assign) uint8_t nodeIndex4;
@end

@interface FTerrainBVTree : FReadable
@property (strong) FArray *nodes;
@end
