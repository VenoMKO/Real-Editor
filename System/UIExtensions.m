//
//  UIExtensions.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 04/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UIExtensions.h"

@implementation AlphaColorWell

- (void)activate:(BOOL)exclusive
{
  [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
  [super activate:exclusive];
}

- (void)deactivate
{
  [super deactivate];
  [[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
}

@end

@implementation LockedColorWell

- (void)mouseDown:(NSEvent *)event
{
  [self.superview mouseDown:event];
}

@end


@implementation USWindow
@end

@implementation USPanel
@end
