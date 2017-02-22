//
//  FGUID.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FGUID.h"
#import "Extensions.h"

@implementation FGUID

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.data forKey:@"data"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if (self) {
    self.data = [coder decodeObjectForKey:@"data"];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  FGUID *obj = [FGUID newWithPackage:self.package];
  obj.data = self.data;
  return obj;
}

+ (id)readFrom:(FIStream *)stream
{
  
  FGUID *guid = [super readFrom:stream];
  void *ptr = [stream readBytes:16 error:NULL];
  if (!ptr)
  {
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  guid.data = [[NSData dataWithBytes:ptr length:16] mutableCopy];
  free(ptr);
  
  return guid;
}

+(id)guid
{
  FGUID *guid = [FGUID new];
  
  unsigned char uuid[16];
  [[NSUUID UUID] getUUIDBytes:uuid];
  guid.data = [[NSData dataWithBytes:uuid length:16] mutableCopy];
  
  return guid;
}

+ (id)guidFromString:(NSString *)string
{
  if (string.length != 35)
  {
    DThrow(@"Invalid guid length %d!",string.length);
    return nil;
  }
  
  NSArray *components = [string componentsSeparatedByString:@"-"];
  if (components.count != 4)
  {
    DThrow(@"Invalid components count %d",components.count);
    return nil;
  }
  NSMutableData *data = [NSMutableData data];
  for (NSString *component in components) {
    if (component.length != 8) { DThrow(@"Invalid componnt length %d",component.length); return nil;}
    
    const char *p = [component cStringUsingEncoding:NSASCIIStringEncoding];
    if (!p)
    {
      DThrow(@"Error! Failed to convert component %@ to ascii",component);
      return nil;
    }
    int t;
    sscanf(p,"%X",&t);
    
    [data writeInt:t];
  }
  FGUID *guid = [FGUID new];
  guid.data = data;
  
  return guid;
}

+ (id)guidFromLEString:(NSString *)string
{
  if (string.length != 35)
  {
    DThrow(@"Invalid leguid length %d!",string.length);
    return nil;
  }
  
  NSArray *components = [string componentsSeparatedByString:@"-"];
  if (components.count != 4)
  {
    DThrow(@"Invalid lecomponents count %d",components.count);
    return nil;
  }
  NSMutableData *data = [NSMutableData data];
  for (NSString *component in components) {
    if (component.length != 8) { DThrow(@"Invalid lecomponnt length %d",component.length); return nil; }
    NSString *nc = @"";
    for (int i = 1; i <= 4; i++) {
      nc = [nc stringByAppendingString:[component substringWithRange:NSMakeRange(component.length - i * 2, 2)]];
    }
    const char *p = [nc cStringUsingEncoding:NSASCIIStringEncoding];
    if (!p)
    {
      DThrow(@"Error! Failed to convert lecomponent %@ to ascii",component);
      return nil;
    }
    int t;
    sscanf(p,"%X",&t);
    
    [data writeInt:t];
  }
  
  FGUID *guid = [FGUID new];
  guid.data = data;
  
  return guid;
}

- (NSString *)string
{
  NSString *str = @"";
  
  int buf;
  
  [self.data getBytes:&buf range:NSMakeRange(0, 4)];
  str = [str stringByAppendingFormat:@"%08X-",buf];
  [self.data getBytes:&buf range:NSMakeRange(4, 4)];
  str = [str stringByAppendingFormat:@"%08X-",buf];
  [self.data getBytes:&buf range:NSMakeRange(8, 4)];
  str = [str stringByAppendingFormat:@"%08X-",buf];
  [self.data getBytes:&buf range:NSMakeRange(12, 4)];
  str = [str stringByAppendingFormat:@"%08X",buf];
  
  return str;
}

- (NSMutableData *)cooked
{
  return self.data;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [self cooked];
}

- (NSString *)description
{
  return self.string;
}

- (id)plist
{
  return [self string];
}


@end
