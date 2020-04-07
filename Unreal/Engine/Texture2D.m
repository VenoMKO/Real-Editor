//
//  Texture2D.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 06/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <GLUT/GLUT.h>
#import "TextureUtils.h"
#import "Texture2D.h"
#import "UPackage.h"
#import "FMipMap.h"
#import "DDSType.h"
#import "FArray.h"
#import "FString.h"
#import "FGUID.h"

@interface Texture2D ()
{
  unsigned  unk[3];
  Byte      *rgba;
}
@property (weak) FMipMap *bestMip;
@property (strong) NSImage *image;
@property (assign) BOOL cachedR;
@property (assign) BOOL cachedG;
@property (assign) BOOL cachedB;
@property (assign) BOOL cachedA;
@end

@implementation Texture2D

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self cookedProperties];
  [d appendData:[self.sourceArt cooked:offset + d.length]];
  if (self.package.game == UGameTera)
    [d appendData:[self.source cooked:0]];
  [d appendData:[self.mips cooked:offset + d.length]];
  [d appendData:[self.guid cooked:0]];
  if (self.package.game == UGameBless)
  {
    [d appendData:[self.cachedMips cooked:offset + d.length]];
  }
  return d;
}

- (BOOL)canExport
{
  FMipMap *m = [self bestMipMap];
  if (!m)
    return NO;
  return !NSEqualSizes(NSZeroSize, NSMakeSize(m.width, m.height));
}

- (void)dealloc
{
  if (rgba)
  {
    free(rgba);
    rgba = NULL;
  }
  self.image = nil;
  self.mips = nil;
  self.source = nil;
  self.guid = nil;
  self.properties = nil;
  self.editor = nil;
  self.customData = nil;
}

- (NSImage *)icon
{
  return [UObject systemIcon:kClippingPictureTypeIcon];;
}

- (FMipMap *)bestMipMap
{
  if (self.bestMip)
    return self.bestMip;
  
  if (!self.rawDataOffset)
      [self properties];
  
  FMipMap *b = nil;
  for (FMipMap *m in self.mips)
  {
    if ([m isValid] && m.width > b.width && m.height > b.height)
      b = m;
  }
  self.bestMip = b;
  return b;
}

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  s.position = self.rawDataOffset;
  self.sourceArt = [FByteBulkData readFrom:s];
  if (s.game == UGameTera)
    self.source = [FString readFrom:s];
  self.mips = [FArray readFrom:s type:[FMipMap class]];
  self.guid = [FGUID readFrom:s];
  if (s.game == UGameBless)
  {
    self.cachedMips = [FArray readFrom:s type:[FMipMap class]];
    self.maxCachedResolution = [s readInt:0];
    self.cachedAtiMips = [FArray readFrom:s type:[FMipMap class]];
    self.cachedFlashMips = [FByteBulkData readFrom:s];
    self.cachedETCMips = [FArray readFrom:s type:[FMipMap class]];
  }
  
  return s;
}

- (EPixelFormat)pixelFormat
{
  return NSStringToPixelFormat([self propertyForName:@"Format"].formattedValue);
}

- (NSString *)textureCompression
{
  FPropertyTag *p = [self propertyForName:@"CompressionSettings"];
  return p.formattedValue;
}

- (BOOL)isDXT
{
  EPixelFormat pf = [self pixelFormat];
  return pf == PF_DXT1 || pf == PF_DXT3 || pf == PF_DXT5;
}

- (NSSize)size
{
  FMipMap *mip = [self bestMipMap];
  if (!mip)
    return NSZeroSize;
  
  EPixelFormat format = [self pixelFormat];
  
  NSData *bitmapData = [mip rawData];
  
  if (!bitmapData)
    return NSZeroSize;
  
  int width = mip.width;
  int height = mip.height;
  int bytesPerBlock = 16;
  if (format == PF_DXT1)
    bytesPerBlock = 8;
  
  if (format != FCC_None && [bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
  {
    while ([bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
    {
      width *= 0.5f;
      height *= 0.5f;
    }
  }
  
  return NSMakeSize(width, height);
}

- (NSImage *)renderMetallnes
{
  return [self renderedImageR:NO G:NO B:NO A:YES invert:NO];
}

- (NSImage *)renderRoughness
{
  return [self renderedImageR:NO G:NO B:NO A:YES invert:NO];
}

- (NSImage *)renderedImageR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a
{
  return [self renderedImageR:r G:g B:b A:a invert:NO];
}

- (NSImage *)forceExportedRenderedImageR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a invert:(BOOL)invert
{
  
  if (self.exportObject.exportFlags & EF_ForcedExport)
  {
    UObject *loaded = [self.package resolveImport:(FObjectImport *)self.fObject];
    if (loaded && [loaded isKindOfClass:[Texture2D class]])
    {
      NSImage *i = [(Texture2D *)loaded renderedImageR:r G:g B:b A:a invert:invert];
      if (i)
        return i;
    }
  }
  
  return [self renderedImageR:r G:g B:b A:a invert:invert];
}

- (NSImage *)renderedImageR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a invert:(BOOL)invert
{
  if (self.image && r == self.cachedR && g == self.cachedG && b == self.cachedB && a == self.cachedA)
    return self.image;
  
  @synchronized (self)
  {
    self.cachedA = a;
    self.cachedB = b;
    self.cachedG = g;
    self.cachedR = r;
    FMipMap *mip = [self bestMipMap];
    if (!mip)
      return nil;
    if (![self isDXT])
      return nil;
    
    EPixelFormat fmt = [self pixelFormat];
    NSData *bitmapData = [mip rawData];
    
    if (!bitmapData)
      return nil;
    
    int width = mip.width;
    int height = mip.height;
    int bytesPerBlock = 16;
    if (fmt == PF_DXT1)
      bytesPerBlock = 8;
    
    if ([bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
    {
      while ([bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
      {
        width *= 0.5f;
        height *= 0.5f;
      }
    }
    CGImageRef ref = [self renderR:r G:g B:b A:a invert:invert];
    self.image = [[NSImage alloc] initWithCGImage:ref size:NSMakeSize(width, height)];
    CGImageRelease(ref);
    return self.image;
  }
}

- (BOOL)isNormalMap
{
  return [[self textureCompression] isEqualToString:@"TC_Normalmap"] || [[self textureCompression] isEqualToString:@"TC_NormalmapAlpha"];
}

- (CGImageRef)renderR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a
{
  return [self renderR:r G:g B:b A:a invert:NO];
}

- (CGImageRef)renderR:(BOOL)r G:(BOOL)g B:(BOOL)b A:(BOOL)a invert:(BOOL)invert
{
  FMipMap *mip = [self bestMipMap];
  if (!mip)
    return nil;
  NSData *bitmapData = [mip rawData];
  if (!bitmapData)
    return nil;
  
  EPixelFormat pf = [self pixelFormat];
  
  int width = 0;
  int height = 0;
  BOOL isNormalMap = [self isNormalMap];
  if ([self isDXT])
  {
    width = mip.width;
    height = mip.height;
    int bytesPerBlock = 16;
    if (pf == PF_DXT1)
      bytesPerBlock = 8;
    int channels[4] = {r,g,b,a};
    int decompressedChannels = 4;
    int sourceBlock = 0;
    
    if ([bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
    {
      while ([bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
      {
        width *= 0.5f;
        height *= 0.5f;
      }
    }
    if (rgba)
    {
      free(rgba);
      rgba = NULL;
    }
    rgba = malloc(width * height * 4);
    
    for (int y = 0; y < height; y += 4)
    {
      for (int x = 0; x < width; x += 4)
      {
        Byte targetRgba[64];
        if (pf == PF_DXT1)
        {
          DecompressColor(targetRgba, bitmapData, sourceBlock, YES);
        }
        else
        {
          DecompressColor(targetRgba, bitmapData, sourceBlock + 8, NO);
          DecompressAlphaDXT5(targetRgba, bitmapData, sourceBlock, 4, 3);
        }
        
        int sourcePixel = 0;
        for (int py = 0; py < 4; py++)
        {
          for (int px = 0; px < 4; px++)
          {
            int sx = x + px;
            int sy = y + py;
            if (sx < width && sy < height)
            {
              int targetPixel = 4 * (width * sy + sx);
              for (int i = 0; i < 4; i++)
              {
                rgba[targetPixel] = targetRgba[sourcePixel];
                targetPixel++;
                sourcePixel++;
              }
              
              Byte tmp = rgba[targetPixel - 4];
              rgba[targetPixel - 4] = rgba[targetPixel - 2];  // blue => red
              rgba[targetPixel - 2] = tmp;   //rot            // red => blue
              
              if (pf == PF_DXT1)
              {
                if (channels[0] != 1) rgba[targetPixel - 4] = 0;    // b
                if (channels[1] != 1) rgba[targetPixel - 3] = 0;    // g
                else if (isNormalMap) rgba[targetPixel - 3] = 0xFF - rgba[targetPixel - 3];
                if (channels[2] != 1) rgba[targetPixel - 2] = 0;    // r
                if (channels[3] != 1) rgba[targetPixel - 1] = 0xff; // a
              }
              else
              {
                if (!channels[0] && !channels[1] && !channels[2])
                {
                  if (invert)
                  {
                    rgba[targetPixel - 2] = 0xff - rgba[targetPixel - 1];    // b
                    rgba[targetPixel - 3] = 0xff - rgba[targetPixel - 1];    // g
                    rgba[targetPixel - 4] = 0xff - rgba[targetPixel - 1];    // r
                    rgba[targetPixel - 1] = 0xff; // a
                  }
                  else
                  {
                    rgba[targetPixel - 2] = rgba[targetPixel - 1];    // b
                    rgba[targetPixel - 3] = rgba[targetPixel - 1];    // g
                    rgba[targetPixel - 4] = rgba[targetPixel - 1];    // r
                    rgba[targetPixel - 1] = 0xff; // a
                  }
                }
                else
                {
                  if (channels[2] != 1) rgba[targetPixel - 2] = 0;    // b
                  if (channels[1] != 1) rgba[targetPixel - 3] = 0;    // g
                  else if (isNormalMap) rgba[targetPixel - 3] = 0xFF - rgba[targetPixel - 3];
                  if (channels[0] != 1) rgba[targetPixel - 4] = 0;    // r
                  if (channels[3] != 1) rgba[targetPixel - 1] = 0xff; // a
                }
              }
            }
            else
            {
              sourcePixel += decompressedChannels;
            }
          }
        }
        sourceBlock += bytesPerBlock;
      }
    }
  }
  else
  {
    width = mip.width;
    height = mip.height;
    
    if (rgba)
    {
      free(rgba);
      rgba = NULL;
    }
    rgba = malloc(width * height * 4);
    Byte *ptr = (Byte *)[bitmapData bytes];
    if (pf == PF_G8)
    {
      for (int x = 0; x < (height * width * 4); x += 4, ptr++)
      {
        rgba[x    ] = *ptr;
        rgba[x + 1] = *ptr;
        rgba[x + 2] = *ptr;
        rgba[x + 3] = 0xFF;
      }
    }
    else if (pf == PF_A8R8G8B8)
    {
      for (int x = 0; x < (height * width * 4); x += 4, ptr+=4)
      {
        rgba[x    ] = ptr[1]; // R
        rgba[x + 1] = ptr[2]; // G
        rgba[x + 2] = ptr[3]; // B
        rgba[x + 3] = *ptr;   // A
      }
    }
    else
    {
      free(rgba);
      rgba = nil;
      return NULL;
    }
  }
  
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, width * height * 4, NULL);
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  CGBitmapInfo bitmapInfo = pf == PF_DXT1 ? kCGBitmapByteOrderDefault : kCGBitmapByteOrderDefault | kCGImageAlphaLast;
  CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
  
  CGImageRef imageRef = CGImageCreate(width,
                                      height,
                                      8 /*bitsPerComponent*/,
                                      32 /*bitsPerPixel*/,
                                      4 * width /*bytesPerRow*/,
                                      colorSpaceRef,
                                      bitmapInfo,
                                      provider,
                                      NULL /*decode*/,
                                      NO /*shouldInterpolate*/,
                                      renderingIntent);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpaceRef);
  return imageRef;
}

- (NSData *)exportWithOptions:(NSDictionary *)options
{
  Texture2DExportOptions mode = [options[@"mode"] unsignedIntValue];
  
  if (options[@"raw"])
  {
    NSData *raw = nil;
    FIStream *s = [self.package.stream copy];
    if (self.rawDataOffset)
    {
      [s setPosition:self.rawDataOffset];
      raw = [s readData:self.exportObject.serialSize - (self.rawDataOffset - self.exportObject.serialOffset)];
    }
    else
    {
      [s setPosition:self.exportObject.serialOffset];
      raw = [s readData:self.exportObject.serialSize];
    }
    
    return raw;
  }
  
  NSData *bitmapData  = nil;
  NSMutableData *data = nil;
  FMipMap *mip = [self bestMipMap];
  int width, height;
  width = mip.width;
  height = mip.height;
  EPixelFormat pf = [self pixelFormat];
  bitmapData = [mip rawData];
  int bytesPerBlock = 16;
  if (pf == PF_DXT1)
    bytesPerBlock = 8;
  
  if (!bitmapData)
    return nil;
  
  if ([self isDXT] && [bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4))
  {
    while ([bitmapData length] < (width / 4 * bytesPerBlock) * (height / 4) &&
           width && height)
    {
      width *= 0.5f;
      height *= 0.5f;
    }
  }

  
  if (mode == Texture2DExportOptionsDDS)
  {
    
    NSMutableData *ddsData = [NSMutableData new];
    int mipCnt = 0;
    for (FMipMap *m in self.mips)
    {
      NSData *d = m.rawData;
      if (!d.length)
      {
        if (mipCnt)
          break;
        continue;
      }
      [ddsData appendData:d];
      mipCnt++;
    }
    data = DDSHeader(pf, NSMakeSize(width, height), mipCnt);
    [data appendData:ddsData];
  }
  else if (mode == Texture2DExportOptionsTGA)
  {
    TextureDecompiler *d = [TextureDecompiler decompilerWithTexture:self];
    d.swizzle = [options[@"swizzle"] boolValue];
    [d saveTo:[[options[@"path"] stringByDeletingPathExtension] stringByAppendingString:@".tga"]];
  }
  return data;
}

- (NSString *)importMipmaps:(NSDictionary *)info
{
  NSArray *mips = info[@"mips"];
  BOOL failed = NO;
  if (!mips.count)
  {
    mips = @[[FMipMap unusedMip]];
    failed = YES;
  }
  self.mips = [FArray arrayWithArray:mips package:self.package];
  self.bestMip = nil;
  [self setDirty:YES];
  FPropertyTag *tag;
  
  tag = [self propertyForName:@"SizeX"];
  if (tag)
    tag.value = @(self.bestMipMap.width);
  else
  {
    tag = [FPropertyTag intProperty:self.bestMipMap.width name:@"SizeX" object:self];
    [self.properties addObject:tag];
  }
  
  tag = [self propertyForName:@"SizeY"];
  if (tag)
    tag.value = @(self.bestMipMap.width);
  else
  {
    tag = [FPropertyTag intProperty:self.bestMipMap.width name:@"SizeY" object:self];
    [self.properties addObject:tag];
  }
  
  tag = [self propertyForName:@"SourceFilePath"];
  if (tag) {
    FString *path = nil;
    if (failed)
      path = [FString stringWithString:[NSString stringWithFormat:@"Failed to import image! %@",info[@"path"]]];
    else
      path = [FString stringWithString:info[@"path"]];
    tag.value = path;
    tag.dataSize = (int)[[path cooked] length];
  }
  else
  {
    NSString *path = nil;
    if (failed)
      path = [NSString stringWithFormat:@"Failed to import image! %@",info[@"path"]];
    else
      path = info[@"path"];
    tag = [FPropertyTag stringProperty:path name:@"SourceFilePath" object:self];
    [self.properties addObject:tag];
  }
  
  self.source = [FString stringWithString:info[@"path"]];
  tag = [self propertyForName:@"SourceFileTimestamp"];
  
  if (tag)
  {
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    FString *tsmp = [FString stringWithString:[df stringFromDate:date]];
    tag.value = tsmp;
    tag.dataSize = (int)[[tsmp cooked] length];
  }
  else
  {
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    tag = [FPropertyTag stringProperty:[df stringFromDate:date]
                                  name:@"SourceFileTimestamp"
                                object:self];
    [self.properties addObject:tag];
  }
  tag = [self propertyForName:@"MipTailBaseIdx"];
  if (tag)
  {
    int mipCnt = (int)self.mips.count;
    tag.value = @(mipCnt ? mipCnt - 1 : 0);
  }
  else
  {
    int mipCnt = (int)self.mips.count;
    tag = [FPropertyTag intProperty:mipCnt name:@"MipTailBaseIdx" object:self];
    [self.properties addObject:tag];
  }
  
  tag = [self propertyForName:@"Format"];
  if (tag)
  {
    EPixelFormat pf = [info[@"pf"] intValue];
    tag.value = @([self.package indexForName:NSStringFromPixelFormat(pf)]);
  }
  else
  {
    EPixelFormat pf = [info[@"pf"] intValue];
    int idx = [self.package indexForName:NSStringFromPixelFormat(pf)];
    tag = [FPropertyTag byteProperty:idx size:4 name:@"Format" object:self];
    [self.properties addObject:tag];
  }
  self.image = nil;
  return nil;
}

@end

@implementation ShadowMapTexture2D

- (NSString *)xib
{
  return kClassTexture2D;
}

@end

@implementation LightMapTexture2D

- (NSString *)xib
{
  return kClassTexture2D;
}

@end

@implementation TerrainWeightMapTexture

- (NSString *)xib
{
  return kClassTexture2D;
}

@end
