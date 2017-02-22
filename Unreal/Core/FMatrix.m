//
//  FMatrix.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FMatrix.h"
#import "FStream.h"

@interface FMatrix ()
{
  float m[16];
}
@end

@implementation FMatrix

+ (id)readFrom:(FIStream *)stream
{
  FMatrix *m = [super readFrom:stream];
  
  for (int i = 0; i < 16; ++i)
    m[i] = @([stream readFloat:0]);
  
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData data];
  for (int i = 0; i < 16; i++)
  {
    [d writeFloat:m[i]];
  }
  return d;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
  return @(m[idx]);
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
  m[idx] = [obj floatValue];
}

- (id)copyWithZone:(NSZone *)zone
{
  FMatrix *f = [FMatrix newWithPackage:self.package];
  
  for (int i = 0; i < 16; i++)
  {
    f[i] = @(m[i]);
  }
  
  return f;
}

@end
