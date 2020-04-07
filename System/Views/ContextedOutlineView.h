//
//  ContextedOutlineView.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 31/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ContextedOutlineViewDelegate <NSObject>

- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForItem:(id)item;

@end

@interface ContextedOutlineView : NSOutlineView
- (void)expandParentsOfItem:(id)item;
- (void)selectItem:(id)item;
@end
