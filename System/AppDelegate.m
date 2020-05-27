//
//  AppDelegate.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "AppDelegate.h"
#import "PackageController.h"
#import "UObjectEditor.h"
#import "PreferencesController.h"
#import "UObject.h"
#import "FReadable.h"

const int MenuItemTagPackageNew = 101;
const int MenuItemTagPackageInfo = 103;
const int MenuItemTagObjectExport = 400;
const int MenuItemTagObjectExportRaw = 401;
const int MenuItemTagObjectExportProperties = 402;

#ifndef DEBUG
#define DEBUG 0
#endif

const BOOL MenuItemDebugVisible = DEBUG;

#define SECONDS_PRE_DAY 86400

@interface AppDelegate ()

@property (strong) NSMutableArray *controllers;
@property (strong) PreferencesController *preferencesController;

@property (assign) IBOutlet NSMenuItem  *menuItemNew;
@property (assign) IBOutlet NSMenuItem  *menuItemSave;
@property (assign) IBOutlet NSMenuItem  *menuItemSaveAs;
@property (assign) IBOutlet NSMenuItem  *menuItemDebugDecompressedSave;
@property (assign) IBOutlet NSMenuItem *menuItemDebug;

- (IBAction)openFile:(id)sender;

@end

@implementation AppDelegate

+ (void)initialize
{
  [[NSUserDefaults standardUserDefaults] registerDefaults:Defaults()];
}

- (void)applicationDidFinishLaunching:(__unused NSNotification *)aNotification
{
#ifndef DEBUG
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLogging])
  {
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Logs/RealEditor/"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath])
      [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSDateFormatter *f = [NSDateFormatter new];
    f.dateFormat = @"dd_MM_yyyy_HH_mm_ss";
    logPath = [logPath stringByAppendingFormat:@"/RE_%@.log",[f stringFromDate:[NSDate date]]];
    freopen([logPath fileSystemRepresentation], "w", stderr);
  }
#endif
  
  [self cleanupLogsIfNeeded];
  
  
  [self.menuItemDebug setHidden:!MenuItemDebugVisible];
#ifdef DEBUG
  NSArray *array = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
  if (array.count)
    [self application:[NSApplication sharedApplication] openFile:[array.firstObject path]];
#else
  [self openFile:nil];
#endif
}

- (IBAction)showPreferences:(id)sender
{
  if (!self.preferencesController)
    self.preferencesController = [PreferencesController new];
  
  [self.preferencesController showWindow:nil];
}

- (IBAction)openFile:(__unused id)sender
{
  NSOpenPanel *openpanel = [NSOpenPanel new];
  NSArray *array = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
  
  for (NSURL *url in array) {
    NSString *p = [[url URLByDeletingLastPathComponent] path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:p]) {
      if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        openpanel.directoryURL = url;
      } else {
        openpanel.directoryURL = [url URLByDeletingLastPathComponent];
      }
      break;
    }
  }
  
  [openpanel setTitle:@"Open package..."];
  NSArray *types = @[@"gpk",@"gmp",@"upk",@"umap",@"u"];
  
  [openpanel setAllowedFileTypes:types];
  [openpanel setAllowsMultipleSelection:NO];
  [openpanel setAllowsOtherFileTypes:NO];
  
  [openpanel beginWithCompletionHandler:^(NSInteger result) {
    if (result && [openpanel URL]) {
      [self application:[NSApplication sharedApplication] openFile:[[openpanel URL] path]];
    }
  }];
}

- (BOOL)application:(__unused NSApplication *)sender openFile:(NSString *)filename
{
  if (![[NSFileManager defaultManager] fileExistsAtPath:filename])
    return NO;
  if (!self.controllers)
    self.controllers = [NSMutableArray array];
  
  PackageController *ctrl = [PackageController controllerForPackageAtPath:filename];
  if (!ctrl)
    return NO;
  [self.controllers addObject:ctrl];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
  [ctrl.window makeKeyAndOrderFront:nil];
  return YES;
}

- (NSString *)validateWindowTitleForController:(PackageController *)controller
{
  NSString *titleCandidate = nil;
  if (controller.package.originalURL)
    titleCandidate = [controller.package.originalURL lastPathComponent];
  else
    titleCandidate = [[controller.package.stream url] lastPathComponent];
  return titleCandidate;
}

- (PackageController *)activeController
{
  return (PackageController *)[[[NSApplication sharedApplication] mainWindow] delegate];
}

- (IBAction)save:(id)sender
{
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  [alert setMessageText:@"Save package"];
  [alert setInformativeText:@"You will overwrite the original package!"];
  [alert setAlertStyle:NSAlertStyleWarning];
  [alert setShowsSuppressionButton:NO];
  PackageController *activeController = self.activeController;
  [alert beginSheetModalForWindow:self.activeController.window completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSAlertFirstButtonReturn)
    {
      [activeController performSelectorOnMainThread:@selector(saveTo:) withObject:nil waitUntilDone:NO];
    }
  }];
}

- (IBAction)saveAs:(id)sender
{
  PackageController *activeController = self.activeController;
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.nameFieldStringValue = [activeController.package.name stringByAppendingPathExtension:activeController.package.extension];
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsSaveAsPath];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]];
  
  panel.accessoryView = activeController.saveSettingsView;
  [panel beginSheetModalForWindow:activeController.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
      [activeController performSelectorOnMainThread:@selector(saveTo:) withObject:panel.URL waitUntilDone:NO];
  }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  PackageController *c = [self activeController];
  if (menuItem == self.menuItemDebugDecompressedSave)
    return c.package.originalURL ? YES : NO;
  if (menuItem == self.menuItemSave)
    return c.package.isDirty;
  if (menuItem.tag == MenuItemTagPackageNew)
    return NO; // Not implemented
  if (menuItem.tag == MenuItemTagObjectExportRaw || menuItem.tag == MenuItemTagObjectExportProperties)
  {
    return [c.selectedObject exportObject] != nil;
  }
  else if (menuItem.tag == MenuItemTagObjectExport)
    return [c.selectedObject canExport];
  else if (menuItem.tag == MenuItemTagPackageInfo)
    return c ? YES : NO;
  return YES;
}

- (void)controllerWillClose:(PackageController *)controller
{
  [self.controllers removeObject:controller];
}

- (IBAction)_debugSaveDecompressed:(id)sender
{
#ifdef DEBUG
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.nameFieldStringValue = [self.activeController.package name];
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsSaveAsPath];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]];
  NSURL *url = self.activeController.package.stream.url;
  [panel beginSheetModalForWindow:self.activeController.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
      [[NSFileManager defaultManager] copyItemAtURL:url toURL:panel.URL error:nil];
  }];
#endif
}

- (IBAction)_debugSaveExportsTable:(id)sender
{
#ifdef DEBUG
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.nameFieldStringValue = [[self.activeController.package name] stringByAppendingPathExtension:@"plist"];
  UPackage *p = self.activeController.package;
  [panel beginSheetModalForWindow:self.activeController.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      NSDictionary *result = [p dummpExports];
      [result writeToURL:panel.URL atomically:YES];
    }
  }];
#endif
}

- (IBAction)selectObjectAtIndex:(id)sender
{
#ifdef DEBUG
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Object index:"];
  [alert addButtonWithTitle:@"Ok"];
  [alert addButtonWithTitle:@"Cancel"];
  
  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
  [input setStringValue:@""];
  
  [alert setAccessoryView:input];
  PackageController *c = [self activeController];
  [alert beginSheetModalForWindow:c.window completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSAlertFirstButtonReturn)
    {
      NSInteger idx = [input integerValue];
      [c _debugSelectObjectWithIndex:idx];
    }
  }];
#endif
}

- (IBAction)packageShowInfo:(id)sender
{
  if ([[self activeController].infoPanel isVisible])
    [[self activeController].infoPanel makeKeyAndOrderFront:sender];
  else
  {
    NSRect parentFrame = [self activeController].window.frame;
    NSRect infoFrame = [self activeController].infoPanel.frame;
    [[self activeController].infoPanel setFrameOrigin:NSMakePoint(NSMidX(parentFrame) - NSWidth(infoFrame) * .5, NSMidY(parentFrame) - NSHeight(infoFrame) * .5)];
    [[self activeController].window addChildWindow:[self activeController].infoPanel ordered:NSWindowAbove];
    [[self activeController].infoPanel makeKeyAndOrderFront:sender];
  }
}

- (IBAction)exportObjectProperties:(id)sender
{
  [[self activeController] exportProperties:sender];
}

- (IBAction)exportObject:(id)sender
{
  [[self activeController].selectedObject.editor exportData:sender];
}

- (IBAction)exportObjectRaw:(id)sender
{
  [[self activeController].selectedObject.editor exportRaw:sender];
}

- (void)cleanupLogsIfNeeded
{
  NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Logs/RealEditor/"];
  NSArray *logNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logPath error:NULL];
  NSDateFormatter *f = [NSDateFormatter new];
  f.dateFormat = @"dd_MM_yyyy_HH_mm_ss";
  NSInteger retention = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsRetention];
  retention *= SECONDS_PRE_DAY;
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLogging])
    retention = 0;
  for (NSString *logName in logNames)
  {
    if ([logName hasPrefix:@"RE_"])
    {
      NSString *dateString = [[logName stringByReplacingOccurrencesOfString:@"RE_" withString:@""] stringByDeletingPathExtension];
      NSDate *date = [f dateFromString:dateString];
      
      if ([[date dateByAddingTimeInterval:(NSTimeInterval)retention] isLessThan:[NSDate date]])
      {
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[logPath stringByAppendingPathComponent:logName] error:&err];
        if (err)
          DLog(@"[Logs]%@",err.description);
      }
    }
  }
}

@end
