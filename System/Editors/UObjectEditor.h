//
//  UObjectEditor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UObject.h"

@interface UObjectEditor : NSViewController
@property (strong) IBOutlet NSView *toolBarView;
@property (strong) IBOutlet NSView *exportOptionsView;
@property (strong) IBOutlet NSView *importOptionsView;
@property (weak) UObject *object;
- (IBAction)exportRaw:(id)sender;
- (IBAction)exportData:(id)sender;
- (NSArray *)propertiesViews;
- (BOOL)hideProperties;
@end

@interface RawExportOptions : NSViewController
@property (weak) IBOutlet NSButton *exportAllModeButton;
@property (weak) IBOutlet NSButton *exportDataModeButton;
@property (weak) IBOutlet NSButton *exportPropertiesModeButton;
@property (weak) UObjectEditor *parent;
@end
