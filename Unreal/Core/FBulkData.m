//
//  FBulkData.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FBulkData.h"
#import "UPackage.h"

#define BULKDATA_StoreInSeparateFile	0x01		// bulk stored in different file
#define BULKDATA_CompressedZlib       0x02		// lzo
#define BULKDATA_CompressedLzo        0x10		// zlib
#define BULKDATA_Unused               0x20		// empty bulk block
#define BULKDATA_SeparateData         0x40		// offset differs

NSString *NSStringFromBulkFlags(int flags)
{
  NSString *retVal = @"";
  if (flags & BULKDATA_CompressedZlib)
    retVal = [retVal stringByAppendingString:@"CompressedZlib, "];
  else if (flags & BULKDATA_CompressedLzo)
    retVal = [retVal stringByAppendingString:@"CompressedLzo, "];
  else
    retVal = [retVal stringByAppendingString:@"CompressNone, "];
  if (flags & BULKDATA_StoreInSeparateFile)
    retVal = [retVal stringByAppendingString:@"StoreInSeparateFile, "];
  if (flags & BULKDATA_Unused)
    retVal = [retVal stringByAppendingString:@"Unused, "];
  if (flags & BULKDATA_SeparateData)
    retVal = [retVal stringByAppendingString:@"SeparateData, "];
  if ([retVal hasSuffix:@", "])
    retVal = [retVal stringByPaddingToLength:retVal.length - 2 withString:@"" startingAtIndex:0];
  return retVal;
}

@implementation FBulkData

+ (instancetype)emptyUnusedData
{
  FBulkData *d = [FBulkData new];
  d.flags = BULKDATA_Unused;
  return d;
}

- (instancetype)init
{
  self = [super init];
  if (self)
  {
    self.flags = BULKDATA_CompressedLzo;
  }
  return self;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  FBulkData *data = [super readFrom:stream];
  BOOL err = NO;
  data.flags = [stream readInt:&err];
  data.decompressedSize = [stream readInt:&err];
  data.compressedSize = [stream readInt:&err];
  data.compressedOffset = [stream readInt:&err];
  
  if (err)
  {
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  
  if (!(data.flags & BULKDATA_Unused) && !(data.flags & BULKDATA_StoreInSeparateFile) && data.compressedSize)
  {
    NSInteger pos = 0;
    if (stream.position != data.compressedOffset && data.compressedOffset)
    {
      pos = stream.position;
      stream.position = data.compressedOffset;
    }
    
    data.data = [stream readData:data.compressedSize];
    if ([data.data length] != data.compressedSize)
    {
      DThrow(@"Warning! Bulk data has incorrect length!");
      return nil;
    }
    if (pos)
      stream.position = pos;
  }
  
  return data;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.flags];
  [d writeInt:self.decompressedSize];
  [d writeInt:self.compressedSize];
  if (!(self.flags & BULKDATA_Unused || self.flags & BULKDATA_StoreInSeparateFile))
    self.compressedOffset = (int)offset + (int)d.length + 4;
  if (self.compressedSize == INT32_MAX)
    self.compressedOffset = INT32_MAX;
  [d writeInt:self.compressedOffset];
  if (!(self.flags & BULKDATA_Unused || self.flags & BULKDATA_StoreInSeparateFile))
    [d appendData:self.data];
  return d;
}

- (NSData *)decompressedData
{
  if (!self.data)
  {
    DLog(@"[%@]Error! Cant decompress empty data!",self.package.name);
    return nil;
  }
  NSMutableData *d = [NSMutableData new];
  BOOL success = NO;
  if (self.flags & BULKDATA_CompressedLzo)
    success = decompressLZO((uint8_t *)self.data.bytes,d);
  else if (self.flags & BULKDATA_CompressedZlib)
    success = decompressZLib((uint8_t *)self.data.bytes,d);
  else
    d = [NSMutableData dataWithData:self.data];
  
  if (!success && !d)
  {
    DThrow(@"[%@]Failed to decompress Bulk data!",self.package.name);
    return nil;
  }
  
  return d;
}

- (void)setCompression:(int)compression
{
  NSData *raw = [self decompressedData];
  if (compression == COMPRESSION_LZO)
  {
    if (self.flags & BULKDATA_CompressedZlib)
      self.flags &= ~BULKDATA_CompressedZlib;
    
    self.flags |= BULKDATA_CompressedLzo;
  }
  else if (compression == COMPRESSION_ZLIB)
  {
    if (self.flags & BULKDATA_CompressedLzo)
      self.flags &= ~BULKDATA_CompressedLzo;
    
    self.flags |= BULKDATA_CompressedZlib;
  }
  else if (compression == COMPRESSION_NONE)
  {
    if (self.flags & BULKDATA_CompressedZlib)
      self.flags &= ~BULKDATA_CompressedZlib;
    if (self.flags & BULKDATA_CompressedLzo)
      self.flags &= ~BULKDATA_CompressedLzo;
  }
  if (raw)
    [self setDecompressedData:raw];
  else
    [self setUnused:YES];
}

- (int)compression
{
  if (self.flags & BULKDATA_CompressedZlib)
    return COMPRESSION_ZLIB;
  if (self.flags & BULKDATA_CompressedLzo)
    return COMPRESSION_LZO;
  return COMPRESSION_NONE;
}

- (void)setDecompressedData:(NSData *)data
{
  NSMutableData *compressed = [NSMutableData new];
  if (self.flags & BULKDATA_CompressedLzo)
    compressLZO(data,compressed);
  else if (self.flags & BULKDATA_CompressedZlib)
    compressZLib(data,compressed);
  else
    compressed = [NSMutableData dataWithData:data];
  
  self.data = compressed;
  self.decompressedSize = (unsigned)data.length;
  self.compressedSize = (unsigned)compressed.length;
  if (compressed.length)
    self.isUnused = NO;
}

- (BOOL)isUnused
{
  return self.flags & BULKDATA_Unused;
}

- (void)setUnused:(BOOL)flag
{
  if (flag)
    self.flags |= BULKDATA_Unused;
  else
    self.flags &= ~BULKDATA_Unused;
  
}

- (BOOL)isRemote
{
  return self.flags & BULKDATA_StoreInSeparateFile;
}

- (void)setIsRemote:(BOOL)flag
{
  if (flag)
    self.flags |= BULKDATA_StoreInSeparateFile;
  else
    self.flags &= ~BULKDATA_StoreInSeparateFile;
}

- (void)setIsUnused:(BOOL)flag
{
  [self setUnused:flag];
}

@end

@implementation FByteBulkData

+ (instancetype)readFrom:(FIStream *)stream
{
  FByteBulkData *data = [super readFrom:stream];
  BOOL err = NO;
  data.flags = [stream readInt:&err];
  data.elementCount = [stream readInt:&err];
  data.compressedSize = [stream readInt:&err];
  data.compressedOffset = [stream readInt:&err];
  
  if (!(data.flags & BULKDATA_Unused) && !(data.flags & BULKDATA_StoreInSeparateFile) && data.elementCount * data.elementSize)
  {
    NSInteger pos = 0;
    if (stream.position != data.compressedOffset && data.compressedOffset)
    {
      pos = stream.position;
      stream.position = data.compressedOffset;
    }
    
    data.data = [stream readData:data.elementCount * data.elementSize];
    if ([data.data length] != data.compressedSize)
    {
      DThrow(@"Warning! Bulk data has incorrect length!");
      return nil;
    }
    if (pos)
      stream.position = pos;
  }
  
  return data;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.flags];
  [d writeInt:self.elementCount];
  [d writeInt:self.compressedSize];
  self.compressedOffset = (int)offset + (int)d.length + 4;
  [d writeInt:self.compressedOffset];
  if (!(self.flags & BULKDATA_Unused || self.flags & BULKDATA_StoreInSeparateFile))
    [d appendData:self.data];
  return d;
}

- (int)elementSize
{
  return 1;
}

- (BOOL)isUnused
{
  return self.flags & BULKDATA_Unused;
}

- (void)setUnused:(BOOL)flag
{
  if (flag)
    self.flags |= BULKDATA_Unused;
  else
    self.flags &= ~BULKDATA_Unused;
  
}

- (BOOL)isRemote
{
  return self.flags & BULKDATA_StoreInSeparateFile;
}

- (void)setIsRemote:(BOOL)flag
{
  if (flag)
    self.flags |= BULKDATA_StoreInSeparateFile;
  else
    self.flags &= ~BULKDATA_StoreInSeparateFile;
}

- (NSData *)decompressedData
{
  if (!self.data)
  {
    DThrow(@"Error! Cant decompress empty data!");
    return nil;
  }
  NSMutableData *d = [NSMutableData new];
  BOOL success = NO;
  if (self.flags & BULKDATA_CompressedLzo)
    success = decompressLZO((uint8_t *)self.data.bytes,d);
  else if (self.flags & BULKDATA_CompressedZlib)
    success = decompressZLib((uint8_t *)self.data.bytes,d);
  else
    d = [NSMutableData dataWithData:self.data];
  
  if (!success)
  {
    DThrow(@"Failed to decompress Bulk data!");
    return nil;
  }
  
  return d;
}

- (void)setCompression:(int)compression
{
  NSData *raw = [self decompressedData];
  if (compression == COMPRESSION_LZO)
  {
    if (self.flags & BULKDATA_CompressedZlib)
      self.flags &= ~BULKDATA_CompressedZlib;
    
    self.flags |= BULKDATA_CompressedLzo;
  }
  else if (compression == COMPRESSION_ZLIB)
  {
    if (self.flags & BULKDATA_CompressedLzo)
      self.flags &= ~BULKDATA_CompressedLzo;
    
    self.flags |= BULKDATA_CompressedZlib;
  }
  else if (compression == COMPRESSION_NONE)
  {
    if (self.flags & BULKDATA_CompressedZlib)
      self.flags &= ~BULKDATA_CompressedZlib;
    if (self.flags & BULKDATA_CompressedLzo)
      self.flags &= ~BULKDATA_CompressedLzo;
  }
  if (raw)
    [self setDecompressedData:raw];
  else
    [self setUnused:YES];
}

- (int)compression
{
  if (self.flags & BULKDATA_CompressedZlib)
    return COMPRESSION_ZLIB;
  if (self.flags & BULKDATA_CompressedLzo)
    return COMPRESSION_LZO;
  return COMPRESSION_NONE;
}

- (void)setDecompressedData:(NSData *)data
{
  NSMutableData *compressed = [NSMutableData new];
  if (self.flags & BULKDATA_CompressedLzo)
    compressLZO(data,compressed);
  else if (self.flags & BULKDATA_CompressedZlib)
    compressZLib(data,compressed);
  else
    compressed = [NSMutableData dataWithData:data];
  
  self.data = compressed;
  self.compressedSize = (unsigned)compressed.length;
}

@end
