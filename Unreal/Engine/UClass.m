//
//  UField.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 18/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UClass.h"
#import "UObject.h"

@implementation FImplementedInterface

+ (instancetype)readFrom:(FIStream *)stream
{
  FImplementedInterface *interface = [super readFrom:stream];
  interface.objectClass = [UObject readFrom:stream];
  interface.pointerProperty = [UObject readFrom:stream]; // ?
  return interface;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.objectClass cookedIndex];
  [d appendData:[self.pointerProperty cookedIndex]];
  return d;
}

@end

@implementation UField

+ (BOOL)isNative
{
  return YES;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  UField *f = [self newWithPackage:stream.package];
  f.superfield = (UField *)[UObject readFrom:stream];
  f.next = (UField *)[UObject readFrom:stream];
  return f;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.superfield cookedIndex]];
  [d appendData:[self.next cookedIndex]];
  return d;
}

@end

@implementation UStruct

+ (instancetype)readFrom:(FIStream *)stream
{
  UStruct *f = [super readFrom:stream];
  f.scriptText = [TextBuffer readFrom:stream];
  f.children = (UField *)[UObject readFrom:stream];
  f.cppText = [TextBuffer readFrom:stream];
  f.line = [stream readInt:0];
  f.textPos = [stream readInt:0];
  int ScriptBytecodeSize = 0;
  ScriptBytecodeSize = [stream readInt:0];
  if (!ScriptBytecodeSize)
  {
    return f;
  }
  f.scriptData = [stream readData:ScriptBytecodeSize];
  // TODO: decompile script add show it in the editor
  return f;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.scriptText cookedIndex]];
  [d appendData:[self.children cookedIndex]];
  [d appendData:[self.cppText cookedIndex]];
  [d writeInt:(int)self.scriptData.length];
  [d appendData:self.scriptData];
  return d;
}

@end


@implementation UState

+ (instancetype)readFrom:(FIStream *)stream
{
  UState *s = [super readFrom:stream];
  s.unk = [stream readInt:0];
  s.probeMask = [stream readInt:0];
  s.igonreMask = [stream readLong:0];
  s.labelTableOffset = [stream readShort:0];
  s.stateFlags = [stream readInt:0];
  s.funcMap = [FMap readFrom:stream keyType:[FName class] type:[UObject class]];
  return s;;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:self.unk];
  [d writeInt:self.probeMask];
  [d writeLong:self.igonreMask];
  [d writeShort:self.labelTableOffset];
  [d writeInt:self.stateFlags];
  [d appendData:[self.funcMap cooked:offset + d.length]];
  return d;
}

@end


@implementation UClass

+ (instancetype)readFrom:(FIStream *)stream
{
  UClass *c = [super readFrom:stream];
  c.classFlags = [stream readInt:0];
  c.classWithin = (UClass *)[UObject readFrom:stream];
  c.classConfigName = [FName readFrom:stream];
  c.hideCategories = [FArray readFrom:stream type:[FName class]];
  c.componentNameToDefaultObjectMap = [FMap readFrom:stream keyType:[FName class] type:[UObject class]];
  c.interfaces = [FArray readFrom:stream type:[FImplementedInterface class]];
  c.autoExpandCategories = [FArray readFrom:stream type:[FName class]];
  c.classDefaultObject = [UObject readFrom:stream];
  return c;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:self.classFlags];
  [d appendData:[self.classWithin cookedIndex]];
  [d appendData:[self.classConfigName cooked:offset + d.length]];
  [d appendData:[self.hideCategories cooked:offset + d.length]];
  [d appendData:[self.componentNameToDefaultObjectMap cooked:offset + d.length]];
  [d appendData:[self.interfaces cooked:offset + d.length]];
  [d appendData:[self.autoExpandCategories cooked:offset + d.length]];
  [d appendData:[self.classDefaultObject cookedIndex]];
  return d;
}

@end

@implementation FStateFrame

+ (instancetype)readFrom:(FIStream *)stream
{
  FStateFrame *f = [FStateFrame newWithPackage:stream.package];
  f.node = (UState *)[UObject readFrom:stream];
  f.stateNode = (UState *)[UObject readFrom:stream];
  f.probeMask = [stream readLong:0];
  f.latentAction = [stream readShort:0];
  f.stateStack = [FArray readFrom:stream type:[FPushedState class]];
  if (f.node && ![f.node isZero])
    f.offset = [stream readInt:0];
  return f;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.node cookedIndex];
  [d appendData:[self.stateNode cookedIndex]];
  [d writeLong:self.probeMask];
  [d writeShort:self.latentAction];
  [d appendData:[self.stateStack cooked:offset + d.length]];
  if (self.node && ![self.node isZero])
    [d writeInt:self.offset];
  return d;
  
}

@end

@implementation FPushedState

+ (instancetype)readFrom:(FIStream *)stream
{
  FPushedState *s = [super readFrom:stream];
  s.state = (UState *)[UObject readFrom:stream];
  s.node = (UStruct *)[UObject readFrom:stream];
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self.state cookedIndex];
  [d appendData:[self.node cookedIndex]];
  return d;
}

@end
