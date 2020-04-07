//
//  UObjectEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "UIExtensions.h"
#import "SkeletalMeshEditor.h"
#import "TextureView.h"
#import "FPropertyTag.h"
#import "Material.h"
#import "SceneView.h"
#import "UPackage.h"
#import "Texture2D.h"
#import "FMesh.h"
#import "FBXUtils.h"

@interface SkeletalMeshEditor () <NSTableViewDelegate>
{
  SCNMaterial *defMat;
}
@property (weak) IBOutlet NSPopUpButton   *lodSelector;
@property (weak) IBOutlet ModelView       *sceneView;
@property (strong) SCNNode                *meshNode;
@property (strong) SCNNode                *subMesh1;
@property (strong) SCNNode                *subMesh2;

@property (assign, nonatomic) BOOL        renderWireframe;

@property (weak) IBOutlet NSPopUpButton   *subMesh1Selector;
@property (weak) IBOutlet NSPopUpButton   *subMesh2Selector;

@property (weak) IBOutlet NSButton        *exportSkel;
@property (weak) IBOutlet NSPopUpButton   *exportType;

@property (assign) BOOL                   importIgnoreBPrefix;
@property (assign) BOOL                   importFlipTangents;
@property (assign) BOOL                   importGenTangents;
@property (assign) BOOL                   importImportSkeleton;
@property (assign) BOOL                   allowMat;
@property (assign) BOOL                   allowImpSkel;

@property (strong) IBOutlet USPanel       *materialMapPanel;
@property (weak) IBOutlet NSTableView     *materialMapTable;

@property (strong) IBOutlet USPanel       *materialPanel;
@property (weak) IBOutlet NSTableView     *materialTable;

@property (strong) NSMutableArray         *meshes;
@property (strong) NSMutableDictionary    *materials;

@property (strong) RawImportData          *importData;
@property (weak) NSSavePanel              *currentPanel;

@property (assign) BOOL                   loading;

@end

@implementation SkeletalMeshEditor
@dynamic object;

- (void)viewDidLoad
{
  self.loading = YES;
  [super viewDidLoad];
  [self.sceneView setup];
  self.allowMat = YES;
  self.allowImpSkel = YES;
  NSUInteger lodCount = self.object.lodInfo.count;
  for (NSUInteger idx = 0; idx < lodCount; idx++)
    [self.lodSelector addItemWithTitle:[NSString stringWithFormat:@"%lu",idx+1]];
  
  self.meshes = (NSMutableArray *)[self.object.package allObjectsOfClass:kClassSkeletalMesh];
  
  [self.subMesh1Selector removeAllItems];
  [self.subMesh2Selector removeAllItems];
  [self.subMesh1Selector addItemWithTitle:@"None"];
  [self.subMesh2Selector addItemWithTitle:@"None"];
  NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
  self.importGenTangents = [d boolForKey:kSettingsSkelMeshCalcTangents];
  self.importFlipTangents = [d boolForKey:kSettingsSkelMeshFlipTangents];
  self.importIgnoreBPrefix = [d boolForKey:kSettingsSkelMeshIgnoreBPrefix];
  self.importImportSkeleton = [d boolForKey:kSettingsSkelMeshImportSkeleton];
  
  for (SkeletalMesh *mesh in self.meshes)
  {
    if (mesh == self.object)
      continue;
    NSMenuItem *item = [NSMenuItem new];
    item.title = mesh.objectName;
    item.representedObject = mesh;
    [self.subMesh1Selector.menu addItem:item];
    [self.subMesh2Selector.menu addItem:item.copy];
    
  }
  [self.subMesh1Selector selectItemAtIndex:0];
  [self.subMesh2Selector selectItemAtIndex:0];
  [self loadLod:0];
}

- (void)setRenderWireframe:(BOOL)renderWireframe
{
  _renderWireframe = renderWireframe;
  self.sceneView.debugOptions = renderWireframe ? SCNDebugOptionShowWireframe : SCNDebugOptionNone;
}

- (IBAction)loadSubMesh:(NSPopUpButton *)sender
{
  SCNNode *node = nil;
  SkeletalMesh *m = nil;
  if (sender == self.subMesh1Selector)
  {
    m = sender.selectedItem.representedObject;
    [self.subMesh1 removeFromParentNode];
    if (m)
    {
      node = [m renderNode:self.lodSelector.indexOfSelectedItem];
      if (node)
      {
        [self.sceneView.objectNode addChildNode:node];
      }
      self.subMesh1 = node;
    }
  }
  else if (sender == self.subMesh2Selector)
  {
    m = sender.selectedItem.representedObject;
    [self.subMesh2 removeFromParentNode];
    if (m)
    {
      node = [m renderNode:self.lodSelector.indexOfSelectedItem];
      if (node)
      {
        [self.sceneView.objectNode addChildNode:node];
      }
      self.subMesh2 = node;
    }
  }
  if (m && node)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      [self setupMaterialsForNode:node object:m lod:0];
    });
}

- (void)loadLod:(NSUInteger)lodIndex
{
  self.loading = YES;
  SCNNode *node = [self.object renderNode:lodIndex];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self setupMaterialsForNode:node object:self.object lod:lodIndex];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.loading = NO;
    });
  });
  NSArray *children = self.sceneView.objectNode.childNodes;
  
  for (SCNNode *child in children)
    [child performSelectorOnMainThread:@selector(removeFromParentNode) withObject:nil waitUntilDone:NO];
  
  [self.sceneView.objectNode performSelectorOnMainThread:@selector(addChildNode:) withObject:node waitUntilDone:YES];
  [self.sceneView reset];
  if (self.subMesh1Selector.selectedItem.representedObject)
    [self loadSubMesh:self.subMesh1Selector];
  if (self.subMesh2Selector.selectedItem.representedObject)
    [self loadSubMesh:self.subMesh2Selector];
  
  self.meshNode = node;
}

- (IBAction)setLod:(NSPopUpButton *)sender
{
  NSUInteger idx = [sender indexOfSelectedItem];
  [self loadLod:idx];
}

- (IBAction)editMaterials:(id)sender
{
  FArray *mats = [FArray arrayWithArray:self.object.materials.nsarray package:self.object.package];
  self.materialPanel.hostWindow = self.view.window;
  [self.view.window beginSheet:self.materialPanel completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK)
    {
      [self.object setDirty:YES];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self setupMaterialsForNode:self.meshNode object:self.object lod:self.lodSelector.indexOfSelectedItem];
        [[self materialMapTable] reloadData];
      });
    }
    else
      self.object.materials = mats;
  }];
}

- (IBAction)editMaterialsAdd:(id)sender
{
  NSArray *all = self.allMaterialObjects;
  for (UObject *o in all)
  {
    if ([self.object.materials indexOfObject:o] == NSNotFound)
    {
      [self.object.materials addObject:o];
      [self.materialTable reloadData];
      return;
    }
  }
  NSBeep();
}

- (IBAction)editMaterialsWhileImporting:(id)sender
{
  FArray *mats = [FArray arrayWithArray:self.object.materials.nsarray package:self.object.package];
  self.materialPanel.hostWindow = self.materialMapPanel;
  [self.materialMapPanel beginSheet:self.materialPanel completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK)
    {
      [self.object setDirty:YES];
      [self.materialMapTable reloadData];
      [self.materialTable reloadData];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self setupMaterialsForNode:self.meshNode object:self.object lod:self.lodSelector.indexOfSelectedItem];
      });
    }
    else
      self.object.materials = mats;
  }];
}

- (NSArray *)allMaterialObjects
{
  NSArray *materials = [self.object.package allObjectsOfClass:kClassMaterial];
  NSArray *constants = [self.object.package allObjectsOfClass:kClassMaterialInstanceConstant];
  NSMutableArray *array = [NSMutableArray array];
  [array addObjectsFromArray:constants];
  [array addObjectsFromArray:materials];
  return array;
}

- (NSString *)exportName
{
  return self.object.objectName;
}

- (NSString *)exportExtension
{
  return @"fbx";
}

- (void)configureMaterial:(SCNMaterialProperty *)materialProperty image:(NSImage *)tex
{
  NSImage *img = tex;
  materialProperty.contents = img;
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

- (void)setupMaterialsForNode:(SCNNode *)node object:(SkeletalMesh *)object lod:(NSUInteger)lod
{
  NSMutableArray *tempMat = [NSMutableArray new];
  
  FPropertyTag *matMapProp = [self.object propertyForName:@"LODInfo"];
  NSArray *matMap = nil;
  if (matMapProp && [matMapProp.value count] > lod)
  {
    NSArray *subPropsArray = [matMapProp.value objectAtIndex:lod];
    matMap = [[FPropertyTag propertyForName:@"LODMaterialMap" from:subPropsArray] value];
  }
  
  NSArray *matSource = object.materials.nsarray;
  NSMutableArray *tMat = [NSMutableArray array];
  for (NSNumber *matIdx in matMap)
  {
    [tMat addObject:matSource[matIdx.integerValue]];
  }
  if (tMat.count)
    matSource = tMat;
  
  for (__unused MaterialInstanceConstant *mat in matSource)
  {
    [tempMat addObject:self.defaultMaterial];
  }
  
  [node.geometry performSelectorOnMainThread:@selector(setMaterials:) withObject:tempMat waitUntilDone:YES];
  
  FArray *sections = [(FLodInfo *)object.lodInfo[lod] sections];
  NSMutableArray *matsToRender = [NSMutableArray new];
  NSMutableArray *processingMats = [NSMutableArray new];
  for (int idx = 0; idx < sections.count; idx++)
  {
    [matsToRender addObject:@([(FMeshSection *)sections[idx] material])];
    [processingMats addObject:self.defaultMaterial];
  }
  
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
    
    if ([mat.className isEqualToString:@"UObject"] || !mat)
    {
      DLog(@"Failed to load material #%lu - %@",idx,mat);
      continue;
    }
    
    SCNMaterial *m = [mat sceneMaterial];
    tempMat[idx] = m;
      
    
    NSUInteger mapped = [matsToRender indexOfObject:@(idx)];
    if (mapped != NSNotFound)
    {
      processingMats[mapped] = m;
      [node.geometry performSelectorOnMainThread:@selector(setMaterials:) withObject:processingMats waitUntilDone:NO];
    }
  }
  
  
  NSMutableArray *a = [NSMutableArray new];
  for (int idx = 0; idx < sections.count; idx++)
  {
    short matIdx = [(FMeshSection *)sections[idx] material];
    if (tempMat.count > matIdx)
      [a addObject:tempMat[matIdx]];
    else
      [a addObject:self.defaultMaterial];
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    node.geometry.materials = a;
  });
}

- (IBAction)exportData:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  self.currentPanel = panel;
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = self.exportName;
  panel.accessoryView = self.exportOptionsView;
  panel.extensionHidden = NO;
  panel.prompt = @"Export";
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  [self switchExportType:nil];
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSString *p = panel.URL.path;
      FBXUtils *u = [FBXUtils new];
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
      [u exportSkeletalMesh:self.object options:@{@"path" : p,
                                                  @"lodIdx" : @(self.lodSelector.indexOfSelectedItem),
                                                  @"skeleton" : @(self.exportSkel.state),
                                                  @"type" : @(self.exportType.selectedTag)}];
    }
  }];
}

- (IBAction)switchExportType:(id)sender
{
  NSString *ext = @"";
  switch (self.exportType.selectedTag)
  {
    case 0:
    case 3:
      ext = @"fbx";
      break;
      
    case 7:
      ext = @"obj";
      break;
      
    case 8:
      ext = @"dae";
      break;
      
    default:
      break;
  }
  self.currentPanel.nameFieldStringValue = [[self.currentPanel.nameFieldStringValue stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
}

- (IBAction)importData:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.prompt = @"Import";
  panel.allowedFileTypes = @[@"fbx"];
  panel.accessoryView = self.importOptionsView;
  panel.accessoryViewDisclosed = YES;
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsImportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      FBXUtils *utils = [FBXUtils new];
      NSString *error = nil;
      self.importData = [utils importLodFromURL:[panel URL] forSkeletalMesh:self.object options:@{@"prfx" : @(self.importIgnoreBPrefix), @"skel" : @(self.importImportSkeleton), @"impTan" : @(!self.importGenTangents), @"flpTan" : @(self.importFlipTangents)} error:&error];
      if (self.importData)
      {
        if (self.object.materials.count && !([self.object.materials[0] isZero] && self.object.materials.count == 1 ))
        {
          [self performSelectorOnMainThread:@selector(importMaterialMap)
                                 withObject:nil
                              waitUntilDone:NO];
          return;
        }
        FLodInfo *model = [self.importData buildLod:@{@"mesh" : self.object}];
        if (!model)
        {
          if (error)
            NSAppError(self.object.package, [NSString stringWithFormat:@"Error! Failed to import mesh! %@", error]);
          else
            NSAppError(self.object.package, @"Error! Failed to import mesh!");
          return;
        }
        else if (error)
        {
          NSAppError(self.object.package, error);
        }
        [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsImportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
        [self.object.lodInfo replaceObjectAtIndex:self.lodSelector.selectedTag withObject:model];
        [self.object setDirty:YES];
        [self setLod:self.lodSelector];
      }
      else if (error)
      {
        NSAppError(self.object.package, error);
      }
      else
        DLog(@"Unexpected error while importing mesh!");
    }
  }];
}

- (void)importMaterialMap
{
  
  NSTableView *tableView = self.materialMapTable;
  tableView.dataSource = self;
  tableView.delegate = self;
  [tableView reloadData];
  
  [self.view.window beginSheet:self.materialMapPanel completionHandler:^(NSModalResponse returnCode) {
    if (!returnCode)
    {
      self.importData = nil;
      return;
    }
    NSMutableArray *mmap = [NSMutableArray array];
    for (int i = 0; i < self.importData.materials.count; i++) {
      NSPopUpButton *btn = [[tableView viewAtColumn:1 row:i makeIfNecessary:NO] subviews][0];
      if (btn)
        [mmap addObject:@(btn.selectedTag)];
    }
    
    FLodInfo *model = [self.importData buildLod:@{@"mesh" : self.object, @"mmap" : mmap}];
    [self.object.lodInfo replaceObjectAtIndex:self.lodSelector.selectedTag withObject:model];
    [self.object setDirty:YES];
    [self setLod:self.lodSelector];
    self.importData = nil;
  }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  if (tableView == _materialTable)
    return self.object.materials.count;
  return self.importData.materials.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
  if (tableView == _materialMapTable)
  {
    if ([tableColumn.identifier isEqualToString:@"fbx"])
    {
      NSTableCellView *tv = [tableView makeViewWithIdentifier:@"fbxView" owner:self];
      tv.textField.stringValue = self.importData.materials[row];
      return tv;
    }
    
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"teraView" owner:self];
    NSString *proposedTitle = self.importData.materials[row];
    NSPopUpButton *btn = [[NSPopUpButton alloc] initWithFrame:result.bounds];
    btn.menu = [NSMenu new];
    btn.cell.bezeled = NO;
    btn.cell.bordered = NO;
    int idx = 0;
    int selection = -1;
    for (UObject *material in self.object.materials)
    {
      NSString *matName = [material objectName];
      if ([matName isEqualToString:proposedTitle])
        selection = idx;
      NSMenuItem *itm = [NSMenuItem new];
      itm.title = [NSString stringWithFormat:@"[%d]%@",[material.package indexForObject:material],matName];
      itm.tag = idx;
      [btn.menu addItem:itm];
      idx++;
    }
    if (selection >= 0)
      [btn selectItemWithTag:selection];
    
    [result addSubview:btn];
    
    return result;
  }
  else if (tableView == _materialTable)
  {
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"MaterialCellID" owner:self];
    
    NSPopUpButton *btn = [result subviews][0];
    
    NSArray *a = [self allMaterialObjects];
    NSMenuItem *itemToSelect = nil;
    for (UObject *mat in a)
    {
      NSMenuItem *i = [NSMenuItem new];
      i.title = [NSString stringWithFormat:@"[%d]%@",[mat.package indexForObject:mat],mat.objectName];
      i.representedObject = mat;
      i.target = self;
      i.action = @selector(changeObjectMaterial:);
      i.tag = row;
      [btn.menu addItem:i];
      if (mat == self.object.materials[row])
        itemToSelect = i;
    }
    if (itemToSelect)
      [btn selectItem:itemToSelect];
    
    return result;
  }
  NSTableCellView *result = [tableView makeViewWithIdentifier:@"teraView" owner:self];
  
  return result;
}

- (void)changeObjectMaterial:(NSMenuItem *)sender
{
  UObject *material = [sender representedObject];
  [self.object.materials replaceObjectAtIndex:sender.tag withObject:material];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self setupMaterialsForNode:self.meshNode object:self.object lod:self.lodSelector.indexOfSelectedItem];
  });
}

- (IBAction)switchRenderMode:(id)sender
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self setupMaterialsForNode:self.meshNode object:self.object lod:self.lodSelector.indexOfSelectedItem];
  });
}

- (IBAction)ok:(NSButton *)sender
{
  NSWindow *host = [(USPanel *)sender.window hostWindow];
  if (host)
    [host endSheet:sender.window returnCode:NSModalResponseOK];
  else
    [self.view.window endSheet:sender.window returnCode:NSModalResponseOK];
}

- (IBAction)cancel:(NSButton *)sender
{
  NSWindow *host = [(USPanel *)sender.window hostWindow];
  if (host)
    [host endSheet:sender.window returnCode:NSModalResponseCancel];
  else
    [self.view.window endSheet:sender.window returnCode:NSModalResponseCancel];
}

- (BOOL)hideProperties
{
  return YES;
}

@end
