//
//  FStream.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FStream.h"
#import "UPackage.h"
#import "MeshUtils.h"

@interface FIStream ()
@property (strong) NSInputStream *stream;
@property (assign) BOOL isDataStream;
@property (assign) BOOL isOpen;
@end

@implementation FIStream

+ (instancetype)streamForUrl:(NSURL *)url
{
  FIStream *s = [FIStream new];
  s.url = url;
  s.stream = [NSInputStream inputStreamWithURL:url];
  [s.stream open];
  s.isOpen = YES;
  return s;
}

+ (instancetype)streamForPath:(NSString *)path
{
  FIStream *s = [FIStream new];
  s.url = [NSURL fileURLWithPath:path];
  s.stream = [NSInputStream inputStreamWithFileAtPath:path];
  [s.stream open];
  s.isOpen = YES;
  return s;
}

+ (instancetype)streamForData:(NSData *)data
{
  // TODO: implement proper stream for data. Should be used to cook packages
  FIStream *s = [FIStream new];
  s.stream = [NSInputStream inputStreamWithData:data];
  s.isDataStream = YES;
  [s.stream open];
  s.isOpen = YES;
  return nil;
}

- (void)dealloc
{
  if (self.stream && self.isOpen)
    [self close];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
#ifdef DEBUG
  const char *t = getenv("STREAM_BREAK_OFFSET");
  if (t)
  {
    long long offset = atoll(t);
    if (offset)
      if (offset >= self.position && offset < self.position + len)
      {
        @try
        {
          [NSException raise:@"Stopped on STREAM_BREAK_OFFSET" format:@"Position %lld", offset];
        }
        @catch (NSException *exception)
        {
          DLog(@"Passed stream position '%lld' (0x%08llX) while reading %lu bytes at %lu(0x%08lX)", offset, offset, len, self.position, (unsigned long)self.position);
        }
      }
  }
#endif
  return [self.stream read:buffer maxLength:len];
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

- (void)setPosition:(NSUInteger)position
{
  [self.stream setProperty:@(position) forKey:NSStreamFileCurrentOffsetKey];
  NSUInteger t = [[self.stream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedIntegerValue];
  if (t != position)
  {
    DLog(@"Error! Failed to set stream position: %lu",t);
  }
}

- (NSUInteger)position
{
  return [[self.stream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedIntegerValue];
}

- (id)copy
{
  FIStream *s = [FIStream new];
  s.url = self.url;
  s.stream = [NSInputStream inputStreamWithURL:self.url];
  [s.stream open];
  s.isOpen = YES;
  s.position = self.position;
  s.package = self.package;
  s.game = self.game;
  return s;
}

- (void)close
{
  self.isOpen = NO;
  [self.stream close];
}

@end
