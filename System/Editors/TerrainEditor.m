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
  //NSImage *img = [self.object forceExportedRenderedImageR:_r.state G:_g.state B:_b.state A:_a.state invert:NO];
  //self.imageView.image = [img CGImageForProposedRect:NULL context:NULL hints:NULL];
  self.imageView.image = [self.object heightMap];
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
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:[panel.URL.path stringByAppendingPathExtension:@"png"]];
      CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
      if (!destination)
      {
        return;
      }

      CGImageDestinationAddImage(destination, self.imageView.image, nil);

      if (!CGImageDestinationFinalize(destination))
      {
        CFRelease(destination);
        return;
      }

      CFRelease(destination);
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL path] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
      
      [self.object.info writeToFile:[panel.URL.path stringByAppendingPathExtension:@"txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
  }];
}

- (NSString*)exportName
{
  return [self.object.package.name stringByAppendingFormat:@"_%@", self.object.objectName];
}

@end
