//
//  MaterialInstanceConstantEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 31/10/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "MaterialInstanceConstantEditor.h"
#import <SceneKit/SceneKit.h>
#import "UPackage.h"
#import "SceneView.h"
#import "Texture2D.h"

@interface MaterialInstanceConstantEditor ()
@property (weak) IBOutlet ModelView       *sceneView;
@property (weak) IBOutlet NSPopUpButton   *previewModel;
@property (strong) SCNNode                *meshNode;
@end

void GetWarpModesFromTextureForMaterial(Texture2D *tex, SCNWrapMode *wrapX, SCNWrapMode *wrapY)
{
  FPropertyTag *tag = [tex propertyForName:@"AddressX"];
  if (tag && [tag.type isEqualToString:kPropTypeByte]) {
    if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Mirror"])
      *wrapX = SCNWrapModeMirror;
    else if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Clamp"])
      *wrapX = SCNWrapModeClamp;
  }
  tag = [tex propertyForName:@"AddressY"];
  if (tag && [tag.type isEqualToString:kPropTypeByte]) {
    if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Mirror"])
      *wrapY = SCNWrapModeMirror;
    else if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Clamp"])
      *wrapY = SCNWrapModeClamp;
  }
}

void ConfigureMaterial(SCNMaterialProperty *materialProperty, NSImage *tex)
{
  NSImage *img = tex;
  materialProperty.contents = img;
}

@implementation MaterialInstanceConstantEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.sceneView.materialView = YES;
  [self.sceneView setup];
  [self loadMesh:[self.previewModel selectedTag]];
}

- (void)loadMesh:(NSInteger)index
{
  SCNNode *mesh = nil;
  
  CGFloat size = 50.0;
  switch (index) {
    case 0:
    {
      SCNBox *geo = [SCNBox boxWithWidth:size height:size length:size chamferRadius:0];
      mesh = [SCNNode nodeWithGeometry:geo];
      break;
    }
      
    case 1:
    {
      SCNSphere *geo = [SCNSphere sphereWithRadius:size * .5];
      mesh = [SCNNode nodeWithGeometry:geo];
      break;
    }
      
    default:
      break;
  }
  
  if (!mesh)
    return;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self setupMaterialsForNode:mesh object:self.object];
  });
  NSArray *children = self.sceneView.objectNode.childNodes;
  
  for (SCNNode *child in children)
    [child performSelectorOnMainThread:@selector(removeFromParentNode) withObject:nil waitUntilDone:NO];
  
  [self.sceneView.objectNode performSelectorOnMainThread:@selector(addChildNode:) withObject:mesh waitUntilDone:YES];
  [self.sceneView reset];
  self.meshNode = mesh;
}

- (void)setupMaterialsForNode:(SCNNode *)node object:(MaterialInstanceConstant *)object
{
  NSMutableArray *tempMat = [NSMutableArray new];
  [node.geometry performSelectorOnMainThread:@selector(setMaterials:) withObject:tempMat waitUntilDone:YES];
  
  SCNMaterial *m = nil;
  MaterialInstanceConstant *mat = object;
  
  if ([mat isZero]) // Mesh may have no valid materials (eg bone_skel)
    return;
  
  if ([mat.fObject isKindOfClass:[FObjectImport class]])
  {
    MaterialInstanceConstant *t = (MaterialInstanceConstant *)[object.package resolveImport:(FObjectImport *)mat.fObject];
    if (t)
      mat = t;
  }
  
  if ([mat.className isEqualToString:@"UObject"] || !mat)
  {
    DLog(@"Failed to load material %@",mat);
    return;
  }
  
  m = [mat sceneMaterial];
  if (!m)
    return;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    node.geometry.materials = @[m];
  });
}

- (IBAction)changedModel:(id)sender
{
  [self loadMesh:[self.previewModel selectedTag]];
}

@end
