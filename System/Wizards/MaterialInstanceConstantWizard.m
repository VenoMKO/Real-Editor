//
//  MaterialInstanceConstantWizard.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 05/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "MaterialInstanceConstantWizard.h"
#import "Texture2DWizard.h"
#import "Texture2D.h"
#import "UPackage.h"
#import "FColor.h"

@interface TextureCellView : NSTableCellView
@end

@implementation TextureCellView

+ (NSString *)previewNotificationName
{
  return [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@".TexturePreviewAction"];
}

- (IBAction)previewAction:(id)sender
{
  [[NSNotificationCenter defaultCenter] postNotificationName:[TextureCellView previewNotificationName] object:self.objectValue];
}

@end

@interface TextureMaterialProperty : NSObject
@property (copy) NSString *name;
@property (strong) UObject *value;
+ (instancetype)propertyWithName:(NSString *)name value:(UObject *)value;
@end

@implementation TextureMaterialProperty

+ (instancetype)propertyWithName:(NSString *)name value:(UObject *)value
{
  TextureMaterialProperty *prop = [TextureMaterialProperty new];
  prop.name = name;
  prop.value = value;
  return prop;
}

@end

@interface ScalarMaterialProperty : NSObject
@property (copy) NSString *name;
@property (strong) id value;
+ (instancetype)propertyWithName:(NSString *)name value:(id)value;
@end

@implementation ScalarMaterialProperty

+ (instancetype)propertyWithName:(NSString *)name value:(id)value
{
  ScalarMaterialProperty *prop = [ScalarMaterialProperty new];
  prop.name = name;
  prop.value = value;
  return prop;
}

@end

@interface VectorMaterialProperty : NSObject
@property (copy) NSString *name;
@property (strong, nonatomic) id value;
+ (instancetype)propertyWithName:(NSString *)name value:(id)value;
- (NSString *)displayValue;
- (NSColor *)colorValue;
@end

@implementation VectorMaterialProperty

+ (instancetype)propertyWithName:(NSString *)name value:(id)value
{
  VectorMaterialProperty *prop = [VectorMaterialProperty new];
  prop.name = name;
  prop.value = value;
  return prop;
}

- (NSString *)displayValue
{
  FLinearColor *c = (FLinearColor *)_value;
  return [NSString stringWithFormat:@"R:%.1f G:%.1f B:%.1f A:%.1f",c.r,c.g,c.b,c.a];
}

- (NSColor *)colorValue
{
  FLinearColor *c = (FLinearColor *)_value;
  return [c NSColor];
}

- (void)setColorValue:(NSColor *)color
{
  [self willChangeValueForKey:@"colorValue"];
  [self willChangeValueForKey:@"displayValue"];
  self.value = [FLinearColor linearColorWithColor:color package:nil];
  [self didChangeValueForKey:@"colorValue"];
  [self didChangeValueForKey:@"displayValue"];
}
@end

@interface FColorEditor : NSWindowController
@property (weak) IBOutlet NSTextField *red;
@property (weak) IBOutlet NSTextField *green;
@property (weak) IBOutlet NSTextField *blue;
@property (weak) IBOutlet NSTextField *alpha;
@property (weak) IBOutlet NSComboBox  *nameBox;
@property (weak) IBOutlet NSColorWell *colorWell;
@property (copy, nonatomic) NSColor *color;

@property (assign) BOOL               returnCode;

- (FLinearColor *)linearColor;
- (FColor *)resultColor;
@end

@implementation FColorEditor
@synthesize color = _color;
- (NSColor *)color
{
  NSColor *c = nil;
  @synchronized (self)
  {
    c = _color;
  }
  return [c copy];
}

- (void)setColor:(NSColor *)color
{
  if (color == _color)
    return;
  @synchronized (self)
  {
    [self willChangeValueForKey:@"redComponent"];
    [self willChangeValueForKey:@"greenComponent"];
    [self willChangeValueForKey:@"blueComponent"];
    [self willChangeValueForKey:@"alphaComponent"];
    _color = [color copy];
    [self didChangeValueForKey:@"redComponent"];
    [self didChangeValueForKey:@"greenComponent"];
    [self didChangeValueForKey:@"blueComponent"];
    [self didChangeValueForKey:@"alphaComponent"];
  }
}

- (CGFloat)redComponent
{
  return self.color.redComponent;
}

- (CGFloat)greenComponent
{
  return self.color.greenComponent;
}

- (CGFloat)blueComponent
{
  return self.color.blueComponent;
}

- (CGFloat)alphaComponent
{
  return self.color.alphaComponent;
}

- (void)setRedComponent:(CGFloat)r
{
  NSColor *c = self.color;
  self.color = [NSColor colorWithCalibratedRed:r green:c.greenComponent blue:c.blueComponent alpha:c.alphaComponent];
}

- (void)setGreenComponent:(CGFloat)g
{
  NSColor *c = self.color;
  self.color = [NSColor colorWithCalibratedRed:c.redComponent green:g blue:c.blueComponent alpha:c.alphaComponent];
}

- (void)setBlueComponent:(CGFloat)b
{
  NSColor *c = self.color;
  self.color = [NSColor colorWithCalibratedRed:c.redComponent green:c.greenComponent blue:b alpha:c.alphaComponent];
}

- (void)setAlphaComponent:(CGFloat)a
{
  NSColor *c = self.color;
  self.color = [NSColor colorWithCalibratedRed:c.redComponent green:c.greenComponent blue:c.blueComponent alpha:a];
}

- (BOOL)runForWindow:(NSWindow *)host
{
  if (!self.color)
    self.color = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  [NSApp beginSheet:self.window modalForWindow:host modalDelegate:nil didEndSelector:nil contextInfo:nil];
  [NSApp runModalForWindow:self.window];
  [self.window close];
#pragma GCC diagnostic pop
  return self.returnCode;
}

- (IBAction)ok:(id)sender
{
  self.returnCode = YES;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)cancel:(id)sender
{
  self.returnCode = NO;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (FLinearColor *)linearColor
{
  return [FLinearColor linearColorWithColor:self.colorWell.color package:nil];
}

- (FColor *)resultColor
{
  return [FColor colorWithColor:self.colorWell.color package:nil];
}

- (NSString *)name
{
  return self.nameBox.stringValue;
}

- (void)setName:(NSString *)name
{
  self.nameBox.stringValue = name;
}

@end

@interface TextureEditor : NSWindowController

@property (weak) IBOutlet NSImageView   *preivew;
@property (weak) IBOutlet NSPopUpButton *objects;
@property (strong) NSString               *name;

@property (assign) BOOL               returnCode;
@property (strong) NSOperationQueue     *renderQueue;
@end

@implementation TextureEditor

- (void)awakeFromNib
{
  self.renderQueue = [[NSOperationQueue alloc] init];
  _renderQueue.maxConcurrentOperationCount = 1;
}

- (BOOL)runForWindow:(NSWindow *)host
{
  if (!self.name)
    self.name = @"Untitled";
  [self.objects selectItemAtIndex:0];
  
  if ([self.objects.selectedItem representedObject])
  {
    [self selectObject:nil];
  }
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  [NSApp beginSheet:self.window modalForWindow:host modalDelegate:nil didEndSelector:nil contextInfo:nil];
  [NSApp runModalForWindow:self.window];
  [self.window close];
#pragma GCC diagnostic pop
  return self.returnCode;
}

- (IBAction)ok:(id)sender
{
  self.returnCode = YES;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)cancel:(id)sender
{
  self.returnCode = NO;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)selectObject:(id)sender
{
  [self.renderQueue cancelAllOperations];
  NSBlockOperation *renderOperation = [[NSBlockOperation alloc] init];
  
  __unsafe_unretained TextureEditor *wself = self;
  __unsafe_unretained NSBlockOperation *wrenderOperation = renderOperation;
  [renderOperation addExecutionBlock:^{
    __strong TextureEditor *sself = wself;
    Texture2D *tex = [sself.objects.selectedItem representedObject];
    if (tex.importObject)
    {
      tex = (Texture2D *)[tex.package resolveImport:tex.importObject];
    }
    if (!tex || !tex.exportObject)
    {
      sself.preivew.image = nil;
      return;
    }
    NSImage *img = [tex renderedImageR:YES G:YES B:YES A:NO];
    if (!wrenderOperation.isCancelled)
      sself.preivew.image = img;
  }];
  [self.renderQueue addOperation:renderOperation];
}


@end

@interface MaterialInstanceConstantWizard () <NSComboBoxDelegate>

@property (weak) UPackage                               *package;
@property (copy) NSString                               *title;
@property (assign) NSInteger                            preset;
@property (assign) NSInteger                            existen;
@property (weak) IBOutlet NSPopUpButton                 *existenMaterialsButton;
@property (assign) BOOL                                 preserveProperties;

@property (assign) IBOutlet NSComboBox                  *scalarParameterName;
@property (assign) IBOutlet NSTextField                 *scalarParameterValue;
@property (weak) IBOutlet NSArrayController             *scalarArrayController;

@property (assign) IBOutlet NSComboBox                  *vectorParameterName;
@property (weak) IBOutlet NSArrayController             *vectorArrayController;

@property (weak) IBOutlet NSComboBox                    *textureParameterName;
@property (weak) IBOutlet NSPopUpButton                 *textureParameterValue;
@property (weak) IBOutlet NSArrayController             *textureArrayController;

@property (strong) NSMutableArray                       *mats;

@property (weak) IBOutlet NSPopUpButton                 *premutationMaterialsButton;
@property (strong) NSData                               *premutationData;


@property (strong) IBOutlet FColorEditor                *colorEditor;
@property (strong) IBOutlet TextureEditor               *textureEditor;

@property (assign) BOOL                                 returnCode;

@end

@implementation MaterialInstanceConstantWizard

+ (instancetype)wizardForPackage:(UPackage *)package
{
  MaterialInstanceConstantWizard *wizard = [[MaterialInstanceConstantWizard alloc] initWithWindowNibName:@"NewMaterialInstanceConstant"];
  wizard.package = package;
  return wizard;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
  NSComboBox *sender = [notification object];
  NSString *key = [sender itemObjectValueAtIndex:sender.indexOfSelectedItem];
  if (!key.length)
    return;
  
  if (sender == _scalarParameterName)
  {
    NSDictionary *scalarMap = @{@"Fake_Spec_Intensity" : @"1.0",
                                @"Env_Strength" : @"3.0"};
    
    NSString *value = scalarMap[key];
    if (value.length)
      self.scalarParameterValue.stringValue = value;
  }
}

- (void)windowDidLoad
{
  self.title = @"Untitled_MI";
  [self.existenMaterialsButton removeAllItems];
  [self.premutationMaterialsButton removeAllItems];
  NSArray *mic = [self.package allObjectsOfClass:kClassMaterialInstanceConstant];
  NSArray *mat = [self.package allObjectsOfClass:kClassMaterial];
  
  NSMutableArray *arr = [NSMutableArray arrayWithArray:mic];
  [arr addObjectsFromArray:mat];
  [self willChangeValueForKey:@"hasMaterials"];
  self.mats = arr;
  [self didChangeValueForKey:@"hasMaterials"];
  
  for (UObject *object in arr)
  {
    NSMenuItem *item = [NSMenuItem new];
    item.title = [NSString stringWithFormat:@"[%d]%@ (%@)",[self.package indexForObject:object],object.objectName, object.objectClass];
    item.representedObject = object;
    [self.existenMaterialsButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:item.title action:nil keyEquivalent:@""];
    item.representedObject = object;
    [self.premutationMaterialsButton.menu addItem:item];
  }
  
  NSArray *tex = [self.package allObjectsOfClass:kClassTexture2D];
  [self.textureEditor.objects removeAllItems];
  {
    // TODO: add search item
  }
  for (UObject *object in tex)
  {
    NSMenuItem *item = [NSMenuItem new];
    item.title = [NSString stringWithFormat:@"[%d]%@ (%@)",[self.package indexForObject:object],object.objectName, object.objectClass];
    item.representedObject = object;
    [self.textureEditor.objects.menu addItem:item];
  }
  
  [self.scalarParameterName removeAllItems];
  [self.scalarParameterName addItemsWithObjectValues:@[@"Fake_Spec_Intensity",@"Env_Strength",@"PCC_FacialAttToggle",@"JordonCrossFactor",
                                                       @"WiggleStrength",@"WiggleSpeed",@"WiggleMapUVTiling"]];
  
  [self.vectorParameterName removeAllItems];
  [self.vectorParameterName addItemsWithObjectValues:@[@"Color",@"ControlMaskColor",@"RageModeEmissiveCtrl"]];
  
  [self.textureParameterName removeAllItems];
  [self.textureParameterName addItemsWithObjectValues:@[@"DiffuseMap",@"NormalMap",@"SpecularMap",@"CustomizingMaskMap",@"MaskMap",
                                                        @"Fake_Spec_Cube",@"Env_Cube",@"EmissiveMap",@"Overlay2Map",@"RageModeEmissiveMap",
                                                        @"PCC_HairDiffuseMap"]];
}

- (void)previewAction:(NSNotification *)notification
{
  TextureMaterialProperty *sender = [notification object];
  if (!sender)
    return;
  // TODO: popup
}


- (BOOL)hasMaterials
{
  return self.mats.count;
}

- (BOOL)runForWindow:(NSWindow *)host
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(previewAction:)
                                               name:[TextureCellView previewNotificationName]
                                             object:nil];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  [NSApp beginSheet:self.window modalForWindow:host modalDelegate:nil didEndSelector:nil contextInfo:nil];
  [NSApp runModalForWindow:self.window];
  [self.window close];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
#pragma GCC diagnostic pop
  return self.returnCode;
}

- (IBAction)createScalarValue:(id)sender
{
  NSString *name = self.scalarParameterName.stringValue;
  if (!name.length)
  {
    NSDictionary *err = @{NSLocalizedDescriptionKey : @"Can't add property with out name!",
                          NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
    [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
    return;
  }
  NSNumber *value = @(self.scalarParameterValue.doubleValue);
  for (ScalarMaterialProperty *prop in self.scalarArrayController.arrangedObjects)
  {
    if ([prop.name isEqualToString:name])
    {
      NSDictionary *err = @{NSLocalizedDescriptionKey : @"Property with this name already exists!",
                            NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
      [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
      return;
    }
  }
  ScalarMaterialProperty *prop = [ScalarMaterialProperty propertyWithName:name value:value];
  [self.scalarArrayController addObject:prop];
}

- (IBAction)removeScalarValue:(id)sender
{
  if (!self.scalarArrayController.selectedObjects.count)
    return;
  ScalarMaterialProperty *prop = [self.scalarArrayController.selectedObjects firstObject];
  [self.scalarArrayController removeObject:prop];
}

- (IBAction)createVectorValue:(id)sender
{
  if ([self.colorEditor runForWindow:self.window])
  {
    
    NSString *name = [self.colorEditor name];
    if (!name.length)
    {
      NSDictionary *err = @{NSLocalizedDescriptionKey : @"Can't add property with out name!",
                            NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
      [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
      return;
    }
    for (VectorMaterialProperty *prop in self.vectorArrayController.arrangedObjects)
    {
      if ([prop.name isEqualToString:name])
      {
        NSDictionary *err = @{NSLocalizedDescriptionKey : @"Property with this name already exists!",
                              NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
        [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
        return;
      }
    }
    VectorMaterialProperty *prop = [VectorMaterialProperty propertyWithName:name value:self.colorEditor.linearColor];
    [self.vectorArrayController addObject:prop];
  }
}

- (IBAction)editVectorValue:(id)sender
{
  if (!self.vectorArrayController.selectedObjects.count)
    return;
  VectorMaterialProperty *eprop = [[self.vectorArrayController selectedObjects] firstObject];
  self.colorEditor.color = eprop.colorValue;
  self.colorEditor.name = eprop.name;
  if ([self.colorEditor runForWindow:self.window])
  {
    NSString *name = [self.colorEditor name];
    if (!name.length)
    {
      NSDictionary *err = @{NSLocalizedDescriptionKey : @"Can't add property with out name!",
                            NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
      [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
      return;
    }
    for (VectorMaterialProperty *prop in self.vectorArrayController.arrangedObjects)
    {
      if ([prop.name isEqualToString:name] && prop != eprop)
      {
        NSDictionary *err = @{NSLocalizedDescriptionKey : @"Property with this name already exists!",
                              NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
        [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
        return;
      }
    }
    eprop.name = name;
    eprop.value = self.colorEditor.linearColor;
    [self.vectorArrayController rearrangeObjects];
  }
}

- (IBAction)createTextureValue:(id)sender
{
  if ([self.textureEditor runForWindow:self.window])
  {
    NSString *name = [self.textureEditor name];
    if (!name.length)
    {
      NSDictionary *err = @{NSLocalizedDescriptionKey : @"Can't add property with out name!",
                            NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
      [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
      return;
    }
    for (TextureMaterialProperty *prop in self.textureArrayController.arrangedObjects)
    {
      if ([prop.name isEqualToString:name])
      {
        NSDictionary *err = @{NSLocalizedDescriptionKey : @"Property with this name already exists!",
                              NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
        [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]];
        return;
      }
    }
    TextureMaterialProperty *prop = [TextureMaterialProperty propertyWithName:name value:[self.textureEditor.objects.selectedItem representedObject]];
    [self.textureArrayController addObject:prop];
  }
}

- (IBAction)createImportedTextureValue:(id)sender
{
  
}

- (IBAction)setupPremutationFromMaterial:(id)sender
{
  
}

- (IBAction)resetPremutation:(id)sender
{
  self.premutationData = nil;
}

- (IBAction)cancel:(id)sender
{
  self.returnCode = NO;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)ok:(id)sender
{
  self.returnCode = YES;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

@end

