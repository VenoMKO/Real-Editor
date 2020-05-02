//
//  FQuat.m
//  Real Editor
//
//  Created by VenoMKO on 1.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "FQuat.h"

@implementation FQuat

+ (instancetype)readFrom:(FIStream *)stream
{
  FQuat *q = [super readFrom:stream];
  q.x = [stream readFloat:NO];
  q.y = [stream readFloat:NO];
  q.z = [stream readFloat:NO];
  q.w = [stream readFloat:NO];
  return q;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeFloat:self.x];
  [d writeFloat:self.y];
  [d writeFloat:self.z];
  [d writeFloat:self.w];
  return d;
}

@end
