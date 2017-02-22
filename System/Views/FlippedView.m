//
//  FlippedView.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 30/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FlippedView.h"

@implementation FlippedView

- (BOOL)isFlipped
{
  return YES;
}

@end

@implementation DebugView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor redColor] setFill];
  NSRectFill(dirtyRect);
}

@end

@implementation PropertyView

- (BOOL)isOpaque
{
  return YES;
}

@end
