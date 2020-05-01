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

NSString *const kSettingsSaveAsPath = @"com.VenoMKO.Real-Editor.SettingsSaveAsPath";
NSString *const kSettingsLoadTextures = @"com.VenoMKO.Real-Editor.SettingsLoadTextures";
NSString *const kSettingsLoadLights = @"com.VenoMKO.Real-Editor.SettingsLoadLights";
NSString *const kSettingsShowObjectInfo = @"com.VenoMKO.Real-Editor.SettingsShowObjectInfo";
NSString *const kSettingsCacheSize = @"com.VenoMKO.Real-Editor.SettingsCacheSize";
NSString *const kSettingsAAMode = @"com.VenoMKO.Real-Editor.AA-Mode";
NSString *const kSettingsFov = @"com.VenoMKO.Real-Editor.FoV";
NSString *const kSettings3DControls = @"com.VenoMKO.Real-Editor.3DControlsMode";
NSString *const kSettingsExportMode = @"com.VenoMKO.Real-Editor.SettingsExportMode";
NSString *const kSettingsTextureRenderR = @"com.VenoMKO.Real-Editor.SettingsRenderRed";
NSString *const kSettingsTextureRenderG = @"com.VenoMKO.Real-Editor.SettingsRenderGreen";
NSString *const kSettingsTextureRenderB = @"com.VenoMKO.Real-Editor.SettingsRenderBlue";
NSString *const kSettingsTextureRenderA = @"com.VenoMKO.Real-Editor.SettingsRenderAlpha";
NSString *const kSettingsTextureIsNormalMap = @"com.VenoMKO.Real-Editor.SettingsImportIsNormalMap";
NSString *const kSettingsTextureGenMipMap = @"com.VenoMKO.Real-Editor.SettingsImportGenMipMap";
NSString *const kSettingsTextureSaveMode = @"com.VenoMKO.Real-Editor.SettingsSaveMode";
NSString *const kSettingsTextureFormat = @"com.VenoMKO.Real-Editor.SettingsImportTextureFormat";
NSString *const kSettingsLevelExportStaticMeshes = @"com.VenoMKO.Real-Editor.SettingsExportLevelSM";
NSString *const kSettingsLevelExportSkeletalMeshes = @"com.VenoMKO.Real-Editor.SettingsExportLevelSkel";
NSString *const kSettingsLevelExportTerrain = @"com.VenoMKO.Real-Editor.SettingsExportLevelTerrain";
NSString *const kSettingsLevelExportLights = @"com.VenoMKO.Real-Editor.SettingsExportLevelLights";
NSString *const kSettingsLevelExportInterp = @"com.VenoMKO.Real-Editor.SettingsExportLevelInterp";
NSString *const kSettingsLevelExportTrees = @"com.VenoMKO.Real-Editor.SettingsExportLevelTrees";
NSString *const kSettingsLevelExportOther = @"com.VenoMKO.Real-Editor.SettingsExportLevelOther";
NSString *const kSettingsLevelExportAddIndex = @"com.VenoMKO.Real-Editor.SettingsExportLevelAddIndex";

NSString *const kSettingsSkelMeshCalcTangents = @"com.VenoMKO.Real-Editor.SettingsImportSkelMeshCalculateTangents";
NSString *const kSettingsSkelMeshFlipTangents = @"com.VenoMKO.Real-Editor.SettingsImportSkelMeshFlipTangents";
NSString *const kSettingsSkelMeshImportSkeleton = @"com.VenoMKO.Real-Editor.SettingsImportSkelMeshImportSkeleton";
NSString *const kSettingsSkelMeshIgnoreBPrefix = @"com.VenoMKO.Real-Editor.SettingsImportSkelMeshIgonrePrefix";

NSString *const kSettingsExportPath = @"com.VenoMKO.Real-Editor.SettingsExportPath";
NSString *const kSettingsImportPath = @"com.VenoMKO.Real-Editor.SettingsImportPath";
NSString *const kSettingsLookForDepends = @"com.VenoMKO.Real-Editor.LookForDepends";
NSString *const kSettingsProjectDir = @"com.VenoMKO.Real-Editor.ProjectDir";

NSString *const kSettingsCheckForUpdates = @"com.VenoMKO.Real-Editor.CheckForUpdates";

NSString *const kSettingsLogging = @"com.VenoMKO.Real-Editor.Logging";
NSString *const kSettingsRetention = @"com.VenoMKO.Real-Editor.Retention";

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
           kSettingsLevelExportAddIndex : @(YES)
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


