//
//  TextureCubeEditor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 25/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "TextureCubeEditor.h"
#import "FPropertyTag.h"
#import "UPackage.h"
#import "Texture2D.h"

@interface TextureCubeEditor ()
@property (strong) NSImage *render;
@property (strong) NSMutableDictionary<NSString *,Texture2D *> *set;
@end

@implementation TextureCubeEditor

- (void)viewDidLoad
{
  NSMutableDictionary<NSString *,Texture2D *> *faces = [NSMutableDictionary new];
  FPropertyTag *tag = [self.object propertyForName:@"FacePosZ"];
  if (tag.value)
    faces[@"Z+"] = [self.object.package objectForIndex:[tag.value intValue]];
  else
    return;
  
  tag = [self.object propertyForName:@"FaceNegZ"];
  if (tag.value)
    faces[@"Z-"] = [self.object.package objectForIndex:[tag.value intValue]];
  else
    return;
  
  tag = [self.object propertyForName:@"FacePosX"];
  if (tag.value)
    faces[@"X+"] = [self.object.package objectForIndex:[tag.value intValue]];
  else
    return;
  
  tag = [self.object propertyForName:@"FaceNegX"];
  if (tag.value)
    faces[@"X-"] = [self.object.package objectForIndex:[tag.value intValue]];
  else
    return;
  
  tag = [self.object propertyForName:@"FacePosY"];
  if (tag.value)
    faces[@"Y+"] = [self.object.package objectForIndex:[tag.value intValue]];
  else
    return;
  
  tag = [self.object propertyForName:@"FaceNegY"];
  if (tag.value)
    faces[@"Y-"] = [self.object.package objectForIndex:[tag.value intValue]];
  else
    return;
  
  self.set = faces;
  [self updateImage];
}

- (void)updateImage
{
  CGFloat refSizeX = 0;
  CGFloat refSizeY = 0;
  __block NSSize size = NSZeroSize;
  [self.set enumerateKeysAndObjectsUsingBlock:^(NSString *key, Texture2D *obj, BOOL * _Nonnull stop) {
    if ([obj size].width > size.width)
      size = [obj size];
  }];
  if (NSEqualSizes(NSZeroSize, size))
    return;
  refSizeX = size.width;
  refSizeY = size.height;
  size.height = size.height * 3;
  size.width = size.width * 4;
  NSImage *render = [[NSImage alloc] initWithSize:size];
  
  [render lockFocus];
  
  NSPoint pos = NSMakePoint(0, refSizeY);
  NSImage *r = [self.set[@"X-"] renderedImageR:YES G:YES B:YES A:NO];
  [r drawInRect:NSMakeRect(pos.x, pos.y, refSizeX, refSizeY)];
  
  pos = NSMakePoint(refSizeX, 0);
  r = [self.set[@"Y-"] renderedImageR:YES G:YES B:YES A:NO];
  [r drawInRect:NSMakeRect(pos.x, pos.y, refSizeX, refSizeY)];
  
  pos = NSMakePoint(refSizeX, refSizeY);
  r = [self.set[@"Z+"] renderedImageR:YES G:YES B:YES A:NO];
  [r drawInRect:NSMakeRect(pos.x, pos.y, refSizeX, refSizeY)];
  
  pos = NSMakePoint(refSizeX, refSizeY * 2);
  r = [self.set[@"Y+"] renderedImageR:YES G:YES B:YES A:NO];
  [r drawInRect:NSMakeRect(pos.x, pos.y, refSizeX, refSizeY)];
  
  pos = NSMakePoint(refSizeX * 2, refSizeY);
  r = [self.set[@"X+"] renderedImageR:YES G:YES B:YES A:NO];
  [r drawInRect:NSMakeRect(pos.x, pos.y, refSizeX, refSizeY)];
  
  pos = NSMakePoint(refSizeX * 3, refSizeY);
  r = [self.set[@"Z-"] renderedImageR:YES G:YES B:YES A:NO];
  [r drawInRect:NSMakeRect(pos.x, pos.y, refSizeX, refSizeY)];
  
  [render unlockFocus];
  self.render = render;
}

@end
