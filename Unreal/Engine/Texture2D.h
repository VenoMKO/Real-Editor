//
//  Texture2D.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 06/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FBulkData.h"
#import "DDSUtils.h"

typedef NS_ENUM(int, Texture2DExportOptions)
{
  Texture2DExportOptionsDDS = 0,
  Texture2DExportOptionsTGA = 1
};

typedef NS_OPTIONS(int, TextureGroup)
{
  TEXTUREGROUP_World                  =0,
  TEXTUREGROUP_WorldNormalMap         =1,
  TEXTUREGROUP_WorldSpecular          =2,
  TEXTUREGROUP_Character              =3,
  TEXTUREGROUP_CharacterNormalMap     =4,
  TEXTUREGROUP_CharacterSpecular      =5,
  TEXTUREGROUP_Weapon                 =6,
  TEXTUREGROUP_WeaponNormalMap        =7,
  TEXTUREGROUP_WeaponSpecular         =8,
  TEXTUREGROUP_Vehicle                =9,
  TEXTUREGROUP_VehicleNormalMap       =10,
  TEXTUREGROUP_VehicleSpecular        =11,
  TEXTUREGROUP_Cinematic              =12,
  TEXTUREGROUP_Effects                =13,
  TEXTUREGROUP_EffectsNotFiltered     =14,
  TEXTUREGROUP_Skybox                 =15,
  TEXTUREGROUP_UI                     =16,
  TEXTUREGROUP_Lightmap               =17,
  TEXTUREGROUP_RenderTarget           =18,
  TEXTUREGROUP_MobileFlattened        =19,
  TEXTUREGROUP_ProcBuilding_Face      =20,
  TEXTUREGROUP_ProcBuilding_LightMap  =21,
  TEXTUREGROUP_Shadowmap              =22,
  TEXTUREGROUP_ColorLookupTable       =23,
  TEXTUREGROUP_Terrain_Heightmap      =24,
  TEXTUREGROUP_Terrain_Weightmap      =25,
  TEXTUREGROUP_ImageBasedReflection   =26,
  TEXTUREGROUP_Bokeh                  =27,
  TEXTUREGROUP_None                   = INT32_MAX,
};

@class FString, FGUID, FArray, FMipMap;
@interface Texture2D : UObject
@property (strong) FByteBulkData *sourceArt;
@property (strong) FArray   *mips;
// Bless
@property (strong) FArray   *cachedMips;
@property (strong) FArray   *cachedAtiMips;
@property (strong) FArray   *cachedETCMips;
@property (assign) int      maxCachedResolution;
@property (strong) FByteBulkData *cachedFlashMips;
// End Bless
@property (strong) FString  *source;
@property (strong) FGUID    *guid;
- (EPixelFormat)pixelFormat;
- (NSSize)size;

- (FMipMap *)bestMipMap;
- (CGImageRef)renderR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a;
- (NSImage *)renderedImageR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a;
- (NSImage *)forceExportedRenderedImageR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a invert:(BOOL)invert;
- (NSString *)importMipmaps:(NSDictionary *)info;
- (NSImage *)renderMetallnes;
- (NSImage *)renderRoughness;
- (BOOL)isNormalMap;

@end

@interface ShadowMapTexture2D : Texture2D

@end

@interface LightMapTexture2D : Texture2D

@end

@interface TerrainWeightMapTexture : Texture2D
@end
