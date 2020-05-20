//
//  TerrainEditor.m
//  Real Editor
//
//  Created by VenoMKO on 12.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "TerrainEditor.h"
#import "TextureView.h"
#import "TextureUtils.h"
#import "FPropertyTag.h"
#import "UPackage.h"

@interface TerrainEditor ()
@property (weak) IBOutlet TextureView *imageView;
@property IBOutlet NSButton *visibilitySwitch;
@property IBOutlet NSButton *heightSwitch;
@property BOOL renderVisibilityData;
@end

@implementation TerrainEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self updateImage];
}

- (void)updateImage
{
  if (self.renderVisibilityData)
  {
    self.imageView.image = [self.object visibilityMap];
  }
  else
  {
    self.imageView.image = [self.object heightMap];
  }
}

- (IBAction)exportData:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = self.exportName;
  panel.allowedFileTypes = @[@"png"];
  panel.prompt = @"Export";
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      [self writeCGImage:[self.object heightMap] to:[panel.URL.path.stringByDeletingPathExtension stringByAppendingFormat:@"_TerrainHeightMap"]];
      [self writeCGImage:[self.object visibilityMap] to:[panel.URL.path.stringByDeletingPathExtension stringByAppendingString:@"_TerrainVisibilityMap"]];
      [self.object.info writeToFile:[panel.URL.path stringByAppendingPathExtension:@"txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL path] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
    }
  }];
}

- (void)writeCGImage:(CGImageRef)image to:(NSString *)path
{
  if (![path.pathExtension isEqualToString:@"png"])
  {
    path = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
  }
  WriteImageRef(image, path);
}

- (NSString*)exportName
{
  return [self.object.package.name stringByAppendingFormat:@"_%@", self.object.objectName];
}

- (IBAction)setRenderMode:(id)sender
{
  self.renderVisibilityData = [sender tag];
  self.visibilitySwitch.state = self.renderVisibilityData;
  self.heightSwitch.state = !self.renderVisibilityData;
  [self updateImage];
}

@end
