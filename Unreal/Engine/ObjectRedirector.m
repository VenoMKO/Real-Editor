//
//  ObjectRedirector.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 04/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "ObjectRedirector.h"
#import "UPackage.h"
#import "FStream.h"

@implementation ObjectRedirector

- (BOOL)canExport
{
  return [self.reference canExport];
}

- (NSImage *)icon
{
  if (!self.reference)
    [self readProperties];
  NSImage* fileIcon = [self.reference icon];
  NSImage* aliasBadge = [UObject systemIcon:kAliasBadgeIcon];
  NSImage* badgedFileIcon = [NSImage imageWithSize:fileIcon.size flipped:NO drawingHandler:^BOOL (NSRect dstRect){
    [fileIcon drawAtPoint:dstRect.origin fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
    [aliasBadge drawAtPoint:dstRect.origin fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
    return YES;
  }];
  return badgedFileIcon;
}

- (FIStream *)postProperties
{
  [super postProperties];
  FIStream *s = [self.package.stream copy];
  s.position = self.rawDataOffset;
  self.reference = [UObject readFrom:s];
  return s;
}

- (NSData *)exportWithOptions:(NSDictionary *)options
{
  return [self.reference exportWithOptions:options];
}

@end
