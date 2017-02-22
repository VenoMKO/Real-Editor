//
//  PreferencesController.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 24/10/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "PreferencesController.h"

@interface PreferencesController ()
@property (assign) BOOL loadDepends;
@property (copy) NSString *gamePath;
@property (assign) BOOL loadTextures;
@property (assign) BOOL loadLights;
@property (assign) NSInteger aaMode;
@property (assign) CGFloat fov;
@property (assign) NSInteger cacheSize;
@property (assign) BOOL checkForUpdates;
@property (assign) BOOL logging;
@property (assign) NSInteger retention;
@end

@implementation PreferencesController

- (id)init
{
  if ((self = [super initWithWindowNibName:@"Preferences"]))
  {
    [self loadPreferences];
  }
  return self;
}

- (void)loadPreferences
{
  NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
  self.loadDepends = [d boolForKey:kSettingsLookForDepends];
  self.gamePath = [d objectForKey:kSettingsProjectDir];
  self.loadTextures = [d boolForKey:kSettingsLoadTextures];
  self.aaMode = [d integerForKey:kSettingsAAMode];
  self.loadLights = [d boolForKey:kSettingsLoadLights];
  self.fov = [d doubleForKey:kSettingsFov];
  self.cacheSize = [d integerForKey:kSettingsCacheSize];
  self.checkForUpdates = [d boolForKey:kSettingsCheckForUpdates];
  self.logging = [d boolForKey:kSettingsLogging];
  self.retention = [d integerForKey:kSettingsRetention];
}

- (void)windowDidLoad
{
  [super windowDidLoad];
}

- (IBAction)okClicked:(id)sender
{
  NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
  [d setBool:self.loadDepends forKey:kSettingsLookForDepends];
  [d setInteger:self.aaMode forKey:kSettingsAAMode];
  [d setObject:self.gamePath forKey:kSettingsProjectDir];
  [d setBool:self.loadTextures forKey:kSettingsLoadTextures];
  [d setBool:self.loadLights forKey:kSettingsLoadLights];
  [d setDouble:self.fov forKey:kSettingsFov];
  [d setInteger:self.cacheSize forKey:kSettingsCacheSize];
  [d setBool:self.checkForUpdates forKey:kSettingsCheckForUpdates];
  [d setBool:self.logging forKey:kSettingsLogging];
  [d setInteger:self.retention forKey:kSettingsRetention];
  [d synchronize];
  [self.window close];
}

- (IBAction)showLogs:(id)sender
{
  [[NSWorkspace sharedWorkspace] openFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/RealEditor"]];
}

- (IBAction)clearLogs:(id)sender
{
  NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/RealEditor"];
  [[NSFileManager defaultManager] removeItemAtPath:logPath error:NULL];
  [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:nil];
}

- (IBAction)cancelClicked:(id)sender
{
  [self loadPreferences];
  [self.window close];
}

- (IBAction)browseClicked:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  
  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelOKButton)
    {
      self.gamePath = [panel.URL path];
    }
  }];
}

@end
