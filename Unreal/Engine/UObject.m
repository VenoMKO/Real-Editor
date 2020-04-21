//
//  UObject.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 18/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "UPackage.h"
#import "PackageController.h"
#import "FPropertyTag.h"
#import "UObjectEditor.h"
#import "UClass.h"
#import "UComponent.h"

@interface UObject ()
@end

@implementation UObject

+ (BOOL)isNative
{
  return NO;
}

+ (id)zero
{
  UObject *o = [UObject new];
  o.isZero = YES;
  return o;
}

- (BOOL)canExport
{
  return NO;
}

+ (id)objectForClass:(NSString *)className
{
  if ([className isEqualToString:@"Object"])
    className = nil;
  if ([className isEqualToString:kClass])
    className = nil;
  Class cls = NSClassFromString(className);
  if (cls)
    return [cls new];
  else if ([className hasSuffix:kComponent])
  {
    if (![className isEqualToString:kComponent])
      DLog(@"Unimplemented component: %@", className);
    return [UComponent new];
  }
  else if ([className hasPrefix:@"Distribution"])
  {
    DLog(@"Unimplemented component: %@", className);
    return [UComponent new];
  }
  
  return [UObject new];
}

+ (id)readFrom:(FIStream *)stream
{
  int idx = [stream readInt:0];
  if (!idx)
    return [UObject zero];
  return [stream.package objectForIndex:idx];
}

- (void)readProperties
{
  @synchronized (self)
  {
    NSArray *arg = [[NSProcessInfo processInfo] arguments];
    if ((!self.exportObject.originalOffset || [arg indexOfObject:@"-noProps"] != NSNotFound) && !(self.exportObject.objectFlags & RF_ClassDefaultObject) && ![self.class isNative])
    {
      self.properties = [NSMutableArray new];
      return;
    }
    
    FIStream *s = [self.package.stream copy];
    s.position = self.exportObject.originalOffset;
    
    if (self.exportObject.objectFlags & RF_HasStack)
    {
      self.stateFrame = [FStateFrame readFrom:s];
    }
    
    if (![self.class isNative] && !(self.exportObject.objectFlags & RF_ClassDefaultObject) && !([self.parent objectFlags] & RF_ClassDefaultObject))
    {
      if ([self.class isSubclassOfClass:[UComponent class]])
      {
        self.expressionIndex = [s readInt:0];
      }
      else
      {
        if ([self.objectClass hasPrefix:@"Distribution"])
        {
          self.expressionIndex = [s readInt:0];
          DThrow(@"error!");
        }
        else if ([self.objectClass hasSuffix:@"Component"]) // StaticMeshComponent, AudioComponent, DecalComponent
        {
          self.expressionIndex = [s readInt:0];
          DThrow(@"error!");
        }
      }
    }
    
    self.netIndex = [s readInt:0];
    
    if ([self.class isNative])
    {
      self.native = [self.class readFrom:s];
      return;
    }
    
    if (self.exportObject.archetypeIdx > 0)
    {
      self.archetype = [self.package objectForIndex:self.exportObject.archetypeIdx];
    }
    
    FPropertyTag *property = [FPropertyTag readFrom:s object:self];
    self.properties = [NSMutableArray array];
    
    if (!property)
    {
      DLog(@"Failed to read properties of %@", self);
      return;
    }
    
    [self.properties addObject:property];
    
    while (![property isNone])
    {
      property = [FPropertyTag readFrom:s object:self];
      if (!property)
        break;
      [self.properties addObject:property];
    }
    self.rawDataOffset = (unsigned)s.position;
    [self willChangeValueForKey:@"displaySize"];
    self.dataSize = self.exportObject.serialSize - (self.rawDataOffset - self.exportObject.originalOffset);
    [self didChangeValueForKey:@"displaySize"];
    if (self.exportObject.objectFlags & RF_ClassDefaultObject)
      return;
    [s close];
    s = [self postProperties];
    if (s)
      [s close];
  }
}

- (FIStream *)postProperties
{
  return nil;
}

- (NSMutableData *)cookedProperties
{
  NSMutableData *d = [NSMutableData new];
  NSArray *p = self.properties;
  
  if (self.exportObject.objectFlags & RF_HasStack)
  {
    [d appendData:[self.stateFrame cooked:0]];
  }
  
  if (![self.class isNative] && !(self.exportObject.objectFlags & RF_ClassDefaultObject) && !([self.parent objectFlags] & RF_ClassDefaultObject))
  {
    if ([self.class isSubclassOfClass:[UComponent class]])
    {
      [d writeInt:self.expressionIndex];
    }
    else
    {
      if ([self.objectClass hasPrefix:@"Distribution"])
      {
        [d writeInt:self.expressionIndex];
      }
      else if ([self.objectClass hasSuffix:@"Component"]) // StaticMeshComponent, AudioComponent, DecalComponent
      {
        [d writeInt:self.expressionIndex];
      }
    }
  }
  
  [d writeInt:self.netIndex];
  
  if ([self.class isNative])
  {
    [d appendData:[self.native cooked:0]];
    return d;
  }
  
  for (FPropertyTag *tag in p)
    [d appendData:tag.cooked];
  
  return d;
}

- (NSMutableData *)cooked:(NSInteger)offset options:(NSDictionary *)options
{
  return [self cooked:offset];
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  if (!self.isDirty)
  {
    FIStream *s = [self.package.stream copy];
    s.position = self.exportObject.originalOffset;
    return [[s readData:self.exportObject.serialSize] mutableCopy];
  }
  NSMutableData *d = [self cookedProperties];
  if (self.customData)
  {
    [d appendData:self.customData];
  }
  else if (self.rawDataOffset)
  {
    FIStream *s = [self.package.stream copy];
    s.position = self.rawDataOffset;
    [d appendData:[s readData:self.dataSize]];
  }
  else
  {
    FIStream *s = [self.package.stream copy];
    s.position = self.exportObject.originalOffset;
    return [[s readData:self.exportObject.serialSize] mutableCopy];
  }
  return d;
}

- (NSMutableData *)cookedIndex
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:(int)self.objectIndex];
  return d;
}

- (NSInteger)objectIndex
{
  if (self.isZero)
    return 0;
  return [self.package indexForObject:self];
}

- (NSArray *)properties
{
  if (!_properties && self.exportObject.originalOffset)
    [self readProperties];
  return _properties;
}

- (NSImage *)icon
{
  if (self.importObject && !self.parent)
    return [UObject systemIcon:kGenericRemovableMediaIcon];
  if ([self.objectClass isEqualToString:kClassPackage])
    return [UObject systemIcon:kGenericFolderIcon];
  return [UObject systemIcon:kGenericComponentIcon];
}

+ (NSImage *)systemIcon:(OSType)iconCode
{
  NSImage *i = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(iconCode)];
  [i setSize:NSMakeSize(16, 16)];
  return i;
}

- (BOOL)canHaveChildOfClass:(NSString *)className
{
  if ([self.objectClass isEqualToString:kClassPackage])
    return YES;
  return NO;
}

- (FObject *)fObject
{
  return self.importObject ? self.importObject : self.exportObject;
}

- (NSString *)objectName
{
  return [self.fObject objectName];
}

- (NSString *)objectClass
{
  return [self.fObject objectClass];
}

- (NSString *)displayName
{
  return [NSString stringWithFormat:@"%@(%@)",self.objectName,self.objectClass];
}

- (NSString *)displayOffset
{
  return [NSString stringWithFormat:@"0x%08X",self.exportObject.originalOffset];
}

- (NSString *)displaySize
{
  return [NSString stringWithFormat:@"0x%08X",self.dataSize];
}

- (NSString *)displaySerialSize
{
  return [NSString stringWithFormat:@"0x%08X",self.exportObject.serialSize];
}

- (NSString *)displayPropsSize
{
  int v = 0;
  if (self.exportObject.serialSize)
    v = self.exportObject.serialSize - self.dataSize;
  return [NSString stringWithFormat:@"0x%08X", v];
}

- (id)parent
{
  return self.fObject.parent;
}

- (NSArray *)children
{
  return self.fObject.children;
}

- (NSUInteger)bytesToEnd:(FIStream *)stream
{
  NSUInteger pos = stream.position;
  if (pos < self.exportObject.originalOffset + self.exportObject.serialSize)
    return self.exportObject.originalOffset + self.exportObject.serialSize - pos;
  return 0;
}

- (FPropertyTag *)propertyForName:(NSString *)aName
{
  @synchronized (self)
  {
    if (!self.properties)
      [self readProperties];
    FPropertyTag *prop = [FPropertyTag propertyForName:aName from:self.properties];
    if (!prop && self.archetype)
    {
      return [self.archetype propertyForName:aName];
    }
    return prop;
  }
}

- (id)propertyValue:(NSString *)name
{
  FPropertyTag *p = [self propertyForName:name];
  if (!p)
  {
    return nil;
  }
  return p.value;
}

- (NSString *)xib
{
  if ([[NSBundle mainBundle] pathForResource:self.className ofType:@"nib"])
    return [self className];
  return @"UObject";
}

- (id)editor
{
  if (!_editor)
  {
    Class cls = NSClassFromString([[self className] stringByAppendingString:@"Editor"]);
    if (!cls)
      cls = [UObjectEditor class];
    _editor = [(UObjectEditor*)[cls alloc] initWithNibName:self.xib bundle:[NSBundle mainBundle]];
    _editor.object = self;
  }
  return _editor;
}

- (NSString *)description
{
  return self.isZero ? @"[0]<ZERO>" : [self.fObject description];
}

- (BOOL)isDirty
{
  return self.exportObject.objectFlags & RF_StateChanged;
}

- (void)setDirty:(BOOL)flag
{
  if (flag)
  {
    if (!self.isDirty)
      self.exportObject.objectFlags |= RF_StateChanged;
    self.package.isDirty = YES;
  }
  else if (self.isDirty)
  {
    self.exportObject.objectFlags &= ~RF_StateChanged;
  }
  [self.package.controller updateExports];
}

- (void)cleanup
{
  self.editor = nil;
  for (FPropertyTag *tag in self.properties)
  {
    [tag.controller cleanup];
    tag.controller = nil;
  }
}

- (NSData *)exportWithOptions:(NSDictionary *)options
{
  NSData *export = nil;
  
  UObjectExportOptions mode = [options[@"mode"] intValue];
  NSUInteger start = 0;
  NSUInteger length = 0;
  switch (mode) {
    case UObjectExportOptionsAll:
      start = self.exportObject.originalOffset;
      length = self.exportObject.serialSize;
      break;
      
    case UObjectExportOptionsData:
      start = self.rawDataOffset;
      length = self.dataSize;
      break;
      
    case UObjectExportOptionsProperties:
      start = self.exportObject.originalOffset;
      length = self.exportObject.serialSize - self.dataSize;
      break;
      
    default:
      break;
  }
  
  FIStream *s = [self.package.stream copy];
  s.position = start;
  export = [s readData:(int)length];
  
  return export;
}

- (void)testCook
{
#ifdef DEBUG
  [self setDirty:YES];
  NSData *cooked = [self cooked:self.exportObject.originalOffset];
  [self setDirty:NO];
  FIStream *s = [self.package.stream copy];
  s.position = self.exportObject.originalOffset;
  NSData *orig = [s readData:self.exportObject.serialSize];
  if (![cooked isEqualToData:orig])
  {
    DLog(@"Cook missmatch!");
    NSString *p = [[[NSHomeDirectory() stringByAppendingPathComponent:@"DEBUG_RE"] stringByAppendingPathComponent:self.package.name] stringByAppendingPathComponent:self.objectName];
    [[NSFileManager defaultManager] createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:NULL];
    p = [p stringByAppendingPathComponent:@"original.bin"];
    [orig writeToFile:p atomically:YES];
    DLog(@"Saved original to: %@",p);
    p = [[p stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cooked.bin"];
    [cooked writeToFile:p atomically:YES];
    DLog(@"Saved cooked to: %@",p);
    DThrow(@"STOP");
    s.position = self.exportObject.originalOffset;
    self.properties = nil;
    [self readProperties];
    cooked = [self cooked:self.exportObject.originalOffset];
  }
#endif
}

- (NSArray *)propertiesToPlist
{
  NSMutableArray *a = [NSMutableArray new];
  NSArray *p = self.properties;
  if (!p)
    return @[@"Failed to read properties!"];
  
  for (FPropertyTag *prop in p)
  {
    NSDictionary *d = [prop dictionary];
    if (d)
      [a addObject:d];
  }
  
  return a;
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
