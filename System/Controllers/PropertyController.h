//
//  PropertyController.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 30/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class FPropertyTag;
@interface PropertyController : NSViewController
@property (weak) FPropertyTag *property;
+ (id)controllerForProperty:(FPropertyTag *)tag;
- (void)cleanup;
@end
