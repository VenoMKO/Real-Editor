//
//  StaticMeshEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 23/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "PrefabEditor.h"
#import "MeshActor.h"
#import "StaticMesh.h"
#import "TextureView.h"
#import "FPropertyTag.h"
#import "Material.h"
#import "SceneView.h"
#import "UPackage.h"
#import "Texture2D.h"
#import "FMesh.h"

@interface PrefabEditor ()
{
  SCNMaterial *defMat;
}
@property (weak) IBOutlet NSPopUpButton   *lodSelector;
@property (weak) IBOutlet ModelView       *sceneView;
@property (weak) IBOutlet NSPopUpButton   *exportType;
@property (strong) SCNNode                *meshNode;
@property (assign, nonatomic) BOOL        renderWireframe;
@end

@implementation PrefabEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self defaultMaterial];
  [self.sceneView setup];
  NSUInteger lodCount = 1;
  for (NSUInteger idx = 0; idx < lodCount; idx++)
    [self.lodSelector addItemWithTitle:[NSString stringWithFormat:@"%lu",idx+1]];
  [self loadLod:0];
}

- (void)loadLod:(NSUInteger)lodIndex
{
  NSArray<StaticMeshActor*> *objects = [self.object prefabArchetypes];
  SCNNode *rootNode = [self.object renderNode:lodIndex];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
    for (int i = 0; i < objects.count; ++i)
    {
      [self setupMaterialsForNode:rootNode.childNodes[i] object:[objects[i] mesh] lod:lodIndex];
    }
  });
  
  NSArray *children = self.sceneView.objectNode.childNodes;
  
  for (SCNNode *child in children)
    [child performSelectorOnMainThread:@selector(removeFromParentNode) withObject:nil waitUntilDone:NO];
  
  [self.sceneView.objectNode performSelectorOnMainThread:@selector(addChildNode:) withObject:rootNode waitUntilDone:YES];
  [self.sceneView reset];
  
  self.meshNode = rootNode;
}

- (void)setRenderWireframe:(BOOL)renderWireframe
{
  _renderWireframe = renderWireframe;
  self.sceneView.debugOptions = renderWireframe ? SCNDebugOptionShowWireframe : SCNDebugOptionNone;
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
      NSAppError(mat.package, @"Failed to load material #%lu - %@",idx,mat);
      continue;
    }
    
    SCNMaterial *m = [mat sceneMaterial];
    if (m)
    {
      if (idx < tempMat.count)
      {
        tempMat[idx] = m;
      }
      else
      {
        [tempMat addObject:m];
      }
    }
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    node.geometry.materials = tempMat;
  });
}

- (NSString *)exportName
{
  return self.object.objectName;
}

- (IBAction)exportData:(id)sender
{
}

@end
