//
//  TextureView.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 09/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "TextureView.h"

#define PATTERN_CELL_WIDTH  sPatternCellSize
#define PATTERN_CELL_HEIGHT sPatternCellSize

static float sPatternCellSize = 32.0;

static  void drawPatternCell(void *info, CGContextRef context)
{
  float cellWidth = PATTERN_CELL_WIDTH;
  float cellHeight = PATTERN_CELL_HEIGHT;
  
  CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
  CGContextFillRect(context, CGRectMake(0.0, 0.0, cellWidth, cellHeight));
  CGContextSetFillColorWithColor(context, [NSColor grayColor].CGColor);
  CGContextFillRect(context, CGRectMake(0.0, 0.0, cellWidth/2.0, cellHeight/2.0));
  CGContextFillRect(context, CGRectMake(cellWidth/2.0, cellHeight/2.0, cellWidth/2.0, cellHeight/2.0));
}

static void PatternReleaseInfoCallback(void *info)
{
}

@interface TextureView ()
{
  CGPatternRef checkboard;
}

@property (weak) IBOutlet NSScrollView *scroll;
@property (weak) CALayer *imgLayer;

@end

@implementation TextureView

- (void)dealloc
{
  CGPatternRelease(checkboard);
}

- (void)centerLayer
{
  NSRect r = [self centerRect];
  self.imgLayer.frame = r;
}

- (void)awakeFromNib
{
  
  CALayer *l = [CALayer new];
  self.imgLayer = l;
  l.backgroundColor = [[NSColor clearColor] CGColor];
  self.wantsLayer = YES;
  [self.layer addSublayer:l];
  
  CGPatternCallbacks callBack;
  callBack.drawPattern = &drawPatternCell;
  callBack.releaseInfo = &PatternReleaseInfoCallback;
  callBack.version = 0;
  if (checkboard)
    CGPatternRelease(checkboard);
  checkboard = CGPatternCreate(NULL,
                               CGRectMake(0.0, 0.0, PATTERN_CELL_WIDTH, PATTERN_CELL_HEIGHT),
                               CGAffineTransformIdentity,
                               PATTERN_CELL_WIDTH,
                               PATTERN_CELL_HEIGHT,
                               kCGPatternTilingConstantSpacing,
                               true,
                               &callBack);
  CGPatternRetain(checkboard);
}

- (NSRect)centerRect
{
  NSRect r;
  
  NSSize s = NSMakeSize(CGImageGetWidth(_image), CGImageGetHeight(_image));
  r.size = s;
  r.origin.x = NSMidX(self.bounds) - (s.width * .5);
  r.origin.y = NSMidY(self.bounds) - (s.height * .5);
  
  return r;
}

- (void)setImage:(CGImageRef)image
{
  if (_image && image != _image)
  {
    CGImageRelease(_image);
  }
  _image = image;
  if (image)
    CGImageRetain(_image);
  [self.imgLayer setFrame:[self centerRect]];
  self.imgLayer.contents = (__bridge id)(_image);
  [self invalidateIntrinsicContentSize];
  
}

- (void)setFrameSize:(NSSize)newSize
{
  [super setFrameSize:newSize];
  [self centerLayer];
}

- (NSSize)intrinsicContentSize
{
  return NSMakeSize(CGImageGetWidth(_image), CGImageGetHeight(_image));
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)zoomToActual
{
  self.scroll.animator.magnification = 1.0;
}

- (void)zoomToFit
{
  CGFloat xDiff, yDiff;
  NSSize intrinsicSize = self.intrinsicContentSize;
  xDiff = NSWidth(self.scroll.frame) - intrinsicSize.width;
  yDiff = NSHeight(self.scroll.frame) - intrinsicSize.height;
  
  if (yDiff < xDiff)
  {
    self.scroll.animator.magnification = NSHeight(self.scroll.frame) / intrinsicSize.height;
  }
  else
  {
    self.scroll.animator.magnification = NSWidth(self.scroll.frame) / intrinsicSize.width;
  }
}

- (void)mouseUp:(NSEvent *)theEvent
{
  if([theEvent clickCount] == 2)
  {
    if (self.scroll.magnification > 1)
    {
      [self zoomToActual];
    }
    else
    {
      [self zoomToFit];
    }
  }
}

- (void)drawRect:(NSRect)dirtyRect
{
  /*
  CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(context);
  CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
  CGContextSetFillColorSpace(context, patternSpace);
  CGColorSpaceRelease(patternSpace);
  CGFloat a = 1.0;
  CGContextSetFillPattern(context, checkboard, &a);
  CGContextFillRect(context, self.layer.bounds);
  CGContextRestoreGState(context);
   */
  [super drawRect:dirtyRect];
}

@end

@implementation CenteredClipView

CGFloat centeredCoordinateUnitWithProposedContentViewBoundsDimensionAndDocumentViewFrameDimension
(CGFloat proposedContentViewBoundsDimension,
 CGFloat documentViewFrameDimension )
{
  return floor( (proposedContentViewBoundsDimension - documentViewFrameDimension) / -2.0F );
}

- (NSRect)constrainBoundsRect:(NSRect)proposedClipViewBoundsRect {
  
  NSRect constrainedClipViewBoundsRect = [super constrainBoundsRect:proposedClipViewBoundsRect];
  
  if (self.centersDocumentView == NO)
    return constrainedClipViewBoundsRect;
  
  NSRect documentViewFrameRect = [self.documentView frame];
  
  if (proposedClipViewBoundsRect.size.width >= documentViewFrameRect.size.width)
  {
    constrainedClipViewBoundsRect.origin.x = centeredCoordinateUnitWithProposedContentViewBoundsDimensionAndDocumentViewFrameDimension(proposedClipViewBoundsRect.size.width, documentViewFrameRect.size.width);
  }
  if (proposedClipViewBoundsRect.size.height >= documentViewFrameRect.size.height)
  {
    constrainedClipViewBoundsRect.origin.y = centeredCoordinateUnitWithProposedContentViewBoundsDimensionAndDocumentViewFrameDimension(proposedClipViewBoundsRect.size.height, documentViewFrameRect.size.height);
  }
  
  return constrainedClipViewBoundsRect;
}

@end
