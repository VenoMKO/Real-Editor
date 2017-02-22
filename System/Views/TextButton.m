//
//  TextButton.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "TextButton.h"

@implementation TextButton

- (void)setState:(NSInteger)state
{
  [super setState:state];
  [self setColoredTitle];
}

- (void)setColoredTitle
{
  NSColor *color = self.state ? [NSColor selectedMenuItemColor] : [NSColor headerTextColor];
  NSMutableAttributedString *coloredTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitle]];
  NSRange titleRange = NSMakeRange(0, [coloredTitle length]);
  [coloredTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
  [self setAttributedTitle:coloredTitle];
  [self setNeedsDisplay];
}

@end

@implementation AlternatableTableCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
  if (backgroundStyle == NSBackgroundStyleDark)
  {
    self.textField.textColor = [NSColor whiteColor];
  }
  else
  {
    self.textField.textColor = [NSColor blackColor];
  }
  [super setBackgroundStyle:backgroundStyle];
}

@end

@implementation CancelableTextField

- (void)cancelOperation:(id)sender
{
  [self abortEditing];
  [[self window] makeFirstResponder:nil];
}

@end

@implementation TextFieldWithGoButtonCell

- (NSRect)titleRectForBounds:(NSRect)theRect
{
  NSRect titleFrame = [super titleRectForBounds:theRect];
  titleFrame.size.width -= self.margin;
  return titleFrame;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
  NSRect textFrame = aRect;
  textFrame.size.width -= self.margin;
  [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
  NSRect textFrame = aRect;
  textFrame.size.width -= self.margin;
  [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}



- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
  NSRect titleRect = [self titleRectForBounds:cellFrame];
  [[self attributedStringValue] drawInRect:titleRect];
}

@end

@interface TextFieldWithGoButton ()
@property (weak) NSButton *goButton;
@end
@implementation TextFieldWithGoButton

+ (Class)cellClass
{
  return [TextFieldWithGoButtonCell class];
}

- (void)awakeFromNib
{
  NSButton *popoverButton = [NSButton new];
  popoverButton.translatesAutoresizingMaskIntoConstraints = NO;
  popoverButton.buttonType = NSMomentaryChangeButton;
  popoverButton.bezelStyle = NSInlineBezelStyle;
  popoverButton.bordered = NO;
  popoverButton.imagePosition = NSImageOnly;
  [popoverButton setImage:[NSImage imageNamed:@"NSFollowLinkFreestandingTemplate"]];
  [popoverButton.cell setHighlightsBy:NSContentsCellMask];
  popoverButton.target = self.goTarget;
  popoverButton.action = self.goAction;
  [self addSubview:popoverButton];
  self.goButton = popoverButton;
  [self addConstraint:[NSLayoutConstraint constraintWithItem:popoverButton
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute 
                                                  multiplier:1.0 
                                                    constant:16]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:popoverButton
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:1.0
                                                    constant:16]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[popoverButton]-2-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(popoverButton)]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:popoverButton
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1
                                                    constant:0]];
  //[self.cell setBezeled:YES];
}

- (void)setGoAction:(SEL)goAction
{
  [self willChangeValueForKey:@"goAction"];
  _goAction = goAction;
  self.goButton.action = goAction;
  [self didChangeValueForKey:@"goAction"];
}

- (void)setGoTarget:(id)goTarget
{
  [self willChangeValueForKey:@"goTarget"];
  _goTarget = goTarget;
  self.goButton.target = goTarget;
  [self didChangeValueForKey:@"goTarget"];
}

@end

