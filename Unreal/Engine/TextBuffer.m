//
//  TextBuffer.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 18/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "TextBuffer.h"
#import "UPackage.h"
#import "FStream.h"

@implementation TextBuffer

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  s.position = self.rawDataOffset;
  self.pos = [s readInt:0];
  self.top = [s readInt:0];
  self.text = [FString readFrom:s];
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self cookedProperties];
  [d writeInt:self.pos];
  [d writeInt:self.top];
  [d appendData:[self.text cooked:offset + d.length]];
  return d;
}

@end
