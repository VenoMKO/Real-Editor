//
//  FRawAnimSequenceTrack.m
//  Real Editor
//
//  Created by VenoMKO on 1.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "FRawAnimSequenceTrack.h"
#import "FVector.h"
#import "FQuat.h"

@implementation FRawAnimSequenceTrack

+ (instancetype)readFrom:(FIStream *)stream
{
  FRawAnimSequenceTrack *r = [super readFrom:stream];
  r.posKeys = [TArray bulkSerializeFrom:stream type:[FVector3 class]];
  r.rotKeys = [TArray bulkSerializeFrom:stream type:[FQuat class]];
  r.timeKeys = [TArray bulkSerializeFrom:stream type:[NSNumber class]];
  return r;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  offset += d.length;
  NSMutableData *arrayData = [self.posKeys bulkCooked:offset];
  offset += arrayData.length;
  [d appendData:arrayData];
  return d;
}

@end
