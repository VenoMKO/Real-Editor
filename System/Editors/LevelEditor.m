//
//  LevelEditor.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "LevelEditor.h"
#import "FPropertyTag.h"
#import "SceneView.h"
#import "StaticMesh.h"
#import "SkeletalMesh.h"
#import "MeshComponent.h"
#import "Material.h"
#import "Texture2D.h"
#import "Actor.h"
#import "MeshActor.h"
#import "LightActor.h"
#import "FBXUtils.h"
#import "T3DUtils.h"
#import "Terrain.h"
#import "SpeedTreeActor.h"
#import "PrefabInstance.h"
#import "LevelStreaming.h"
#import "TextureUtils.h"

#define DEBUG_EXPORT_BOUNDS 0
#define DEBUG_EXPORT_CLASS 0

BOOL CheckBounds(Actor *a)
{
  GLKVector3 pos = [a absolutePostion];
  GLKVector3 min = GLKVector3Make(0, 0, 0);
  GLKVector3 max = GLKVector3Make(-1, -1, -1);
  return pos.x >= min.x && pos.y >= min.y && pos.x <= max.x && pos.y <= max.y;
}

BOOL CheckClass(Actor *a)
{
  NSArray *allowedClasses = @[@"SpotLight"];
  return [allowedClasses indexOfObject:[a objectClass]] != NSNotFound;
}

NSString *MeshComponentExportPath(MeshActor *actor)
{
  UObject *mesh = [actor mesh];
  NSMutableArray *targetPathComps = [[[mesh objectPath] componentsSeparatedByString:@"."] mutableCopy];
  [targetPathComps removeObjectAtIndex:0];
  return [targetPathComps componentsJoinedByString:@"/"];
}

const double ScaleFactor = 1.0;

@interface LevelEditor () <NSTableViewDataSource>
{
  SCNMaterial *defMat;
  NSMutableArray *meshes;
  BOOL cancelExport;
}

@property BOOL loading;
@property (strong) NSMutableArray         *terrains;
@property (weak) IBOutlet ModelView       *sceneView;
@property (weak) IBOutlet NSTableView     *actorsTable;
@property (strong) NSMutableArray         *nodes;
@property (strong) NSMutableArray         *meshNodes;
@property (strong) NSMutableArray         *actors;
@property (strong) NSOperationQueue       *materialQueue;
@property (weak) IBOutlet NSWindow        *exportProgressPanel;
@property double                          exportProgressValue;
@property NSString                        *exportProgressDescription;
@property NSString                        *exportProgressCancelTitle;

@property BOOL                            exportStaticMeshes;
@property BOOL                            exportSkeletalMeshes;
@property BOOL                            exportTerrain;
@property BOOL                            exportLights;
@property BOOL                            exportInterpActors;
@property BOOL                            exportOtherActors;
@property BOOL                            exportAddObjectIndex;
@property BOOL                            exportSpeedTrees;
@property BOOL                            exportMaterials;
@property BOOL                            exportTextures;
@property BOOL                            exportBlockingVolumes;
@property BOOL                            exportAeroSets;
@property BOOL                            exportAnimations;
@property BOOL                            exportLODs;
@property BOOL                            exportResampleTerrain;
@property BOOL                            exportResampleWeightMaps;
@property int                             exportActorsPerFile;

@property (strong) IBOutlet NSWindow      *exportPanel;

@end

@implementation LevelEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.actors = [NSMutableArray new];
  self.terrains = [NSMutableArray new];
  [self.sceneView setup];
  self.nodes = [NSMutableArray new];
  self.meshNodes = [NSMutableArray new];
  self.materialQueue = [NSOperationQueue new];
  self.materialQueue.maxConcurrentOperationCount = 3;
  self.loading = YES;
  [self performSelectorInBackground:@selector(setupLevel) withObject:nil];
}

- (void)setupLevel
{
  for (FObjectExport *child in self.object.children)
  {
    if ([[child objectClass] isEqualToString:@"Terrain"] && child.object)
    {
      [self.terrains addObject:child.object];
    }
  }
  
  BOOL loadLights = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadLights];
  meshes = [NSMutableArray new];
  SCNVector3 max = SCNVector3Make(CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN);
  SCNVector3 min = SCNVector3Make(CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX);
  BOOL loadedAero = NO;
  NSMutableArray *actors = [NSMutableArray new];
  for (Actor *actor in self.object.actors)
  {
    [actors addObject:actor];
  }
  for (Actor *actor in self.object.crossLevelActors)
  {
    [actors addObject:actor];
  }
  for (Actor *actor in actors)
  {
    if (![actor isKindOfClass:[Actor class]])
    {
      DLog(@"Skipping: %@[%d]", actor.objectName, [self.object.package indexForObject:actor]);
      continue;
    }
    
    [actor properties];
    SCNNode *n = nil;
    UObject *object = nil;
    GLKVector3 postRotation = GLKVector3Make(0, 0, 0);
    
    if ((object = [self meshForActor:actor]))
    {
      n = [(StaticMesh *)object renderNode:0];
      if (n)
        [meshes addObject:object];
      else
        continue;
      
      [self.meshNodes addObject:n];
    }
    else if ([actor isKindOfClass:[PrefabInstance class]])
    {
      Prefab *prefab = [(PrefabInstance*)actor templatePrefab];
      n = [prefab renderNode:0];
    }
    else if ([actor isKindOfClass:[SpotLight class]] && loadLights)
    {
      n = [SCNNode new];
      SCNLight *l = [SCNLight new];
      l.type = SCNLightTypeSpot;
      l.color = [[(PointLight *)actor lightComponent] lightColor].NSColor;
      l.intensity = [[(PointLight *)actor lightComponent] brightness] * 200.0;
      l.spotInnerAngle = [(SpotLightComponent *)[(SpotLight *)actor lightComponent] innerConeAngle];
      l.spotOuterAngle = [(SpotLightComponent *)[(SpotLight *)actor lightComponent] outerConeAngle];
      l.attenuationEndDistance = [(SpotLightComponent *)[(PointLight *)actor lightComponent] radius] * ScaleFactor * [[(PointLight *)actor lightComponent] scale];
      l.attenuationFalloffExponent = [(SpotLightComponent *)[(SpotLight *)actor lightComponent] falloffExponent];
      n.light = l;
      postRotation.y = -90;
    }
    else if ([actor isKindOfClass:[PointLight class]] && loadLights)
    {
      n = [SCNNode new];
      SCNLight *l = [SCNLight new];
      l.type = SCNLightTypeOmni;
      l.color = [[(PointLight *)actor lightComponent] lightColor].NSColor;
      l.castsShadow = YES;
      l.intensity = [[(PointLight *)actor lightComponent] brightness] * 200.0;
      GLKVector3 vscale3D = [actor drawScale3D];
      CGFloat scale3D = (vscale3D.x + vscale3D.y + vscale3D.z) / 3.0;
      l.attenuationEndDistance = [(PointLightComponent *)[(PointLight *)actor lightComponent] radius] * ScaleFactor * [actor absoluteDrawScale] * scale3D;
      l.attenuationFalloffExponent = [(PointLightComponent *)[(PointLight *)actor lightComponent] falloffExponent];
      n.light = l;
    }
    
    if (!n)
      continue;
    
    [self.nodes addObject:n];
    [self.actors addObject:actor];
    n.name = [NSString stringWithFormat:@"%d",[actor.package indexForObject:actor]];
    
    n.scale = SCNVector3Make(ScaleFactor, ScaleFactor, ScaleFactor);
    
    {
      GLKVector3 pos = [actor absolutePostion];
      n.position = SCNVector3Make(pos.x * ScaleFactor, pos.y * ScaleFactor, pos.z * ScaleFactor);
      
      if (pos.x > max.x)
        max.x = pos.x;
      else if (pos.x < min.x)
        min.x = pos.x;
      
      if (pos.y > max.y)
        max.y = pos.y;
      else if (pos.y < min.y)
        min.y = pos.y;
      
      if (pos.z > max.z)
        max.z = pos.z;
      else if (pos.z < min.z)
        min.z = pos.z;
    }
    {
      GLKVector3 scaleVec = [actor absoluteDrawScale3D];
      scaleVec = GLKVector3MultiplyScalar(scaleVec, [actor absoluteDrawScale]);
      SCNVector3 s = n.scale;
      s.x *= scaleVec.x;
      s.y *= scaleVec.y;
      s.z *= scaleVec.z;
      n.scale = s;
    }
    {
      GLKVector3 p = [[[actor absoluteRotator] euler] glkVector3];
      p = GLKVector3Add(p, postRotation);
      n.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-p.x), GLKMathDegreesToRadians(-p.y), GLKMathDegreesToRadians(p.z));
    }
  }
  
  GLKVector3 center = GLKVector3Make((min.x + max.x) * .5, (min.y + max.y) * .5, (min.z + max.z) * .5);
  
  for (SCNNode *n in self.nodes)
  {
    @autoreleasepool
    {
      GLKVector3 t = SCNVector3ToGLKVector3(n.position);
      t = GLKVector3Subtract(t, center);
      n.position = SCNVector3FromGLKVector3(t);
      n.geometry.materials = @[self.defaultMaterial];
      [self.sceneView.objectNode performSelectorOnMainThread:@selector(addChildNode:) withObject:n waitUntilDone:NO];
    }
  }
  
  if (!loadedAero)
  {
    SCNLight *aeroLight = [SCNLight new];
    aeroLight.type = SCNLightTypeDirectional;
    aeroLight.intensity = 1000;
    SCNNode *n = [SCNNode new];
    n.light = aeroLight;
    [self.sceneView.objectNode performSelectorOnMainThread:@selector(addChildNode:) withObject:n waitUntilDone:NO];
  }
  
  self.sceneView.objectNode.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(0), GLKMathDegreesToRadians(-90), GLKMathDegreesToRadians(-90));
  self.sceneView.objectNode.scale = SCNVector3Make(1, -1, 1);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.actorsTable reloadData];
    [self.sceneView reset];
    self.loading = NO;
  });
}

- (StaticMesh *)meshForActor:(Actor *)actor
{
  if (!actor.component)
    return nil;
  UObject *comp = [actor component];
  if (!comp || [comp isZero] || ![comp respondsToSelector:@selector(mesh)])
    return nil;
  StaticMesh *obj = (StaticMesh *)[(StaticMeshComponent *)comp mesh];
  if (!obj || ![obj respondsToSelector:@selector(renderNode:)])
    return nil;
  return obj;
}

- (IBAction)loadMaterials:(id)sender
{
  [self.materialQueue addOperationWithBlock:^{
    for (SCNNode *n in self.meshNodes)
    {
      @autoreleasepool
      {
        NSInteger idx = [self.meshNodes indexOfObject:n];
        [self.materialQueue addOperationWithBlock:^{
          @try
          {
            [self setupMaterialsForNode:n object:meshes[idx] lod:0];
          }
          @catch(NSException *e)
          {
            DLog(@"%@",e.description);
          }
        }];
      }
    }
  }];
}

- (void)exportT3D:(NSString *)path level:(Level *)level
{
  NSString *dataDirPath = [path stringByDeletingLastPathComponent];
  [[NSFileManager defaultManager] createDirectoryAtPath:dataDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
  
  NSMutableString *result = [NSMutableString new];
  unsigned padding = 0;
  T3DAddLine(result, padding, T3DBeginObject(@"Map", nil, nil)); padding++;
  T3DAddLine(result, padding, T3DBeginObject(@"Level", nil, nil)); padding++;
  
  NSArray *actors = [[[level actors] nsarray] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Actor *actor, NSDictionary<NSString *,id> *bindings) {
    if ([actor isKindOfClass:[StaticMeshActor class]])
    {
      if (!self.exportStaticMeshes)
      {
        return NO;
      }
    }
    else if ([actor isKindOfClass:[SkeletalMeshActor class]])
    {
      if (!self.exportSkeletalMeshes)
      {
        return NO;
      }
    }
    else if ([actor isKindOfClass:[InterpActor class]])
    {
      if (!self.exportInterpActors)
      {
        return NO;
      }
    }
    else if ([actor isKindOfClass:[LightActor class]])
    {
      if (!self.exportLights)
      {
        return NO;
      }
    }
    else if ([actor isKindOfClass:[Terrain class]])
    {
      if (!self.exportTerrain)
      {
        return NO;
      }
    }
    else if ([actor isKindOfClass:[SpeedTreeActor class]])
    {
      if (!self.exportSpeedTrees)
      {
        return NO;
      }
    }
    else if (!self.exportOtherActors)
    {
      return NO;
    }
    return [actor respondsToSelector:@selector(exportToT3D:padding:index:)];
  }]];
  NSMutableDictionary *indicies = [NSMutableDictionary new];
  double step = 100. / (float)actors.count;
  double progress = 0;
  NSMutableString *actorsList = [@"Actors:\n" mutableCopy];
  int fileIdx = 0;
  int actorCount = 0;
  int totalActorCount = 0;
  for (Actor *actor in actors)
  {
    @autoreleasepool
    {
      [actor properties];
      if (self.exportActorsPerFile > 0 && actorCount >= self.exportActorsPerFile)
      {
        padding--;
        T3DAddLine(result, padding, T3DEndObject(@"Level"));
        padding--;
        T3DAddLine(result, padding, T3DEndObject(@"Map"));
        T3DAddLine(result, padding, T3DBeginObject(@"FolderList", nil, nil));
        padding++;
        T3DAddLine(result, padding, @"Folder=\"%@\"",level.package.name);
        padding--;
        T3DAddLine(result, padding, T3DEndObject(@"FolderList"));
        NSString *t3dpath = [path.stringByDeletingPathExtension stringByAppendingFormat:@"_%d.t3d", ++fileIdx];
        DLog(@"Saving %@", t3dpath);
        [result writeToFile:t3dpath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        result = [NSMutableString new];
        padding = 0;
        actorCount = 0;
        T3DAddLine(result, padding, T3DBeginObject(@"Map", nil, nil)); padding++;
        T3DAddLine(result, padding, T3DBeginObject(@"Level", nil, nil)); padding++;
      }
      progress += step;
      if (cancelExport)
      {
        return;
      }
      NSString *name = [actor displayName];
      int idx = -1;
      if (!self.exportAddObjectIndex)
      {
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
      }
      else
      {
        idx = [actor.package indexForObject:actor];
      }
  #if DEBUG_EXPORT_BOUNDS
      if (!CheckBounds(actor))
      {
        continue;
      }
  #endif
  #if DEBUG_EXPORT_CLASS
      if (!CheckClass(actor))
      {
        continue;
      }
  #endif
      dispatch_async(dispatch_get_main_queue(), ^{
        self.exportProgressValue = progress;
        self.exportProgressDescription = [NSString stringWithFormat:@"Exporting: %@/%@", [actor.objectPath stringByReplacingOccurrencesOfString:@"." withString:@"/"].stringByDeletingLastPathComponent, name];
      });
      if ([actor isKindOfClass:[StaticMeshActor class]] ||
          [actor isKindOfClass:[InterpActor class]] ||
          [actor isKindOfClass:[SkeletalMeshActor class]])
      {
        StaticMesh *mesh = (StaticMesh*)[(StaticMeshActor*)actor mesh];
        NSString *contentPath = nil;
        
        [mesh properties];
        
        NSString *materials = @"";
        if (self.exportMaterials)
        {
          for (MaterialInstance *m in mesh.materials)
          {
            NSString *mPath = [self exportMaterial:m includeingTextures:self.exportTextures to:dataDirPath];
            materials = [materials stringByAppendingFormat:@"%@\n", mPath];
          }
        }
        
        if (![self resolveObject:&mesh path:&contentPath])
        {
          continue;
        }
        
        NSString *t3DContentPath = [@"/Game/S1Data/" stringByAppendingString:contentPath];
        
        if (![(MeshActor *)actor exportToT3D:result padding:padding index:idx contentPath:t3DContentPath])
        {
          continue;
        }
        
        NSString *meshTypeDir = [mesh isKindOfClass:[StaticMesh class]] ? @"StaticMeshes/S1Data" : @"SkeletalMeshes/S1Data";
        NSString *fbxPath = [[[dataDirPath stringByAppendingPathComponent:meshTypeDir] stringByAppendingPathComponent:contentPath] stringByAppendingPathExtension:@"fbx"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:fbxPath])
        {
          NSDictionary *fbxOptions = @{@"path" : fbxPath, @"lodIdx" : @(0), @"type" : @(0)};
          [[NSFileManager defaultManager] createDirectoryAtPath:[fbxPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
          if ([mesh isKindOfClass:[StaticMesh class]])
          {
            [[FBXUtils new] exportStaticMesh:mesh options:fbxOptions];
          }
          else
          {
            [[FBXUtils new] exportSkeletalMesh:(SkeletalMesh*)mesh options:fbxOptions];
          }
        }
        NSString *actorOutput = [NSString stringWithFormat:@"[%d]%@(%@)\n\tMesh: %@", [actor.package indexForObject:actor], [mesh objectName], [actor objectClass], contentPath];
        if (materials.length)
        {
          actorOutput = [actorOutput stringByAppendingFormat:@"\n\tMaterials:\n\t\t%@",[materials stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t\t"]];
        }
        [actorsList appendFormat:@"%@\n", actorOutput];
      }
      else if ([actor isKindOfClass:[SpeedTreeActor class]])
      {
        SpeedTree *tree = [[(SpeedTreeActor *)actor component] speedTree];
        NSString *materials = @"";
        if (self.exportMaterials)
        {
          for (MaterialInstance *m in tree.materials)
          {
            NSString *mPath = [self exportMaterial:m includeingTextures:self.exportTextures to:dataDirPath];
            materials = [materials stringByAppendingFormat:@"%@\n", mPath];
          }
        }
        NSString *contentPath = nil;
        
        if (![self resolveObject:&tree path:&contentPath])
        {
          continue;
        }
        
        NSString *actorOutput = [NSString stringWithFormat:@"[%d]%@(%@)\n\tTree: %@", [actor.package indexForObject:actor], [tree objectName], [actor objectClass], contentPath];
        NSString *t3DContentPath = [@"/Game/S1Data/" stringByAppendingString:contentPath];
        if (![(SpeedTreeActor*)actor exportToT3D:result padding:padding index:idx contentPath:t3DContentPath])
        {
          continue;
        }
        [actorsList appendFormat:@"[%d]%@(%@)\n", [actor.package indexForObject:actor], [actor displayName], [actor objectClass]];
        
        NSString *sptPath = [[[dataDirPath stringByAppendingPathComponent:@"SpeedTree/S1Data"] stringByAppendingPathComponent:contentPath] stringByAppendingPathExtension:@"spt"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:sptPath])
        {
          [[NSFileManager defaultManager] createDirectoryAtPath:[sptPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
          NSData *data = [tree exportWithOptions:@{@"expMaterials" : @(self.exportMaterials)}];
          if (data.length)
          {
            [data writeToFile:sptPath atomically:YES];
          }
        }
        if (materials.length)
        {
          actorOutput = [actorOutput stringByAppendingFormat:@"\n\tMaterials:\n\t\t%@",[materials stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t\t"]];
        }
        [actorsList appendFormat:@"%@\n", actorOutput];
      }
      else if ([actor isKindOfClass:[Terrain class]])
      {
        NSString *terrainPath = [dataDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_Terrain", actor.package.name]];
        [[NSFileManager defaultManager] createDirectoryAtPath:terrainPath withIntermediateDirectories:YES attributes:nil error:NULL];
        CGImageRef img = [(Terrain *)actor renderResampledHeightMap:self.exportResampleTerrain];
        WriteImageRef(img, [terrainPath stringByAppendingPathComponent:@"HeightMap"]);
        CGImageRelease(img);
        img = [(Terrain *)actor renderResampledVisibilityMap:self.exportResampleTerrain];
        WriteImageRef(img, [terrainPath stringByAppendingPathComponent:@"VisibilityMap"]);
        CGImageRelease(img);
        {
          GLKVector3 v = actor.absolutePostion;
          NSString *info = [NSString stringWithFormat:@"Position: %f %f %f\n", v.x, v.y, v.z];
          v = actor.absoluteDrawScale3D;
          v = GLKVector3MultiplyScalar(v, actor.absoluteDrawScale);
          if (self.exportResampleTerrain)
          {
            v.x /= [(Terrain*)actor resampleScaleX];
            v.y /= [(Terrain*)actor resampleScaleY];
          }
          info = [info stringByAppendingFormat:@"Scale %f %f %f\n", v.x, v.y, v.z];
          if (self.exportResampleTerrain)
          {
            info = [info stringByAppendingFormat:@"Resample Scale %f %f\n", [(Terrain*)actor resampleScaleX], [(Terrain*)actor resampleScaleY]];
          }
          [info writeToFile:[terrainPath stringByAppendingPathComponent:@"Info.txt"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        }
        NSArray *weightMaps = [(Terrain*)actor renderResampledWeightMaps:self.exportResampleWeightMaps && !self.exportResampleTerrain];
        NSString *terrainLayersPath = [terrainPath stringByAppendingPathComponent:@"Layers"];
        [[NSFileManager defaultManager] createDirectoryAtPath:terrainLayersPath withIntermediateDirectories:YES attributes:nil error:NULL];
        NSArray *layers = [(Terrain *)actor layers];
        weightMaps = [weightMaps subarrayWithRange:NSMakeRange(0, layers.count)];
        NSMutableString *layerInfo = [NSMutableString new];
        int layersCount = (int)layers.count;
        for (NSDictionary *layer in layers)
        {
          int layerIdx = [layer[@"index"] intValue];
          NSImage *map = nil;
          if (layerIdx < 0)
          {
            map = weightMaps[layersCount + layerIdx];
            layersCount--;
          }
          else
          {
            map = weightMaps[(layersCount - 1) - layerIdx];
          }
          NSData *pngData = [[map unscaledBitmapImageRep] representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
          [pngData writeToFile:[terrainLayersPath stringByAppendingFormat:@"/[%@]%@.png", layer[@"index"], layer[@"name"]] atomically:YES];
          [layerInfo appendFormat:@"%d %@\n", layerIdx, layer[@"name"]];
          [layerInfo appendFormat:@"\tMapping Scale: %@\n", layer[@"scale"]];
          [layerInfo appendFormat:@"\tMaterial: %@\n", layer[@"material"]];
          
          if (self.exportMaterials && layer[@"material"])
          {
            [self exportMaterial:layer[@"material"] includeingTextures:self.exportTextures to:dataDirPath];
          }
          
        }
        [layerInfo writeToFile:[terrainLayersPath stringByAppendingPathComponent:@"Setup.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [actorsList appendFormat:@"[%d]%@(%@)\n", [actor.package indexForObject:actor], [actor objectName], [actor objectClass]];
      }
      else
      {
        if (![actor exportToT3D:result padding:padding index:idx])
        {
          continue;
        }
        [actorsList appendFormat:@"[%d]%@(%@)\n", [actor.package indexForObject:actor], [actor objectName], [actor objectClass]];
      }
      actorCount++;
      totalActorCount++;
    }
  }
  
  if (totalActorCount)
  {
    [actorsList writeToFile:[[path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@_Actors.txt", level.package.name] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  }
  
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Level"));
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Map"));
  T3DAddLine(result, padding, T3DBeginObject(@"FolderList", nil, nil));
  padding++;
  T3DAddLine(result, padding, @"Folder=\"%@\"",level.package.name);
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"FolderList"));
  [result deleteCharactersInRange:NSMakeRange(0, 1)];
  if (cancelExport) return;
  if (fileIdx)
  {
    path = [path.stringByDeletingPathExtension stringByAppendingFormat:@"_%d.t3d", fileIdx];
  }
  DLog(@"Saving %@", path);
  if (actorCount)
  {
    [result writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
  }
}

// FIXME: Already resolved objects may produce incorrect contentPath with the first path component dropped
- (BOOL)resolveObject:(UObject **)object path:(NSString **)path
{
  UObject *obj = *object;
  if (!obj)
  {
    return NO;
  }
  
  if (obj.exportObject.exportFlags | EF_ForcedExport)
  {
    UObject *resolved = [obj.package resolveForcedExport:obj.exportObject];
    if (resolved)
    {
      obj = resolved;
    }
    else
    {
      DThrow(@"Failed to resolve %@", *object);
    }
  }
  
  [obj properties];
  
  NSString *contentPath = [obj objectNetPath];
  if (!contentPath)
  {
    NSArray *pathComponents = [[*object objectPath] componentsSeparatedByString:@"."];
    contentPath = [[pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count-1)] componentsJoinedByString:@"/"];
  }
  else
  {
    NSArray *pathComponents = [contentPath componentsSeparatedByString:@"."];
    NSString *objectPath = [[pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count - 1)] componentsJoinedByString:@"/"];
    pathComponents = [[*object objectPath] componentsSeparatedByString:@"."];
    NSString *packageName = pathComponents[1];
    contentPath = [packageName stringByAppendingPathComponent:objectPath];
  }
  
  *object = obj;
  *path = contentPath;
  
  return YES;
}

- (NSString *)exportMaterial:(UObject *)material includeingTextures:(BOOL)textures to:(NSString *)dataDir
{
  if ([material isKindOfClass:[MaterialInstance class]] || [material isKindOfClass:[MaterialInstanceConstant class]])
  {
    MaterialInstance *mat = (MaterialInstance *)material;
    NSString *contentPath = nil;
    if (![self resolveObject:&mat path:&contentPath])
    {
      return nil;
    }
    
    NSString *result = [(MaterialInstance *)material exportIncluding:textures to:dataDir];
    NSString *expPath = [[dataDir stringByAppendingPathComponent:@"Materials/S1Data"] stringByAppendingFormat:@"/%@.txt", contentPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:expPath])
    {
      [[NSFileManager defaultManager] createDirectoryAtPath:expPath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];
      [result writeToFile:[[dataDir stringByAppendingPathComponent:@"Materials/S1Data"] stringByAppendingFormat:@"/%@.txt", contentPath] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    return contentPath;
  }
  return nil;
}

- (NSArray *)exportMaterialTextures:(UObject *)material path:(NSString *)path
{
  NSMutableArray *textures = [NSMutableArray new];
  NSArray *textureIds = [(UObject*)material propertyValue:@"ReferencedTextures"];
  for (NSNumber *texId in textureIds)
  {
    Texture2D *texture = [material.package objectForIndex:[texId intValue]];
    NSString *contentPath = nil;
    if (![self resolveObject:&texture path:&contentPath])
    {
      continue;
    }
    
    NSString *texturePath = [[[path stringByAppendingPathComponent:@"Textures/S1Data"] stringByAppendingPathComponent:contentPath] stringByAppendingPathExtension:@"tga"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:texturePath])
    {
      [[NSFileManager defaultManager] createDirectoryAtPath:[texturePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
      [texture exportWithOptions:@{@"path" : texturePath, @"mode" : @(Texture2DExportOptionsTGA)}];
      [textures addObject:[contentPath stringByAppendingPathExtension:@"tga"]];
    }
    
  }
  return textures;
}

- (IBAction)endExportPanel:(id)sender
{
  cancelExport = YES;
  [self.view.window endSheet:self.exportProgressPanel];
}

- (SCNMaterial *)defaultMaterial
{
  if (!defMat)
  {
    SCNMaterial *defaultMaterial = [SCNMaterial new];
    defaultMaterial.doubleSided = YES;
    defaultMaterial.locksAmbientWithDiffuse = YES;
    NSImage *img = [NSImage imageNamed:@"tex0"];
    if (img && !NSEqualSizes(img.size, NSZeroSize))
    {
      defaultMaterial.diffuse.contents = img;
      defaultMaterial.diffuse.wrapS = SCNWrapModeRepeat;
      defaultMaterial.diffuse.wrapT = SCNWrapModeRepeat;
      defaultMaterial.shininess = .2f;
    }
    defMat = defaultMaterial;
  }
  return defMat;
}

- (void)setupMaterialsForNode:(SCNNode *)node object:(StaticMesh *)object lod:(NSUInteger)lod
{
  NSArray *matSource = object.materials;
  NSMutableArray *tempMat = [NSMutableArray new];
  
  for (__unused MaterialInstanceConstant *mat in matSource)
  {
    [tempMat addObject:self.defaultMaterial];
  }
  
  [node.geometry performSelectorOnMainThread:@selector(setMaterials:) withObject:tempMat waitUntilDone:YES];
  
  for (NSUInteger idx = 0; idx < matSource.count; idx++)
  {
    MaterialInstanceConstant *mat = matSource[idx];
    
    if ([mat isZero]) // Mesh may have no valid materials (eg bone_skel)
      continue;
    
    if ([mat.fObject isKindOfClass:[FObjectImport class]])
    {
      MaterialInstanceConstant *t = (MaterialInstanceConstant *)[object.package resolveImport:(FObjectImport *)mat.fObject];
      if (t)
        mat = t;
    }
    
    if ([mat.className isEqualToString:@"UObject"] || !mat)
    {
      DLog(@"Failed to load material #%lu - %@",idx,mat);
      continue;
    }
    
    SCNMaterial *m = [mat sceneMaterial];
    tempMat[idx] = m;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    node.geometry.materials = tempMat;
  });
}

- (BOOL)hideProperties
{
  return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return self.actors.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return self.actors[row];
}

- (NSString *)exportName
{
  return [self.object.package.name stringByAppendingPathExtension:@"t3d"];
}

- (IBAction)exportData:(id)sender
{
  NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
  self.exportOtherActors = [d boolForKey:kSettingsLevelExportOther];
  self.exportStaticMeshes = [d boolForKey:kSettingsLevelExportStaticMeshes];
  self.exportSkeletalMeshes = [d boolForKey:kSettingsLevelExportSkeletalMeshes];
  self.exportLights =  [d boolForKey:kSettingsLevelExportLights];
  self.exportInterpActors = [d boolForKey:kSettingsLevelExportInterp];
  self.exportTerrain = [d boolForKey:kSettingsLevelExportTerrain];
  self.exportSpeedTrees = [d boolForKey:kSettingsLevelExportTrees];
  self.exportAddObjectIndex = [d boolForKey:kSettingsLevelExportAddIndex];
  self.exportLODs = [d boolForKey:kSettingsLevelExportLODs];
  self.exportBlockingVolumes = [d boolForKey:kSettingsLevelExportBlockingVolumes];
  self.exportAeroSets = [d boolForKey:kSettingsLevelExportAero];
  self.exportTextures = [d boolForKey:kSettingsLevelExportTextures];
  self.exportMaterials = [d boolForKey:kSettingsLevelExportMaterials];
  self.exportAnimations = [d boolForKey:kSettingsLevelExportAnimations];
  self.exportResampleTerrain = [d boolForKey:kSettingsLevelExportTerrainResample];
  self.exportResampleWeightMaps = [d boolForKey:kSettingsLevelExportWeightMapResample];
  self.exportActorsPerFile = CLAMP((int)[d integerForKey:kSettingsLevelExportActorsPerFile], 0, 99999);
  
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canCreateDirectories = YES;
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.prompt = @"Export";
  NSString *path = [d objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@", self.object.objectClass]];
  if (path)
  {
    panel.directoryURL = [NSURL fileURLWithPath:path];
  }
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      [self showExportOptions:panel.URL];
    }
  }];
}

- (void)showExportOptions:(NSURL*)url
{
  [self.view.window beginSheet:self.exportPanel completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK)
    {
      [self doExport:url.path];
    }
  }];
}

- (IBAction)onExportOptionsOk:(id)sender
{
  [self.view.window endSheet:self.exportPanel returnCode:NSModalResponseOK];
}

- (IBAction)onExportOptionsCancel:(id)sender
{
  [self.view.window endSheet:self.exportPanel returnCode:NSModalResponseCancel];
}

- (void)doExport:(NSString *)path
{
  NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
  [d setObject:path forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  [d setBool:self.exportOtherActors forKey:kSettingsLevelExportOther];
  [d setBool:self.exportStaticMeshes forKey:kSettingsLevelExportStaticMeshes];
  [d setBool:self.exportSkeletalMeshes forKey:kSettingsLevelExportSkeletalMeshes];
  [d setBool:self.exportLights forKey:kSettingsLevelExportLights];
  [d setBool:self.exportInterpActors forKey:kSettingsLevelExportInterp];
  [d setBool:self.exportTerrain forKey:kSettingsLevelExportTerrain];
  [d setBool:self.exportSpeedTrees forKey:kSettingsLevelExportTrees];
  [d setBool:self.exportAddObjectIndex forKey:kSettingsLevelExportAddIndex];
  [d setBool:self.exportLODs forKey:kSettingsLevelExportLODs];
  [d setBool:self.exportBlockingVolumes forKey:kSettingsLevelExportBlockingVolumes];
  [d setBool:self.exportAeroSets forKey:kSettingsLevelExportAero];
  [d setBool:self.exportTextures forKey:kSettingsLevelExportTextures];
  [d setBool:self.exportMaterials forKey:kSettingsLevelExportMaterials];
  [d setBool:self.exportAnimations forKey:kSettingsLevelExportAnimations];
  [d setBool:self.exportResampleTerrain forKey:kSettingsLevelExportTerrainResample];
  [d setBool:self.exportResampleWeightMaps forKey:kSettingsLevelExportWeightMapResample];
  [d setInteger:CLAMP(self.exportActorsPerFile, 0, 999999) forKey:kSettingsLevelExportActorsPerFile];
  [d synchronize];
  cancelExport = NO;
  self.exportProgressCancelTitle = @"Cancel";
  self.exportProgressValue = 0.;
  [self.view.window beginSheet:self.exportProgressPanel completionHandler:nil];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSArray *streamingLevels = self.object.worldInfo.streamingLevels;
    
    if (!streamingLevels.count)
    {
      [self exportT3D:[path stringByAppendingFormat:@"/%@_PersistentLevel.t3d", self.object.package.name] level:self.object];
    }
    else
    {
      for (NSNumber *objIdx in streamingLevels)
      {
        LevelStreamingDistance *streamingLevel = [self.object.package objectForIndex:[objIdx intValue]];
        if (![streamingLevel respondsToSelector:@selector(streamingPackageName)])
        {
          DThrow(@"Unimplemented streaming level %@", streamingLevel);
          continue;
        }
        NSString *packageName = [streamingLevel streamingPackageName];
        UPackage *p = [UPackage package:packageName];
        if (p)
        {
          [self.object.package addDependentPackage:p];
          Level *l = [p objectForName:@"PersistentLevel"];
          if (!l)
          {
            DThrow(@"Failed to find level in the package %@", p.name);
          }
          else
          {
            [self exportT3D:[path stringByAppendingFormat:@"/%@_PersistentLevel.t3d", p.name] level:l];
          }
        }
        else
        {
          DThrow(@"Failed to find package %@", packageName);
        }
      }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      self.exportProgressValue = 100;
      self.exportProgressDescription = @"Finished!";
      self.exportProgressCancelTitle = @"Done";
    });
  });
}

- (void)exportTerrain:(Terrain *)terrain path:(NSString *)path
{
  CGImageRef heightMap = [terrain heightMap];
  WriteImageRef(heightMap, [path stringByAppendingFormat:@"_TerrainHeightMap_%d.png",[terrain.package indexForObject:terrain]]);
  CGImageRelease(heightMap);
  [terrain.info writeToURL:[NSURL fileURLWithPath:[path stringByAppendingFormat:@"_TerrainInfo_%d.txt",[terrain.package indexForObject:terrain]]]
                atomically:YES
                  encoding:NSUTF8StringEncoding
                     error:NULL];
}

@end
