//
//  ShaderCache.m
//  Real Editor
//
//  Created by VenoMKO on 6.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "ShaderCache.h"
#import "UPackage.h"
#import "FMap.h"
#import "FString.h"

@implementation FShaderType

+ (instancetype)readFrom:(FIStream *)stream
{
  FShaderType *t = [super readFrom:stream];
  
  return t;
}

@end

@implementation ShaderCache

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  uint8_t platform = [s readByte:nil];
  FMap *dummy = [FMap readFrom:s keyType:[FName class] type:[NSNumber class]]; // FShaderType*, dword
  // Name indexes are mapped to the global shadertype map, not the package name map
  return s;
}

@end
