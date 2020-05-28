//
//  Extensions.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "Extensions.h"
#import "FStream.h"
#import "FReadable.h"
#import "minilzo.h"
#import "MeshUtils.h"
#import <zlib.h>
#import <stdlib.h>

#import <objc/runtime.h>

#define HEAP_ALLOC(var,size) \
lzo_align_t __LZO_MMODEL var [ ((size) + (sizeof(lzo_align_t) - 1)) / sizeof(lzo_align_t) ]
static HEAP_ALLOC(wrkmem, LZO1X_1_MEM_COMPRESS);
#define LZO_CHUNK_SIZE 0x20000 //131072
#define ZLIB_CHUNK_SIZE LZO_CHUNK_SIZE
#define LZO_MAGIC 0x9E2A83C1
#define ZLIB_MAGIC LZO_MAGIC

@implementation NSURLSession (SynchronousTask)

#pragma mark - NSURLSessionDataTask

- (NSData *)sendSynchronousDataTaskWithURL:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  return [self sendSynchronousDataTaskWithRequest:[NSURLRequest requestWithURL:url] returningResponse:response error:error];
}

- (NSData *)sendSynchronousDataTaskWithRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block NSData *data = nil;
  [[self dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
    data = taskData;
    if (response) {
      *response = taskResponse;
    }
    if (error) {
      *error = taskError;
    }
    dispatch_semaphore_signal(semaphore);
  }] resume];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  
  return data;
}

#pragma mark - NSURLSessionDownloadTask

- (NSURL *)sendSynchronousDownloadTaskWithURL:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  return [self sendSynchronousDownloadTaskWithRequest:[NSURLRequest requestWithURL:url] returningResponse:response error:error];
}

- (NSURL *)sendSynchronousDownloadTaskWithRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block NSURL *location = nil;
  [[self downloadTaskWithRequest:request completionHandler:^(NSURL *taskLocation, NSURLResponse *taskResponse, NSError *taskError)
  {
    location = taskLocation;
    if (response)
    {
      *response = taskResponse;
    }
    if (error)
    {
      *error = taskError;
    }
    dispatch_semaphore_signal(semaphore);
  }] resume];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  
  return location;
}

#pragma mark - NSURLSessionUploadTask

- (NSData *)sendSynchronousUploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  return [self sendSynchronousUploadTaskWithRequest:request fromData:[NSData dataWithContentsOfURL:fileURL] returningResponse:response error:error];
}

- (NSData *)sendSynchronousUploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block NSData *data = nil;
  [[self uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
    data = taskData;
    if (response)
    {
      *response = taskResponse;
    }
    if (error)
    {
      *error = taskError;
    }
    dispatch_semaphore_signal(semaphore);
  }] resume];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  
  return data;
}

@end


@implementation NSArray (Extensions)

+ (instancetype)readFrom:(FIStream *)stream class:(Class)type length:(NSUInteger)length
{
  NSMutableArray *a = [NSMutableArray arrayWithCapacity:length];
  
  for (int idx = 0; idx < length; ++idx)
  {
    id child = [type readFrom:stream];
    if (!child)
    {
      DThrow(@"Error failed to read array of objects %@ at index: %d", NSStringFromClass(type), idx);
      return nil;
    }
    [a addObject:child];
  }
  
  return a;
}

- (NSMutableData *)cookedAt:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData data];
  NSUInteger off = offset;
  for (FReadable *obj in self)
  {
    NSMutableData *c = [obj cooked:off];
    [d appendData:c];
    off+= c.length;
  }
  return d;
}

@end

@implementation NSView (Extensions)

- (void)addScaledSubview:(NSView *)aView
{
  if (aView.superview == self)
    return;
  
  aView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:aView];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[v]-0-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:@{@"v" : aView}]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[v]-0-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:@{@"v" : aView}]];
}

@end

@implementation NSImage (Extensions)

-(NSBitmapImageRep *)unscaledBitmapImageRep
{
  
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                           initWithBitmapDataPlanes:NULL
                           pixelsWide:self.size.width
                           pixelsHigh:self.size.height
                           bitsPerSample:8
                           samplesPerPixel:4
                           hasAlpha:YES
                           isPlanar:NO
                           colorSpaceName:NSDeviceRGBColorSpace
                           bytesPerRow:0
                           bitsPerPixel:0];
  rep.size = self.size;
  
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:
   [NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
  
  [self drawAtPoint:NSMakePoint(0, 0)
           fromRect:NSZeroRect
          operation:NSCompositingOperationSourceOver
           fraction:1.0];
  
  [NSGraphicsContext restoreGraphicsState];
  return rep;
}

@end

NSString const *DataOffsetKey = @"DataOffsetKey";

@implementation NSData (Extensions)

- (void)setOffset:(NSUInteger)offset
{
  objc_setAssociatedObject(self, &DataOffsetKey, @(offset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)offset
{
  return [(NSNumber *)objc_getAssociatedObject(self, &DataOffsetKey) unsignedIntegerValue];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
  [self getBytes:(void *)buffer range:NSMakeRange(self.offset, len)];
  self.offset += len;
  return len;
}

- (float)readFloat:(BOOL *)error
{
  float v;
  NSInteger rLength;
  rLength = [self read:(uint8_t *)&v maxLength:sizeof(v)];
  if (rLength != sizeof(v) && error)
  {
    *error = YES;
    return 0;
  }
  return v;
}

- (float)readHalfFloat:(BOOL *)error
{
  short v = [self readShort:error];
  if (error && *error)
    return 0;
  return half2float(v);
}

- (int)readInt:(BOOL *)error
{
  int v;
  NSInteger rLength;
  rLength = [self read:(uint8_t *)&v maxLength:sizeof(v)];
  if (rLength != sizeof(v) && error)
  {
    *error = YES;
    v = 0;
  }
  return v;
}

- (long)readLong:(BOOL *)error
{
  long v;
  NSInteger rLength;
  rLength = [self read:(uint8_t *)&v maxLength:sizeof(v)];
  if (rLength != sizeof(v) && error)
  {
    *error = YES;
    v = 0;
  }
  return v;
}

- (short)readShort:(BOOL *)error
{
  short v;
  NSInteger rLength;
  rLength = [self read:(uint8_t *)&v maxLength:sizeof(v)];
  if (rLength != sizeof(v) && error)
  {
    *error = YES;
    v = 0;
  }
  return v;
}

- (Byte)readByte:(BOOL *)error
{
  Byte v;
  NSInteger rLength;
  rLength = [self read:(uint8_t *)&v maxLength:sizeof(v)];
  if (rLength != sizeof(v) && error)
  {
    *error = YES;
    v = 0;
  }
  return v;
}

- (void *)readBytes:(int)length error:(BOOL *)error
{
  void *ptr = malloc(length);
  int rLength = (int)[self read:(uint8_t *)ptr maxLength:length];
  if (rLength != length)
  {
    if (error)
      *error = YES;
    free(ptr);
    DThrow(kErrorUnexpectedEnd);
    return NULL;
  }
  return ptr;
}

- (NSData *)readData:(int)length
{
  void *ptr = malloc(length);
  int rLength = (int)[self read:(uint8_t *)ptr maxLength:length];
  if (rLength != length)
  {
    free(ptr);
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  
  NSData *d = [NSData dataWithBytes:ptr length:rLength];
  free(ptr);
  return d;
}

- (NSString *)readString:(BOOL *)error
{
  int l = [self readInt:error];
  if (error && *error)
  {
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  char *ptr = (char *)malloc(l + 1);
  int rLength = (int)[self read:(uint8_t *)ptr maxLength:l];
  if (rLength != l)
  {
    if (error)
    {
      *error = YES;
    }
    free(ptr);
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  ptr[l] = '\0';
  
  NSString *result = [NSString stringWithCString:ptr encoding:NSUTF8StringEncoding];
  if (!result)
  {
    wchar_t *wstr = calloc(l, 2);
    size_t nl = mbstowcs(wstr, ptr, l);
    if (nl && wstr)
    {
      result = [[NSString alloc] initWithBytes:(const void *)wstr length:nl encoding:NSUTF32LittleEndianStringEncoding];
      free(ptr);
      free(wstr);
      return result;
    }
  }
  free(ptr);
  return result;
}

- (void)setPosition:(NSUInteger)position
{
  self.offset = position;
}

- (NSUInteger)position
{
  return self.offset;
}

@end

@implementation NSMutableData (Extensions)

- (NSData *)zlibInflate
{
  if ([self length] == 0) return self;
  
  unsigned full_length = (int)[self length];
  unsigned half_length = (int)[self length] / 2;
  
  NSMutableData *decompressed = [NSMutableData dataWithLength:full_length + half_length];
  BOOL done = NO;
  int status;
  
  z_stream strm;
  strm.next_in = (Bytef *)[self bytes];
  strm.avail_in = (uInt)[self length];
  strm.total_out = 0;
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  
  if (inflateInit (&strm) != Z_OK)
    return nil;
  
  while (!done)
  {
    // Make sure we have enough room and reset the lengths.
    if (strm.total_out >= [decompressed length])
      [decompressed increaseLengthBy:half_length];
    strm.next_out = [decompressed mutableBytes] + strm.total_out;
    strm.avail_out = (uInt)[decompressed length] - (uInt)strm.total_out;
    
    // Inflate another chunk.
    status = inflate (&strm, Z_SYNC_FLUSH);
    if (status == Z_STREAM_END)
      done = YES;
    else if (status != Z_OK)
      break;
  }
  if (inflateEnd (&strm) != Z_OK)
    return nil;
  
  // Set real length.
  if (done)
  {
    [decompressed setLength:strm.total_out];
    return [NSData dataWithData:decompressed];
  }
  return nil;
}
- (NSData *)zlibDeflate
{
  if ([self length] == 0)
    return self;
  
  z_stream strm;
  
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  strm.total_out = 0;
  strm.next_in=(Bytef *)[self bytes];
  strm.avail_in = (uInt)[self length];
  
  if (deflateInit(&strm, Z_BEST_COMPRESSION) != Z_OK)
    return nil;
  
  NSMutableData *compressed = [NSMutableData dataWithLength:ZLIB_CHUNK_SIZE];
  
  do
  {
    
    if (strm.total_out >= [compressed length])
      [compressed increaseLengthBy:ZLIB_CHUNK_SIZE];
    
    strm.next_out = [compressed mutableBytes] + strm.total_out;
    strm.avail_out = (uInt)[compressed length] - (uInt)strm.total_out;
    
    deflate(&strm, Z_FINISH);
    
  } while (strm.avail_out == 0);
  
  deflateEnd(&strm);
  
  [compressed setLength:strm.total_out];
  return [NSData dataWithData:compressed];
}

- (void)writeInt:(int)value
{
  [self appendBytes:&value length:4];
}

- (void)writeLong:(long)value
{
  [self appendBytes:&value length:8];
}

- (void)writeByte:(Byte)value
{
  [self appendBytes:&value length:1];
}

- (void)writeShort:(short)value
{
  [self appendBytes:&value length:2];
}

- (void)writeFloat:(float)value
{
  int32_t a = *(int32_t *)&value;
  [self appendBytes:&a length:4];
}

@end

BOOL compressZLib(NSData *inData, NSMutableData *outData)
{
  lzo_uint chunkSize = LZO_CHUNK_SIZE;
  if (outData.length - chunkSize > 0 && outData.length - LZO_CHUNK_SIZE < 12) // ?
    chunkSize -= outData.length - LZO_CHUNK_SIZE;
  
  NSMutableArray *chunks = [NSMutableArray array];
  NSMutableArray *cchunks = [NSMutableArray array];
  lzo_uint sum = 0;
  
  do
  {
    
    NSData *d = [inData subdataWithRange:NSMakeRange(sum, MIN(chunkSize, [inData length] - sum))];
    [chunks addObject:d];
    sum+= [d length];
    
  } while (sum < [inData length]);
  
  sum = 0;
  
  for (int i = 0; i < [chunks count]; i++)
  {
    NSData *chunk = chunks[i];
    
    NSMutableData *inDat = [chunk mutableCopy];
    NSData *outDat = [inDat zlibDeflate];
    
    if (!outDat)
    {
      DLog(@"Error! ZLib Compressor error!");
      return NO;
    }
    
    [cchunks addObject:outDat];
    sum+= (int)[outDat length];
  }
  
  NSMutableData *t = [NSMutableData data];
  
  for (int i = 0; i < [cchunks count]; i++)
  {
    NSData *cchunk = cchunks[i];
    [t appendData:cchunk];
  }
  
  [outData writeInt:ZLIB_MAGIC];
  int bs = (int)ceilf((float)[inData length] / (float)[chunks count]);
  [outData writeInt:bs];
  [outData writeInt:(int)[t length]];
  [outData writeInt:(int)[inData length]];
  
  for (int i = 0; i < [cchunks count]; i++)
  {
    [outData writeInt:(int)[cchunks[i] length]];
    [outData writeInt:(int)[chunks[i] length]];
  }
  
  [outData appendData:t];
  return YES;
}

BOOL compressLZO(NSData *inData, NSMutableData *outData)
{
  lzo_uint chunkSize = LZO_CHUNK_SIZE;
  if (outData.length - chunkSize > 0 && outData.length - LZO_CHUNK_SIZE < 12) // ?
    chunkSize -= outData.length - LZO_CHUNK_SIZE;
  
  NSMutableArray *chunks = [NSMutableArray array];
  NSMutableArray *cchunks = [NSMutableArray array];
  lzo_uint sum = 0;
  
  do
  {
    
    NSData *d = [inData subdataWithRange:NSMakeRange(sum, MIN(chunkSize, [inData length] - sum))];
    [chunks addObject:d];
    sum+= [d length];
    
  } while (sum < [inData length]);
  
  lzo_init();
  sum = 0;
  
  for (int i = 0; i < [chunks count]; i++)
  {
    NSData *chunk = chunks[i];
    
    lzo_bytep inBytes = (lzo_bytep)[chunk bytes];
    lzo_bytep outBytes = malloc([chunk length] + [chunk length]);
    
    lzo_uint len;
    int e = lzo1x_1_compress(inBytes,[chunk length], outBytes, &len,wrkmem);
    
    if (e!=LZO_E_OK)
    {
      DLog(@"Error! LZO Compressor error! (%d)",e);
      return NO;
    }
    
    [cchunks addObject:[NSData dataWithBytes:outBytes length:len]];
    free(outBytes);
    sum+= len;
  }
  
  NSMutableData *t = [NSMutableData data];
  
  for (int i = 0; i < [cchunks count]; i++)
  {
    NSData *cchunk = cchunks[i];
    [t appendData:cchunk];
  }
  
  [outData writeInt:LZO_MAGIC];
  int bs = (int)ceilf((float)[inData length] / (float)[chunks count]);
  [outData writeInt:bs];
  [outData writeInt:(int)[t length]];
  [outData writeInt:(int)[inData length]];
  
  for (int i = 0; i < [cchunks count]; i++)
  {
    [outData writeInt:(int)[cchunks[i] length]];
    [outData writeInt:(int)[chunks[i] length]];
  }
  
  [outData appendData:t];
  return YES;
}

BOOL decompressZLib(uint8_t *inData, NSMutableData *outData)
{
  __block lzo_bytep input = inData;
  lzo_bytep ptr = input;
  
  if (*(int *)ptr != ZLIB_MAGIC)
  {
    DLog(@"Error! ZLib Decompressor Error! Wrong magic: %d",*(int *)ptr);
    return NO;
  }
  ptr+=4;
  
  uint blockSize = *(uint *)ptr; ptr+=4;
  uint compressedSize = *(uint *)ptr; ptr+=4;
  uint decompressedSize = *(uint *)ptr; ptr+=4;
  
  if (decompressedSize > 1024 * 1024 * 256) // 256Mb max
  {
    DLog(@"Error! ZLib Decompressor Error! Failed to read bulk data! Decompressed size is too large: %uKb",decompressedSize / 1024);
    return NO;
  }
  
  int totalBlocks = (int)ceilf((float)decompressedSize / (float)blockSize);
  
  NSMutableArray *chunks = [NSMutableArray array];
  
  uint compressedOffset = 0;
  uint decompressedOffset = 0;
  
  for (int i = 0; i < totalBlocks; i++)
  {
    lzo_uint chunkCompressedSize = *(uint *)ptr; ptr+=4;
    lzo_uint chunkDecompressedSize = *(uint *)ptr; ptr+=4;
    NSDictionary *chunk = @{@"cS" : @(chunkCompressedSize),
                            @"cO" : @(16 + compressedOffset + totalBlocks * 8),
                            @"dO" : @(decompressedOffset)};
    [chunks addObject:chunk];
    compressedOffset+= chunkCompressedSize;
    decompressedOffset+= chunkDecompressedSize;
  }
  
  if (compressedSize != compressedOffset || decompressedSize != decompressedOffset)
  {
    DLog(@"Error! ZLib Decompressor Error! Failed to read bulk data! Compressed size or decompressed size missmatch!");
    return NO;
  }
  __block lzo_bytep output = malloc(decompressedSize);
  __block BOOL err = NO;
  
  [chunks enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
     
     lzo_uint chunkCompressedSize = [obj[@"cS"] unsignedLongValue];
     lzo_uint chunkCompressedOffset = [obj[@"cO"] unsignedLongValue];
     lzo_uint chunkDecompressedOffset = [obj[@"dO"] unsignedLongValue];
     lzo_bytep inputPtr = input + chunkCompressedOffset;
     lzo_bytep outputPtr = output + chunkDecompressedOffset;
     
     NSMutableData *oData = [NSMutableData dataWithBytes:inputPtr length:chunkCompressedSize];
     NSData *dData = [oData zlibInflate];
     if (!oData)
     {
       DLog(@"Error! ZLib Decompressor Error! Failed to decompress!");
       err = YES;
       *stop = YES;
     }
     
     memcpy(outputPtr, [dData bytes], [dData length]);
   }];
  
  if (err)
  {
    free(output);
    return NO;
  }
  
  [outData appendBytes:output length:decompressedSize];
  free(output);
  return YES;
}

BOOL decompressLZO(uint8_t *inData, NSMutableData *outData)
{
  __block lzo_bytep input = inData;
  lzo_bytep ptr = input;
  
  if (*(int *)ptr != LZO_MAGIC)
  {
    DLog(@"Error! LZO Decompressor Error! Wrong magic: %d",*(int *)ptr);
    return NO;
  }
  ptr+=4;
  
  uint blockSize = *(uint *)ptr; ptr+=4;
  uint compressedSize = *(uint *)ptr; ptr+=4;
  uint decompressedSize = *(uint *)ptr; ptr+=4;
  
  if (decompressedSize > 1024 * 1024 * 256)
  { // 256Mb max
    DLog(@"Error! LZO Decompressor Error! Failed to read bulk data! Decompressed size is too large: %uKb",decompressedSize / 1024);
    return NO;
  }
  
  int totalBlocks = (int)ceilf((float)decompressedSize / (float)blockSize);
  
  NSMutableArray *chunks = [NSMutableArray array];
  
  uint compressedOffset = 0;
  uint decompressedOffset = 0;
  
  for (int i = 0; i < totalBlocks; i++)
  {
    lzo_uint chunkCompressedSize = *(uint *)ptr; ptr+=4;
    lzo_uint chunkDecompressedSize = *(uint *)ptr; ptr+=4;
    NSDictionary *chunk = @{@"cS" : @(chunkCompressedSize),
                            @"cO" : @(16 + compressedOffset + totalBlocks * 8),
                            @"dO" : @(decompressedOffset)};
    [chunks addObject:chunk];
    compressedOffset+= chunkCompressedSize;
    decompressedOffset+= chunkDecompressedSize;
  }
  
  if (compressedSize != compressedOffset || decompressedSize != decompressedOffset)
  {
    DLog(@"Error! LZO Decompressor Error! Failed to read bulk data! Compressed size or decompressed size missmatch!");
    return NO;
  }
  
  __block BOOL err = (LZO_E_OK != lzo_init());
  
  if (err)
  {
    DLog(@"Error! LZO Decompressor Error! Failed to initialize LZO! Code: %d",err);
    return NO;
  }
  
  __block lzo_bytep output = malloc(decompressedSize);
  
  [chunks enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
     
     lzo_uint chunkCompressedSize = [obj[@"cS"] unsignedLongValue];
     lzo_uint chunkCompressedOffset = [obj[@"cO"] unsignedLongValue];
     lzo_uint chunkDecompressedSize = 0;
     lzo_uint chunkDecompressedOffset = [obj[@"dO"] unsignedLongValue];
     lzo_bytep inputPtr = input + chunkCompressedOffset;
     lzo_bytep outputPtr = output + chunkDecompressedOffset;
     
     int e = lzo1x_decompress(inputPtr, chunkCompressedSize, outputPtr, &chunkDecompressedSize, NULL);
     if (e != LZO_E_OK)
     {
       DLog(@"Error! LZO Decompressor Error! Failed to decompress! Code: %d",e);
       err = YES;
       *stop = YES;
     }
   }];
  
  if (err)
  {
    free(output);
    return NO;
  }
  
  [outData appendBytes:output length:decompressedSize];
  free(output);
  return YES;
}

RFObjectFlags NSStringToObjectFlags(NSString *s)
{
  NSArray *tflags = [s componentsSeparatedByString:@","];
  NSMutableArray *flags = [NSMutableArray array];
  
  for(int i = 0; i < tflags.count; i++)
  {
    NSString *t = tflags[i];
    while ([t hasPrefix:@" "])
    {
      t = [t substringFromIndex:1];
    }
    while ([t hasSuffix:@" "] || [t hasSuffix:@","])
    {
      t = [t substringToIndex:t.length-2];
    }
    BOOL s = NO;
    for (NSString *f in flags)
    {
      if ([f isEqualToString:t])
      {
        s = YES;
        break;
      }
    }
    if (!s)
      [flags addObject:t];
  }
  
  long expFlag = 0;
  for (NSString *strFlag in flags) {
    if ([strFlag isEqualToString:@"InSingularFunc"]) { expFlag |= RF_InSingularFunc; continue; }
    if ([strFlag isEqualToString:@"StateChanged"]) { expFlag |= RF_StateChanged; continue; }
    if ([strFlag isEqualToString:@"DebugPostLoad"]) { expFlag |= RF_DebugPostLoad; continue; }
    if ([strFlag isEqualToString:@"DebugSerialize"]) { expFlag |= RF_DebugSerialize; continue; }
    if ([strFlag isEqualToString:@"DebugFinishDestroyed"]) { expFlag |= RF_DebugFinishDestroyed; continue; }
    if ([strFlag isEqualToString:@"EdSelected"]) { expFlag |= RF_EdSelected; continue; }
    if ([strFlag isEqualToString:@"ZombieComponent"]) { expFlag |= RF_ZombieComponent; continue; }
    if ([strFlag isEqualToString:@"Protected"]) { expFlag |= RF_Protected; continue; }
    if ([strFlag isEqualToString:@"ClassDefaultObject"]) { expFlag |= RF_ClassDefaultObject; continue; }
    if ([strFlag isEqualToString:@"ArchetypeObject"]) { expFlag |= RF_ArchetypeObject; continue; }
    if ([strFlag isEqualToString:@"ForceTagExp"]) { expFlag |= RF_ForceTagExp; continue; }
    if ([strFlag isEqualToString:@"TokenStreamAssembled"]) { expFlag |= RF_TokenStreamAssembled; continue; }
    if ([strFlag isEqualToString:@"MisalignedObject"]) { expFlag |= RF_MisalignedObject; continue; }
    if ([strFlag isEqualToString:@"RootSet"]) { expFlag |= RF_RootSet; continue; }
    if ([strFlag isEqualToString:@"BeginDestroyed"]) { expFlag |= RF_BeginDestroyed; continue; }
    if ([strFlag isEqualToString:@"FinishDestroyed"]) { expFlag |= RF_FinishDestroyed; continue; }
    if ([strFlag isEqualToString:@"DebugBeginDestroyed"]) { expFlag |= RF_DebugBeginDestroyed; continue; }
    if ([strFlag isEqualToString:@"MarkedByCooker"]) { expFlag |= RF_MarkedByCooker; continue; }
    if ([strFlag isEqualToString:@"LocalizedResource"]) { expFlag |= RF_LocalizedResource; continue; }
    if ([strFlag isEqualToString:@"InitializedProps"]) { expFlag |= RF_InitializedProps; continue; }
    if ([strFlag isEqualToString:@"PendingFieldPatches"]) { expFlag |= RF_PendingFieldPatches; continue; }
    if ([strFlag isEqualToString:@"IsCrossLevelReferenced"]) { expFlag |= RF_IsCrossLevelReferenced; continue; }
    if ([strFlag isEqualToString:@"DebugBeginDestroyed"]) { expFlag |= RF_DebugBeginDestroyed; continue; }
    if ([strFlag isEqualToString:@"Saved"]) { expFlag |= RF_Saved; continue; }
    if ([strFlag isEqualToString:@"Transactional"]) { expFlag |= RF_Transactional; continue; }
    if ([strFlag isEqualToString:@"Unreachable"]) { expFlag |= RF_Unreachable; continue; }
    if ([strFlag isEqualToString:@"Public"]) { expFlag |= RF_Public; continue; }
    if ([strFlag isEqualToString:@"TagImp"]) { expFlag |= RF_TagImp; continue; }
    if ([strFlag isEqualToString:@"TagExp"]) { expFlag |= RF_TagExp; continue; }
    if ([strFlag isEqualToString:@"Obsolete"]) { expFlag |= RF_Obsolete; continue; }
    if ([strFlag isEqualToString:@"TagGarbage"]) { expFlag |= RF_TagGarbage; continue; }
    if ([strFlag isEqualToString:@"DisregardForGC"]) { expFlag |= RF_DisregardForGC; continue; }
    if ([strFlag isEqualToString:@"PerObjectLocalized"]) { expFlag |= RF_PerObjectLocalized; continue; }
    if ([strFlag isEqualToString:@"NeedLoad"]) { expFlag |= RF_NeedLoad; continue; }
    if ([strFlag isEqualToString:@"AsyncLoading"]) { expFlag |= RF_AsyncLoading; continue; }
    if ([strFlag isEqualToString:@"NeedPostLoadSubobjects"]) { expFlag |= RF_NeedPostLoadSubobjects; continue; }
    if ([strFlag isEqualToString:@"Suppress"]) { expFlag |= RF_Suppress; continue; }
    if ([strFlag isEqualToString:@"InEndState"]) { expFlag |= RF_InEndState; continue; }
    if ([strFlag isEqualToString:@"Transient"]) { expFlag |= RF_Transient; continue; }
    if ([strFlag isEqualToString:@"Cooked"]) { expFlag |= RF_Cooked; continue; }
    if ([strFlag isEqualToString:@"LoadForClient"]) { expFlag |= RF_LoadForClient; continue; }
    if ([strFlag isEqualToString:@"LoadForServer"]) { expFlag |= RF_LoadForServer; continue; }
    if ([strFlag isEqualToString:@"LoadForEdit"]) { expFlag |= RF_LoadForEdit; continue; }
    if ([strFlag isEqualToString:@"Standalone"]) { expFlag |= RF_Standalone; continue; }
    if ([strFlag isEqualToString:@"NotForClient"]) { expFlag |= RF_NotForClient; continue; }
    if ([strFlag isEqualToString:@"NotForServer"]) { expFlag |= RF_NotForServer; continue; }
    if ([strFlag isEqualToString:@"NotForEdit"]) { expFlag |= RF_NotForEdit; continue; }
    if ([strFlag isEqualToString:@"NeedPostLoad"]) { expFlag |= RF_NeedPostLoad; continue; }
    if ([strFlag isEqualToString:@"HasStack"]) { expFlag |= RF_HasStack; continue; }
    if ([strFlag isEqualToString:@"Native"]) { expFlag |= RF_Native; continue; }
    if ([strFlag isEqualToString:@"Marked"]) { expFlag |= RF_Marked; continue; }
    if ([strFlag isEqualToString:@"ErrorShutdown"]) { expFlag |= RF_ErrorShutdown; continue; }
    if ([strFlag isEqualToString:@"PendingKill"]) { expFlag |= RF_PendingKill; continue; }
  }
  return expFlag;
}

NSString *NSStringFromObjectFlags(RFObjectFlags expFlag)
{
  NSString *s = @"";
  if (expFlag & RF_InSingularFunc)
    s = [s stringByAppendingString:@"InSingularFunc, "];
  if (expFlag & RF_StateChanged)
    s = [s stringByAppendingString:@"StateChanged, "];
  if (expFlag & RF_DebugPostLoad)
    s = [s stringByAppendingString:@"DebugPostLoad, "];
  if (expFlag & RF_DebugSerialize)
    s = [s stringByAppendingString:@"DebugSerialize, "];
  if (expFlag & RF_DebugFinishDestroyed)
    s = [s stringByAppendingString:@"DebugFinishDestroyed, "];
  if (expFlag & RF_EdSelected)
    s = [s stringByAppendingString:@"EdSelected, "];
  if (expFlag & RF_ZombieComponent)
    s = [s stringByAppendingString:@"ZombieComponent, "];
  if (expFlag & RF_Protected)
    s = [s stringByAppendingString:@"Protected, "];
  if (expFlag & RF_ClassDefaultObject)
    s = [s stringByAppendingString:@"ClassDefaultObject, "];
  if (expFlag & RF_ArchetypeObject)
    s = [s stringByAppendingString:@"ArchetypeObject, "];
  if (expFlag & RF_ForceTagExp)
    s = [s stringByAppendingString:@"ForceTagExp, "];
  if (expFlag & RF_TokenStreamAssembled)
    s = [s stringByAppendingString:@"TokenStreamAssembled, "];
  if (expFlag & RF_MisalignedObject)
    s = [s stringByAppendingString:@"MisalignedObject, "];
  if (expFlag & RF_RootSet)
    s = [s stringByAppendingString:@"RootSet, "];
  if (expFlag & RF_BeginDestroyed)
    s = [s stringByAppendingString:@"BeginDestroyed, "];
  if (expFlag & RF_FinishDestroyed)
    s = [s stringByAppendingString:@"FinishDestroyed, "];
  if (expFlag & RF_DebugBeginDestroyed)
    s = [s stringByAppendingString:@"DebugBeginDestroyed, "];
  if (expFlag & RF_MarkedByCooker)
    s = [s stringByAppendingString:@"MarkedByCooker, "];
  if (expFlag & RF_LocalizedResource)
    s = [s stringByAppendingString:@"LocalizedResource, "];
  if (expFlag & RF_InitializedProps)
    s = [s stringByAppendingString:@"InitializedProps, "];
  if (expFlag & RF_PendingFieldPatches)
    s = [s stringByAppendingString:@"PendingFieldPatches, "];
  if (expFlag & RF_IsCrossLevelReferenced)
    s = [s stringByAppendingString:@"IsCrossLevelReferenced, "];
  if (expFlag & RF_DebugBeginDestroyed)
    s = [s stringByAppendingString:@"DebugBeginDestroyed, "];
  if (expFlag & RF_Saved)
    s = [s stringByAppendingString:@"Saved, "];
  if (expFlag & RF_Transactional)
    s = [s stringByAppendingString:@"Transactional, "];
  if (expFlag & RF_Unreachable)
    s = [s stringByAppendingString:@"Unreachable, "];
  if (expFlag & RF_Public)
    s = [s stringByAppendingString:@"Public, "];
  if (expFlag & RF_TagImp)
    s = [s stringByAppendingString:@"TagImp, "];
  if (expFlag & RF_TagExp)
    s = [s stringByAppendingString:@"TagExp, "];
  if (expFlag & RF_Obsolete)
    s = [s stringByAppendingString:@"Obsolete, "];
  if (expFlag & RF_TagGarbage)
    s = [s stringByAppendingString:@"TagGarbage, "];
  if (expFlag & RF_DisregardForGC)
    s = [s stringByAppendingString:@"DisregardForGC, "];
  if (expFlag & RF_PerObjectLocalized)
    s = [s stringByAppendingString:@"PerObjectLocalized, "];
  if (expFlag & RF_NeedLoad)
    s = [s stringByAppendingString:@"NeedLoad, "];
  if (expFlag & RF_AsyncLoading)
    s = [s stringByAppendingString:@"AsyncLoading, "];
  if (expFlag & RF_NeedPostLoadSubobjects)
    s = [s stringByAppendingString:@"NeedPostLoadSubobjects, "];
  if (expFlag & RF_Suppress)
    s = [s stringByAppendingString:@"Suppress, "];
  if (expFlag & RF_InEndState)
    s = [s stringByAppendingString:@"InEndState, "];
  if (expFlag & RF_Transient)
    s = [s stringByAppendingString:@"Transient, "];
  if (expFlag & RF_Cooked)
    s = [s stringByAppendingString:@"Cooked, "];
  if (expFlag & RF_LoadForClient)
    s = [s stringByAppendingString:@"LoadForClient, "];
  if (expFlag & RF_LoadForServer)
    s = [s stringByAppendingString:@"LoadForServer, "];
  if (expFlag & RF_LoadForEdit)
    s = [s stringByAppendingString:@"LoadForEdit, "];
  if (expFlag & RF_Standalone)
    s = [s stringByAppendingString:@"Standalone, "];
  if (expFlag & RF_NotForClient)
    s = [s stringByAppendingString:@"NotForClient, "];
  if (expFlag & RF_NotForServer)
    s = [s stringByAppendingString:@"NotForServer, "];
  if (expFlag & RF_NotForEdit)
    s = [s stringByAppendingString:@"NotForEdit, "];
  if (expFlag & RF_NeedPostLoad)
    s = [s stringByAppendingString:@"NeedPostLoad, "];
  if (expFlag & RF_HasStack)
    s = [s stringByAppendingString:@"HasStack, "];
  if (expFlag & RF_Native)
    s = [s stringByAppendingString:@"Native, "];
  if (expFlag & RF_Marked)
    s = [s stringByAppendingString:@"Marked, "];
  if (expFlag & RF_ErrorShutdown)
    s = [s stringByAppendingString:@"ErrorShutdown, "];
  if (expFlag & RF_NotForEdit)
    s = [s stringByAppendingString:@"NotForEdit, "];
  if (expFlag & RF_PendingKill)
    s = [s stringByAppendingString:@"PendingKill, "];
  s = [s substringToIndex:s.length > 1 ? s.length - 2 : 0];
  return s;
}

NSArray<NSString *> *AllObjectFlags()
{
  return @[@"InSingularFunc", @"StateChanged", @"DebugPostLoad", @"DebugSerialize", @"DebugFinishDestroyed", @"EdSelected", @"ZombieComponent", @"Protected", @"ClassDefaultObject", @"ArchetypeObject", @"ForceTagExp", @"TokenStreamAssembled", @"MisalignedObject", @"RootSet", @"BeginDestroyed", @"FinishDestroyed", @"DebugBeginDestroyed", @"MarkedByCooker", @"LocalizedResource", @"InitializedProps", @"PendingFieldPatches", @"IsCrossLevelReferenced", @"DebugBeginDestroyed", @"Saved", @"Transactional", @"Unreachable", @"Public", @"TagImp", @"TagExp", @"Obsolete", @"TagGarbage", @"DisregardForGC", @"PerObjectLocalized", @"NeedLoad", @"AsyncLoading", @"NeedPostLoadSubobjects", @"Suppress", @"InEndState", @"Transient", @"Cooked", @"LoadForClient", @"LoadForServer", @"LoadForEdit", @"Standalone", @"NotForClient", @"NotForServer", @"NotForEdit", @"NeedPostLoad", @"HasStack", @"Native", @"Marked", @"ErrorShutdown", @"PendingKill"];
}

NSString *NSStringFromPackageFlags(EPackageFlags pkgFlags)
{
  NSString *s = @"";
  
  if (pkgFlags & PKG_AllowDownload)
    s = [s stringByAppendingString:@"AllowDownload, "];
  if (pkgFlags & PKG_ClientOptional)
    s = [s stringByAppendingString:@"ClientOptional, "];
  if (pkgFlags & PKG_ServerSideOnly)
    s = [s stringByAppendingString:@"ServerSideOnly, "];
  if (pkgFlags & PKG_Cooked)
    s = [s stringByAppendingString:@"Cooked, "];
  if (pkgFlags & PKG_Unsecure)
    s = [s stringByAppendingString:@"Unsecure, "];
  if (pkgFlags & PKG_SavedWithNewerVersion)
    s = [s stringByAppendingString:@"SavedWithNewerVersion, "];
  if (pkgFlags & PKG_Need)
    s = [s stringByAppendingString:@"Need, "];
  if (pkgFlags & PKG_Compiling)
    s = [s stringByAppendingString:@"Compiling, "];
  if (pkgFlags & PKG_ContainsMap)
    s = [s stringByAppendingString:@"ContainsMap, "];
  if (pkgFlags & PKG_Trash)
    s = [s stringByAppendingString:@"Trash, "];
  if (pkgFlags & PKG_DisallowLazyLoading)
    s = [s stringByAppendingString:@"DisallowLazyLoading, "];
  if (pkgFlags & PKG_PlayInEditor)
    s = [s stringByAppendingString:@"PlayInEditor, "];
  if (pkgFlags & PKG_ContainsScript)
    s = [s stringByAppendingString:@"ContainsScript, "];
  if (pkgFlags & PKG_ContainsDebugInfo)
    s = [s stringByAppendingString:@"ContainsDebugInfo, "];
  if (pkgFlags & PKG_RequireImportsAlreadyLoaded)
    s = [s stringByAppendingString:@"RequireImportsAlreadyLoaded, "];
  if (pkgFlags & PKG_SelfContainedLighting)
    s = [s stringByAppendingString:@"SelfContainedLighting, "];
  if (pkgFlags & PKG_StoreCompressed)
    s = [s stringByAppendingString:@"StoreCompressed, "];
  if (pkgFlags & PKG_StoreFullyCompressed)
    s = [s stringByAppendingString:@"StoreFullyCompressed, "];
  if (pkgFlags & PKG_ContainsInlinedShaders)
    s = [s stringByAppendingString:@"ContainsInlinedShaders, "];
  if (pkgFlags & PKG_ContainsFaceFXData)
    s = [s stringByAppendingString:@"ContainsFaceFXData, "];
  if (pkgFlags & PKG_NoExportAllowed)
    s = [s stringByAppendingString:@"NoExportAllowed, "];
  if (pkgFlags & PKG_NoExportAllowed)
    s = [s stringByAppendingString:@"StrippedSource, "];
  
  s = [s substringToIndex:s.length > 1 ? s.length - 2 : 0];
  if (!s.length)
    return @"None";
  return s;
}

EPackageFlags NSStringToPackageFlags(NSString *s)
{
  NSArray *tflags = [s componentsSeparatedByString:@","];
  NSMutableArray *flags = [NSMutableArray array];
  
  for(int i = 0; i < tflags.count; i++)
  {
    NSString *t = tflags[i];
    if ([t hasPrefix:@" "])
      t = [t substringFromIndex:1];
    BOOL s = NO;
    for (NSString *f in flags)
    {
      if ([f isEqualToString:@"t"])
      {
        s = YES;
        break;
      }
    }
    if (!s)
      [flags addObject:t];
  }
  
  int pFlags = 0;
  for (NSString *strFlag in flags) {
    if ([strFlag isEqualToString:@"AllowDownload"]) {pFlags |= PKG_AllowDownload;continue;}
    if ([strFlag isEqualToString:@"ClientOptional"]) {pFlags |= PKG_ClientOptional;continue;}
    if ([strFlag isEqualToString:@"ServerSideOnly"]) {pFlags |= PKG_ServerSideOnly;continue;}
    if ([strFlag isEqualToString:@"Cooked"]) {pFlags |= PKG_Cooked;continue;}
    if ([strFlag isEqualToString:@"Unsecure"]) {pFlags |= PKG_Unsecure;continue;}
    if ([strFlag isEqualToString:@"SavedWithNewerVersion"]) {pFlags |= PKG_SavedWithNewerVersion;continue;}
    if ([strFlag isEqualToString:@"Need"]) {pFlags |= PKG_Need;continue;}
    if ([strFlag isEqualToString:@"Compiling"]) {pFlags |= PKG_Compiling;continue;}
    if ([strFlag isEqualToString:@"ContainsMap"]) {pFlags |= PKG_ContainsMap;continue;}
    if ([strFlag isEqualToString:@"Trash"]) {pFlags |= PKG_Trash;continue;}
    if ([strFlag isEqualToString:@"DisallowLazyLoading"]) {pFlags |= PKG_DisallowLazyLoading;continue;}
    if ([strFlag isEqualToString:@"PlayInEditor"]) {pFlags |= PKG_PlayInEditor;continue;}
    if ([strFlag isEqualToString:@"ContainsScript"]) {pFlags |= PKG_ContainsScript;continue;}
    if ([strFlag isEqualToString:@"ContainsDebugInfo"]) {pFlags |= PKG_ContainsDebugInfo;continue;}
    if ([strFlag isEqualToString:@"RequireImportsAlreadyLoaded"]) {pFlags |= PKG_RequireImportsAlreadyLoaded;continue;}
    if ([strFlag isEqualToString:@"SelfContainedLighting"]) {pFlags |= PKG_SelfContainedLighting;continue;}
    if ([strFlag isEqualToString:@"StoreCompressed"]) {pFlags |= PKG_StoreCompressed;continue;}
    if ([strFlag isEqualToString:@"StoreFullyCompressed"]) {pFlags |= PKG_StoreFullyCompressed;continue;}
    if ([strFlag isEqualToString:@"ContainsInlinedShaders"]) {pFlags |= PKG_ContainsInlinedShaders;continue;}
    if ([strFlag isEqualToString:@"ContainsFaceFXData"]) {pFlags |= PKG_ContainsFaceFXData;continue;}
    if ([strFlag isEqualToString:@"NoExportAllowed"]) {pFlags |= PKG_NoExportAllowed;continue;}
    if ([strFlag isEqualToString:@"StrippedSource"]) {pFlags |= PKG_StrippedSource;continue;}
  }
  return pFlags;
}

NSArray<NSString *> *AllPackageFlags()
{
  return @[@"AllowDownload",@"ClientOptional",@"ServerSideOnly",@"Cooked",@"Unsecure",@"SavedWithNewerVersion",@"Need",@"Compiling",@"ContainsMap",@"Trash",@"DisallowLazyLoading",@"PlayInEditor",@"ContainsScript",@"ContainsDebugInfo",@"RequireImportsAlreadyLoaded",@"SelfContainedLighting",@"StoreCompressed",@"StoreFullyCompressed",@"ContainsInlinedShaders",@"ContainsFaceFXData",@"NoExportAllowed",@"StrippedSource"];
}

NSString *NSStringFromExportFlags(EFExportFlags expFlag)
{
  NSString *s = @"";
  if (expFlag == EF_None)
    s = [s stringByAppendingString:@"None, "];
  if (expFlag & EF_ForcedExport)
    s = [s stringByAppendingString:@"ForcedExport, "];
  if (expFlag & EF_ScriptPatcherExport)
    s = [s stringByAppendingString:@"ScriptPatcherExport, "];
  if (expFlag & EF_MemberFieldPatchPending)
    s = [s stringByAppendingString:@"MemberFieldPatchPending, "];
  if (expFlag & EF_AllFlags)
    s = [s stringByAppendingString:@"AllFlags, "];
  s = [s substringToIndex:s.length > 1 ? s.length - 2 : 0];
  return s;
}

EFExportFlags NSStringToExportFlags(NSString *s)
{
  int eFlags = 0;
  
  NSArray *tflags = [s componentsSeparatedByString:@","];
  NSMutableArray *flags = [NSMutableArray array];
  
  for(int i = 0; i < tflags.count; i++)
  {
    NSString *t = tflags[i];
    while ([t hasPrefix:@" "])
    {
      t = [t substringFromIndex:1];
    }
    while ([t hasSuffix:@" "] || [t hasSuffix:@","])
    {
      t = [t substringToIndex:t.length-2];
    }
    BOOL s = NO;
    for (NSString *f in flags)
    {
      if ([f isEqualToString:@"t"])
      {
        s = YES;
        break;
      }
    }
    if (!s)
      [flags addObject:t];
  }
  
  for (NSString *strFlag in flags)
  {
    if ([strFlag isEqualToString:@"None"]) {eFlags = EF_None;break;}
    if ([strFlag isEqualToString:@"ForcedExport"]) {eFlags |= EF_ForcedExport;continue;}
    if ([strFlag isEqualToString:@"ScriptPatcherExport"]) {eFlags |= EF_ScriptPatcherExport;continue;}
    if ([strFlag isEqualToString:@"MemberFieldPatchPending"]) {eFlags |= EF_MemberFieldPatchPending;continue;}
    if ([strFlag isEqualToString:@"AllFlags"]) {eFlags = EF_AllFlags;break;}
  }
  
  return eFlags;
}

NSArray<NSString *> *AllExportFlags()
{
  return @[@"None", @"ForcedExport", @"ScriptPatcherExport", @"MemberFieldPatchPending", @"AllFlags"];
}
