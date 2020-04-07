//
//  AppDelegate.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PackageController;
@interface AppDelegate : NSObject <NSApplicationDelegate>

- (NSString *)validateWindowTitleForController:(PackageController *)controller;
- (void)controllerWillClose:(PackageController *)controller;

@end

