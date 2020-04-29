//
//  prefix-tools.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#ifndef prefix_tools_h
#define prefix_tools_h

#import "Extensions.h"

FOUNDATION_EXPORT NSString *const kErrorUnexpectedEnd;

FOUNDATION_EXPORT NSString *const kSettingsSaveAsPath;
FOUNDATION_EXPORT NSString *const kSettingsLoadTextures;
FOUNDATION_EXPORT NSString *const kSettingsLoadLights;
FOUNDATION_EXPORT NSString *const kSettingsShowObjectInfo;
FOUNDATION_EXPORT NSString *const kSettingsCacheSize;
FOUNDATION_EXPORT NSString *const kSettingsAAMode;
FOUNDATION_EXPORT NSString *const kSettingsFov;
FOUNDATION_EXPORT NSString *const kSettings3DControls;
FOUNDATION_EXPORT NSString *const kSettingsExportMode;
FOUNDATION_EXPORT NSString *const kSettingsTextureRenderR;
FOUNDATION_EXPORT NSString *const kSettingsTextureRenderG;
FOUNDATION_EXPORT NSString *const kSettingsTextureRenderB;
FOUNDATION_EXPORT NSString *const kSettingsTextureRenderA;
FOUNDATION_EXPORT NSString *const kSettingsTextureIsNormalMap;
FOUNDATION_EXPORT NSString *const kSettingsTextureGenMipMap;
FOUNDATION_EXPORT NSString *const kSettingsTextureFormat;
FOUNDATION_EXPORT NSString *const kSettingsTextureSaveMode;
FOUNDATION_EXPORT NSString *const kSettingsExportPath;
FOUNDATION_EXPORT NSString *const kSettingsImportPath;
FOUNDATION_EXPORT NSString *const kSettingsLookForDepends;
FOUNDATION_EXPORT NSString *const kSettingsProjectDir;
FOUNDATION_EXPORT NSString *const kSettingsCheckForUpdates;
FOUNDATION_EXPORT NSString *const kSettingsLogging;
FOUNDATION_EXPORT NSString *const kSettingsRetention;

FOUNDATION_EXPORT NSString *const kSettingsLevelExportStaticMeshes;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportSkeletalMeshes;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportTerrain;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportLights;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportInterp;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportTrees;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportOther;
FOUNDATION_EXPORT NSString *const kSettingsLevelExportAddIndex;

FOUNDATION_EXPORT NSString *const kSettingsSkelMeshCalcTangents;
FOUNDATION_EXPORT NSString *const kSettingsSkelMeshFlipTangents;
FOUNDATION_EXPORT NSString *const kSettingsSkelMeshImportSkeleton;
FOUNDATION_EXPORT NSString *const kSettingsSkelMeshIgnoreBPrefix;

FOUNDATION_EXPORT NSString *const kClass;
FOUNDATION_EXPORT NSString *const kComponent;
FOUNDATION_EXPORT NSString *const kClassPackage;
FOUNDATION_EXPORT NSString *const kClassMaterial;
FOUNDATION_EXPORT NSString *const kClassMaterialInstanceConstant;
FOUNDATION_EXPORT NSString *const kClassTexture2D;
FOUNDATION_EXPORT NSString *const kClassSkeletalMesh;
FOUNDATION_EXPORT NSString *const kClassStaticMesh;

FOUNDATION_EXPORT NSString *const kSiteProtocol;
FOUNDATION_EXPORT NSString *const kSitePrefix;

FOUNDATION_EXPORT NSDictionary *Defaults();

typedef NS_ENUM(unsigned, UGame)
{
  UGameTera, // 610(584)/14(13)
  UGameBless, // 864/9
  UGameBNS, // 
};
@class UPackage;
FOUNDATION_EXPORT void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
FOUNDATION_EXPORT void PublicLog(NSString *format, ...);
FOUNDATION_EXPORT NSError *NSStringToError(NSString *string);
FOUNDATION_EXPORT void NSAppError(UPackage *package, NSString *format, ...);
FOUNDATION_EXPORT void DThrow(NSString *format, ...);

#define CLAMP(x, low, high) ({\
__typeof__(x) __x = (x); \
__typeof__(low) __low = (low);\
__typeof__(high) __high = (high);\
__x > __high ? __high : (__x < __low ? __low : __x);\
})

#define DivideAndRoundUp(Dividend, Divisor) (Dividend + Divisor - 1) / Divisor

#ifdef DEBUG
  #ifndef TOOLS
    #define DLog(args...) ExtendNSLog(__FILE__, __LINE__, __PRETTY_FUNCTION__, args);
  #else
    #define DLog(...) {/*Stub*/}
  #endif
#else
  #define DLog(...) PublicLog(__VA_ARGS__)
#endif

#endif /* prefix_tools_h */
