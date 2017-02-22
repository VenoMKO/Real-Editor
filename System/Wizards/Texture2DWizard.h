//
//  Texture2DWizard.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 05/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UPackage.h"

@interface Texture2DWizard : NSWindowController
+ (instancetype)wizardForPackage:(UPackage *)package;
- (BOOL)runForWindow:(NSWindow *)host;
- (FObject *)buildObject;
@end
