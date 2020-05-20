//
//  UObjectEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObjectEditor.h"
#import "FPropertyTag.h"

@interface UObjectEditor ()
@property (weak) NSView *saveAccessoryView;
@property (strong) RawExportOptions     *rawExportOptions;
@property (assign) UObjectExportOptions saveMode;
@end

@implementation UObjectEditor

- (void)awakeFromNib
{
  self.rawExportOptions = [[RawExportOptions alloc] initWithNibName:@"RawExportOptions" bundle:[NSBundle mainBundle]];
  self.rawExportOptions.parent = self;
}

- (NSString *)exportOptionsXib
{
  return nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if (!self.object.rawDataOffset) // Read object data if have not yet
    [self.object properties];
}

- (NSString *)exportName
{
  return [self.object.objectName stringByAppendingFormat:@"(%@)",self.object.objectClass];
}

- (NSString *)rawExportExtension
{
  return @"bin";
}

- (NSString *)exportExtension
{
  return @"bin";
}

- (IBAction)exportRaw:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = [self.exportName stringByAppendingPathExtension:self.rawExportExtension];
  panel.accessoryView = self.rawExportOptions.view;
  panel.prompt = @"Export";
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  self.saveMode = MIN(2,MAX(0,[[[NSUserDefaults standardUserDefaults] objectForKey:kSettingsExportMode] intValue]));
  
  NSArray *arg = [[NSProcessInfo processInfo] arguments];
  if (self.saveMode == UObjectExportOptionsData && self.object.dataSize)
    self.rawExportOptions.exportDataModeButton.state = NSControlStateValueOn;
  else if (self.saveMode == UObjectExportOptionsAll && self.object.dataSize)
    self.rawExportOptions.exportAllModeButton.state = NSControlStateValueOn;
  else
    self.rawExportOptions.exportPropertiesModeButton.state = NSControlStateValueOn;
  
  if ([arg indexOfObject:@"-noProps"] == NSNotFound)
  {
    self.rawExportOptions.exportDataModeButton.enabled = self.object.dataSize;
    self.rawExportOptions.exportAllModeButton.enabled = self.object.dataSize;
  }
  else
  {
    self.rawExportOptions.exportDataModeButton.enabled = NO;
    self.rawExportOptions.exportPropertiesModeButton.enabled = NO;
    self.rawExportOptions.exportAllModeButton.state = NSControlStateValueOn;
  }
  
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSData *export = [self.object exportWithOptions:@{@"mode" : @(self.saveMode), @"raw" : @(YES)}];
      [export writeToURL:panel.URL atomically:YES];
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.object.objectClass]];
      [[NSUserDefaults standardUserDefaults] setObject:@(self.saveMode) forKey:kSettingsExportMode];
    }
  }];
}

- (IBAction)exportData:(id)sender
{
}

- (IBAction)switchSaveMode:(id)sender
{
  self.saveMode = (int)[sender tag];
}

- (NSArray *)propertiesViews
{
  NSArray *tags = [self.object properties];
  NSMutableArray *views = [NSMutableArray new];
  for (FPropertyTag *tag in tags)
  {
    NSView *v = [(PropertyController *)tag.controller view];
    if (v)
      [views addObject:v];
  }
  return views;
}

- (BOOL)hideProperties
{
  return NO;
}

@end

@interface RawExportOptions ()
@property (nonatomic, assign) UObjectExportOptions saveMode;
@end

@implementation RawExportOptions

- (void)setSaveMode:(UObjectExportOptions)saveMode
{
  [self willChangeValueForKey:@"SaveMode"];
  self.parent.saveMode = saveMode;
  _saveMode = saveMode;
  [self didChangeValueForKey:@"SaveMode"];
}

- (IBAction)switchSaveMode:(id)sender
{
  self.saveMode = (int)[sender tag];
}

@end
