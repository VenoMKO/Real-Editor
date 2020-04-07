//
//  FMipMap.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 06/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FMipMap.h"
#import "FBulkData.h"

@interface FMipMap ()
@property (strong) FBulkData *data;
@end

@implementation FMipMap

+ (instancetype)readFrom:(FIStream *)s
{
  FMipMap *mipmap = [super readFrom:s];
  mipmap.data = [FBulkData readFrom:s];
  mipmap.width = [s readInt:0];
  mipmap.height = [s readInt:0];
  return mipmap;
}

+ (instancetype)unusedMip
{
  FMipMap *mipmap = [FMipMap new];
  mipmap.data = [FBulkData new];
  [mipmap.data setUnused:YES];
  return mipmap;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.data cooked:offset]];
  [d writeInt:self.width];
  [d writeInt:self.height];
  return d;
}

- (BOOL)isValid
{
  return !([self.data isUnused] && [self.data isRemote]) && self.data.data && self.width && self.height;
}

- (NSData *)rawData
{
  return [self.data decompressedData];
}

- (void)setRawData:(NSData *)data
{
  if (!self.data)
  {
    self.data = [FBulkData new];
    self.data.package = self.package;
  }
  [self.data setDecompressedData:data];
}

- (void)setCompression:(int)compression
{
  if (!self.data)
  {
    self.data = [FBulkData new];
    self.data.package = self.package;
  }
  [self.data setCompression:compression];
}

- (int)compression
{
  return self.data.compression;
}

@end
