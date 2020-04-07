//
//  PackageController.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "PackageController.h"
#import "ObjectController.h"
#import "ContextedOutlineView.h"
#import "AppDelegate.h"
#import "UObject.h"
#import "FString.h"
#import "MaterialInstanceConstantWizard.h"
#import "Texture2DWizard.h"
#import "ImportWizard.h"

#define MAX_HISTORY 100

@interface PackageController () <NSSearchFieldDelegate>

@property (strong) NSMutableArray               *cache;
@property (strong) NSMutableArray               *operations;

@property (weak) IBOutlet NSSplitView           *splitView;
@property (assign) CGFloat                      propertiesDivierWidth;

// Project navigator
@property (strong) ObjectController             *exportController;
@property (strong) ImportController             *importController;
@property (weak) IBOutlet NSStackView           *propertiesStack;
@property (weak) IBOutlet ContextedOutlineView  *exportsView;
@property (weak) IBOutlet ContextedOutlineView  *importsView;
@property (weak) IBOutlet NSTableView           *namesView;
@property (weak) IBOutlet NSView                *editorContainer;
@property (weak) IBOutlet NSButton              *exportsButton;
@property (weak) IBOutlet NSButton              *importsButton;
@property (weak) IBOutlet NSButton              *namesButton;
@property (assign) NSInteger                    activeTable;
@property (weak) IBOutlet NSButton              *addExportButton;
@property (weak) IBOutlet NSSearchField         *exportsSearchField;
@property (weak) IBOutlet NSSearchField         *importsSearchField;
@property (weak) IBOutlet NSSearchField         *namesSearchField;
@property (weak) IBOutlet NSVisualEffectView    *navigatorEffectView;

// History
@property (strong) NSMutableArray               *selectionHistory;
@property (assign) NSUInteger                   historyIndex;
@property (nonatomic, assign) BOOL              canGoBack;
@property (nonatomic,assign) BOOL               canGoForward;
@property (assign) BOOL                         igonreHistory;

// Cooking
@property (strong) IBOutlet NSPanel             *progressPanel;
@property (weak) IBOutlet NSProgressIndicator   *progressBar;
@property (weak) IBOutlet NSTextField           *progressDescription;
@property (weak) IBOutlet NSTextField           *progressState;
@property (weak) IBOutlet NSButton              *progressCancelButton;

// Settings
@property (assign) IBOutlet NSButton            *saveSettingsModeDefault;
@property (assign) IBOutlet NSButton            *saveSettingsModePreserveOffsets;
@property (assign) NSInteger                    saveSettingsCompression;
@property (assign) NSInteger                    saveSettingsPropagateCompression;
@property (assign) BOOL                         saveSettingsFixChecksum;
@property (assign) BOOL                         saveSettingsUpdateGen;
@property (assign) BOOL                         saveSettingsSingleChunk;
@property (assign) BOOL                         saveSettingsForceFullCooking;
@property (assign) BOOL                         saveSettingsCanForceCook;
@property (assign) BOOL                         saveSettingsCanCompress;

@property (assign) BOOL                         allowExportWizards;
@property (assign) BOOL                         allowImportsWizards;
@property (assign) BOOL                         allowNamesWizards;

@property (strong) NSString                     *exportsPredicate;
@property (strong) NSString                     *importsPredicate;
@property (strong) NSString                     *namesPredicate;

// Package info

@property (copy) NSString                       *infoName;
@property (copy) NSString                       *infoFolderName;
@property (copy) NSString                       *infoLocation;
@property (copy) NSString                       *infoVersion;
@property (copy) NSString                       *infoCooker;
@property (copy) NSString                       *infoCompression;
@property (copy) NSString                       *infoChunks;
@property (copy) NSString                       *infoSize;
@property (copy) NSString                       *infoHeaderSize;
@property (copy) NSString                       *infoChecksum;
@property (copy) NSString                       *infoExp;
@property (copy) NSString                       *infoImp;
@property (copy) NSString                       *infoNames;

@end

@implementation PackageController

+ (instancetype)controllerForPackage:(UPackage *)package
{
  PackageController *c = [[self alloc] initWithPackage:package];
  [package preheat];
  [c setup];
  return c;
}

+ (instancetype)controllerForPackageAtPath:(NSString *)path
{
  UPackage *package = [UPackage readFromPath:path];
  if (!package)
    return nil;
  PackageController *c = [[self alloc] initWithPackage:package];
  [package preheat];
  [c setup];
  NSString * p =  package.originalURL ? [package.originalURL path] : [package.stream.url path];
  c.infoName = [package name];
  c.infoFolderName = [[package folderName] string];
  c.infoLocation = p;
  c.infoVersion = [NSString stringWithFormat:@"%d/%d", package.fileVersion, package.licenseVersion];
  c.infoCooker = [NSString stringWithFormat:@"%d/%d", package.engineVersion, package.cookedContentVersion];
  c.infoCompression = package.compression ? package.compression == COMPRESSION_LZO ? @"LZO" : @"ZLib" : @"None";
  c.infoChunks = [NSString stringWithFormat:@"%d", package.compressedChunksCount];
  c.infoSize = [NSString stringWithFormat:@"%llu", [[[NSFileManager defaultManager] attributesOfItemAtPath:p error:nil] fileSize]];
  c.infoHeaderSize = [NSString stringWithFormat:@"%d", package.headerSize];
  c.infoChecksum = [NSString stringWithFormat:@"0x%08X", package.packageSource];
  c.infoExp = [NSString stringWithFormat:@"0x%08X", package.exportsOffset];
  c.infoImp = [NSString stringWithFormat:@"0x%08X", package.importsOffset];
  c.infoNames = [NSString stringWithFormat:@"0x%08X", package.namesOffset];
  return c;
}

- (void)setup
{
  self.saveSettingsCompression = self.package.compression;
  self.saveSettingsCanForceCook = YES;
  self.saveSettingsCanCompress = YES;
  self.allowNamesWizards = YES;
  self.allowExportWizards = YES;
  self.allowImportsWizards = YES;
}

+ (instancetype)defaultController
{
  return [[self alloc] initWithWindowNibName:kClassPackage];
}

- (id)initWithPackage:(UPackage *)package
{
  if ((self = [super initWithWindowNibName:kClassPackage]))
  {
    self.package = package;
    package.controller = self;
  }
  return self;
}

- (IBAction)infoShowLocation:(id)sender
{
  NSString *p = self.package.originalURL ? self.package.originalURL.path : self.package.stream.url.path;
  [[NSWorkspace sharedWorkspace] selectFile:p inFileViewerRootedAtPath:[p stringByDeletingLastPathComponent]];
}

- (IBAction)selectTable:(id)sender
{
  NSArray<NSButton *> *tableButtons = @[self.exportsButton, self.importsButton, self.namesButton];
  for (NSButton *b in tableButtons)
  {
    if (b != sender)
      b.state = NSOffState;
  }
  self.activeTable = [sender tag];
  [sender setState:NSOnState];
  [self cleanupProperties];
  [self cleanupDataView];
  
  [self willChangeValueForKey:@"canGoBack"];
  [self willChangeValueForKey:@"canGoForward"];
  if (sender == self.namesButton)
    [self togglePropertiesView:NO];
  else if (sender == self.exportsButton)
    [self outlineView:self.exportsView shouldSelectItem:self.selectedExport.fObject];
  else if (sender == self.importsButton)
    [self outlineView:self.importsView shouldSelectItem:self.selectedImport.fObject];
  [self didChangeValueForKey:@"canGoBack"];
  [self didChangeValueForKey:@"canGoForward"];
}

- (void)windowDidLoad
{
  [self.window setRepresentedURL:self.package.originalURL ? self.package.originalURL : self.package.stream.url];
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(splitViewDidResize:)
   name:NSSplitViewWillResizeSubviewsNotification
   object:self.splitView
   ];
  [self togglePropertiesView:NO];
  [super windowDidLoad];
}

- (NSString *)windowTitle
{
  return [(AppDelegate *)[NSApp delegate] validateWindowTitleForController:self];
}

- (void)cleanupProperties
{
  NSArray *subviews = [[self.propertiesStack subviews] copy];
  [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)cleanupDataView
{
  NSArray *subviews = [self.editorContainer.subviews copy];
  [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)populateProperties:(NSArray *)views
{
  int idx = 0;
  for (NSView *view in views)
  {
    [self.propertiesStack insertView:view atIndex:idx inGravity:NSStackViewGravityCenter];
    idx++;
  }
}

- (void)selectObject:(UObject *)object
{
  ContextedOutlineView *outline = nil;
  if (object.exportObject)
  {
    self.activeTable = 0;
    outline = self.exportsView;
    [self selectTable:self.exportsButton];
  }
  else
  {
    self.activeTable = 1;
    outline = self.importsView;
    [self selectTable:self.importsButton];
  }
  [outline selectItem:object.fObject];
  [outline scrollRowToVisible:[outline rowForItem:object.fObject]];
}

- (void)updateNames
{
  [self.namesView reloadData];
}

- (void)updateImports
{
  [self.importsView reloadData];
}

- (void)updateExports
{
  [self.exportsView reloadData];
}

- (IBAction)addObjectAction:(NSButton *)sender
{
  [NSMenu popUpContextMenu:sender.menu withEvent:[NSApp currentEvent] forView:(NSButton *)sender];
}

- (IBAction)createNewObject:(id)sender
{
  NSInteger tag = [sender tag];
  
  if (!tag)
  {
    // TODO: create new package
  }
  else if (tag == 1)
  {
    MaterialInstanceConstantWizard *wizard = [MaterialInstanceConstantWizard wizardForPackage:self.package];
    [wizard runForWindow:self.window];
  }
  else if (tag == 2)
  {
    Texture2DWizard *wizard = [Texture2DWizard wizardForPackage:self.package];
    if ([wizard runForWindow:self.window])
    {
      FObject *newObject = [wizard buildObject];
      FObject *parent = [self.exportsView itemAtRow:self.exportsView.selectedRow];
      while (![parent.object canHaveChildOfClass:newObject.objectClass] && parent != self.package.rootExports)
      {
        parent = parent.parent;
        if (!parent)
          return;
      }
      
      [self.package addNewExportObject:newObject forParent:parent];
      [self.exportsView reloadData];
      [self selectObject:newObject.object];
    }
  }
}

- (IBAction)createNewImport:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowsMultipleSelection = NO;
  panel.allowedFileTypes = @[@"gpk", @"gmp", @"upk"];
  [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      [self performSelector:@selector(runImportWiardForURL:) withObject:panel.URL afterDelay:0.9];
    }
  }];
}

- (void)runImportWiardForURL:(NSURL *)url
{
  UPackage *importPack = [UPackage readFromURL:url];
  NSString *err = [importPack preheat];
  if (err || !importPack)
  {
    NSAppError(self.package, err);
    return;
  }
  ImportWizard *importWizard = [ImportWizard wizardForPackage:importPack];
  importWizard.parentPackage = self.package;
  [importWizard runForWindow:self.window];
  NSArray *result = [importWizard resultObjects];
  
  if (!result)
    return;
}

- (IBAction)showPropertiesMenu:(NSButton *)sender
{
  [NSMenu popUpContextMenu:sender.menu withEvent:[NSApp currentEvent] forView:(NSButton *)sender];
}

- (IBAction)exportProperties:(id)sender
{
  if (!self.selectedObject)
    return;
  
  NSArray *aresult = [self.selectedObject propertiesToPlist];
  if (!aresult)
    return;
  
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.nameFieldStringValue = [self.selectedObject.objectName stringByAppendingString:@"-properties"];
  panel.prompt = @"Export";
  NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.selectedObject.objectClass]];
  if (path)
    panel.directoryURL = [NSURL fileURLWithPath:path];
  
  [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK)
    {
      [aresult writeToURL:[panel.URL URLByAppendingPathExtension:@"plist"] atomically:YES];
      [[NSUserDefaults standardUserDefaults] setObject:[panel.URL path] forKey:[kSettingsExportPath stringByAppendingFormat:@".%@",self.selectedObject.objectClass]];
    }
  }];
}

- (void)_debugSelectObjectWithIndex:(NSInteger)index
{
  @try
  {
    [self selectObject:[self.package objectForIndex:index]];
  }
  @catch (NSException *exception)
  {
    NSBeep();
    DLog(@"%@",exception);
  }
}

#pragma mark - Cooking

- (void)saveTo:(NSURL *)url
{
  if (!url)
    url = self.package.originalURL ? self.package.originalURL : self.package.stream.url;
  
  self.progressBar.indeterminate = YES;
  self.progressDescription.stringValue = @"Warming up...";
  self.progressState.stringValue = @"";
  self.progressCancelButton.enabled = YES;
  NSWindow *window = self.window;
  [self.window beginSheet:self.progressPanel completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK)
    {
      NSError *err = nil;
      if (![self.package.cookedData writeToURL:url options:NSDataWritingAtomic error:&err] && err)
        [NSApp presentError:err modalForWindow:window delegate:nil didPresentSelector:nil contextInfo:nil];
    }
  }];
  NSDictionary *options = @{@"SingleChunk" : @(self.saveSettingsSingleChunk),
                            @"Mode" : @(self.saveSettingsModePreserveOffsets.state),
                            @"Compression" : @(self.saveSettingsCompression),
                            @"CRC" : @(self.saveSettingsFixChecksum),
                            @"UpdateGen" : @(self.saveSettingsUpdateGen),
                            @"FullCook" : @(self.saveSettingsForceFullCooking),
                            @"Name" : url.lastPathComponent
                            };
  
  UPackage *p = self.package;
  NSPanel *panel = self.progressPanel;
  
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSString *error = [p cook:options];
    NSInteger result = NSModalResponseCancel;
    if (error)
    {
      NSError *err = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:@{NSLocalizedDescriptionKey : error}];
      [NSApp presentError:err modalForWindow:window delegate:nil didPresentSelector:nil contextInfo:nil];
    }
    else if (!self.progressCanceled)
    {
      result = NSModalResponseOK;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [window endSheet:panel returnCode:result];
      if (result == NSModalResponseOK)
      {
        [self.window close];
        [[NSApp delegate] application:[NSApplication sharedApplication] openFile:url.path];
      }
    });
  });
}

- (IBAction)cancelCooking:(id)sender
{
  self.progressCanceled = YES;
  [self.window endSheet:[sender window]returnCode:NSModalResponseCancel];
}

- (IBAction)setCookingMode:(id)sender
{
  if (sender == self.saveSettingsModePreserveOffsets)
  {
    self.saveSettingsForceFullCooking = NO;
    self.saveSettingsCanForceCook = NO;
  }
  else
  {
    self.saveSettingsCanForceCook = YES;
  }
}

#pragma mark - History

- (void)goBack:(id)sender
{
  [self willChangeValueForKey:@"canGoBack"];
  [self willChangeValueForKey:@"canGoForward"];
  self.igonreHistory = YES;
  if (self.historyIndex > 0)
    self.historyIndex--;
  if (self.selectionHistory[_historyIndex] == self.package.rootExports)
  {
    self.activeTable = 0;
    [self selectTable:self.exportsButton];
    [self.exportsView selectItem:self.selectionHistory[_historyIndex]];
  }
  else
    [self selectObject:[self.selectionHistory[_historyIndex] object]];
  self.igonreHistory = NO;
  [self didChangeValueForKey:@"canGoBack"];
  [self didChangeValueForKey:@"canGoForward"];
}

- (BOOL)canGoBack
{
  return self.historyIndex > 0;
}

- (void)goForward:(id)sender
{
  [self willChangeValueForKey:@"canGoBack"];
  [self willChangeValueForKey:@"canGoForward"];
  self.igonreHistory = YES;
  if (self.historyIndex + 1 < self.selectionHistory.count)
    self.historyIndex++;
  [self selectObject:[self.selectionHistory[_historyIndex] object]];
  self.igonreHistory = NO;
  [self didChangeValueForKey:@"canGoBack"];
  [self didChangeValueForKey:@"canGoForward"];
}

- (BOOL)canGoForward
{
  return self.historyIndex + 1 < self.selectionHistory.count;
}

#pragma mark - OutlineView datasouce & delegate

- (IBAction)outlineViewDoubleAction:(NSOutlineView *)outlineView
{
  FObject *item = [outlineView itemAtRow:outlineView.selectedRow];
  if (item) {
    if (!item.isExpanded)
      [[outlineView animator] expandItem:item];
    else
      [[outlineView animator] collapseItem:item];
  }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(FObject *)item
{
  if (outlineView == self.exportsView && self.exportsPredicate)
  {
    return item ? [item visibleForSearch:self.exportsPredicate] ? [item childrenForSearch:self.exportsPredicate].count : 0 : 1;
  }
  else if (outlineView == self.importsView && self.importsPredicate)
  {
    return item ? [item visibleForSearch:self.importsPredicate] ? [item childrenForSearch:self.importsPredicate].count : 0 : [self.package.rootImports childrenForSearch:self.importsPredicate].count;
  }
  return item ? item.children.count : outlineView == self.importsView ? self.package.rootImports.children.count : 1;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(FObject *)item
{
  return !item ? YES : [item children] && [[item children] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(FObject *)item
{
  item.isExpanded = YES;
  return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(FObject *)item
{
  item.isExpanded = NO;
  return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(FObject *)item
{
  if (!item)
  {
    if (outlineView == self.exportsView)
      return self.package.rootExports;
    else
      return self.importsPredicate ? [self.package.rootImports childrenForSearch:self.importsPredicate][index] : self.package.rootImports.children[index];
  }
  
  if (outlineView == self.importsView)
  {
    return self.importsPredicate ? [item childrenForSearch:self.importsPredicate][index] : item.children[index];
  }
  
  return self.exportsPredicate ? [item childrenForSearch:self.exportsPredicate][index] : item.children[index];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(FObject *)item
{
  NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"DataView" owner:self];
  
  if (item.object.exportObject && item.object.isDirty)
  {
    NSString *nm = [item objectName];
    nm = [nm stringByAppendingString:@"*"];
    cellView.textField.stringValue = nm;
  }
  else
  {
    cellView.textField.stringValue = [item objectName];
  }
  
  cellView.imageView.objectValue = [item icon];
  
  if (item.object.exportObject && item.object.isDirty)
  {
    [cellView.textField setFont:[NSFont boldSystemFontOfSize:cellView.textField.font.pointSize]];
  }
  else
  {
    [cellView.textField setFont:[NSFont systemFontOfSize:cellView.textField.font.pointSize]];
  }
  return cellView;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(FObject *)item
{
  [self cleanupProperties];
  self.addExportButton.enabled = (item != nil) ? YES : NO;
  if (!self.selectionHistory)
    self.selectionHistory = [NSMutableArray new];
  if (!self.cache)
    self.cache = [NSMutableArray new];
  
  if ([item isKindOfClass:[FObjectExport class]] && [self.cache indexOfObject:item] == NSNotFound)
  {
    NSInteger maxCache = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsCacheSize];
    if (maxCache < 1)
      maxCache = 1;
    NSInteger cacheSize = self.cache.count - maxCache;
    if (cacheSize >= 0)
    {
      for (int idx = 0; idx < cacheSize; ++idx)
      {
        [self.cache[0] cleanup];
        [self.cache removeObjectAtIndex:0];
      }
    }
    [self.cache addObject:item];
  }
  
  if (!self.igonreHistory)
  {
    if (!self.selectionHistory.count && item)
      [self.selectionHistory addObject:item];
    else if (item && item != self.selectionHistory[self.historyIndex])
    {
      if (self.historyIndex != self.selectionHistory.count - 1)
      {
        [self.selectionHistory removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.historyIndex + 1, self.selectionHistory.count - (self.historyIndex + 1))]];
      }
      if (self.selectionHistory.count >= MAX_HISTORY)
      {
        NSInteger diff = self.selectionHistory.count - (MAX_HISTORY - 1);
        [self.selectionHistory removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, diff)]];
        self.historyIndex -= diff;
      }
      [self.selectionHistory addObject:item];
      self.historyIndex++;
      self.canGoBack = self.selectionHistory.count > 1;
    }
  }
  
  if (outlineView == self.exportsView && item.object)
  {
    if (!self.exportController)
      self.exportController = [ObjectController objectController];
    if (!self.exportController.view.superview)
    {
      [self cleanupDataView];
      [self.editorContainer addScaledSubview:self.exportController.view];
    }
    self.exportController.object = item.object;
    self.exportController.packageController = self;
    [self togglePropertiesView:!self.exportController.hideProperties];
    if (!self.exportController.hideProperties)
    {
      NSArray *views = self.exportController.propertiesViews;
      if (views)
        [self populateProperties:views];
    }
    
    if (item)
      self.selectedObject = [item object];
    else
      self.selectedObject = nil;
    
    self.selectedExport = self.selectedObject;
    return YES;
  }
  else if (outlineView == self.importsView && item.object)
  {
    if (!self.importController)
      self.importController = [ImportController objectController];
    if (!self.importController.view.superview)
    {
      [self cleanupDataView];
      [self.editorContainer addScaledSubview:self.importController.view];
    }
    self.importController.object = item.object;
    [self togglePropertiesView:NO];
    
    if (item)
      self.selectedObject = [item object];
    else
      self.selectedObject = nil;
    
    self.selectedImport = self.selectedObject;
  }
  
  self.selectedObject = nil;
  
  return YES;
}

- (void)togglePropertiesView:(BOOL)visible
{
  SEL selector = NSSelectorFromString(@"_setArrangedView:isCollapsed:");
  NSMethodSignature *signature = [NSSplitView instanceMethodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = self.splitView;
  invocation.selector = selector;
  NSView *view = [self.splitView.arrangedSubviews lastObject];
  [invocation setArgument:&view atIndex:2];
  BOOL arg = !visible;
  [invocation setArgument:&arg atIndex:3];
  [invocation invoke];
}

- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForItem:(UObject *)item
{
  return nil;
}

#pragma mark - TableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
  if (self.namesPredicate)
    return [self.package.names filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.string contains[cd] %@ || self.index == %ld",self.namesPredicate,self.namesPredicate.integerValue]].count;
  return self.package.names.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (self.namesPredicate)
  {
    id value = nil;
    NSArray *filter = [self.package.names filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.string contains[cd] %@ || self.index == %ld",self.namesPredicate,self.namesPredicate.integerValue]];
    
    if ([tableColumn.identifier isEqualToString:@"identifierNameIndex"])
      value = [NSString stringWithFormat:@"%lu",[self.package.names indexOfObject:filter[row]]];
    else if ([tableColumn.identifier isEqualToString:@"identifierNameString"])
      value = filter[row];
    
    return value;
  }
  id value = nil;
  if ([tableColumn.identifier isEqualToString:@"identifierNameIndex"])
    value = [NSString stringWithFormat:@"%ld",row];
  else if ([tableColumn.identifier isEqualToString:@"identifierNameString"])
    value = [self.package nameForIndex:row];
  return value;
}

#pragma mark - Cleanup

- (void)cleanupViews
{
  self.exportController = nil;
  [self.propertiesStack removeFromSuperview];
  [self.editorContainer removeFromSuperview];
}

- (void)close
{
  self.cache = nil;
  [self cleanupViews];
  [(AppDelegate *)[NSApp delegate] controllerWillClose:self];
  [super close];
}

- (void)windowWillClose:(NSNotification *)notification
{
  [self.cache makeObjectsPerformSelector:@selector(cleanup)];
  self.window = nil;
  [self performSelector:@selector(close) withObject:nil afterDelay:5];
}

#pragma mark - ProgressManager

- (void)setMaxProgress:(double)value
{
  if (![NSThread isMainThread])
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.progressBar.maxValue = value;
    });
  }
  else
    self.progressBar.maxValue = value;
}

- (void)setProgressValue:(double)value
{
  if (![NSThread isMainThread])
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.progressBar.indeterminate = !value;
      self.progressBar.doubleValue = value;
    });
  }
  else
  {
    self.progressBar.indeterminate = !value;
    self.progressBar.doubleValue = value;
  }
}

- (void)setProgressStateValue:(NSString *)state
{
  if (![NSThread isMainThread])
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.progressState.stringValue = state;
    });
  }
  else
    self.progressState.stringValue = state;
}

- (void)setProgressDescriptionValue:(NSString *)progressDescription
{
  if (![NSThread isMainThread])
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.progressDescription.stringValue = progressDescription;
    });
  }
  else
    self.progressDescription.stringValue = progressDescription;
}

- (void)splitViewDidResize:(NSNotification *)aNotification
{
  self.propertiesDivierWidth = NSMinX([self.splitView.subviews lastObject].frame);
}

#pragma mark - SearchField delegate

- (void)searchFieldDidStartSearching:(NSSearchField *)sender
{
  if (sender == self.exportsSearchField)
    [self searchExport:sender.stringValue];
  else if (sender == self.importsSearchField)
    [self searchImport:sender.stringValue];
  else if (sender == self.namesSearchField)
    [self searchName:sender.stringValue];
}

- (void)searchFieldDidEndSearching:(NSSearchField *)sender
{
  if (sender == self.exportsSearchField)
  {
    self.exportsPredicate = nil;
    [self.exportsView reloadData];
  }
  else if (sender == self.importsSearchField)
  {
    self.importsPredicate = nil;
    [self.importsView reloadData];
  }
  else if (sender == self.namesSearchField)
  {
    self.namesPredicate = nil;
    [self.namesView reloadData];
  }
}

- (IBAction)search:(NSSearchField *)sender
{
  if (sender == self.exportsSearchField)
  {
    if (!self.exportsPredicate)
      return;
    [self searchExport:sender.stringValue];
  }
  else if (sender == self.importsSearchField)
  {
    if (!self.importsPredicate)
      return;
    [self searchImport:sender.stringValue];
  }
  else if (sender == self.namesSearchField)
  {
    if (!self.namesPredicate)
      return;
    [self searchName:sender.stringValue];
  }
}

- (void)searchExport:(NSString *)search
{
  if (!search.length)
    self.exportsPredicate = nil;
  else
    self.exportsPredicate = search;
  [self.exportsView reloadData];
  [self.exportsView expandItem:nil expandChildren:YES];
}

- (void)searchImport:(NSString *)search
{
  if (!search.length)
    self.importsPredicate = nil;
  else
    self.importsPredicate = search;
  [self.importsView reloadData];
  [self.importsView expandItem:nil expandChildren:YES];
}

- (void)searchName:(NSString *)search
{
  if (!search.length)
    self.namesPredicate = nil;
  else
    self.namesPredicate = search;
  
  [self.namesView reloadData];
}

@end
