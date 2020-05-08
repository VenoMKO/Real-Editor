//
//  UObjectEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "Texture2DEditor.h"
#import "TextureView.h"
#import "TextureUtils.h"
#import "FPropertyTag.h"
#import "UPackage.h"

@interface Texture2DEditor () <NSOpenSavePanelDelegate>
@property (weak) IBOutlet TextureView *imageView;
@property (assign) Texture2DExportOptions saveMode;

@property (assign) IBOutlet NSButton *r;
@property (assign) IBOutlet NSButton *g;
@property (assign) IBOutlet NSButton *b;
@property (assign) IBOutlet NSButton *a;

@property (assign) BOOL              importIsNormal;
@property (assign) BOOL              importIsNormalEnabled;
@property (assign) BOOL              importGenMips;
@property (assign) BOOL              importGenMipsEnabled;
@property (assign) NSInteger         importFormat;
@property (assign) BOOL              importFormatEnabled;
@property (assign) BOOL              exportSwizzleY;

@property (weak) IBOutlet NSPopUpButton   *exportType;
@property (weak) NSSavePanel              *currentPanel;

@end

@implementation Texture2DEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.r.state = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsTextureRenderR];
  self.g.state = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsTextureRenderG];
  self.b.state = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsTextureRenderB];
  self.a.state = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsTextureRenderA];
  self.importIsNormal = [self.object.objectName hasSuffix:@"norm"];
  self.importGenMips = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsTextureGenMipMap];
  self.importFormat = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsTextureGenMipMap];
  self.saveMode = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsTextureSaveMode];
  [self updateImage];
}

- (void)updateImage
{
  NSImage *img = [self.object forceExportedRenderedImageR:_r.state G:_g.state B:_b.state A:_a.state invert:NO];
  self.imageView.image = [img CGImageForProposedRect:NULL context:NULL hints:NULL];
}

- (IBAction)setChannel:(NSButton *)sender
{
  if (sender == _r)
  {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kSettingsTextureRenderR];
  }
  if (sender == _g)
  {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kSettingsTextureRenderG];
  }
  if (sender == _b)
  {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kSettingsTextureRenderB];
  }
  if (sender == _a)
  {
    [[NSUserDefaults standardUserDefaults] setBool:sender.state forKey:kSettingsTextureRenderA];
  }
  if (!sender)
  {
    [[NSUserDefaults standardUserDefaults] setBool:_r.state forKey:kSettingsTextureRenderR];
    [[NSUserDefaults standardUserDefaults] setBool:_g.state forKey:kSettingsTextureRenderG];
    [[NSUserDefaults standardUserDefaults] setBool:_b.state forKey:kSettingsTextureRenderB];
    [[NSUserDefaults standardUserDefaults] setBool:_a.state forKey:kSettingsTextureRenderA];
  }
  
  NSImage *img = [self.object forceExportedRenderedImageR:_r.state G:_g.state B:_b.state A:_a.state invert:NO];
  self.imageView.image = [img CGImageForProposedRect:NULL context:NULL hints:NULL];
}

- (IBAction)invertChannels:(id)sender
{
  _r.state = !_r.state;
  _g.state = !_g.state;
  _b.state = !_b.state;
  _a.state = !_a.state;
  [self setChannel:nil];
}

- (NSString *)exportName
{
  return self.object.objectName;
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
  
  self.currentPanel = panel;
  [self switchExportType:nil];
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSData *export = nil;
      if (self.object.exportObject.exportFlags & EF_ForcedExport)
      {
        UObject *tmp = [self.object.package resolveForcedExport:self.object.exportObject];
        if (tmp)
        {
          export = [tmp exportWithOptions:@{@"mode" : @(self.exportType.selectedTag),
                                          @"path" : panel.URL.path,
                                          @"swizzle" : @(_exportSwizzleY)}];
        }
      }
      else
      {
        export = [self.object exportWithOptions:@{@"mode" : @(self.exportType.selectedTag),
                                                  @"path" : panel.URL.path,
                                                  @"swizzle" : @(_exportSwizzleY)}];
      }
      
      if (!export)
        return;
      NSString *path = [[panel.URL.path stringByDeletingPathExtension] stringByAppendingPathExtension:@"dds"];
      [export writeToURL:[NSURL fileURLWithPath:path] atomically:YES];
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL path] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
      [[NSUserDefaults standardUserDefaults] setObject:@(self.saveMode) forKey:kSettingsExportMode];
    }
  }];
}

- (IBAction)switchExportType:(id)sender
{
  NSString *ext = @"";
  switch (self.exportType.selectedTag)
  {
    case 0:
      ext = @"dds";
      break;
      
    case 1:
      ext = @"tga";
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
  panel.allowedFileTypes = @[@"dds",@"tga", @"bmp", @"png", @"tiff", @"tif"];
  panel.accessoryView = self.importOptionsView;
  panel.accessoryViewDisclosed = YES;
  panel.delegate = self;
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsImportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  switch ([self.object pixelFormat])
  {
    case PF_DXT1:
      self.importFormat = 1;
      break;
    case PF_DXT3:
      self.importFormat = 2;
      break;
    case PF_DXT5:
      self.importFormat = 3;
      break;
    case PF_A8R8G8B8:
      self.importFormat = 4;
      break;
    case PF_G8:
      self.importFormat = 5;
      break;
    default:
    case PF_None:
      break;
  }
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSDictionary *result = nil;
      if ([[panel.URL pathExtension] isEqualToString:panel.allowedFileTypes[0]]) //DDS
      {
        result = MipmapsFromDDS(panel.URL,self.object.package);
      }
      else
      {
        EPixelFormat pf = PF_None;
        switch (self.importFormat)
        {
          case 0:
          default:
            pf = PF_None;
            break;
          case 1:
            pf = PF_DXT1;
            break;
          case 2:
            pf = PF_DXT3;
            break;
          case 3:
            pf = PF_DXT5;
            break;
          case 4:
            pf = PF_A8R8G8B8;
            break;
          case 5:
            pf = PF_G8;
            break;
        }
        result = MipmapsFromNVTT(panel.URL,self.object.package,pf,_importIsNormal,!_importIsNormal,_importGenMips);
        [[NSUserDefaults standardUserDefaults] setInteger:self.saveMode forKey:kSettingsTextureSaveMode];
      }
      
      if (!result[@"mips"])
      {
        DLog(@"Failed to get mips from \"%@\"",panel.URL.path);
        NSAppError(self.object.package, result[@"err"] ? result[@"err"] : @"Unknown error!");
        return;
      }
      
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsImportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
      
      if (![self.object importMipmaps:result])
        [self updateImage];
    }
  }];
}

- (void)panelSelectionDidChange:(NSOpenPanel *)sender
{
  NSURL *url = sender.URL;
  BOOL enabled = ![[url pathExtension] isEqualToString:@"dds"];
  self.importIsNormalEnabled = enabled;
  self.importGenMipsEnabled = enabled;
  self.importFormatEnabled = enabled;
}

- (NSString *)exportExtension
{
  switch (self.saveMode) {
    default:
    case Texture2DExportOptionsDDS:
      return @"dds";
    case Texture2DExportOptionsTGA:
      return @"tga";
  }
}

@end

@implementation ShadowMapTexture2DEditor

@end

@implementation LightMapTexture2DEditor

@end

@implementation TerrainWeightMapTextureEditor

@end
