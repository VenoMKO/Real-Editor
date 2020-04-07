//
//  ObjectController.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PropertyController.h"
#import "UObject.h"

@interface ObjectController : NSViewController
@property (weak) id       packageController;
@property (weak) UObject  *object;
+ (instancetype)objectController;
- (NSArray *)propertiesViews;
- (BOOL)hideProperties;
@end

@interface ImportController : NSViewController
@property (weak) id       packageController;
@property (weak, nonatomic) UObject  *object;
+ (instancetype)objectController;
@end
