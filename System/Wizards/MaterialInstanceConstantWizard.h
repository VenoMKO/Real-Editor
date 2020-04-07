//
//  MaterialInstanceConstantWizard.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 05/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UObjectEditor.h"
#import "Material.h"

@interface MaterialInstanceConstantWizard : NSWindowController
+ (instancetype)wizardForPackage:(UPackage *)package;
- (BOOL)runForWindow:(NSWindow *)host;
@end
