//
//  FColor.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FColor.h"

@implementation FLinearColor

+ (instancetype)linearColorWithColor:(NSColor *)color package:(UPackage *)package
{
  FLinearColor *c = [FLinearColor new];
  c.package = package;
  c.r = [color redComponent];
  c.g = [color greenComponent];
  c.b = [color blueComponent];
  c.a = [color alphaComponent];
  return c;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  FLinearColor *v = [super readFrom:stream];
  v.r = [stream readFloat:0];
  v.g = [stream readFloat:0];
  v.b = [stream readFloat:0];
  v.a = [stream readFloat:0];
  return v;
}

- (id)init
{
  if ((self = [super init]))
  {
    _a = 1;
  }
  return self;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeFloat:self.r];
  [d writeFloat:self.g];
  [d writeFloat:self.b];
  [d writeFloat:self.a];
  return d;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
  if (idx == 0)
    return @(self.r);
  if (idx == 1)
    return @(self.g);
  if (idx == 2)
    return @(self.b);
  if (idx == 3)
    return @(self.a);
  return @(self.r);
}

- (NSColor *)NSColor
{
  return [NSColor colorWithCalibratedRed:_r green:_g blue:_b alpha:_a];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FLinearColor *c = [FLinearColor newWithPackage:self.package];
  c.r = self.r;
  c.g = self.g;
  c.b = self.b;
  c.a = self.a;
  
  return c;
}

- (id)plist
{
  return @{@"r" : @(self.r), @"g" : @(self.g), @"b" : @(self.b), @"a" : @(self.a), @"type" : @"lc"};
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"R:%.3f G:%.3f B:%.3f A:%.3f", self.r,self.g,self.b,self.a];
}

@end

@implementation FColor

+ (instancetype)colorWithColor:(NSColor *)color package:(UPackage *)package
{
  FColor *c = [FColor new];
  c.package = package;
  c.r = [color redComponent] * 255;
  c.g = [color greenComponent] * 255;
  c.b = [color blueComponent] * 255;
  c.a = [color alphaComponent] * 255;
  return c;
}

+ (instancetype)readFrom:(FIStream *)stream
{
  FColor *v = [super readFrom:stream];
  v.r = [stream readByte:0];
  v.g = [stream readByte:0];
  v.b = [stream readByte:0];
  v.a = [stream readByte:0];
  return v;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d writeByte:self.r];
  [d writeByte:self.g];
  [d writeByte:self.b];
  [d writeByte:self.a];
  return d;
}

- (NSColor *)NSColor
{
  return [NSColor colorWithCalibratedRed:(float)_r / 255.0 green:(float)_g / 255.0 blue:(float)_b / 255.0 alpha:(float)_a / 255.0];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FColor *c = [FColor newWithPackage:self.package];
  c.r = self.r;
  c.g = self.g;
  c.b = self.b;
  c.a = self.a;
  
  return c;
}

- (id)plist
{
  return @{@"r" : @(self.r), @"g" : @(self.g), @"b" : @(self.b), @"a" : @(self.a), @"type" : @"c"};
}

@end
