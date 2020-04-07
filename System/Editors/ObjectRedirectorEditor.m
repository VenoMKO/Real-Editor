//
//  ObjectRedirectorEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 04/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "ObjectRedirectorEditor.h"
#import "UPackage.h"
#import "PackageController.h"

@interface ObjectRedirectorEditor ()

@end

@implementation ObjectRedirectorEditor
@dynamic object;

-(void)viewDidAppear
{
  if (!self.view.superview)
    return;
  NSView *v = self.object.reference.editor.view;
  if (v.superview)
    [v removeFromSuperview];
  [self.view addScaledSubview:v];
}

- (NSArray *)propertiesViews
{
  return self.object.reference.editor.propertiesViews;
}

- (IBAction)goToOriginal:(id)sender
{
  [self.object.package.controller selectObject:self.object.reference];
}

- (BOOL)hideProperties
{
  return YES;
}

@end
