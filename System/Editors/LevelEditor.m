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

- (void)exportT3D:(NSString *)path
{
  NSString *dataDirPath = [path stringByDeletingLastPathComponent];
  [[NSFileManager defaultManager] createDirectoryAtPath:dataDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
  
  NSMutableString *result = [NSMutableString new];
  unsigned padding = 0;
  T3DAddLine(result, padding, T3DBeginObject(@"Map", nil, nil)); padding++;
  T3DAddLine(result, padding, T3DBeginObject(@"Level", nil, nil)); padding++;
  
  NSArray *actors = [[[self.object actors] nsarray] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Actor *actor, NSDictionary<NSString *,id> *bindings) {
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
  for (Actor *actor in actors)
  {
    progress += step;
    if (cancelExport)
    {
      return;
    }
    [actor properties];
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
      self.exportProgressDescription = [NSString stringWithFormat:@"Exporting: %@", name];
    });
    if ([actor isKindOfClass:[StaticMeshActor class]] ||
        [actor isKindOfClass:[InterpActor class]])
    {
      if (![actor exportToT3D:result padding:padding index:idx])
      {
        continue;
      }
      [actorsList appendFormat:@"[%d]%@(%@)\n", [actor.package indexForObject:actor], [actor displayName], [actor objectClass]];
      StaticMesh *mesh = (StaticMesh*)[(StaticMeshActor*)actor mesh];
      
      if (mesh)
      {
        if (mesh.exportObject.exportFlags | EF_ForcedExport)
        {
          mesh = (id)[mesh.package resolveForcedExport:mesh.exportObject];
          if (cancelExport) return;
        }
        else if (mesh.importObject)
        {
          mesh = (id)[mesh.package resolveImport:mesh.importObject];
          if (cancelExport) return;
        }
        if (!mesh || !mesh.lodInfo.count)
        {
          DLog(@"Failed to find mesh: %@", actor);
          continue;
        }
        if (cancelExport) return;
        
        NSString *targetPath = nil;
        NSString *fbxPath = nil;
        {
          NSArray *targetPathComps = [[mesh objectPath] componentsSeparatedByString:@"."];
          //targetPathComps = [targetPathComps subarrayWithRange:NSMakeRange(1, targetPathComps.count - 1)];
          NSString *meshTypeDir = [mesh isKindOfClass:[StaticMesh class]] ? @"StaticMeshes/S1Data" : @"SkeletalMeshes/S1Data";
          targetPath = [[dataDirPath stringByAppendingPathComponent:meshTypeDir] stringByAppendingPathComponent:[targetPathComps componentsJoinedByString:@"/"]];
          fbxPath = [targetPath stringByAppendingPathExtension:@"fbx"];
        }
        
        [actorsList appendFormat:@"\tMesh: %@:%@\n", mesh.package.stream.url.path, [mesh.objectPath stringByReplacingOccurrencesOfString:@"." withString:@"/"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fbxPath])
        {
          [[NSFileManager defaultManager] createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
          dispatch_async(dispatch_get_main_queue(), ^{
            self.exportProgressDescription = [NSString stringWithFormat:@"Exporting: %@", [fbxPath lastPathComponent]];
          });
          if ([mesh isKindOfClass:[StaticMesh class]])
          {
            //TODO: UCX_name collisions
            [[FBXUtils new] exportStaticMesh:mesh options:@{@"path" : fbxPath, @"lodIdx" : @(0), @"type" : @(0)}];
          }
          else if ([mesh isKindOfClass:[SkeletalMesh class]])
          {
            [[FBXUtils new] exportSkeletalMesh:(SkeletalMesh*)mesh options:@{@"path" : fbxPath, @"lodIdx" : @(0), @"type" : @(0)}];
          }
        }
      }
    }
    else if ([actor isKindOfClass:[SpeedTreeActor class]])
    {
      if (![actor exportToT3D:result padding:padding index:idx])
      {
        continue;
      }
      [actorsList appendFormat:@"[%d]%@(%@)\n", [actor.package indexForObject:actor], [actor displayName], [actor objectClass]];
      
      SpeedTree *tree = [[(SpeedTreeActor *)actor component] speedTree];
      
      if (tree)
      {
        if (tree.exportObject.exportFlags | EF_ForcedExport)
        {
          tree = (id)[tree.package resolveForcedExport:tree.exportObject];
          if (cancelExport) return;
        }
        else if (tree.importObject)
        {
          tree = (id)[tree.package resolveImport:tree.importObject];
          if (cancelExport) return;
        }
        
        NSString *targetPath = nil;
        NSString *sptPath = nil;
        {
          NSArray *targetPathComps = [[tree objectPath] componentsSeparatedByString:@"."];
          //targetPathComps = [targetPathComps subarrayWithRange:NSMakeRange(1, targetPathComps.count - 1)];
          targetPath = [[dataDirPath stringByAppendingPathComponent:@"SpeedTree/S1Data"] stringByAppendingPathComponent:[targetPathComps componentsJoinedByString:@"/"]];
          sptPath = [targetPath stringByAppendingPathExtension:@"spt"];
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:sptPath])
        {
          [[NSFileManager defaultManager] createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
          dispatch_async(dispatch_get_main_queue(), ^{
            self.exportProgressDescription = [NSString stringWithFormat:@"Exporting: %@", [sptPath lastPathComponent]];
          });
          
          NSData *data = [tree exportWithOptions:nil];
          if (data.length)
          {
            [data writeToFile:sptPath atomically:YES];
          }
        }
      }
    }
    else
    {
      if ([actor exportToT3D:result padding:padding index:idx])
      {
        [actorsList appendFormat:@"[%d]%@(%@)\n", [actor.package indexForObject:actor], [actor objectName], [actor objectClass]];
      }
    }
  }
  
  [actorsList writeToFile:[[path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@_actors_list.txt", self.object.package.name] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Level"));
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"Map"));
  T3DAddLine(result, padding, T3DBeginObject(@"FolderList", nil, nil));
  padding++;
  T3DAddLine(result, padding, @"Folder=\"%@\"",self.object.package.name);
  padding--;
  T3DAddLine(result, padding, T3DEndObject(@"FolderList"));
  [result deleteCharactersInRange:NSMakeRange(0, 1)];
  if (cancelExport) return;
  [result writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
  dispatch_async(dispatch_get_main_queue(), ^{
    self.exportProgressValue = 100;
    self.exportProgressDescription = @"Finished!";
    self.exportProgressCancelTitle = @"Done";
  });
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
  
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = self.exportName;
  panel.accessoryView = self.exportOptionsView;
  panel.prompt = @"Export";
  NSString *path = [d objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  __weak id wself = self;
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    [d setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
    if (result == NSModalResponseOK && wself)
    {
      __strong LevelEditor *sself = wself;
      [d setBool:sself.exportOtherActors forKey:kSettingsLevelExportOther];
      [d setBool:sself.exportStaticMeshes forKey:kSettingsLevelExportStaticMeshes];
      [d setBool:sself.exportSkeletalMeshes forKey:kSettingsLevelExportSkeletalMeshes];
      [d setBool:sself.exportLights forKey:kSettingsLevelExportLights];
      [d setBool:sself.exportInterpActors forKey:kSettingsLevelExportInterp];
      [d setBool:sself.exportTerrain forKey:kSettingsLevelExportTerrain];
      [d setBool:sself.exportSpeedTrees forKey:kSettingsLevelExportTrees];
      [d setBool:sself.exportAddObjectIndex forKey:kSettingsLevelExportAddIndex];
      [d synchronize];
      [sself doExport:[panel.URL path]];
    }
  }];
}

- (void)doExport:(NSString *)path
{
  cancelExport = NO;
  self.exportProgressCancelTitle = @"Cancel";
  self.exportProgressValue = 0.;
  [self.view.window beginSheet:self.exportProgressPanel completionHandler:nil];
  [self performSelectorInBackground:@selector(exportT3D:) withObject:path];
}

- (void)exportTerrain:(Terrain *)terrain path:(NSString *)path
{
  CGImageRef heightMap = [terrain heightMap];
  CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:[path stringByAppendingFormat:@"_Terrain_%d.png",[terrain.package indexForObject:terrain]]];
  CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
  if (!destination)
  {
    CGImageRelease(heightMap);
    return;
  }

  CGImageDestinationAddImage(destination, heightMap, nil);

  if (!CGImageDestinationFinalize(destination))
  {
    CFRelease(destination);
    CGImageRelease(heightMap);
    return;
  }

  CFRelease(destination);
  CGImageRelease(heightMap);
  
  [terrain.info writeToURL:[NSURL fileURLWithPath:[path stringByAppendingFormat:@"_Terrain_%d.txt",[terrain.package indexForObject:terrain]]]
                atomically:YES
                  encoding:NSUTF8StringEncoding
                     error:NULL];
}

@end
