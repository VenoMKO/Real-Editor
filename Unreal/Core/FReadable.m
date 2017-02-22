//
//  FReadable.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "UPackage.h"
#import "FGUID.h"
#import "FArray.h"
#import "UObject.h"

@implementation FReadable

+ (instancetype)newWithPackage:(UPackage *)package
{
  FReadable *r = [self new];
  r.package = package;
  return r;
}
+ (instancetype)readFrom:(FIStream *)stream
{
  return [self newWithPackage:stream.package];
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return [NSMutableData data];
}

- (id)plist
{
  return nil;
}

@end

@interface FObject ()
@end

@implementation FObject

- (NSString *)objectName
{
  return [self.package nameForIndex:self.nameIdx];
}

- (NSString *)objectClass
{
  return self.classIdx ? [[self.package objectForIndex:self.classIdx] objectName] : @"UClass";
}

- (FObject *)parent
{
  return [self.package fobjectForIndex:self.parentIdx];
}

- (void)addChild:(id)child
{
  if (!self.children)
    self.children = [NSMutableArray array];
  [self.children addObject:child];
}

- (void)removeChild:(id)child
{
  [self.children removeObject:child];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[%d]%@(%@)",[self.package indexForObject:self],self.objectName,self.objectClass];
}

- (NSImage *)icon
{
  return [self.object icon];
}

- (void)cleanup
{
  [self.object cleanup];
}

- (BOOL)visibleForSearch:(NSString *)search
{
  if ([self.objectName containsString:search] || [self.objectClass containsString:search]  || [self.objectName isLike:search] || [self.objectClass isLike:search])
    return YES;
  
  for (FObject *obj in self.children)
  {
    if ([obj visibleForSearch:search])
      return YES;
  }
  
  return NO;
}

- (NSArray *)childrenForSearch:(NSString *)search
{
  NSMutableArray *result = [NSMutableArray new];
  for (FObject *obj in self.children)
  {
    if ([obj visibleForSearch:search])
      [result addObject:obj];
  }
  return result;
}

@end

@implementation FObjectExport

+ (instancetype)readFrom:(FIStream *)stream
{
  FObjectExport *fobj = [super readFrom:stream];
  
  fobj.classIdx = [stream readInt:0];
  fobj.superIdx = [stream readInt:0];
  fobj.parentIdx = [stream readInt:0];
  fobj.nameIdx = [stream readInt:0];
  if (fobj.nameIdx > stream.package.names.count)
  {
    DThrow(@"Error reading export: %d",fobj.nameIdx);
    return nil;
  }
  fobj.archetypeIdx = [stream readLong:0];
  fobj.objectFlags = [stream readLong:0];
  fobj.serialSize = [stream readInt:0];
  if (fobj.serialSize)
  {
    fobj.serialOffset = [stream readInt:0];
    fobj.originalOffset = fobj.serialOffset;
  }
  fobj.exportFlags = [stream readInt:0];
  fobj.generationNetObjectCount = [FArray readFrom:stream type:[NSNumber class]];
  fobj.packageGuid = [FGUID readFrom:stream];
  fobj.packageFlags = [stream readInt:0];
  
  return fobj;
}

- (void)serialize
{
  if (self.object)
    return;
  
  UObject *obj = [UObject objectForClass:self.objectClass];
  self.object = obj;
  obj.package = self.package;
  obj.exportObject = self;
  
  if (self.parentIdx)
  {
    FObjectExport *parent = [self.package fobjectForIndex:self.parentIdx];
    if (!parent.object)
      [parent serialize];
    
    [parent addChild:self];
  }
}

- (NSData *)cookedWithOptions:(NSDictionary *)options objectData:(NSMutableData *)objectData
{
  NSMutableData *data = [NSMutableData data];
  [data writeInt:(int)self.classIdx];
  [data writeInt:self.superIdx];
  [data writeInt:self.parentIdx];
  [data writeInt:self.nameIdx];
  [data writeLong:self.archetypeIdx];
  if (self.objectFlags & RF_StateChanged) // We use RF_StateChanged to detect objects that were chaged. Don't save this tag
  {
    RFObjectFlags f = self.objectFlags;
    f &= ~RF_StateChanged;
    [data writeLong:f];
  }
  else
  {
    [data writeLong:self.objectFlags];
  }
  NSData *cooked = [self.object cooked:self.serialOffset options:options];
  if (!cooked)
  {
    DThrow(@"Error! Failed to cook %@",self.object);
    return nil;
  }
  [objectData appendData:cooked];
  self.serialSize = (int)objectData.length;
  [data writeInt:self.serialSize];
  if (self.serialSize)
    [data writeInt:self.serialOffset];
  [data writeInt:self.exportFlags];
  [data appendData:[self.generationNetObjectCount cooked:0]];
  [data appendData:[self.packageGuid cooked]];
  [data writeInt:self.packageFlags];
  return data;
}

- (NSString *)objectPath
{
  NSString *p = self.objectName;
  
  FObject *parent = self.parent;
  FObject *last = nil;
  while (parent)
  {
    p = [[parent objectName] stringByAppendingFormat:@".%@",p];
    last = parent;
    parent = parent.parent;
  }
  if ([last isKindOfClass:[FObjectExport class]] && !self.exportFlags & EF_ForcedExport)
  {
    p = [self.package.name stringByAppendingFormat:@".%@",p];
  }
  return p;
}

@end

@implementation FObjectImport

+ (instancetype)readFrom:(FIStream *)stream
{
  FObjectImport *fobj = [super readFrom:stream];
  fobj.classPackage = [stream readLong:0];
  fobj.classIdx = [stream readLong:0];
  fobj.parentIdx = [stream readInt:0];
  fobj.nameIdx = [stream readInt:0];
  fobj.unkw = [stream readInt:0];
  return fobj;
}

- (NSString *)objectClass
{
  return [self.package nameForIndex:self.classIdx];
}

- (void)serialize
{
  if (self.object)
    return;
  
  self.object = [UObject newWithPackage:self.package];
  self.object.importObject = self;
  
  if (self.parentIdx)
  {
    FObjectImport *parent = [self.package fobjectForIndex:self.parentIdx];
    if (!parent.object)
      [parent serialize];
    
    [parent addChild:self];
  }
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *data = [NSMutableData new];
  
  [data writeLong:self.classPackage];
  [data writeLong:self.classIdx];
  [data writeInt:self.parentIdx];
  [data writeInt:self.nameIdx];
  [data writeInt:self.unkw];
  
  return data;
}

- (NSString *)objectPath
{
  NSString *p = self.objectName;
  
  FObject *parent = self.parent;
  FObject *last = nil;
  while (parent)
  {
    p = [[parent objectName] stringByAppendingFormat:@".%@",p];
    last = parent;
    parent = parent.parent;
  }
  if ([last isKindOfClass:[FObjectExport class]])
  {
    p = [self.package.name stringByAppendingFormat:@".%@",p];
  }
  return p;
}

@end

@implementation FObjectRef

+ (id)readFrom:(FIStream *)stream
{
  FObjectRef *ref = [super readFrom:stream];
  ref.value = [stream readInt:0];
  return ref;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.value];
  return d;
}

@end
