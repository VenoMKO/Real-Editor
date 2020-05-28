//
//  SpeedTreeEditor.m
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "SpeedTreeEditor.h"

@interface SpeedTreeEditor ()

@end

@implementation SpeedTreeEditor
@dynamic object;

- (NSString *)exportName
{
  return self.object.objectName;
}

- (NSString *)exportExtension
{
  return @"spt";
}

- (IBAction)exportData:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = [self.exportName stringByAppendingPathExtension:self.exportExtension];
  panel.prompt = @"Export";
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsExportPath];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSData *export = [self.object exportWithOptions:nil];
      [export writeToURL:panel.URL atomically:YES];
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:kSettingsExportPath];
    }
  }];
}

- (IBAction)importData:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.prompt = @"Import";
  panel.allowedFileTypes = @[self.exportExtension];
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsImportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSData *data = [NSData dataWithContentsOfURL:panel.URL];
      if (data)
      {
        self.object.sptData = data;
        [self.object setDirty:YES];
      }
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsImportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
    }
  }];
}

@end
