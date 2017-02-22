//
//  FStreamableTextureInstance.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FStreamableTextureInstance.h"

@implementation FStreamableTextureInstance

+ (instancetype)readFrom:(FIStream *)stream
{
  FStreamableTextureInstance *i = [super readFrom:stream];
  i.boundingSphere = [FSphereBounds readFrom:stream];
  i.texelFactor = [stream readFloat:NULL];
  return i;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.boundingSphere cooked:offset];
  [d writeFloat:self.texelFactor];
  return d;
}

@end
