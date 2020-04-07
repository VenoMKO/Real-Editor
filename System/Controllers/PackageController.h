//
//  PackageController.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UPackage.h"

@interface PackageController : NSWindowController <NSOutlineViewDataSource, NSTableViewDataSource, NSWindowDelegate>
@property (strong) UPackage   *package;
@property (strong) IBOutlet NSView      *saveSettingsView;
@property (strong) IBOutlet NSPanel             *infoPanel;

+ (instancetype)controllerForPackage:(UPackage *)package;
+ (instancetype)controllerForPackageAtPath:(NSString *)path;
- (void)selectObject:(UObject *)object;
- (void)saveTo:(NSURL *)url;
- (void)updateNames;
- (void)updateImports;
- (void)updateExports;

@property (weak) UObject                        *selectedObject;
@property (weak) UObject                        *selectedExport;
@property (weak) UObject                        *selectedImport;

@property (assign) BOOL progressCanceled;
- (void)setMaxProgress:(double)value;
- (void)setProgressValue:(double)value;
- (void)setProgressStateValue:(NSString *)state;
- (void)setProgressDescriptionValue:(NSString *)progressDescription;

- (IBAction)exportProperties:(id)sender;
- (void)_debugSelectObjectWithIndex:(NSInteger)index;

@end
