//
//  FMap.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FMap.h"
#import "FArray.h"
#import "UPackage.h"
#import "UObject.h"

@interface FMap ()
@property (strong) NSMutableArray *keys;
@end

@implementation FMap

+ (instancetype)readFrom:(FIStream *)stream keyType:(Class)keyType type:(Class)type
{
  FMap *m = [super readFrom:stream];
  m.keys = [NSMutableArray new];
  int cnt = [stream readInt:NULL];
  
  for (int idx = 0; idx < cnt; ++idx)
  {
    id key = [keyType readFrom:stream];
    id obj = nil;
    if (type == [NSNumber class])
      obj = @([stream readInt:NULL]);
    else
      obj = [type readFrom:stream];
    [m.keys addObject:@{@"key" : key, @"obj" : obj}];
  }
  
  return m;
}

+ (instancetype)readFrom:(FIStream *)stream keyType:(Class)keyType arrayType:(Class)type
{
  FMap *m = [super readFrom:stream];
  m.keys = [NSMutableArray new];
  int cnt = [stream readInt:NULL];
  
  for (int idx = 0; idx < cnt; ++idx)
  {
    id key = [keyType readFrom:stream];
    FArray *obj = [FArray readFrom:stream type:type];
    [m.keys addObject:@{@"key" : key, @"map" : obj}];
  }
  
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeInt:(int)self.keys.count];
  
  for (NSDictionary *keyPair in self.keys)
  {
    id key = keyPair[@"key"];
    if ([key isKindOfClass:[UObject class]])
      [d appendData:[key cookedIndex]];
    else if ([key isKindOfClass:[NSNumber class]])
      [d writeInt:[key intValue]];
    else
      [d appendData:[key cooked]];
    
    id obj = keyPair[@"obj"];
    if ([obj isKindOfClass:[NSNumber class]])
      [d writeInt:[obj intValue]];
    else if ([obj isKindOfClass:[UObject class]])
      [d appendData:[obj cookedIndex]];
    else
      [d appendData:[obj cooked:d.length + offset]];
  }
  return d;
}

@end

@interface FMultiMap ()
@property (strong) NSMutableDictionary *map;
@end

@implementation FMultiMap

+ (instancetype)readFrom:(FIStream *)stream keyType:(Class)keyType type:(Class)type
{
  FMultiMap *m = [super readFrom:stream];
  m.map = [NSMutableDictionary new];
  int cnt = [stream readInt:NULL];
  
  for (int idx = 0; idx < cnt; ++idx)
  {
    int oidx = [stream readInt:NULL];
    if (![stream.package objectForIndex:oidx])
      DThrow(@"Failed to resolve multimap key %d",oidx);
    id key = @(oidx);//[keyType readFrom:stream];
    id obj = [type readFrom:stream];
    if (!m.map[key])
      m.map[key] = [NSMutableArray new];
    [m.map[key] addObject:obj];
  }
  
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  DThrow(@"NOT IMPLEMENTED!");
  return nil;
}

@end
