//
//  Level.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "Level.h"
#import "Texture2D.h"
#import "Actor.h"
#import "MeshActor.h"
#import "Terrain.h"
#import "MeshComponent.h"
#import "StaticMesh.h"
#import "T3DUtils.h"
#import "FBXUtils.h"

@implementation FKCachedConvexDataElement

+ (instancetype)readFrom:(FIStream *)stream
{
  FKCachedConvexDataElement *d = [super readFrom:stream];
  d.convexElementData = [FByteArray readFrom:stream];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.convexElementData cooked:offset];
}

@end

@implementation FKCachedPerTriData

+ (instancetype)readFrom:(FIStream *)stream
{
  FKCachedPerTriData *d = [super readFrom:stream];
  d.cachedPerTriData = [FByteArray readFrom:stream];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.cachedPerTriData cooked:offset];
}

@end

@implementation FKCachedConvexData

+ (instancetype)readFrom:(FIStream *)stream
{
  FKCachedConvexData *d = [super readFrom:stream];
  d.cachedConvexElements = [FArray readFrom:stream type:[FKCachedConvexDataElement class]];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self.cachedConvexElements cooked:offset];
}

@end

@implementation FCachedPhysSMData

+ (instancetype)readFrom:(FIStream *)stream
{
  FCachedPhysSMData *d = [super readFrom:stream];
  d.scale3D = [FVector3 readFrom:stream];
  d.cachedDataIndex = [stream readInt:NULL];
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.scale3D cooked:offset];
  [d writeInt:self.cachedDataIndex];
  return d;
}

@end

@implementation FCachedPerTriPhysSMData
@end

@implementation Level

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  self.actors = [TransFArray readFrom:s type:[UObject class]];
  self.url = [FURL readFrom:s];
  self.model = [UObject readFrom:s];
  [self.model properties];
  self.modelComponents = [FArray readFrom:s type:[UObject class]];
  self.gameSequences = [FArray readFrom:s type:[UObject class]];
  self.textureToInstancesMap = [FMap readFrom:s keyType:[Texture2D class] arrayType:[FStreamableTextureInstance class]];
  self.cachedPhysBSPData = [FByteArray readFrom:s];
  self.cachedPhysSMDataMap = [FMultiMap readFrom:s keyType:[UObject class] type:[FCachedPhysSMData class]]; // StaticMesh
  self.cachedPhysSMDataStore = [FArray readFrom:s type:[FKCachedConvexData class]];
  self.cachedPhysPerTriSMDataMap = [FMultiMap readFrom:s keyType:[UObject class] type:[FCachedPerTriPhysSMData class]]; // StaticMesh
  self.cachedPhysPerTriSMDataStore = [FArray readFrom:s type:[FKCachedPerTriData class]];
  self.cachedPhysBSPDataVersion = [s readInt:NULL];
  self.cachedPhysSMDataVersion = [s readInt:NULL];
  self.forceStreamTextures = [FMap readFrom:s keyType:[Texture2D class] type:[NSNumber class]];
  self.navListStart = [UObject readFrom:s];
  self.navListEnd = [UObject readFrom:s];
  self.coverListStart = [UObject readFrom:s];
  self.coverListEnd = [UObject readFrom:s];
  self.crossLevelActors = [FArray readFrom:s type:[UObject class]];
  if (self.crossLevelActors.count)
  {
    DThrow(@"Cross level actors found!");
  }
  self.unk = [s readInt:NULL];
  if (self.exportObject.originalOffset + self.exportObject.serialSize != s.position)
    DThrow(@"Found unexpected data!");
  return s;
}

- (WorldInfo *)worldInfo
{
  for (id obj in self.actors)
  {
    if ([obj isKindOfClass:[WorldInfo class]])
    {
      return obj;
    }
  }
  return nil;
}

- (void)exportT3D:(NSString *)path
{
  NSString *dataDirPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"S1Data"];
  [[NSFileManager defaultManager] createDirectoryAtPath:dataDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
  
  NSMutableString *result = [NSMutableString new];
  unsigned padding = 0;
  T3DAddLine(result, padding, T3DBeginObject(@"Map", nil, nil)); padding++;
  T3DAddLine(result, padding, T3DBeginObject(@"Level", nil, nil)); padding++;
  
  NSArray *actors = [[self actors] nsarray];
  NSMutableDictionary *indicies = [NSMutableDictionary new];
  for (Actor *actor in actors)
  {
    if (![actor respondsToSelector:@selector(exportToT3D:padding:index:)])
    {
      continue;
    }
    [actor properties];
    NSString *name = [actor displayName];
    int idx = -1;
    if (!indicies[name])
    {
      indicies[name] = @(1);
      idx = 0;
    }
    else
    {
      idx = [indicies[name] intValue];
      indicies[name] = @(idx+1);
    }
    [actor exportToT3D:result padding:padding index:idx];
    if ([actor isKindOfClass:[StaticMeshActor class]])
    {
      StaticMesh *mesh = (StaticMesh*)[(StaticMeshActor*)actor mesh];
      NSMutableArray *targetPathComps = [[[mesh objectPath] componentsSeparatedByString:@"."] mutableCopy];
      [targetPathComps removeObjectAtIndex:0];
      NSString *targetPath = [dataDirPath stringByAppendingPathComponent:[targetPathComps componentsJoinedByString:@"/"]];
      [[NSFileManager defaultManager] createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
      NSString *fbxPath = [targetPath stringByAppendingPathExtension:@"fbx"];
      if (mesh && ![[NSFileManager defaultManager] fileExistsAtPath:fbxPath])
      {
        [[FBXUtils new] exportStaticMesh:mesh options:@{@"path" : fbxPath, @"lodIdx" : @(0), @"type" : @(0)}];
      }
    }
  }
  
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Level"));
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Map"));
  T3DAddLine(result, padding, T3DBeginObject(@"FolderList", nil, nil));
  padding++;
  T3DAddLine(result, padding, @"Folder=\"%@\"",self.package.name);
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"FolderList"));
  [result deleteCharactersInRange:NSMakeRange(0, 1)];
  [result writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

@end

@implementation World

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  self.persistentLevel = (Level*)[UObject readFrom:s];
  [s setPosition:[s position] + 28 * 4]; // Editor ViewPort Information (FVector3 camPos, FRotator camRot, float ortoZoom) * 4
  self.gameSummary = [UObject readFrom:s]; // Deprecated World Info
  self.extraReferencedObjects = [FArray readFrom:s type:[UObject class]];
  [self.persistentLevel readProperties];
  return s;
}

@end

@implementation WorldInfo

- (NSArray *)streamingLevels
{
  return [self propertyValue:@"StreamingLevels"];
}

@end
