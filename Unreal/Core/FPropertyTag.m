//
//  FPropertyTag.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FPropertyTag.h"
#import "Extensions.h"
#import "UObject.h"
#import "UPackage.h"
#import "FString.h"
#import "FGUID.h"
#import "FVector.h"
#import "FColor.h"
#import "FRotator.h"
#import "FMatrix.h"

NSString *const kPropNameNone = @"None";
NSString *const kPropTypeInt = @"IntProperty";
NSString *const kPropTypeFloat = @"FloatProperty";
NSString *const kPropTypeObj = @"ObjectProperty";
NSString *const kPropTypeName = @"NameProperty";
NSString *const kPropTypeString = @"StrProperty";
NSString *const kPropTypeStruct = @"StructProperty";
NSString *const kPropTypeArray = @"ArrayProperty";
NSString *const kPropTypeBool = @"BoolProperty";
NSString *const kPropTypeByte = @"ByteProperty";

NSString *const kPropTypeStructVector = @"Vector";
NSString *const kPropTypeStructVector4 = @"Vector4";
NSString *const kPropTypeStructColor = @"Color";
NSString *const kPropTypeStructLinearColor = @"LinearColor";
NSString *const kPropTypeStructGuid = @"Guid";
NSString *const kPropTypeStructRotator = @"Rotator";
NSString *const kPropTypeStructMatrix = @"Matrix";

@implementation FPropertyTag

+ (NSString *)propertyTypeForName:(NSString *)name ofClass:(NSString *)class
{
  NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Properties" ofType:@"plist"]];
  return plist[class][name];
}

+ (id)readFrom:(FIStream *)stream object:(UObject *)object parent:(FPropertyTag *)parent
{
  FIStream *s = stream;
#ifdef DEBUG
  NSUInteger dpos = s.position;
#endif
  FPropertyTag *tag = [super readFrom:s];
  tag.parent = parent;
  BOOL err = NO;
  tag.object = object;
  tag.fname = [FName readFrom:s];
  if (!tag.name)
  {
    DThrow(@"Warning! Failed to read property of object %@",object);
    return nil;
  }
  if ([tag.name isEqualToString:kPropNameNone])
    return tag;
  
  tag.ftype = [FName readFrom:s];
  if (!tag.type)
  {
    DThrow(@"Warning! Failed to read property of object %@",object);
    return nil;
  }
  
  tag.dataSize = [s readInt:&err];
  tag.arrayIndex = [s readInt:&err];
  
  if ([tag.type isEqualToString:kPropTypeInt] || [tag.type isEqualToString:kPropTypeObj])
  {
    tag.value = @([s readInt:&err]);
    
  }
  else if ( [tag.type isEqualToString:kPropTypeBool])
  {
    if (s.game == UGameBless)
      tag.value = @([s readByte:&err]);
    else
      tag.value = @([s readInt:&err]);
  }
  else if ([tag.type isEqualToString:kPropTypeByte])
  {
    void *ptr = NULL;
    switch (tag.dataSize)
    {
      case 1:
        tag.value = @([s readByte:&err]);
        break;
      case 2:
        tag.value = @([s readShort:&err]);
        break;
      case 4:
        tag.value = @([s readInt:&err]);
        break;
      case 8:
        tag.value = @([s readLong:&err]);
        break;
      default:
        ptr = [s readBytes:tag.dataSize error:&err];
        tag.value = [NSData dataWithBytes:ptr length:tag.dataSize];
        free(ptr);
        break;
    }
    if (s.game == UGameBless)
    {
      tag.fenum = [FName readFrom:s];
    }
  }
  else if ([tag.type isEqualToString:kPropTypeFloat])
  {
    tag.value = @([s readFloat:&err]);
  }
  else if ([tag.type isEqualToString:kPropTypeName])
  {
    tag.value = @([s readLong:&err]);
  }
  else if ([tag.type isEqualToString:kPropTypeString])
  {
    tag.value = [FString readFrom:s];
  }
  else if ([tag.type isEqualToString:kPropTypeStruct])
  {
    tag.fstruct = [FName readFrom:s];
    
    if ([tag.structName isEqualToString:kPropTypeStructVector])
    {
      FVector3 *v = [FVector3 readFrom:s];
      tag.value = v;
    }
    else if ([tag.structName isEqualToString:kPropTypeStructVector4])
    {
      FVector4 *v = [FVector4 readFrom:s];
      tag.value = v;
    }
    else if ([tag.structName isEqualToString:kPropTypeStructColor])
    {
      if (tag.dataSize == 4)
      {
        FColor *c = [FColor readFrom:s];
        tag.value = c;
      }
      else
      {
        DThrow(@"Warning! Incorrect color size %d!", tag.dataSize);
        FLinearColor *c = [FLinearColor readFrom:s];
        tag.value = c;
      }
    }
    else if ([tag.structName isEqualToString:kPropTypeStructLinearColor])
    {
      if (tag.dataSize == 4)
      {
        DThrow(@"Warning! Incorrect linearcolor size %d!", tag.dataSize);
        FColor *c = [FColor readFrom:s];
        tag.value = c;
      }
      else
      {
        FLinearColor *c = [FLinearColor readFrom:s];
        tag.value = c;
      }
    }
    else if ([tag.structName isEqualToString:kPropTypeStructVector4])
    {
      FVector4 *v = [FVector4 readFrom:s];
      tag.value = v;
    }
    else if ([tag.structName isEqualToString:kPropTypeStructGuid])
    {
      tag.value = [FGUID readFrom:s];
    }
    else if ([tag.structName isEqualToString:kPropTypeStructRotator])
    {
      FRotator *r = [FRotator readFrom:s];
      tag.value = r;
    }
    else if ([tag.structName isEqualToString:kPropTypeStructMatrix])
    {
      FMatrix *m = [FMatrix readFrom:s];
      tag.value = m;
    }
    else
    {
      NSInteger safePosition = [s position];
      BOOL err = NO;
      
      FPropertyTag *subProp = nil;
      NSDictionary *props = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Structs" ofType:@"plist"]];
      if ([props[tag.structName] isEqualToString:@"Property"])
        subProp = [FPropertyTag readFrom:s object:object parent:tag];
      else
        DLog(@"Unknown struct: %@",tag.structName);
      if (subProp)
      {
        tag.arrayType = @"Property";
        tag.value = [NSMutableArray array];
        [tag.value addObject:subProp];
        while (![subProp.name isEqualToString:kPropNameNone])
        {
          subProp = [FPropertyTag readFrom:s object:object parent:tag];
          if (!subProp)
          {
            err = YES;
            s.position = safePosition;
            DLog(@"Failed to read sub property!");
            break;
          }
          [tag.value addObject:subProp];
        }
      }
      
      if (err || !subProp)
      {
        tag.arrayType = @"Raw";
        void *ptr = NULL;
        ptr = [s readBytes:tag.dataSize error:&err];
        tag.value = [NSData dataWithBytes:ptr length:tag.dataSize];
        free(ptr);
      }
      
    }
    
  }
  else if ([tag.type isEqualToString:kPropTypeArray])
  {
    
    tag.value = [NSMutableArray array];
    
    if (!tag.dataSize)
      return tag;
    
    tag.elementCount = [s readInt:&err];
    
    if (!tag.elementCount)
      return tag;
    
    NSString *type = [FPropertyTag propertyTypeForName:tag.name ofClass:object.objectClass];
    
    tag.arrayType = type;
    
    if ([type isEqualToString:@"Raw"])
    {
      
      NSData *raw = nil;
      void *ptr = [s readBytes:tag.dataSize - 4 error:&err];
      raw = [NSData dataWithBytes:ptr length:tag.dataSize - 4];
      free(ptr);
      tag.value = raw;
      
    }
    else if ([type isEqualToString:@"Property"])
    {
      
      NSInteger safePosition = [s position];
      int i = 0;
      [tag.value addObject:[NSMutableArray array]];
      
      for (; i < tag.elementCount;)
      {
        FPropertyTag *addTag = [FPropertyTag readFrom:stream object:tag.object parent:tag];
        if (!addTag)
        {
          DLog(@"[%@(%@)]Couldn't read sub property %d out of %d properties at 0x%08lX! Recovering...",tag.name,tag.type,i + 1,tag.elementCount,(unsigned long)[s position]);
          i = -1;
          break;
        }
        
        if (![[addTag name] isEqualToString:kPropNameNone])
        {
          [[tag.value lastObject] addObject:addTag];
        }
        else
        {
          i++;
          [[tag.value lastObject] addObject:addTag];
          if (i < tag.elementCount)
            [tag.value addObject:[NSMutableArray array]];
        }
      }
      
      if (i == -1)
      {
        DLog(@"Falling back to 0x%08lX",(long)safePosition);
        tag.arrayType = @"Raw";
        [s setPosition:safePosition];
        void *ptr = NULL;
        ptr = [s readBytes:tag.dataSize - 4 error:&err];
        tag.value = [NSData dataWithBytes:ptr length:tag.dataSize - 4];
        free(ptr);
      }
      
    }
    else if ([type isEqualToString:@"Object"])
    {
      for (int i = 0; i < tag.elementCount; i++)
      {
        [tag.value addObject:@([s readInt:&err])];
      }
    }
    else if ([type isEqualToString:@"Name"])
    {
      for (int i = 0; i < tag.elementCount; i++)
      {
        [tag.value addObject:[FName readFrom:s]];
      }
    }
    else
    {
      
      int elementSize = (tag.dataSize - 4) / tag.elementCount;
      
      if (elementSize == 1)
      {
        if ([tag.name hasSuffix:@"Data"])
        {
          tag.arrayType = @"Raw";
          tag.value = [s readData:tag.elementCount];
        }
        else
        {
          for (int i = 0; i < tag.elementCount; i++)
          {
            [tag.value addObject:@([s readByte:&err])];
          }
        }
        
      }
      else if (elementSize == 2)
      {
        
        for (int i = 0; i < tag.elementCount; i++)
        {
          [tag.value addObject:@([s readShort:&err])];
        }
        
      }
      else if (elementSize == 4)
      {
        
        for (int i = 0; i < tag.elementCount; i++)
        {
          [tag.value addObject:@([s readInt:&err])];
        }
        
      }
      else if (elementSize == 8)
      {
        
        for (int i = 0; i < tag.elementCount; i++)
        {
          [tag.value addObject:@([s readLong:&err])];
        }
        
      }
      else if (elementSize == 16)
      {
        
        for (int i = 0; i < tag.elementCount; i++)
        {
          [tag.value addObject:[FGUID readFrom:s]];
        }
        
      }
      else
      {
        
        NSInteger safePosition = [s position];
        int i = 0;
        [tag.value addObject:[NSMutableArray array]];
        
        if (!([tag.name isEqualToString:@"EdgeDirections"] || [tag.name isEqualToString:@"FaceNormalDirections"]))
        {
          if ([tag.name hasSuffix:@"Data"])
          {
            DLog(@"Skipping property: %@(DataTag)", tag);
            i = -1;
          }
          else
          {
            for (; i < tag.elementCount;)
            {
              FPropertyTag *addTag = [FPropertyTag readFrom:stream object:tag.object parent:tag];
              if (!addTag)
              {
                DLog(@"[%@(%@)]Couldn't read sub property %d out of %d properties at 0x%08lX! Recovering...",tag.name,tag.type,i + 1,tag.elementCount,(unsigned long)[s position]);
                i = -1;
                break;
              }
              
              if (![[addTag name] isEqualToString:kPropNameNone])
              {
                [[tag.value lastObject] addObject:addTag];
              }
              else
              {
                [[tag.value lastObject] addObject:addTag];
                i++;
                if (i < tag.elementCount)
                  [tag.value addObject:[NSMutableArray array]];
              }
            }
          }
        }
        else
          i = -1;
        
        
        if (i == -1)
        {
          DLog(@"[%@]Falling back to 0x%08lX", tag, (long)safePosition);
          tag.arrayType = @"Raw";
          [s setPosition:safePosition];
          void *ptr = NULL;
          ptr = [s readBytes:tag.dataSize - 4 error:&err];
          tag.value = [NSData dataWithBytes:ptr length:tag.dataSize - 4];
          free(ptr);
          
        }
        else
        {
          
          tag.arrayType = @"Property";
          
        }
        
      }
      
    }
    
  }
  else
  {
    
    DLog(@"Warning! Unknown property type: %@",tag.type);
    if (tag.dataSize)
    {
      NSUInteger safePosition = s.position;
      int i = 0;
      FPropertyTag *addTag = nil;
      do
      {
        tag.value = [NSMutableArray new];
        NSDictionary *props = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Structs" ofType:@"plist"]];
        if ([props[tag.name] isEqualToString:@"Property"])
          addTag = [FPropertyTag readFrom:stream object:tag.object parent:tag];
        if (addTag)
          [tag.value addObject:addTag];
        else
        {
          DLog(@"[%@(%@)]Couldn't read sub property %d out of %d properties at 0x%08lX! Recovering...",tag.name,tag.type,i + 1,tag.elementCount,(unsigned long)[s position]);
          i = -1;
          break;
        }
      } while (!addTag.isNone);
      
      if (i == -1)
      {
        s.position = safePosition;
        void *ptr = [s readBytes:tag.dataSize error:&err];
        tag.value = [NSData dataWithBytes:ptr length:tag.dataSize];
        free(ptr);
        DLog(@"Falling back to 0x%08lX",(unsigned long)safePosition);
        tag.arrayType = @"Raw";
      }
      else
      {
        tag.arrayType = @"Property";
      }
      
    }
    
  }
#ifdef DEBUG
  NSArray *arg = [[NSProcessInfo processInfo] arguments];
  if ([arg indexOfObject:@"-testCook"] != NSNotFound)
  {
    NSUInteger endPos = s.position;
    s.position = dpos;
    NSData *orig = [s readData:(int)(endPos - dpos)];
    NSData *cooked = [tag cooked];
    
    if (![cooked isEqualToData:orig])
    {
      DLog(@"Cook missmatch!");
      NSString *p = [[[NSHomeDirectory() stringByAppendingPathComponent:@"DEBUG_RE"] stringByAppendingPathComponent:tag.package.name] stringByAppendingPathComponent:tag.description];
      [[NSFileManager defaultManager] createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:NULL];
      p = [p stringByAppendingPathComponent:@"original.bin"];
      [orig writeToFile:p atomically:YES];
      DLog(@"Saved original to: %@",p);
      p = [[p stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cooked.bin"];
      [cooked writeToFile:p atomically:YES];
      DLog(@"Saved cooked to: %@",p);
      DThrow(@"STOP");
      s.position = dpos;
      FPropertyTag *otag = [FPropertyTag readFrom:s object:object parent:parent];
      [otag cooked];
    }
    s.position = endPos;
  }
#endif
  return tag;
}

+ (id)intProperty:(int)value name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeInt flags:0 package:object.package];
  tag.dataSize = 4;
  tag.value = @(value);
  return tag;
}

+ (id)floatProperty:(float)value name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeFloat flags:0 package:object.package];
  tag.dataSize = 4;
  tag.value = @(value);
  return tag;
}

+ (id)byteProperty:(long)value size:(int)size name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeByte flags:0 package:object.package];
  tag.dataSize = size;
  tag.value = @(value);
  return tag;
}

+ (id)boolProperty:(BOOL)value name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeBool flags:0 package:object.package];
  tag.dataSize = value ? 4 : 0;
  tag.value = @(value);
  return tag;
}

+ (id)nameProperty:(NSString *)value name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeName flags:0 package:object.package];
  tag.dataSize = 8;
  tag.value = @([object.package indexForName:value]);
  return tag;
}

+ (id)objectProperty:(UObject *)value name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeObj flags:0 package:object.package];
  tag.dataSize = 4;
  tag.value = @([object.package indexForObject:value]);
  return tag;
}

+ (id)stringProperty:(NSString *)value name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeString flags:0 package:object.package];
  tag.value = [FString stringWithString:value];
  tag.dataSize = (int)[[(FString *)tag.value cooked] length];
  return tag;
}

+ (id)guidProperty:(FGUID *)guid name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:kPropTypeStructGuid flags:0 package:object.package];
  tag.value = guid;
  tag.dataSize = 16;
  return tag;
}

+ (id)linearColorProperty:(FLinearColor *)color name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:kPropTypeStructLinearColor flags:0 package:object.package];
  tag.value = color;
  tag.dataSize = 16;
  return tag;
}

+ (id)colorProperty:(FColor *)color name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:kPropTypeStructColor flags:0 package:object.package];
  tag.value = color;
  tag.dataSize = 16;
  return tag;
}

+ (id)rotatorProperty:(FRotator *)rotator name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:kPropTypeStructRotator flags:0 package:object.package];
  tag.value = rotator;
  tag.dataSize = 12;
  return tag;
}

+ (id)vectorProperty:(FVector3 *)vector name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:kPropTypeStructVector flags:0 package:object.package];
  tag.value = vector;
  tag.dataSize = 12;
  return tag;
}

+ (id)vector4Property:(FVector4 *)vector name:(NSString *)aName object:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:kPropTypeStructVector4 flags:0 package:object.package];
  tag.value = vector;
  tag.dataSize = 16;
  return tag;
}

+ (id)customProperty:(NSData *)data name:(NSString *)aName object:(UObject *)object structName:(NSString *)sName
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:aName flags:0 package:object.package];
  tag.ftype = [FName nameWithString:kPropTypeStruct flags:0 package:object.package];
  tag.fstruct = [FName nameWithString:sName flags:0 package:object.package];
  tag.value = data;
  tag.dataSize = (int)[data length];
  return tag;
}

+ (id)nonePropertyForObject:(UObject *)object
{
  FPropertyTag *tag = [FPropertyTag newWithPackage:object.package];
  tag.object = object;
  tag.fname = [FName nameWithString:kPropNameNone flags:0 package:object.package];
  return tag;
}

- (NSDictionary *)dictionary
{
  NSMutableDictionary *dic = [NSMutableDictionary new];
  BOOL isArray = NO, isStruct = NO;
  dic[@"Name"] = self.name;
  if ([self.name isEqualToString:kPropNameNone])
    return dic;
  dic[@"Type"] = self.type;
  
  if ([self.type isEqualToString:kPropTypeArray])
    isArray = YES;
  else if ([self.type isEqualToString:kPropTypeStruct])
    isStruct = YES;
  
  if (isStruct)
  {
    dic[@"Struct"] = self.structName ? self.structName : @"";
    if ([self.value respondsToSelector:@selector(plist)] && [self.value plist])
      dic[@"Value"] = [self.value plist];
    else if ([self.value isKindOfClass:[NSData class]])
      dic[@"Value"] = self.value;
  }
  
  dic[@"DataSize"] = @(self.dataSize);
  dic[@"ArrayIndex"] = @(self.arrayIndex);
  
  if (isArray)
  {
    dic[@"ElementCount"] = @(self.elementCount);
    dic[@"ArrayType"] = self.arrayType;
    if ([self.arrayType isEqualToString:@"Raw"])
      dic[@"Value"] = (NSData *)self.value;
    else if ([self.arrayType isEqualToString:@"Property"])
    {
      NSMutableArray *val = [NSMutableArray new];
      dic[@"Value"] = val;
      
      for (id element in self.value)
      {
        if ([element isKindOfClass:[FPropertyTag class]])
          [val addObject:[(FPropertyTag *)element dictionary]];
        else if ([element isKindOfClass:[NSArray class]])
        {
          NSMutableArray *subVal = [NSMutableArray new];
          [val addObject:subVal];
          for (id subElement in element)
          {
            if ([subElement isKindOfClass:[FPropertyTag class]])
              [subVal addObject:[subElement dictionary]];
            else
              [subVal addObject:subElement];
          }
        }
        else
        {
          [val addObject:element];
        }
      }
    }
    else if ([self.type isEqualToString:@"Object"])
    {
      NSMutableArray *val = [NSMutableArray new];
      dic[@"Value"] = val;
      
      for (id element in self.value)
      {
        if ([element isKindOfClass:[UObject class]])
          [val addObject:[element description]];
        else if ([element isKindOfClass:[NSArray class]])
        {
          NSMutableArray *subVal = [NSMutableArray new];
          [val addObject:subVal];
          for (id subElement in element)
          {
            if ([subElement isKindOfClass:[UObject class]])
              [subVal addObject:[subElement description]];
            else
              [subVal addObject:subElement];
          }
        }
        else
        {
          [val addObject:element];
        }
      }
    }
  }
  return dic;
}

- (void)recalculateSize
{
  if ([self.type isEqualToString:kPropTypeArray])
  {
    int size = 4;
    NSString *type = self.arrayType;
    
    if ([type isEqualToString:@"Raw"]) {
      size += [self.value length];
    } else if ([type isEqualToString:@"Property"]) {
      
      NSMutableData *temp = [NSMutableData data];
      for (id sub in self.value) {
        if ([sub isKindOfClass:[NSArray class]]) {
          BOOL none = NO;
          
          for (FPropertyTag *tag in sub) {
            [temp appendData:[tag cooked]];
            if ([tag.name isEqualToString:kPropNameNone])
              none = YES;
          }
          if (!none)
            [temp increaseLengthBy:8];
        } else if ([sub isKindOfClass:[FPropertyTag class]]) {
          [temp appendData:[(FPropertyTag *)sub cooked]];
        }
      }
      
      size += [temp length];
    }
    
    self.dataSize = size;
  }
}

- (NSData *)cookedWithBody:(NSData *)body
{
  NSMutableData *cookedData = [self.fname cooked:0];
  
  if ([self.name isEqualToString:kPropNameNone])
    return cookedData;
  
  [cookedData appendData:[self.ftype cooked:0]];
  
  int size = (int)[body length];
  
  if ([self.type isEqualToString:kPropTypeStruct]) // Structs don't count structName
    size -= 8;
  else if ([self.type isEqualToString:kPropTypeBool])
    size = 0;//[self.value boolValue] ? 4 : 0;
  
  [cookedData writeInt:size];
  [cookedData writeInt:self.arrayIndex];
  [cookedData appendData:body];
  return cookedData;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  return (NSMutableData *)[self cooked];
}

- (NSData *)cooked
{
  if ([self.name isEqualToString:kPropNameNone])
    return [self cookedWithBody:nil];
  NSMutableData *cooked = [NSMutableData data];
  if ([self.type isEqualToString:kPropTypeInt] ||
      [self.type isEqualToString:kPropTypeObj])
  {
    [cooked writeInt:[self.value intValue]];
  }
  else if ([self.type isEqualToString:kPropTypeBool])
  {
    if (self.package.game == UGameBless)
    {
      [cooked writeByte:[self.value boolValue]];
    }
    else
    {
      [cooked writeInt:[self.value intValue]];
    }
  }
  else if ([self.type isEqualToString:kPropTypeByte])
  {
    
    switch (self.dataSize)
    {
      case 1:
        [cooked writeByte:(Byte)[self.value shortValue]];
        break;
      case 2:
        [cooked writeShort:[self.value shortValue]];
        break;
      case 4:
        [cooked writeInt:[self.value intValue]];
        break;
      case 8:
        [cooked writeLong:[self.value longValue]];
        break;
      default:
        [cooked appendData:self.value];
        break;
    }
    if (self.package.game == UGameBless)
    {
      [cooked appendData:[self.fenum cooked:0]];
    }
  }
  else if ([self.type isEqualToString:kPropTypeFloat])
  {
    [cooked writeFloat:[self.value floatValue]];
  }
  else if ([self.type isEqualToString:kPropTypeName])
  {
    [cooked writeLong:[self.value longValue]];
  }
  else if ([self.type isEqualToString:kPropTypeString])
  {
    [cooked appendData:[(FString *)[self value] cooked]];
  }
  else if ([self.type isEqualToString:kPropTypeStruct])
  {
    
    [cooked appendData:[self.fstruct cooked:0]];
    
    if ([self.structName isEqualToString:kPropTypeStructVector] ||
        [self.structName isEqualToString:kPropTypeStructVector4] ||
        [self.structName isEqualToString:kPropTypeStructGuid] ||
        [self.structName isEqualToString:kPropTypeStructColor] ||
        [self.structName isEqualToString:kPropTypeStructLinearColor] ||
        [self.structName isEqualToString:kPropTypeStructMatrix] ||
        [self.structName isEqualToString:kPropTypeStructRotator])
    {
      
      FReadable *v = self.value;
      [cooked appendData:[v cooked:0]];
      
    }
    else
    {
      
      if ([self.value isKindOfClass:[NSData class]])
        [cooked appendData:self.value];
      else if ([self.value isKindOfClass:[NSArray class]])
      {
        for (id element in self.value)
        {
          if ([element isKindOfClass:[FPropertyTag class]])
            [cooked appendData:[element cooked:0]];
          else
            DThrow(@"Unexpected type %@",[element className]);
        }
      }
      else
        [cooked appendData:[self.value cooked]];
      
    }
  }
  else if ([self.type isEqualToString:kPropTypeArray])
  {
    
    if (!self.dataSize)
      return [self cookedWithBody:cooked];
    
    [cooked writeInt:self.elementCount];
    
    if (!self.elementCount)
      return [self cookedWithBody:cooked];
    
    NSString *type = self.arrayType;
    
    if ([type isEqualToString:@"Raw"])
    {
      
      [cooked appendData:self.value];
      
    }
    else if ([type isEqualToString:@"Property"])
    {
      
      for (NSArray *subArr in self.value)
      {
        BOOL none = NO;
        for (FPropertyTag *tag in subArr)
        {
          [cooked appendData:[tag cooked]];
          if ([tag.name isEqualToString:kPropNameNone])
          {
            none = YES;
          }
        }
        if (!none)
        {
          [cooked writeLong:[self.package indexForName:kPropNameNone]];
        }
      }
      
    }
    else if ([type isEqualToString:@"Object"])
    {
      
      for (NSNumber *value in self.value)
      {
        [cooked writeInt:[value intValue]];
      }
      
    }
    else if ([type isEqualToString:@"Name"])
    {
      for (FName *value in self.value)
      {
        if ([value isKindOfClass:[FName class]])
        {
          [cooked appendData:[value cooked:0]];
        }
        else
        {
          [cooked writeInt:[(NSNumber *)value intValue]];
          [cooked writeInt:0];
        }
      }
    }
    else
    {
      
      int elementSize = (self.dataSize - 4) / self.elementCount;
      
      if (elementSize == 1)
      {
        if ([self.value isKindOfClass:[NSData class]])
        {
          [cooked appendData:self.value];
        }
        else
        {
          for (int i = 0; i < self.elementCount; i++)
          {
            [cooked writeByte:(Byte)[self.value[i] shortValue]];
          }
        }
      }
      else if (elementSize == 2)
      {
        
        for (int i = 0; i < self.elementCount; i++)
        {
          [cooked writeShort:[self.value[i] shortValue]];
        }
        
      }
      else if (elementSize == 4)
      {
        
        for (int i = 0; i < self.elementCount; i++)
        {
          [cooked writeInt:[self.value[i] intValue]];
        }
        
      }
      else if (elementSize == 8)
      {
        
        for (int i = 0; i < self.elementCount; i++)
        {
          [cooked writeLong:[self.value[i] longValue]];
        }
        
      }
      else if (elementSize == 16)
      {
        
        for (int i = 0; i < self.elementCount; i++)
        {
          [cooked appendData:[self.value[i] cooked:0]];
        }
        
      }
    }
  }
  else
  {
    assert(0);
  }
  
  return [self cookedWithBody:cooked];
}

+ (id)readFrom:(FIStream *)stream object:(UObject *)object
{
  return [self readFrom:stream object:object parent:nil];
}

+ (FPropertyTag *)propertyForName:(NSString *)aName from:(NSArray *)props
{
  for (FPropertyTag *prop in props) {
    if ([prop isKindOfClass:[FPropertyTag class]]) {
      if ([[prop name] isEqualToString:aName]) {
        return prop;
        break;
      } else if ([prop.type isEqualToString:@"ArrayProperty"] && [prop.value isKindOfClass:[NSArray class]] && [(NSArray *)prop.value count]) {
        FPropertyTag *t = [self propertyForName:aName from:prop.value];
        if (t)
          return t;
      }
    } else if ([prop isKindOfClass:[NSArray class]]) {
      FPropertyTag *t = [self propertyForName:aName from:(NSArray *)prop];
      if (t)
        return t;
    }
    
  }
  return nil;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@(%@:%d)",self.name,self.type,self.dataSize];
}

- (NSString *)name
{
  return [self.fname string];
}

- (NSString *)enumName
{
  return [self.fenum string];
}

- (NSString *)type
{
  return [self.ftype string];
}

- (NSString *)structName
{
  return [self.fstruct string];
}

- (BOOL)isNone
{
  return [self.name isEqualToString:kPropNameNone];
}

- (NSString *)xib
{
  if (self.isNone)
    return @"NoneProperty";
  
  if ([self.type isEqualToString:kPropTypeBool])
    return @"BoolProperty";
  
  if ([self.type isEqualToString:kPropTypeArray])
  {
    if ([self.arrayType isEqualToString:@"Raw"])
      return @"RawProperty";
    return @"ArrayProperty";
  }
  
  if ([self.type isEqualToString:kPropTypeObj])
    return @"ObjectProperty";
  
  if ([self.type isEqualToString:kPropTypeStruct])
  {
    if ([self.structName isEqualToString:kPropTypeStructColor] || [self.structName isEqualToString:kPropTypeStructLinearColor])
      return @"ColorProperty";
    if ([self.structName isEqualToString:kPropTypeStructVector])
      return @"Vector3Property";
    if ([self.structName isEqualToString:kPropTypeStructRotator])
      return @"Vector3Property";
    if ([self.arrayType isEqualToString:@"Property"])
      return @"ArrayProperty";
  }
  
  if ([self.value isKindOfClass:[NSData class]])
    return @"RawProperty";
  
  return @"GeneralProperty";
}

- (PropertyController *)controller
{
  if (!_controller)
    _controller = [PropertyController controllerForProperty:self];
  return _controller;
}

- (id)formattedValue
{
  if ([self.type isEqualToString:kPropTypeObj])
    return [NSString stringWithFormat:@"%@ (%@)",[self.value objectName],[self.value objectClass]];
  if ([self.type isEqualToString:kPropTypeByte])
  {
    if (self.package.game == UGameBless)
      return self.enumName;
    return [self.package nameForIndex:[self.value intValue]];
  }
  
  if ([self.type isEqualToString:kPropTypeStruct])
  {
    if ([self.structName isEqualToString:kPropTypeStructVector])
    {
      float x = [(FVector3*)self.value x];
      float y = [(FVector3*)self.value y];
      float z = [(FVector3*)self.value z];
      return [NSString stringWithFormat:@"%f,%f,%f",x,y,z];
    }
    if ([self.structName isEqualToString:kPropTypeStructVector4])
    {
      float x = [(FVector4*)self.value x];
      float y = [(FVector4*)self.value y];
      float z = [(FVector4*)self.value z];
      float w = [(FVector4*)self.value w];
      return [NSString stringWithFormat:@"%f,%f,%f,%f",x,y,z,w];
    }
    if ([self.structName isEqualToString:kPropTypeStructColor] || [self.structName isEqualToString:kPropTypeStructLinearColor])
    {
      return self.value;
    }
  }
  
  return self.value;
}

- (void)setValue:(id)value
{
  if (_controller)
    [self.controller willChangeValueForKey:@"formattedValue"];
  _value = value;
  if (_controller)
    [self.controller didChangeValueForKey:@"formattedValue"];
}

@end
