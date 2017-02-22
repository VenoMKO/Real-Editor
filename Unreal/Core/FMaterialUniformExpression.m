//
//  FMaterialUniformExpression.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 12/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FMaterialUniformExpression.h"
#import "UPackage.h"



@implementation FMaterialUniformExpression

+ (instancetype)readFrom:(FIStream *)s
{
  int idx = [s readInt:0];
  int idxFlags = [s readInt:0];
  NSString *type = [s.package nameForIndex:idx];
  Class cls = NSClassFromString(type);
  if (!cls)
    DThrow(@"Class not found: %@",type);
  if (![NSStringFromClass(cls) isEqualToString:type])
    DThrow(@"Invalid class loaded!");
  
  if (cls)
  {
    FMaterialUniformExpression *e = [cls readFrom:s];
    e.typeFlags = idxFlags;
    return e;
  }
  else
    DThrow(@"Unknown expression: %@", type);
  
  return nil;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:[self.package indexForName:[self className]]];
  [d writeInt:self.typeFlags];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [NSMutableDictionary new];
  d[@"type"] = [self className];
  d[@"flags"] = @(self.typeFlags);
  return d;
}

@end

@implementation FMaterialUniformExpressionScalarParameter

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionScalarParameter *e = [FMaterialUniformExpressionScalarParameter newWithPackage:s.package];
  e.parameterName = [s.package nameForIndex:[s readInt:0]];
  e.parameterNameFlags = [s readInt:0];
  e.defaultValue = @([s readFloat:0]);
  return e;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:[self.package indexForName:self.parameterName]];
  [d writeInt:self.parameterNameFlags];
  [d writeFloat:[self.defaultValue floatValue]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"name"] = self.parameterName;
  d[@"nflags"] = @(self.parameterNameFlags);
  d[@"v"] = self.defaultValue;
  return d;
}

@end

@implementation FMaterialUniformExpressionVectorParameter

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionVectorParameter *e = [FMaterialUniformExpressionVectorParameter newWithPackage:s.package];
  e.parameterName = [s.package nameForIndex:[s readInt:0]];
  e.parameterNameFlags = [s readInt:0];
  e.defaultValue = [FLinearColor readFrom:s];
  return e;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:[self.package indexForName:self.parameterName]];
  [d writeInt:self.parameterNameFlags];
  [d appendData:[self.defaultValue cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"name"] = self.parameterName;
  d[@"nflags"] = @(self.parameterNameFlags);
  d[@"v"] = [self.defaultValue plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionTextureParameter

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionTextureParameter *e = [FMaterialUniformExpressionTextureParameter newWithPackage:s.package];
  e.parameterName = [s.package nameForIndex:[s readInt:0]];
  e.parameterNameFlags = [s readInt:0];
  e.defaultValue = @([s readInt:0]);
  return e;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:[self.package indexForName:self.parameterName]];
  [d writeInt:self.parameterNameFlags];
  [d writeInt:[self.defaultValue intValue]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"name"] = self.parameterName;
  d[@"nflags"] = @(self.parameterNameFlags);
  d[@"v"] = [[self.package objectForIndex:[self.defaultValue intValue]] objectPath];
  return d;
}

@end

@implementation FMaterialUniformExpressionTexture

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionTexture *e = [FMaterialUniformExpressionTexture newWithPackage:s.package];
  e.defaultValue = @([s readInt:0]);
  return e;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:[self.defaultValue intValue]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"v"] = [[self.package objectForIndex:[self.defaultValue intValue]] objectPath];
  return d;
}

@end

@implementation FMaterialUniformExpressionTime

+ (instancetype)readFrom:(FIStream *)s
{
  return [FMaterialUniformExpressionTime newWithPackage:s.package];
}

- (id)value
{
  return nil;
}

@end

@implementation FMaterialUniformExpressionAppendVector

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionAppendVector *e = [FMaterialUniformExpressionAppendVector newWithPackage:s.package];
  e.a = [FMaterialUniformExpression readFrom:s];
  e.b = [FMaterialUniformExpression readFrom:s];
  e.numComponentsA = [s readInt:0];
  return e;
}

- (id)value
{
  FLinearColor *result = [FLinearColor newWithPackage:self.package];
  FLinearColor *a = [self.a value];
  FLinearColor *b = [self.b value];
  result.r = self.numComponentsA >= 1 ? a.r : [b[0 - self.numComponentsA] doubleValue];
  result.g = self.numComponentsA >= 2 ? a.g : [b[1 - self.numComponentsA] doubleValue];
  result.b = self.numComponentsA >= 3 ? a.b : [b[2 - self.numComponentsA] doubleValue];
  result.a = self.numComponentsA >= 4 ? a.a : [b[3 - self.numComponentsA] doubleValue];
  return result;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.a cooked:offset + d.length]];
  [d appendData:[self.b cooked:offset + d.length]];
  [d writeInt:self.numComponentsA];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"a"] = [self.a plist];
  d[@"b"] = [self.b plist];
  d[@"v"] = @(self.numComponentsA);
  return d;
}

@end

@implementation FMaterialUniformExpressionPeriodic

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionPeriodic *e = [FMaterialUniformExpressionPeriodic newWithPackage:s.package];
  e.x = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.x cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"x"] = [self.x plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionFoldedMath

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionFoldedMath *e = [FMaterialUniformExpressionFoldedMath newWithPackage:s.package];
  e.a = [FMaterialUniformExpression readFrom:s];
  e.b = [FMaterialUniformExpression readFrom:s];
  e.op = [s readByte:0];
  return e;
}

- (id)value
{
  FLinearColor *result = [FLinearColor newWithPackage:self.package];
  
  return result;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.a cooked:offset + d.length]];
  [d appendData:[self.b cooked:offset + d.length]];
  [d writeByte:self.op];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"a"] = [self.a plist];
  d[@"b"] = [self.b plist];
  d[@"op"] = @(self.op);
  return d;
}

@end

@implementation FMaterialUniformExpressionConstant

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionConstant *e = [FMaterialUniformExpressionConstant newWithPackage:s.package];
  e.defaultValue = [FLinearColor readFrom:s];
  e.type = [s readByte:0];
  return e;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.defaultValue cooked:offset + d.length]];
  [d writeByte:self.type];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"v"] = [self.defaultValue plist];
  d[@"type"] = @(self.type);
  return d;
}

@end

@implementation FMaterialUniformExpressionSine

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionSine *e = [FMaterialUniformExpressionSine newWithPackage:s.package];
  e.x = [FMaterialUniformExpression readFrom:s];
  e.isCosine = [s readInt:0];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.x cooked:offset + d.length]];
  [d writeInt:self.isCosine];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"v"] = [self.x plist];
  d[@"cos"] = @(self.isCosine);
  return d;
}

@end

@implementation FMaterialUniformExpressionClamp

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionClamp *e = [FMaterialUniformExpressionClamp newWithPackage:s.package];
  e.input = [FMaterialUniformExpression readFrom:s];
  e.min = [FMaterialUniformExpression readFrom:s];
  e.max = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.input cooked:offset + d.length]];
  [d appendData:[self.min cooked:offset + d.length]];
  [d appendData:[self.max cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"in"] = [self.input plist];
  d[@"min"] = [self.min plist];
  d[@"max"] = [self.max plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionRealTime

+ (instancetype)readFrom:(FIStream *)s
{
  return [FMaterialUniformExpressionRealTime newWithPackage:s.package];
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionFrac

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionFrac *e = [FMaterialUniformExpressionFrac newWithPackage:s.package];
  e.x = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.x cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"x"] = [self.x plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionFlipBookTextureParameter

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionFlipBookTextureParameter *e = [FMaterialUniformExpressionFlipBookTextureParameter newWithPackage:s.package];
  e.defaultValue = @([s readInt:0]);
  return e;
}

- (id)value
{
  return self.defaultValue;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeInt:[self.defaultValue intValue]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"v"] = [[self.package objectForIndex:[self.defaultValue intValue]] objectPath];
  return d;
}

@end

@implementation FMaterialUniformExpressionFloor

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionFloor *e = [FMaterialUniformExpressionFloor newWithPackage:s.package];
  e.x = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.x cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"x"] = [self.x plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionCeil

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionCeil *e = [FMaterialUniformExpressionCeil newWithPackage:s.package];
  e.x = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.x cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"x"] = [self.x plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionMax

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionMax *e = [FMaterialUniformExpressionMax newWithPackage:s.package];
  e.a = [FMaterialUniformExpression readFrom:s];
  e.b = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (id)value
{
  FLinearColor *result = [FLinearColor newWithPackage:self.package];
  
  return result;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.a cooked:offset + d.length]];
  [d appendData:[self.b cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"a"] = [self.a plist];
  d[@"b"] = [self.b plist];
  return d;
}

@end

@implementation FMaterialUniformExpressionAbs

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterialUniformExpressionAbs *e = [FMaterialUniformExpressionAbs newWithPackage:s.package];
  e.x = [FMaterialUniformExpression readFrom:s];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.x cooked:offset + d.length]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *d = [super plist];
  d[@"x"] = [self.x plist];
  return d;
}

@end
