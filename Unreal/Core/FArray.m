//
//  FArray.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FArray.h"
#import "UPackage.h"
#import "UObject.h"

@interface FArray ()
@property NSMutableArray  *array;
@end

@implementation FArray

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.array forKey:@"data"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if (self) {
    self.array = [coder decodeObjectForKey:@"data"];
  }
  return self;
}

+ (instancetype)arrayWithArray:(NSArray *)nsarray package:(UPackage *)package
{
  FArray *array = [FArray new];
  array.array = [NSMutableArray arrayWithArray:nsarray];
  array.package = package;
  return array;
}

+ (instancetype)readFrom:(FIStream *)stream type:(Class)type
{
  FArray *array = [super readFrom:stream];

  NSUInteger cnt = [stream readInt:0];
  array.array = [NSMutableArray arrayWithCapacity:cnt];
  
  for (NSUInteger idx = 0; idx < cnt; ++idx)
  {
    if ([type isSubclassOfClass:[NSNumber class]])
    {
      NSNumber *n = @([stream readInt:0]);
      [array.array addObject:n];
      continue;
    }
    id child = [type readFrom:stream];
    if (!child && ![type isSubclassOfClass:[UObject class]])
    {
      DThrow(@"Error failed to read array of object %@ at index: %lu",NSStringFromClass(type),idx);
      return nil;
    }
    else if (!child)
    {
      child = [UObject zero];
      [(UObject *)child setPackage:stream.package];
    }
    [array.array addObject:child];
  }
  return array;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *data = [NSMutableData data];
  [data writeInt:(int)self.array.count];
  offset+=4;
  
  for (FReadable *obj in self.array)
  {
    NSMutableData *d = nil;
    if ([[obj class] isSubclassOfClass:[UObject class]])
    {
      UObject *o = (UObject *)obj;
      d = [o cookedIndex];
    }
    else if ([[obj class] isSubclassOfClass:[NSNumber class]])
    {
      d = [NSMutableData new];
      [d writeInt:[(NSNumber *)obj intValue]];
    }
    else
    {
      d = [obj cooked:offset];
    }
    
    [data appendData:d];
    offset += d.length;
  }
  return data;
}

- (NSUInteger)count
{
  return self.array.count;
}

- (id)objectAtIndex:(NSUInteger)index
{
  return [self.array objectAtIndex:index];
}

- (void)addObject:(id)anObject
{
  [self.array addObject:anObject];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
  [self.array insertObject:anObject atIndex:index];
}
- (void)removeLastObject
{
  [self.array removeLastObject];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
  [self.array removeObjectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
  [self.array replaceObjectAtIndex:index withObject:anObject];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
  return [self.array objectAtIndexedSubscript:idx];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
  [self.array setObject:obj atIndexedSubscript:idx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
  return [self.array countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSEnumerator *)objectEnumerator
{
  return [self.array objectEnumerator];
}
- (NSEnumerator *)reverseObjectEnumerator
{
  return [self.array reverseObjectEnumerator];
}
- (NSInteger)indexOfObject:(id)anObject
{
  return [self.array indexOfObject:anObject];
}

- (NSString *)description
{
  NSString *d = [super description];
  NSString *ad = [self.array description];
  NSRange r = [ad rangeOfString:@"\n"];
  if (r.location != NSNotFound)
  {
    d = [ad stringByReplacingCharactersInRange:NSMakeRange(0, r.location) withString:[NSString stringWithFormat:@"%@ %lu elements {",d,self.array.count]];
  }
  return d;
}

- (NSArray *)nsarray
{
  return self.array;
}

- (id)plist
{
  NSMutableArray *a = [NSMutableArray new];
  
  for (id child in self.array)
  {
    id plist = nil;
    if ([child respondsToSelector:@selector(plist)] && (plist = [child plist]))
      [a addObject:plist];
    else
      DThrow(@"Not implemented plist %@", [child className]);
  }
  
  return a;
}

@end

@implementation TransFArray

+ (instancetype)readFrom:(FIStream *)stream type:(Class)type
{
  TransFArray *a;
  UObject *owner = [UObject readFrom:stream];
  a = [super readFrom:stream type:type];
  a.owner = owner;
  return a;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.owner cookedIndex];
  [d appendData:[super cooked:offset]];
  return d;
}

@end

@implementation FByteArray

+ (instancetype)readFrom:(FIStream *)stream
{
  FByteArray *a = [super readFrom:stream];
  a.elementSize = [stream readInt:NULL];
  a.elementCount = [stream readInt:NULL];
  int total = a.elementCount * a.elementSize;
  if (total)
    a.data = [stream readData:total];
  
  return a;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  
  [d writeInt:self.elementSize];
  [d writeInt:self.elementCount];
  if (self.data)
    [d appendData:self.data];
  
  return d;
}

@end

@implementation TArray

+ (instancetype)bulkSerializeFrom:(FIStream *)stream type:(Class)type
{
  TArray *a = [[super superclass] readFrom:stream];
  int cnt = [stream readInt:NULL];
  a.array = [[NSMutableArray alloc] initWithCapacity:cnt];
  a.elementSize = [stream readInt:NULL];
  if ([type isSubclassOfClass:[NSNumber class]] && a.elementSize == sizeof(int))
  {
    for (int i = 0; i < cnt; ++i)
    {
      [a.array addObject:@([stream readInt:NULL])];
    }
  }
  else if ([type isSubclassOfClass:[NSData class]] || ([type isSubclassOfClass:[NSNumber class]] && a.elementSize != sizeof(int)))
  {
    for (int i = 0; i < cnt; ++i)
    {
      [a.array addObject:[stream readData:a.elementSize]];
    }
  }
  else
  {
    for (int i = 0; i < cnt; ++i)
    {
      [a.array addObject:[type readFrom:stream]];
    }
  }
  return a;
}

- (NSMutableData *)bulkCooked:(NSInteger)offset
{
  NSMutableData *r = [NSMutableData new];
  [r writeInt:(int)self.array.count];
  [r writeInt:self.elementSize];
  offset+=8;
  if ([self.array.firstObject isKindOfClass:[NSData class]])
  {
    for (NSNumber *d in self.array)
    {
      [r writeInt:[d intValue]];
    }
  }
  else if ([self.array.firstObject isKindOfClass:[NSData class]])
  {
    for (NSData *d in self.array)
    {
      [r appendData:d];
    }
  }
  else
  {
    for (FReadable *d in self.array)
    {
      [r appendData:[d cooked:offset]];
      offset+=self.elementSize;
    }
  }
  return r;
}

@end
