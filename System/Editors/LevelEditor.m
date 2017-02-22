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
#import "FBXUtils.h"

const double ScaleFactor = 1.0;

@interface LevelEditor () <NSTableViewDataSource>
{
  SCNMaterial *defMat;
  NSMutableArray *meshes;
}

@property (weak) IBOutlet ModelView       *sceneView;
@property (weak) IBOutlet NSTableView     *actorsTable;
@property (strong) NSMutableArray         *nodes;
@property (strong) NSMutableArray         *meshNodes;
@property (strong) NSMutableArray         *actors;
@property (strong) NSOperationQueue       *materialQueue;
@property (weak) IBOutlet NSPopUpButton   *exportType;
@end

@implementation LevelEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.actors = [NSMutableArray new];
  [self.sceneView setup];
  self.sceneView.increaseFogDensity = YES;
  self.nodes = [NSMutableArray new];
  self.meshNodes = [NSMutableArray new];
  self.materialQueue = [NSOperationQueue new];
  self.materialQueue.maxConcurrentOperationCount = 3;
  
  [self performSelectorInBackground:@selector(setupLevel) withObject:nil];
}

- (void)setupLevel
{
  BOOL loadLights = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadLights];
  meshes = [NSMutableArray new];
  SCNVector3 max = SCNVector3Make(CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN);
  SCNVector3 min = SCNVector3Make(CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX);
  BOOL loadedAero = NO;
  for (Actor *actor in self.object.actors)
  {
    if (![actor isKindOfClass:[Actor class]])
    {
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
    n.name = [NSString stringWithFormat:@"%lu",[self.actors count] - 1];
    
    
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
  [self.actorsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
  [self.sceneView performSelectorOnMainThread:@selector(reset) withObject:nil waitUntilDone:NO];
  self.sceneView.cameraNode.camera.zNear = 10;
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
          [self setupMaterialsForNode:n object:meshes[idx] lod:0];
        }];
      }
    }
    [self.actorsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    [self.sceneView performSelectorOnMainThread:@selector(reset) withObject:nil waitUntilDone:NO];
  }];
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
  return [self.object.package.name stringByAppendingPathExtension:@"fbx"];
}

- (IBAction)exportData:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = self.exportName;
  panel.accessoryView = self.exportOptionsView;
  panel.prompt = @"Export";
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  __weak id obj = self.object;
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
    if (result == NSModalResponseOK)
    {
      __strong id sobj = obj;
      dispatch_async(dispatch_get_main_queue(), ^{
        [self doExport:sobj path:[panel.URL path]];
      });
    }
  }];
}

- (void)doExport:(Level *)sobj path:(NSString *)p
{
  FBXUtils *u = [FBXUtils new];
  [u exportLevel:sobj options:@{@"path" : p,
                                @"type" : @(self.exportType.selectedTag)}];
}

@end
