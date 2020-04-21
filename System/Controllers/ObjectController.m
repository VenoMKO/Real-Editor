//
//  ObjectController.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "ObjectController.h"
#import "FPropertyTag.h"
#import "UObjectEditor.h"
#import "UPackage.h"
#import "PackageController.h"

@interface ObjectController () <NSTokenFieldDelegate>
@property (weak) IBOutlet NSLayoutConstraint  *objectInfoHeight;
@property (weak) IBOutlet NSView *toolBoxContainer;
@property (weak) IBOutlet NSView *editorContainer;
@property (weak) IBOutlet NSButton *objectInfoButton;

@property (weak) IBOutlet NSTokenField  *objectFlagsField;
@property (weak) IBOutlet NSTokenField  *packageFlagsField;
@property (weak) IBOutlet NSTokenField  *exportFlagsField;
@end

@implementation ObjectController

+ (instancetype)objectController
{
  return [[self alloc] initWithNibName:@"ObjectController" bundle:[NSBundle mainBundle]];
}

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"object"];
}

- (void)viewDidLoad
{
  self.objectInfoButton.state = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsShowObjectInfo];
  CGFloat v = ![self.objectInfoButton state] ? 26.0 : 96.0;
  self.objectInfoHeight.constant = v;
  [super viewDidLoad];
  [self addObserver:self forKeyPath:@"object" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"object"])
  {
    NSArray *subviews = [self.editorContainer.subviews copy];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    subviews = [self.toolBoxContainer.subviews copy];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.editorContainer addScaledSubview:[self.object.editor view]];
    [self.toolBoxContainer addScaledSubview:[self.object.editor toolBarView]];
    [self.objectFlagsField setObjectValue:NSStringFromObjectFlags(self.object.exportObject.objectFlags)];
    [self.packageFlagsField setObjectValue:NSStringFromPackageFlags(self.object.exportObject.packageFlags)];
    [self.exportFlagsField setObjectValue:NSStringFromExportFlags(self.object.exportObject.exportFlags)];
  }
}

- (IBAction)toggleObjectInfo:(id)sender
{
  CGFloat v = ![sender state] ? 26.0 : 96.0;
  self.objectInfoHeight.animator.constant = v;
  [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:kSettingsShowObjectInfo];
}

- (NSArray *)propertiesViews
{
  return self.object.editor.propertiesViews;
}

- (BOOL)hideProperties
{
  if ([self.object.objectClass isEqualToString:@"Package"])
    return YES;
  return [self.object.editor hideProperties];
}

- (IBAction)goBack:(id)sender
{
  [self.packageController performSelector:@selector(goBack:) withObject:sender];
}

- (IBAction)goForward:(id)sender
{
  [self.packageController performSelector:@selector(goForward:) withObject:sender];
}

- (IBAction)goToArchetype:(id)sender
{
  [self.packageController performSelector:@selector(selectObject:) withObject:self.object.archetype];
}


- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
  if (tokenField == self.objectFlagsField)
  {
    return [AllObjectFlags() filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
  }
  else if (tokenField == self.packageFlagsField)
  {
    return [AllPackageFlags() filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
  }
  else if (tokenField == self.exportFlagsField)
  {
    return [AllExportFlags() filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
  }
  return nil;
}

@end

@interface ImportController () <NSTokenFieldDelegate>
@property (weak) IBOutlet NSLayoutConstraint  *objectInfoHeight;
@property (weak) IBOutlet NSView *toolBoxContainer;
@property (weak) IBOutlet NSView *editorContainer;
@property (weak) IBOutlet NSButton *objectInfoButton;

@property (weak) IBOutlet NSTokenField  *objectFlagsField;
@property (weak) IBOutlet NSTokenField  *packageFlagsField;
@property (weak) IBOutlet NSTokenField  *exportFlagsField;
@end

@implementation ImportController

+ (instancetype)objectController
{
  return [[self alloc] initWithNibName:@"ObjectController" bundle:[NSBundle mainBundle]];
}

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"object"];
}

- (void)viewDidLoad
{
  self.objectInfoButton.state = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsShowObjectInfo];
  CGFloat v = ![self.objectInfoButton state] ? 26.0 : 96.0;
  self.objectInfoHeight.constant = v;
  [super viewDidLoad];
  [self addObserver:self forKeyPath:@"object" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"object"])
  {
    NSArray *subviews = [self.editorContainer.subviews copy];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    subviews = [self.toolBoxContainer.subviews copy];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.editorContainer addScaledSubview:[self.object.editor view]];
    [self.objectFlagsField setObjectValue:NSStringFromObjectFlags(self.object.exportObject.objectFlags)];
    [self.packageFlagsField setObjectValue:NSStringFromPackageFlags(self.object.exportObject.packageFlags)];
    [self.exportFlagsField setObjectValue:NSStringFromExportFlags(self.object.exportObject.exportFlags)];
  }
}

- (IBAction)toggleObjectInfo:(id)sender
{
  CGFloat v = ![sender state] ? 26.0 : 96.0;
  self.objectInfoHeight.animator.constant = v;
  [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:kSettingsShowObjectInfo];
}

- (IBAction)goBack:(id)sender
{
  [self.packageController performSelector:@selector(goBack:) withObject:sender];
}

- (IBAction)goForward:(id)sender
{
  [self.packageController performSelector:@selector(goForward:) withObject:sender];
}


- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
  if (tokenField == self.objectFlagsField)
  {
    return [AllObjectFlags() filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
  }
  else if (tokenField == self.packageFlagsField)
  {
    return [AllPackageFlags() filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
  }
  else if (tokenField == self.exportFlagsField)
  {
    return [AllExportFlags() filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
  }
  return nil;
}

- (void)setObject:(UObject *)object
{
  self.packageController = object.package.controller;
  [object.package.controller willChangeValueForKey:@"canGoBack"];
  [object.package.controller willChangeValueForKey:@"canGoForward"];
  if (object.importObject)
  {
    UObject *o = [object.package resolveImport:object.importObject];
    if (o)
    {
      _object = o;
      return;
    }
  }
  _object = object;
  [object.package.controller didChangeValueForKey:@"canGoBack"];
  [object.package.controller willChangeValueForKey:@"canGoForward"];
}

@end
