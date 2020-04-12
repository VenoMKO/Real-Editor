//
//  MaterialEditor.m
//  Real Editor
//
//  Created by VenoMKO on 7.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "MaterialEditor.h"
#import "UPackage.h"
#import "FString.h"

const CGFloat AttrFontSizeTitle = 11;
const CGFloat AttrFontSize = 8;
const CGFloat CanvasPadding = 100;
const CGFloat ExpressionWidth = 130;
const CGFloat ExpressionHeight = 50;

@interface MaterialEditor ()
@property IBOutlet NSScrollView       *scrollView;
@property IBOutlet NSView             *container;
@property IBOutlet ExpressionView     *canvas;
@property IBOutlet NSLayoutConstraint *widthConstraint;
@property IBOutlet NSLayoutConstraint *heightConstraint;
@end

@interface ExpressionView ()
@property NSMutableArray      *expressions;
@property NSMutableDictionary *expressionToViewMap;
@property CGFloat offsetX;
@property CGFloat offsetY;
@property CGFloat maxX;
@end

@implementation MaterialEditor
@dynamic object;

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.scrollView.allowsMagnification = YES;
  self.scrollView.maxMagnification = 1.5;
  self.scrollView.minMagnification = .25;
  self.scrollView.magnification = self.scrollView.minMagnification;
  [self.object properties];
  self.canvas.expressionToViewMap = [NSMutableDictionary new];
  self.canvas.expressions = [NSMutableArray new];
  for (FObjectExport *expression in self.object.children)
  {
    [expression.object properties];
    [self.canvas.expressions addObject:expression.object];
  }
  
  int maxX = INT_MIN;
  int minX = INT_MAX;
  int maxY = INT_MIN;
  int minY = INT_MAX;
  for (UObject *expression in self.canvas.expressions)
  {
    NSNumber *value = [expression propertyValue:@"EditorX"];
    if (!value)
    {
      value = @0;
    }
    int posX = [value intValue];
    value = [expression propertyValue:@"EditorY"];
    if (!value)
    {
      value = @0;
    }
    int posY = [value intValue];
    
    if (posY < minY)
    {
      minY = posY;
    }
    if (posX < minX)
    {
      minX = posX;
    }
    if (posY > maxY)
    {
      maxY = posY;
    }
    if (posX > maxX)
    {
      maxX = posX;
    }
    value = [expression propertyValue:@"SizeX"];
    if (value)
    {
      posX = [value intValue];
    }
    value = [expression propertyValue:@"SizeY"];
    if (value)
    {
      posY = [value intValue];
    }
    if (posY > maxY)
    {
      maxY = posY;
    }
    if (posX > maxX)
    {
      maxX = posX;
    }
  }
  self.canvas.maxX = maxX;
  int canvasWidth = abs(minX) + abs(maxX) + (CanvasPadding * 2);
  int canvasHeight = abs(minY) + abs(maxY) + (CanvasPadding * 2);
  if (minX < 0)
  {
    self.canvas.offsetX = abs(minX);
  }
  self.canvas.offsetX += CanvasPadding;
  if (minY < 0)
  {
    self.canvas.offsetY = abs(minY);
  }
  self.canvas.offsetY += CanvasPadding;
  self.widthConstraint.constant = canvasWidth + (CanvasPadding * 2);
  self.heightConstraint.constant = canvasHeight + (CanvasPadding * 2);
  [self.canvas.superview.superview setNeedsLayout:YES];
}

@end

@implementation ExpressionView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor grayColor] setStroke];
  
  for (UObject *expression in self.expressions)
  {
    [self drawExpressin:expression color:[NSColor textColor]];
  }
}

- (NSPoint)expressionPosition:(UObject *)expression
{
  NSNumber *value = [expression propertyValue:@"EditorX"];
  if (!value)
  {
    value = @0;
  }
  int posX = (self.maxX - [value intValue]) + self.offsetX;
  value = [expression propertyValue:@"EditorY"];
  if (!value)
  {
    value = @0;
  }
  int posY = [value intValue] + self.offsetY;
  return NSMakePoint(posX, posY);
}

- (NSRect)expressionBounds:(UObject *)expression
{
  NSRect result;
  result.origin = [self expressionPosition:expression];
  
  NSString *name = [expression.objectClass stringByReplacingOccurrencesOfString:@"MaterialExpression" withString:@""];
  NSRect lableRect = [name boundingRectWithSize:NSMakeSize(5000, AttrFontSizeTitle) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [NSFont systemFontOfSize:AttrFontSizeTitle], NSForegroundColorAttributeName : [NSColor labelColor]} context:nil];
  
  int width = NSWidth(lableRect) + AttrFontSizeTitle;
  int height = ExpressionHeight;
  
  NSNumber *value = [expression propertyValue:@"SizeX"];
  if (value)
  {
    width = MAX([value intValue], width);
    result.origin.x -= ([value intValue] - (CanvasPadding * 2));
  }
  value = [expression propertyValue:@"SizeY"];
  if (value)
  {
    height = MAX([value intValue], height);
  }
  
  result.size.width = MAX(width, ExpressionWidth);
  result.size.height = height;
  return result;
}

- (void)drawExpressin:(UObject *)expression color:(NSColor *)color
{
  [color setStroke];
  NSRect bounds = [self expressionBounds:expression];
  NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
  [path stroke];
  NSString *name = [expression.objectClass stringByReplacingOccurrencesOfString:@"MaterialExpression" withString:@""];
  if ([name isEqualToString:@"Comment"] && [expression propertyValue:@"Text"])
  {
    name = [NSString stringWithFormat:@"Comment: %@", [(FString*)[expression propertyValue:@"Text"] string]];
  }
  {
    NSPoint namePos = NSMakePoint(bounds.origin.x + 5, NSMaxY(bounds) - (AttrFontSizeTitle + 5));
    [name drawAtPoint:namePos withAttributes:@{NSFontAttributeName : [NSFont systemFontOfSize:AttrFontSizeTitle], NSForegroundColorAttributeName : color}];
  }
  
  int index = 1;
  
  if ([expression propertyForName:@"Time"])
  {
    [self drawLineFromElement:expression name:@"Time" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Percent"])
  {
    [self drawLineFromElement:expression name:@"Percent" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Coordinate"])
  {
    [self drawLineFromElement:expression name:@"Coordinate" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Coordinates"])
  {
    [self drawLineFromElement:expression name:@"Coordinates" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Alpha"])
  {
    [self drawLineFromElement:expression name:@"Alpha" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Bias"])
  {
    [self drawLineFromElement:expression name:@"Bias" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Exponent"])
  {
    [self drawLineFromElement:expression name:@"Exponent" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Base"])
  {
    [self drawLineFromElement:expression name:@"Base" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Max"])
  {
    [self drawLineFromElement:expression name:@"Max" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Min"])
  {
    [self drawLineFromElement:expression name:@"Min" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Height"])
  {
    [self drawLineFromElement:expression name:@"Height" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"AGreaterThanB"])
  {
    [self drawLineFromElement:expression name:@"AGreaterThanB" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"AEqualsB"])
  {
    [self drawLineFromElement:expression name:@"AEqualsB" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"ALessThanB"])
  {
    [self drawLineFromElement:expression name:@"AGreaterThanB" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"Input"])
  {
    [self drawLineFromElement:expression name:@"Input" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"B"])
  {
    [self drawLineFromElement:expression name:@"B" index:index labelColor:color];index++;
  }
  
  if ([expression propertyForName:@"A"])
  {
    [self drawLineFromElement:expression name:@"A" index:index labelColor:color];index++;
  }
  
  if (index == 1 || ![expression propertyValue:@"Texture"])
  {
    index = 1;
  }
  index = [self drawElementParameters:expression names:@[@"ParameterName"] color:color class:[FName class] index:index];
  index = [self drawElementParameters:expression names:@[@"Speed", @"SpeedX", @"SpeedY", @"UTiling", @"VTiling", @"CoordinateIndex", @"BiasScale", @"Period", @"HeightRatio", @"ReferencePlane", @"DefaultValue"] color:color class:[NSNumber class] index:index];
  
  if ([name hasPrefix:@"Constant"] || [name hasPrefix:@"ComponentMask"])
  {
    index = [self drawElementParameters:expression names:@[@"R", @"G", @"B", @"A"] color:color class:[NSNumber class] index:index];
  }
  
  index = [self drawElementParameters:expression names:@[@"Texture"] color:color class:[UObject class] index:index];
}

- (int)drawElementParameters:(UObject*)expression names:(NSArray *)names color:(NSColor*)color class:(Class)objClass index:(int)idx
{
  __block int index = idx;
  [names enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *cname, NSUInteger idx, BOOL *stop) {
    NSNumber *value = [expression propertyValue:cname];
    if (value)
    {
      NSString *name = [cname copy];
      if ([cname isEqualToString:@"ParameterName"])
      {
        name = @"Name";
      }
      else if ([cname isEqualToString:@"Texture"])
      {
        name = @"Tex";
      }
      if ([objClass isSubclassOfClass:[NSNumber class]] || [objClass isSubclassOfClass:[NSString class]])
      {
        [self drawLabel:[NSString stringWithFormat:@"%@: %@", name, value] ofExpression:expression posY:index right:YES color:color];index++;
      }
      else if ([objClass isSubclassOfClass:[UObject class]])
      {
        [self drawLabel:[NSString stringWithFormat:@"%@: %@", name, [(UObject*)[expression.package objectForIndex:[value intValue]] objectName]] ofExpression:expression posY:index right:YES color:color];index++;
      }
      else if ([objClass isSubclassOfClass:[FName class]])
      {
        [self drawLabel:[NSString stringWithFormat:@"%@: %@", name, [expression.package nameForIndex:[value intValue]]] ofExpression:expression posY:index right:YES color:color];index++;
      }
    }
  }];
  return index;
}

- (void)drawLineFromElement:(UObject *)expression name:(NSString *)expressionName index:(int)index labelColor:(NSColor*)color
{
  NSArray *expressionContainer = [expression propertyValue:expressionName];
  if (![expressionContainer isKindOfClass:[NSArray class]] || ![[(FPropertyTag*)expressionContainer[0] type] isEqualToString:kPropTypeObj])
  {
    return;
  }
  
  NSMutableArray *mask = [NSMutableArray new];
  for (FPropertyTag *property in expressionContainer)
  {
    if ([[property name] isEqualToString:@"MaskR"])
    {
      [mask addObject:@"R"];
    }
    else if ([[property name] isEqualToString:@"MaskG"])
    {
      [mask addObject:@"G"];
    }
    else if ([[property name] isEqualToString:@"MaskB"])
    {
      [mask addObject:@"B"];
    }
    else if ([[property name] isEqualToString:@"MaskA"])
    {
      [mask addObject:@"A"];
    }
  }
  NSRect sourceBounds = [self expressionBounds:expression];
  NSPoint sourcePos = NSMakePoint(NSMinX(sourceBounds), sourceBounds.origin.y);
  
  NSString *label = [NSString stringWithFormat:@"%@%@", expressionName, mask.count ? [NSString stringWithFormat:@"(%@)", [mask componentsJoinedByString:@","]] : @""];
  
  [self drawLabel:label ofExpression:expression posY:index right:NO color:color];
  UObject *destExpression = [expression.package objectForIndex:[[(FPropertyTag*)expressionContainer[0] value] intValue]];
  NSRect targetBounds = [self expressionBounds:destExpression];
  NSPoint targetPos = NSMakePoint(NSMaxX(targetBounds), NSMidY(targetBounds));
  
  [[NSColor grayColor] setStroke];
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:targetPos];
  [path curveToPoint:NSMakePoint(sourcePos.x, sourcePos.y + ((index - 1) * AttrFontSize + AttrFontSize)) controlPoint1:NSMakePoint(targetPos.x + 50, targetPos.y) controlPoint2:NSMakePoint(sourcePos.x - 50, sourcePos.y + ((index - 1) * AttrFontSize) + AttrFontSize)];
  [path stroke];
}

- (void)drawLabel:(NSString *)label ofExpression:(UObject *)expression posY:(int)posY right:(BOOL)right color:(NSColor*)color
{
  NSRect lableRect = [label boundingRectWithSize:NSMakeSize(5000, AttrFontSize) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [NSFont systemFontOfSize:AttrFontSize], NSForegroundColorAttributeName : [NSColor labelColor]} context:nil];
  NSRect bounds = [self expressionBounds:expression];
  NSPoint pos = NSMakePoint(0, NSMinY(bounds) + ((posY - 1) * AttrFontSize) + (AttrFontSize / 2.));
  if (right)
  {
    pos.x = NSMaxX(bounds) - NSWidth(lableRect) - 5;
  }
  else
  {
    pos.x = NSMinX(bounds) + 5;
  }
  [label drawAtPoint:pos withAttributes:@{NSFontAttributeName : [NSFont systemFontOfSize:AttrFontSize], NSForegroundColorAttributeName : [NSColor labelColor]}];
}

@end
