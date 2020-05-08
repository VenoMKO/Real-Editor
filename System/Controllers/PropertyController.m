//
//  PropertyController.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 30/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PropertyController.h"
#import "PackageController.h"
#import "FPropertyTag.h"
#import "UPackage.h"
#import "TextButton.h"
#import "UObject.h"
#import "FVector.h"
#import "FRotator.h"
#import "FString.h"
#import "FColor.h"
#import "FMatrix.h"

@interface PropertyController ()

@property (assign) BOOL                     editMode;
@property (strong) NSArray                  *objects;
@property (strong) NSMutableArray           *subProperties;
@property (strong) NSMutableArray           *subviews;


@property (weak) IBOutlet NSStackView       *arrayStack;
@property (weak) IBOutlet NSBox             *arrayVerticalOutline;
@property (weak) IBOutlet NSComboBox        *objectBox;
@property (weak) IBOutlet NSTextField       *textField;
@property (weak) IBOutlet NSLayoutConstraint*editTrailing;
@property (weak) IBOutlet NSLayoutConstraint*editHeight;
@property (weak) FPropertyTag               *parentProperty;
@property (assign) int                      arrayIndex;
@end

@implementation PropertyController

+ (id)controllerForProperty:(FPropertyTag *)tag arrayIndex:(NSInteger)index parent:(FPropertyTag *)parent
{
  PropertyController *controller = [PropertyController controllerForProperty:tag];
  controller.parentProperty = parent;
  controller.arrayIndex = (int)index;
  return controller;
}

+ (id)controllerForProperty:(FPropertyTag *)tag
{
  if (!tag)
    return nil;
  
  PropertyController *c = [[super alloc] initWithNibName:tag.xib bundle:[NSBundle mainBundle]];
  c.property = tag;
  tag.controller = c;
  return c;
}

- (void)addArraySubView:(NSView *)subview
{
  if (!self.subviews)
    self.subviews = [NSMutableArray new];
  
  [self.subviews addObject:subview];
}

- (void)viewDidLoad
{
  if (([self.property.type isEqualToString:kPropTypeArray] && ![self.property.arrayType isEqualToString:@"Raw"]) || ([self.property.type isEqualToString:kPropTypeStruct] &&
                                                              [self.property.arrayType isEqualToString:@"Property"]))
  {
    if ([self.property.arrayType isEqualToString:@"Property"])
    {
      for (id object in self.property.value)
      {
        if ([object isKindOfClass:[NSArray class]])
        {
          for (FPropertyTag *tag in object)
          {
            [self addArraySubView:tag.controller.view];
          }
        }
        else
        {
          FPropertyTag *tag = (FPropertyTag *)object;
          [self addArraySubView:tag.controller.view];
        }
      }
    }
    else
    {
      if (!self.subProperties)
        self.subProperties = [NSMutableArray new];
      
      for (int idx = 0; idx < self.property.elementCount; ++idx)
      {
        FPropertyTag *t = nil;
        FPropertyTag *tag = self.property;
        NSString *title = [NSString stringWithFormat:@"Item %d",idx + 1];
        NSString *atype = tag.arrayType;
        
        if ([atype isEqualToString:@"Object"])
        {
          t = [FPropertyTag objectProperty:[tag.package objectForIndex:[tag.value[idx] intValue]] name:title object:tag.object];
        }
        else if ([atype isEqualToString:@"Name"])
        {
          t = [FPropertyTag nameProperty:[tag.value[idx] string] name:title object:tag.object];
        }
        else if ([atype isEqualToString:@"Bool"])
        {
          t = [FPropertyTag boolProperty:[tag.value[idx] boolValue] name:title object:tag.object];
        }
        else if ([atype isEqualToString:@"Int"] || ((tag.dataSize - 4) / tag.elementCount) == 4)
        {
          t = [FPropertyTag intProperty:[tag.value[idx] intValue] name:title object:tag.object];
        }
        else if ([atype isEqualToString:@"Float"])
        {
          t = [FPropertyTag floatProperty:[tag.value[idx] floatValue] name:title object:tag.object];
        }
        else if ([atype isEqualToString:@"Raw"])
        {
          DLog(@"Undef RAW:%@",tag.arrayType);
        }
        else
        {
          DLog(@"Undef:%@:%@", tag, atype);
        }
        
        PropertyController *ctrl = [PropertyController controllerForProperty:t arrayIndex:idx parent:tag];
        if (ctrl)
        {
          [self.subProperties addObject:t];
          [self addArraySubView:ctrl.view];
        }
      }
    }
  }
  else if ([self.property.type isEqualToString:kPropTypeObj])
  {
    TextFieldWithGoButton *t = (TextFieldWithGoButton *)self.textField;
    t.goAction = @selector(goToObject:);
    t.goTarget = self;
  }
  [super viewDidLoad];
}

- (IBAction)goToObject:(id)sender
{
  UObject *object = [self.property.package objectForIndex:[self.property.value integerValue]];
  [self.property.package.controller selectObject:object];
}

- (id)formattedM0
{
  FMatrix *m = self.property.value;
  return m[0];
}

- (id)formattedM1
{
  FMatrix *m = self.property.value;
  return m[1];
}
- (id)formattedM2
{
  FMatrix *m = self.property.value;
  return m[2];
}
- (id)formattedM3
{
  FMatrix *m = self.property.value;
  return m[3];
}
- (id)formattedM4
{
  FMatrix *m = self.property.value;
  return m[4];
}
- (id)formattedM5
{
  FMatrix *m = self.property.value;
  return m[5];
}
- (id)formattedM6
{
  FMatrix *m = self.property.value;
  return m[6];
}
- (id)formattedM7
{
  FMatrix *m = self.property.value;
  return m[7];
}
- (id)formattedM8
{
  FMatrix *m = self.property.value;
  return m[8];
}
- (id)formattedM9
{
  FMatrix *m = self.property.value;
  return m[9];
}
- (id)formattedM10
{
  FMatrix *m = self.property.value;
  return m[10];
}
- (id)formattedM11
{
  FMatrix *m = self.property.value;
  return m[11];
}
- (id)formattedM12
{
  FMatrix *m = self.property.value;
  return m[12];
}
- (id)formattedM13
{
  FMatrix *m = self.property.value;
  return m[13];
}
- (id)formattedM14
{
  FMatrix *m = self.property.value;
  return m[14];
}
- (id)formattedM15
{
  FMatrix *m = self.property.value;
  return m[15];
}

- (void)setFormattedM1:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[1] = v;
}
- (void)setFormattedM2:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[2] = v;
}
- (void)setFormattedM3:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[3] = v;
}
- (void)setFormattedM4:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[4] = v;
}
- (void)setFormattedM5:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[5] = v;
}
- (void)setFormattedM6:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[6] = v;
}
- (void)setFormattedM7:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[7] = v;
}
- (void)setFormattedM8:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[8] = v;
}
- (void)setFormattedM9:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[9] = v;
}
- (void)setFormattedM10:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[10] = v;
}
- (void)setFormattedM11:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[11] = v;
}
- (void)setFormattedM12:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[12] = v;
}
- (void)setFormattedM13:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[13] = v;
}
- (void)setFormattedM14:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[14] = v;
}
- (void)setFormattedM15:(NSNumber*)v
{
  FMatrix *m = self.property.value;
  m[15] = v;
}

- (NSString *)formattedName
{
  if ([self.property.type isEqualToString:kPropTypeArray])
  {
    if (![self.property.arrayType isEqualToString:@"Raw"])
    {
      return [NSString stringWithFormat:@"%@ [Count: %ld | Size: %d]",self.property.name, [self.property.value count], self.property.dataSize - 4];
    }
  }
  return self.property.name;
}

- (NSString *)formattedType
{
  return self.property.type;
}

- (id)formattedValue
{
  if ([self.property.type isEqualToString:kPropTypeObj])
  {
    UObject *object = [self.property.package objectForIndex:[self.property.value integerValue]];
    if (!object)
      return @"NULL";
    if ([object isZero])
      return @"ZERO";
    return [NSString stringWithFormat:@"%@ (%@)",object.objectName,object.objectClass];
  }
  else if ([self.property.type isEqualToString:kPropTypeName])
  {
    return [self.property.package nameForIndex:[self.property.value intValue]];
  }
  else if ([self.property.type isEqualToString:kPropTypeByte])
  {
    if (self.property.package.game == UGameBless)
    {
      return self.property.enumName;
    }
    else
    {
      return [self.property.package nameForIndex:[self.property.value intValue]];
    }
  }
  else if ([self.property.type isEqualToString:kPropTypeStruct])
  {
  }
  return self.property.value;
}

- (NSNumber *)formattedX
{
  FVector3 *v = self.property.value;
  if ([v isKindOfClass:[FRotator class]])
  {
    v = [[(FRotator *)v normalized] euler];
  }
  return @(v.x);
}

- (NSNumber *)formattedY
{
  FVector3 *v = self.property.value;
  if ([v isKindOfClass:[FRotator class]])
  {
    v = [[(FRotator *)v normalized] euler];
  }
  return @(v.y);
}

- (NSNumber *)formattedZ
{
  FVector3 *v = self.property.value;
  if ([v isKindOfClass:[FRotator class]])
  {
    v = [[(FRotator *)v normalized] euler];
  }
  return @(v.z);
}

- (NSNumber *)formattedW
{
  FVector4 *v = self.property.value;
  return @(v.w);
}

- (NSNumber *)formattedR
{
  FLinearColor *v = self.property.value;
  return @(v.r);
}

- (NSNumber *)formattedG
{
  FLinearColor *v = self.property.value;
  return @(v.g);
}

- (NSNumber *)formattedB
{
  FLinearColor *v = self.property.value;
  return @(v.b);
}

- (NSNumber *)formattedA
{
  FLinearColor *v = self.property.value;
  return @(v.a);
}

- (void)setFormattedX:(NSNumber *)x
{
  FVector3 *v = self.property.value;
  if ([v isKindOfClass:[FRotator class]])
  {
    FRotator *r = (FRotator *)v;
    v = [[r normalized] euler];
    v.x = [x doubleValue];
    [(FRotator *)v setEuler:v];
  }
  else
  {
    v.x = [x doubleValue];
  }
  [self.property.object setDirty:YES];
}

- (void)setFormattedY:(NSNumber *)x
{
  FVector3 *v = self.property.value;
  if ([v isKindOfClass:[FRotator class]])
  {
    FRotator *r = (FRotator *)v;
    v = [[r normalized] euler];
    v.y = [x doubleValue];
    [(FRotator *)v setEuler:v];
  }
  else
  {
    v.y = [x doubleValue];
  }
  [self.property.object setDirty:YES];
}

- (void)setFormattedZ:(NSNumber *)x
{
  FVector3 *v = self.property.value;
  if ([v isKindOfClass:[FRotator class]])
  {
    FRotator *r = (FRotator *)v;
    v = [[r normalized] euler];
    v.z = [x doubleValue];
    [(FRotator *)v setEuler:v];
  }
  else
  {
    v.z = [x doubleValue];
  }
  [self.property.object setDirty:YES];
}

- (void)setFormattedW:(NSNumber *)x
{
  FVector4 *v = self.property.value;
  v.w = [x doubleValue];
  [self.property.object setDirty:YES];
}

- (void)setFormattedR:(NSNumber *)x
{
  FColor *v = self.property.value;
  if ([v isKindOfClass:[FLinearColor class]])
    v.r = [x doubleValue];
  else
    v.r = [x intValue];
  [self.property.object setDirty:YES];
}

- (void)setFormattedG:(NSNumber *)x
{
  FColor *v = self.property.value;
  if ([v isKindOfClass:[FLinearColor class]])
    v.g = [x doubleValue];
  else
    v.g = [x intValue];
  [self.property.object setDirty:YES];
}

- (void)setFormattedB:(NSNumber *)x
{
  FColor *v = self.property.value;
  if ([v isKindOfClass:[FLinearColor class]])
    v.b = [x doubleValue];
  else
    v.b = [x intValue];
  [self.property.object setDirty:YES];
}

- (void)setFormattedA:(NSNumber *)x
{
  FColor *v = self.property.value;
  if ([v isKindOfClass:[FLinearColor class]])
    v.a = [x doubleValue];
  else
    v.a = [x intValue];
  [self.property.object setDirty:YES];
}

- (NSUInteger)dataSize
{
  if ([self.property.type isEqualToString:kPropTypeArray] && [self.property.arrayType isEqualToString:@"Raw"])
    return [self.property.value length];
  return self.property.dataSize;
}

- (IBAction)exportData:(id)sender
{
  NSData *d = self.property.value;
  if (!d || ![d isKindOfClass:[NSData class]] || !d.length)
    return;
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.directoryURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:kSettingsExportPath]];
  panel.nameFieldStringValue = [self.property.name stringByAppendingString:@".bin"];
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result != NSFileHandlingPanelOKButton)
      return;
    [d writeToURL:panel.URL atomically:YES];
    [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:kSettingsExportPath];
  }];
}

- (IBAction)importData:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.directoryURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:kSettingsImportPath]];
  [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
    if (result != NSFileHandlingPanelOKButton)
      return;
    NSData *d = [NSData dataWithContentsOfURL:panel.URL];
    [self willChangeValueForKey:@"dataSize"];
    self.property.value = d;
    [self.property recalculateSize];
    [self didChangeValueForKey:@"dataSize"];
    [self.property.object setDirty:YES];
    [[NSUserDefaults standardUserDefaults] setObject:[panel.URL.path stringByDeletingLastPathComponent] forKey:kSettingsImportPath];
    
  }];
}

- (void)setFormattedValue:(id)newValue
{
  if ([self.property.type isEqualToString:kPropTypeName] || [self.property.type isEqualToString:kPropTypeByte])
  {
    if ([self.parentProperty.arrayType isEqualToString:@"Name"])
    {
      FName *name = [FName nameWithString:newValue flags:0 package:self.parentProperty.package];
      self.property.value = name;
    }
    else
    {
      self.property.value = @([self.property.package indexForName:newValue]);
    }
  }
  else if ([self.property.type isEqualToString:kPropTypeString])
    self.property.value = [FString stringWithString:newValue];
  else
    self.property.value = newValue;
  
  if (self.parentProperty)
  {
    NSMutableArray *array = self.parentProperty.value;
    array[self.arrayIndex] = self.property.value;
  }
  
  [self.property.object setDirty:YES];
}

- (IBAction)toggleArray:(id)sender
{
  NSScrollView *scrollView = (NSScrollView *)self.view;
  while (scrollView && ![scrollView isKindOfClass:[NSScrollView class]])
  {
    scrollView = (NSScrollView *)scrollView.superview;
  }
  if ([sender state])
  {
    for (NSView *subview in self.subviews)
    {
      
      [self.arrayStack addView:subview inGravity:NSStackViewGravityCenter];
      [self.arrayStack addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[v]-0-|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:@{@"v" : subview}]];
    }
  }
  else
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (IBAction)toggleEdit:(id)sender
{
  self.editMode = !self.editMode;
  
  if (_editMode)
  {
    [self.objectBox removeAllItems];
    
    self.objects = [self.property.package allObjectsOfClass:nil];
    
    for (UObject *object in self.objects)
    {
      [self.objectBox addItemWithObjectValue:[NSString stringWithFormat:@"%@ (%@)",object.objectName,object.objectClass]];
    }
    
    UObject *obj = [self.property.package objectForIndex:[self.property.value integerValue]];
    [self.objectBox selectItemAtIndex:[self.objects indexOfObject:obj]];
  }
  
  [CATransaction begin];
  [CATransaction setAnimationDuration:.1f];
  self.editTrailing.animator.constant = _editMode ? -39 : 5;
  self.editHeight.animator.constant = _editMode ? 78 : 53;
  [CATransaction commit];
}

- (IBAction)applyEdit:(id)sender
{
  NSInteger idx = [self.objectBox indexOfSelectedItem];
  
  if (idx != -1)
  {
    [self willChangeValueForKey:@"formattedValue"];
    self.property.value = @([self.property.package indexForObject:self.objects[idx]]);
    [self didChangeValueForKey:@"formattedValue"];
    if (self.parentProperty)
    {
      NSMutableArray *array = self.parentProperty.value;
      array[self.arrayIndex] = self.property.value;
    }
  }
  else
    NSBeep();
  
  [self toggleEdit:nil];
}

- (void)cleanup
{
  [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  self.subviews = nil;
  [self willChangeValueForKey:@"formattedValue"];
  self.property = nil;
  self.parentProperty = nil;
  [self didChangeValueForKey:@"formattedValue"];
  for (FPropertyTag *tag in self.subProperties)
  {
    tag.controller = nil;
  }
}

@end
