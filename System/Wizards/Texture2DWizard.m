//
//  Texture2DWizard.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 05/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "Texture2DWizard.h"
#import "Texture2D.h"
#import "TextureUtils.h"
#import "FGUID.h"
#import "FString.h"
#import "FPropertyTag.h"

@interface Texture2DWizard ()
@property (weak) UPackage                               *package;
@property (assign) BOOL                                 returnCode;

@property (copy) NSString                               *name;
@property (copy) NSString                               *path;
@property (assign) NSInteger                            compression;
@property (assign) EPixelFormat                         pixelFromat;
@property (strong) NSImage                              *preview;
@property (assign) TextureGroup                         textureGroup;
@property (assign) BOOL                                 isNormalMap;

@property (weak) IBOutlet NSPopUpButton                 *textureGroupButton;
@property (weak) IBOutlet NSPopUpButton                 *textureCompressionButton;
@property (weak) IBOutlet NSButton                      *previewAlphaButton;
@end

@implementation Texture2DWizard

+ (instancetype)wizardForPackage:(UPackage *)package
{
  Texture2DWizard *wizard = [[Texture2DWizard alloc] initWithWindowNibName:@"NewTexture2D"];
  wizard.package = package;
  wizard.name = @"Untitled";
  wizard.compression = COMPRESSION_LZO;
  wizard.textureGroup = TEXTUREGROUP_None;
  return wizard;
}

- (BOOL)runForWindow:(NSWindow *)host
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  [NSApp beginSheet:self.window modalForWindow:host modalDelegate:nil didEndSelector:nil contextInfo:nil];
  [NSApp runModalForWindow:self.window];
  [self.window close];
#pragma GCC diagnostic pop
  return self.returnCode;
}

- (IBAction)cancel:(id)sender
{
  self.returnCode = NO;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)ok:(id)sender
{
  NSArray *objects = self.package.allExports;
  for (UObject *object in objects)
  {
    if ([object.objectName isEqualToString:self.name])
    {
      NSBeep();
      NSDictionary *err = @{NSLocalizedDescriptionKey : @"Object with this name already exists!",
                            NSLocalizedRecoverySuggestionErrorKey : @"Try another name."};
      [NSApp presentError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:err]
           modalForWindow:self.window
                 delegate:nil
       didPresentSelector:nil
              contextInfo:nil];
      return;
    }
  }
  self.returnCode = YES;
  [NSApp endSheet:self.window];
  [NSApp stopModal];
}

- (IBAction)openFile:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.prompt = @"Import";
  panel.allowedFileTypes = @[@"dds",@"tga"];
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsImportPath stringByAppendingFormat:@".Texture2D"]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      [self setImagePreview:panel.URL];
      self.name = [[panel.URL lastPathComponent] stringByDeletingPathExtension];
    }
  }];
}

- (void)setImagePreview:(NSURL *)url
{
  if ([[url pathExtension] isEqualToString:@"dds"]) //DDS
  {
    self.preview = DecompressDDS([url path],YES,YES,YES,self.previewAlphaButton.state);
  }
  else if ([[url pathExtension] isEqualToString:@"tga"]) //TGA
  {
    self.preview = [[NSImage alloc] initWithContentsOfURL:url];
  }
  self.path = [url path];
}

- (IBAction)togglePreviewAlpha:(id)sender
{
  if (!self.path.length)
    return;
  [self setImagePreview:[NSURL fileURLWithPath:self.path]];
}

- (IBAction)selectIsNormalMap:(id)sender
{
  self.isNormalMap = !self.isNormalMap;
  if (self.isNormalMap)
    [self.textureGroupButton selectItemWithTag:TEXTUREGROUP_CharacterNormalMap];
}

- (FObject *)buildObject
{
  FObjectExport *obj = [self.package createExportObject:self.name class:kClassTexture2D];
  Texture2D *tex = [Texture2D newWithPackage:self.package];
  obj.object = tex;
  tex.exportObject = obj;
  obj.objectFlags = RF_LoadForServer | RF_LoadForEdit | RF_LoadForClient | RF_Public | RF_Standalone;
  [obj.object setDirty:YES];
  tex.guid = [FGUID guid];
  tex.source = [FString stringWithString:self.path];
  [tex importMipmaps:CompressedMipmapsFromNVTT([NSURL fileURLWithPath:self.path],self.package, self.pixelFromat, (int)self.compression, self.isNormalMap, !self.isNormalMap, YES)];
  return obj;
}

@end
