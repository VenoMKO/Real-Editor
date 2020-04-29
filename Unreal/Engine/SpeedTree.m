//
//  SpeedTree.m
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "SpeedTree.h"
#import "UPackage.h"

@implementation SpeedTree

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  s.position = self.rawDataOffset;
  int numBytes = [s readInt:NULL];
  self.sptData = [s readData:numBytes];
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self cookedProperties];
  [d writeInt:(int)self.sptData.length];
  [d appendData:self.sptData];
  return d;
}

- (NSData *)exportWithOptions:(NSDictionary *)options
{
  if (self.sptData)
  {
    [self properties];
  }
  return self.sptData;
}

@end
