//
//  prefix-tools.m
//  Real-Editor
//
//  Created by Vladislav Skachkov on 31/10/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UPackage.h"
#import "PackageController.h"
#import "prefix-tools.h"

NSString *const kErrorUnexpectedEnd = @"Unexpected end of file!";

NSString *const kSettingsSaveAsPath = @"SettingsSaveAsPath";
NSString *const kSettingsLoadTextures = @"SettingsLoadTextures";
NSString *const kSettingsLoadLights = @"SettingsLoadLights";
NSString *const kSettingsShowObjectInfo = @"SettingsShowObjectInfo";
NSString *const kSettingsCacheSize = @"SettingsCacheSize";
NSString *const kSettingsAAMode = @"AA-Mode";
NSString *const kSettingsFov = @"FoV";
NSString *const kSettings3DControls = @"3DControlsMode";
NSString *const kSettingsExportMode = @"SettingsExportMode";
NSString *const kSettingsTextureRenderR = @"SettingsRenderRed";
NSString *const kSettingsTextureRenderG = @"SettingsRenderGreen";
NSString *const kSettingsTextureRenderB = @"SettingsRenderBlue";
NSString *const kSettingsTextureRenderA = @"SettingsRenderAlpha";
NSString *const kSettingsTextureIsNormalMap = @"SettingsImportIsNormalMap";
NSString *const kSettingsTextureGenMipMap = @"SettingsImportGenMipMap";
NSString *const kSettingsTextureSaveMode = @"SettingsSaveMode";
NSString *const kSettingsTextureFormat = @"SettingsImportTextureFormat";
NSString *const kSettingsLevelExportStaticMeshes = @"SettingsExportLevelSM";
NSString *const kSettingsLevelExportSkeletalMeshes = @"SettingsExportLevelSkel";
NSString *const kSettingsLevelExportTerrain = @"SettingsExportLevelTerrain";
NSString *const kSettingsLevelExportLights = @"SettingsExportLevelLights";
NSString *const kSettingsLevelExportInterp = @"SettingsExportLevelInterp";
NSString *const kSettingsLevelExportTrees = @"SettingsExportLevelTrees";
NSString *const kSettingsLevelExportBlockingVolumes = @"SettingsExportLevelBlockingVolumes";
NSString *const kSettingsLevelExportAero = @"SettingsExportLevelAero";
NSString *const kSettingsLevelExportMaterials = @"SettingsExportLevelMaterials";
NSString *const kSettingsLevelExportTextures = @"SettingsExportLevelTextures";
NSString *const kSettingsLevelExportLODs = @"SettingsExportLevelLODs";
NSString *const kSettingsLevelExportAnimations = @"SettingsExportLevelAnimations";
NSString *const kSettingsLevelExportTerrainResample = @"SettingsExportLevelTerrainResample";
NSString *const kSettingsLevelExportWeightMapResample = @"SettingsExportLevelWeightMapResample";
NSString *const kSettingsLevelExportOther = @"SettingsExportLevelOther";
NSString *const kSettingsLevelExportAddIndex = @"SettingsExportLevelAddIndex";
NSString *const kSettingsLevelExportActorsPerFile = @"SettingsExportLevelActorsPerFile";

NSString *const kSettingsSkelMeshCalcTangents = @"SettingsImportSkelMeshCalculateTangents";
NSString *const kSettingsSkelMeshFlipTangents = @"SettingsImportSkelMeshFlipTangents";
NSString *const kSettingsSkelMeshImportSkeleton = @"SettingsImportSkelMeshImportSkeleton";
NSString *const kSettingsSkelMeshIgnoreBPrefix = @"SettingsImportSkelMeshIgonrePrefix";

NSString *const kSettingsExportPath = @"SettingsExportPath";
NSString *const kSettingsImportPath = @"SettingsImportPath";
NSString *const kSettingsLookForDepends = @"LookForDepends";
NSString *const kSettingsProjectDir = @"ProjectDir";

NSString *const kSettingsCheckForUpdates = @"CheckForUpdates";

NSString *const kSettingsLogging = @"Logging";
NSString *const kSettingsRetention = @"Retention";

NSString *const kClass = @"Class";
NSString *const kComponent = @"Component";
NSString *const kClassPackage = @"Package";
NSString *const kClassMaterial = @"Material";
NSString *const kClassMaterialInstanceConstant = @"MaterialInstanceConstant";
NSString *const kClassTexture2D = @"Texture2D";
NSString *const kClassSkeletalMesh = @"SkeletalMesh";
NSString *const kClassStaticMesh = @"StaticMesh";

NSString *const kSiteProtocol = @"https://";
NSString *const kSitePrefix = @"sites.google.com/view/real-editor/";

static NSDateFormatter *dfmt;

NSDictionary *Defaults()
{
  return @{kSettingsLoadTextures : @(YES),
           kSettingsShowObjectInfo : @(NO),
           kSettingsCacheSize : @(30),
           kSettingsAAMode : @(4),
           kSettingsLookForDepends : @(YES),
           kSettingsTextureRenderR : @(YES),
           kSettingsTextureRenderG : @(YES),
           kSettingsTextureRenderB : @(YES),
           kSettingsTextureRenderA : @(NO),
           kSettingsTextureGenMipMap : @(YES),
           kSettings3DControls : @(0),
           kSettingsTextureSaveMode : @(1),
           kSettingsSkelMeshCalcTangents : @(YES),
           kSettingsSkelMeshFlipTangents : @(NO),
           kSettingsSkelMeshImportSkeleton : @(NO),
           kSettingsSkelMeshIgnoreBPrefix : @(NO),
           kSettingsLoadLights : @(YES),
           kSettingsFov : @(72),
           kSettingsExportPath : NSHomeDirectory(),
           kSettingsImportPath : NSHomeDirectory(),
           kSettingsCheckForUpdates : @(YES),
           kSettingsLogging : @(YES),
           kSettingsRetention : @(7),
           kSettingsLevelExportStaticMeshes : @(YES),
           kSettingsLevelExportSkeletalMeshes : @(NO),
           kSettingsLevelExportTerrain : @(YES),
           kSettingsLevelExportLights : @(YES),
           kSettingsLevelExportInterp : @(YES),
           kSettingsLevelExportTrees : @(YES),
           kSettingsLevelExportOther : @(NO),
           kSettingsLevelExportBlockingVolumes : @(NO),
           kSettingsLevelExportAero : @(NO),
           kSettingsLevelExportMaterials : @(NO),
           kSettingsLevelExportTextures : @(NO),
           kSettingsLevelExportLODs : @(NO),
           kSettingsLevelExportAnimations : @(NO),
           kSettingsLevelExportWeightMapResample : @(NO),
           kSettingsLevelExportTerrainResample : @(NO),
           kSettingsLevelExportAddIndex : @(YES),
           kSettingsLevelExportActorsPerFile : @(350)
           };
}

void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...)
{
  va_list ap;
  va_start (ap, format);
  
  if (![format hasSuffix:@"\n"])
    format = [format stringByAppendingString:@"\n"];
  
  NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
  
  va_end (ap);
  
  fprintf(stderr,"\"%s:%d\"  %s", functionName, lineNumber, [body UTF8String]);
}

void PublicLog(NSString *format, ...)
{
  if (!dfmt)
  {
    dfmt = [[NSDateFormatter alloc] init];
    dfmt.dateFormat = @"[HH:mm:ss]";
  }
  va_list ap;
  va_start (ap, format);
  if (![format hasSuffix:@"\n"])
    format = [format stringByAppendingString:@"\n"];
  
  NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
  va_end (ap);
  fprintf(stderr,"%s", [[[dfmt stringFromDate:[NSDate date]] stringByAppendingFormat:@" %@", body] UTF8String]);
}

NSError *NSStringToError(NSString *string, NSString *title)
{
  NSDictionary *err = @{NSLocalizedDescriptionKey : title ? title : @"Error!", NSLocalizedRecoverySuggestionErrorKey : string};
  return [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err];
}

void NSAppError(UPackage *package, NSString *format, ...)
{
  va_list ap;
  va_start (ap, format);
  NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
  va_end (ap);
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSWindow *host = package.controller.window;
    NSBeep();
    if (host)
      [NSApp presentError:NSStringToError(body, nil) modalForWindow:host delegate:nil didPresentSelector:NULL contextInfo:NULL];
    else
    {
      [NSApp presentError:NSStringToError(body, package.stream.url.path)];
    }
  });
  
}

void DThrow(NSString *format, ...)
{
  va_list ap;
  va_start (ap, format);
  NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
  va_end (ap);
#ifdef DEBUG
  @try
  {
    [NSException raise:@"DBGSTP" format:@"%@", body];
  }
  @catch (NSException *e)
  {
    DLog(@"%@", e);
  }
#else
  DLog(@"%@", body);
#endif
}


