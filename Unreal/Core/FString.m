//
//  FString.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FString.h"
#import "Extensions.h"
#import "UPackage.h"
#import "FArray.h"

#define MAX_STR_LEN 0xFFFFFF

@implementation FString

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.string forKey:@"data"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if (self) {
    self.string = [coder decodeObjectForKey:@"data"];
  }
  return self;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  FString *str = [self new];
  BOOL err = NO;
  
  int length = [stream readInt:&err];
  
  if (err)
  {
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  if (!length)
    return str;
  
  if (length < 0)
  {
    
    length = -length * 2;
    if (length > MAX_STR_LEN)
    {
      DThrow(@"Error! String length is too big %d",length);
      return nil;
    }
    
    
    unichar ch;
    [stream read:(uint8_t *)&ch maxLength:2];
    NSMutableData *data = [NSMutableData data];
    
    for (int i = 0; i < length && ch != 0 ; i++)
    {
      
      [data appendBytes:&ch length:2];
      [stream read:(uint8_t *)&ch maxLength:2];
      
    }
    
    str.string = [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
    return str;
    
  }
  else
  {
    
    length = length-1;
    
    if (length > MAX_STR_LEN)
    {
      DThrow(@"Error! String length is too big %d",length);
      return nil;
    }
    
    char *charBuffer = malloc(sizeof(char) * length);
    [stream read:(uint8_t *)charBuffer maxLength:length];
    [stream readByte:&err]; // terminator
    
    str.string = [[NSString alloc] initWithBytes:charBuffer length:length encoding:NSASCIIStringEncoding];
    if (!str.string.length)
      DLog(@"Warning not a null-terminated string!");
    
    free(charBuffer);
  }
  return str;
}

+ (id)stringWithString:(NSString *)string
{
  FString *str = [self new];
  str.string = string;
  return str;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FString *s = [FString stringWithString:self.string];
  s.package = self.package;
  return s;
}

- (NSString *)description
{
  return self.string;
}

- (NSMutableData *)cooked
{
  NSMutableData *cookedData = [NSMutableData data];
  
  if (!self.string || !self.string.length)
  {
    [cookedData writeInt:0];
    return cookedData;
  }
  
  BOOL isUnicode = ![self.string canBeConvertedToEncoding:NSASCIIStringEncoding];
  
  if (isUnicode)
  {
    NSData *charData = [self.string dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
    [cookedData writeInt:((int)charData.length / 2) * -1 - 1]; // -1 since we don't count 0x00 char
    [cookedData appendData:charData];
    [cookedData writeShort:0];// Null terminator
    
    return cookedData;
  }
  else
  {
    NSData *charBuffer = [self.string dataUsingEncoding:NSASCIIStringEncoding];
    [cookedData writeInt:(int)charBuffer.length + 1];
    [cookedData appendData:charBuffer];
    char n = '\0';// Null terminator
    [cookedData appendBytes:&n length:1];
    
    return cookedData;
  }
  
  return cookedData;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self cooked];
}

- (BOOL)isEqualToString:(NSString *)string
{
  return [self.string isEqualToString:string];
}

@end

@implementation FNamePair

+ (instancetype)readFrom:(FIStream *)stream
{
  FNamePair *name = [super readFrom:stream];
  name.flags = [stream readLong:NULL];
  
  return name;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FNamePair *s = [FNamePair newWithPackage:self.package];
  s.string = [self.string copy];
  s.flags = self.flags;
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeLong:self.flags];
  return d;
}

- (int)index
{
  return (int)[self.package.names indexOfObject:self];
}

@end

@interface FName ()
@property (assign) int    nameIdx;
@property (assign) int    index;
@end

@implementation FName

+ (instancetype)nameWithString:(NSString *)string flags:(int)flags package:(UPackage *)package
{
  FName *n = [FName newWithPackage:package];
  n.nameIdx = [package indexForName:string];
  n.index = flags;
  return n;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  FName *m = [super readFrom:stream];
  m.nameIdx = [stream readInt:0];
  m.index = [stream readInt:0];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.nameIdx];
  [d writeInt:self.index];
  return d;
}

- (NSString *)name
{
  return [self.package nameForIndex:self.nameIdx];
}

- (NSString *)string
{
  return [self name];
}

- (void)setName:(NSString *)name forIndex:(int)index;
{
  self.nameIdx = [self.package indexForName:name];
  self.index = index;
}

@end

@implementation FURL

+ (instancetype)readFrom:(FIStream *)stream
{
  FURL *u = [super readFrom:stream];
  u.protocol = [FString readFrom:stream];
  u.host = [FString readFrom:stream];
  u.map = [FString readFrom:stream];
  u.portal = [FString readFrom:stream];
  u.op = [FArray readFrom:stream type:[FString class]];
  u.port = [stream readInt:NULL];
  u.valid = [stream readInt:NULL];
  return u;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.protocol cooked]];
  [d appendData:[self.host cooked]];
  [d appendData:[self.map cooked]];
  [d appendData:[self.portal cooked]];
  [d appendData:[self.op cooked:0]];
  [d writeInt:self.port];
  [d writeInt:self.valid];
  return d;
}

@end
