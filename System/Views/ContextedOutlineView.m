//
//  ContextedOutlineView.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 31/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "ContextedOutlineView.h"
#import "FReadable.h"

@implementation ContextedOutlineView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
  NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  id item = [self itemAtRow: [self rowAtPoint:pt]];
  if (self.delegate)
    return [(id <ContextedOutlineViewDelegate>)self.delegate outlineView:self menuForItem:item];
  else
    return nil;
}

- (void)expandParentsOfItem:(FObject *)item
{
  NSMutableArray *stack = [NSMutableArray array];
  
  while (item != nil)
  {
    id parent = item.parent;
    if (parent)
      [stack insertObject:parent atIndex:0];
    if (![self isExpandable:parent])
      break;
    item = parent;
  }
  for (FObject *parent in stack)
  {
    if (![self isItemExpanded:parent])
      [self expandItem:parent];
  }
}

- (void)selectItem:(id)item
{
  NSInteger itemIndex = [self rowForItem:item];
  if (itemIndex < 0)
  {
    [self expandParentsOfItem:item];
    itemIndex = [self rowForItem:item];
    if (itemIndex < 0)
      return;
  }
  
  if ([self.delegate outlineView:self shouldSelectItem:item])
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex: itemIndex] byExtendingSelection: NO];
}
@end
