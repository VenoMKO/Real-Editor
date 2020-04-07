//
//  FMaterial.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 12/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FMaterial.h"
#import "UObject.h"
#import "UPackage.h"

@implementation FStaticSwitchParameter

+ (instancetype)readFrom:(FIStream *)s
{
  FStaticSwitchParameter *p = [super readFrom:s];
  p.parameterName = [FName readFrom:s];
  p.value = [s readInt:0];
  p.bOverride = [s readInt:0];
  p.expressionGUID = [FGUID readFrom:s];
  return p;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.parameterName cooked:offset]];
  [d writeInt:self.value];
  [d writeInt:self.bOverride];
  [d appendData:[self.expressionGUID cooked:offset + d.length]];
  return d;
}

@end

@implementation FStaticComponentMaskParameter

+ (instancetype)readFrom:(FIStream *)s
{
  FStaticComponentMaskParameter *p = [super readFrom:s];
  p.parameterName = [FName readFrom:s];
  p.r = [s readInt:0];
  p.g = [s readInt:0];
  p.b = [s readInt:0];
  p.a = [s readInt:0];
  p.bOverride = [s readInt:0];
  p.expressionGUID = [FGUID readFrom:s];
  return p;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.parameterName cooked:offset]];
  [d writeInt:self.r];
  [d writeInt:self.g];
  [d writeInt:self.b];
  [d writeInt:self.a];
  [d writeInt:self.bOverride];
  [d appendData:[self.expressionGUID cooked:offset + d.length]];
  return d;
}

@end

@implementation FStaticParameterSet

+ (instancetype)readFrom:(FIStream *)s
{
  FStaticParameterSet *set = [super readFrom:s];
  set.baseMaterialId = [FGUID readFrom:s];
  set.staticSwitchParameters = [FArray readFrom:s type:[FStaticSwitchParameter class]];
  set.staticComponentMaskParameters = [FArray readFrom:s type:[FStaticComponentMaskParameter class]];
  return set;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.baseMaterialId cooked:offset]];
  [d appendData:[self.staticSwitchParameters cooked:offset + d.length]];
  [d appendData:[self.staticComponentMaskParameters cooked:offset + d.length]];
  return d;
}

@end

@implementation FShaderFrequencyUniformExpressions

+ (instancetype)readFrom:(FIStream *)s
{
  FShaderFrequencyUniformExpressions *e = [super readFrom:s];
  e.uniformVectorExpressions = [FArray readFrom:s type:[FMaterialUniformExpression class]];
  e.uniformScalarExpressions = [FArray readFrom:s type:[FMaterialUniformExpression class]];
  e.uniform2DTextureExpressions = [FArray readFrom:s type:[FMaterialUniformExpression class]];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.uniformVectorExpressions cooked:d.length + offset]];
  [d appendData:[self.uniformScalarExpressions cooked:d.length + offset]];
  [d appendData:[self.uniform2DTextureExpressions cooked:d.length + offset]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *plist = [NSMutableDictionary new];
  plist[@"scalar"] = [self.uniformScalarExpressions plist];
  plist[@"vector"] = [self.uniformVectorExpressions plist];
  plist[@"texture"] = [self.uniform2DTextureExpressions plist];
  return plist;
}

@end

@implementation FUniformExpressionSet

+ (instancetype)readFrom:(FIStream *)s
{
  FUniformExpressionSet *e = [super readFrom:s];
  e.pixelExpressions = [FShaderFrequencyUniformExpressions readFrom:s];
  e.uniformCubeTextureExpressions = [FArray readFrom:s type:[FMaterialUniformExpression class]];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.pixelExpressions cooked:d.length + offset]];
  [d appendData:[self.uniformCubeTextureExpressions cooked:d.length + offset]];
  return d;
}

- (id)plist
{
  NSMutableDictionary *plist = [NSMutableDictionary new];
  plist[@"pixel"] = [self.pixelExpressions plist];
  plist[@"cube"] = [self.uniformCubeTextureExpressions plist];
  return plist;
}

@end

@implementation FTextureLookup

+ (instancetype)readFrom:(FIStream *)s
{
  FTextureLookup *e = [super readFrom:s];
  e.texCoordIndex = [s readInt:0];
  e.textureIndex = [s readInt:0];
  e.uScale = [s readFloat:0];
  e.vScale = [s readFloat:0];
  return e;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d writeInt:self.texCoordIndex];
  [d writeInt:self.textureIndex];
  [d writeFloat:self.uScale];
  [d writeFloat:self.vScale];
  return d;
}

- (id)plist
{
  NSMutableDictionary *plist = [NSMutableDictionary new];
  plist[@"coord"] = @(self.texCoordIndex);
  plist[@"idx"] = @(self.textureIndex);
  plist[@"u"] = @(self.uScale);
  plist[@"v"] = @(self.vScale);
  return plist;
}

@end

@implementation FMaterial

+ (instancetype)readFrom:(FIStream *)s
{
  FMaterial *m = [super readFrom:s];
  m.compileErrors = [FArray readFrom:s type:[FString class]];
  m.textureDependencyLengthMap = [FMap readFrom:s keyType:[UObject class] type:[NSNumber class]];
  m.maxTextureDependencyLength = [s readInt:0];
  m.identifier = [FGUID readFrom:s];
  m.numUserTexCoords = [s readInt:0];
  m.legacyUniformExpressions = [FUniformExpressionSet readFrom:s];
  m.bUsesSceneColor = [s readInt:0];
  m.bUsesSceneDepth = [s readInt:0];
  m.bUsesDynamicParameter = [s readInt:0];
  m.usingTransforms = [s readInt:0];
  m.textureLookups = [FArray readFrom:s type:[FTextureLookup class]];
  m.dummyDroppedFallbackComponents = [s readInt:0];
  return m;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self.compileErrors cooked:d.length + offset]];
  [d appendData:[self.textureDependencyLengthMap cooked:d.length + offset]];
  [d writeInt:self.maxTextureDependencyLength];
  [d appendData:[self.identifier cooked:d.length + offset]];
  [d writeInt:self.numUserTexCoords];
  [d appendData:[self.legacyUniformExpressions cooked:d.length + offset]];
  [d writeInt:self.bUsesSceneColor];
  [d writeInt:self.bUsesSceneDepth];
  [d writeInt:self.bUsesDynamicParameter];
  [d writeInt:self.usingTransforms];
  [d appendData:[self.textureLookups cooked:d.length + offset]];
  [d writeInt:self.dummyDroppedFallbackComponents];
  return d;
}

- (id)plist
{
  NSMutableDictionary *plist = [NSMutableDictionary new];
  plist[@"errs"] = [self.compileErrors plist];
  plist[@"map"] = [self.textureDependencyLengthMap plist];
  plist[@"maxMap"] = @(self.maxTextureDependencyLength);
  plist[@"guid"] = [self.identifier plist];
  plist[@"texCoords"] = @(self.numUserTexCoords);
  plist[@"exps"] = [self.legacyUniformExpressions plist];
  plist[@"scol"] = @(self.bUsesSceneColor);
  plist[@"sdep"] = @(self.bUsesSceneDepth);
  plist[@"dynParam"] = @(self.bUsesDynamicParameter);
  plist[@"uTrans"] = @(self.usingTransforms);
  plist[@"lookup"] = [self.textureLookups plist];
  plist[@"dummy"] = @(self.dummyDroppedFallbackComponents);
  return plist;
}

@end
