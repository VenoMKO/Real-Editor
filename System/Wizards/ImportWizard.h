//
//  ImportWizard.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 29/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UPackage;
@interface ImportWizard : NSWindowController

@property (weak) UPackage *parentPackage;

+ (instancetype)wizardForPackage:(UPackage *)package;
- (BOOL)runForWindow:(NSWindow *)host;
- (NSArray *)resultObjects;

@end
