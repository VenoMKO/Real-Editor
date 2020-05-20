//
//  TextureUtils.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 08/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <GLUT/GLUT.h>
#import "TextureUtils.h"
#import "DDSUtils.h"
#import "FStream.h"
#import "UPackage.h"
#import "FMipMap.h"

#define DDS_MAGIC               0x20534444

NSString *NSStringFromPixelFormat(EPixelFormat pf)
{
  if (pf == PF_A32B32G32R32F)
    return @"PF_A32B32G32R32F";
  if (pf == PF_A8R8G8B8)
    return @"PF_A8R8G8B8";
  if (pf == PF_G8)
    return @"PF_G8";
  if (pf == PF_G16)
    return @"PF_G16";
  if (pf == PF_DXT1)
    return @"PF_DXT1";
  if (pf == PF_DXT3)
    return @"PF_DXT3";
  if (pf == PF_DXT5)
    return @"PF_DXT5";
  if (pf == PF_UYVY)
    return @"PF_UYVY";
  if (pf == PF_FloatRGB)
    return @"PF_FloatRGB";
  if (pf == PF_FloatRGBA)
    return @"PF_FloatRGBA";
  if (pf == PF_DepthStencil)
    return @"PF_DepthStencil";
  if (pf == PF_ShadowDepth)
    return @"PF_ShadowDepth";
  if (pf == PF_FilteredShadowDepth)
    return @"PF_FilteredShadowDepth";
  if (pf == PF_R32F)
    return @"PF_R32F";
  if (pf == PF_G16R16)
    return @"PF_G16R16";
  if (pf == PF_G16R16F)
    return @"PF_G16R16F";
  if (pf == PF_G16R16F_FILTER)
    return @"PF_G16R16F_FILTER";
  if (pf == PF_G32R32F)
    return @"PF_G32R32F";
  if (pf == PF_A2B10G10R10)
    return @"PF_A2B10G10R10";
  if (pf == PF_A16B16G16R16)
    return @"PF_A16B16G16R16";
  if (pf == PF_D24)
    return @"PF_D24";
  if (pf == PF_R16F)
    return @"PF_R16F";
  if (pf == PF_R16F_FILTER)
    return @"PF_R16F_FILTER";
  if (pf == PF_BC5)
    return @"PF_BC5";
  if (pf == PF_V8U8)
    return @"PF_V8U8";
  if (pf == PF_A1)
    return @"PF_A1";
  if (pf == PF_FloatR11G11B10)
    return @"PF_FloatR11G11B10";
  if (pf == PF_None)
    return @"PF_None";
  return @"PF_MAX";
}

EPixelFormat NSStringToPixelFormat(NSString *pf)
{
  if ([pf isEqualToString:@"PF_A32B32G32R32F"])
    return PF_A32B32G32R32F;
  if ([pf isEqualToString:@"PF_A8R8G8B8"])
    return PF_A8R8G8B8;
  if ([pf isEqualToString:@"PF_G8"])
    return PF_G8;
  if ([pf isEqualToString:@"PF_G16"])
    return PF_G16;
  if ([pf isEqualToString:@"PF_DXT1"])
    return PF_DXT1;
  if ([pf isEqualToString:@"PF_DXT3"])
    return PF_DXT3;
  if ([pf isEqualToString:@"PF_DXT5"])
    return PF_DXT5;
  if ([pf isEqualToString:@"PF_UYVY"])
    return PF_UYVY;
  if ([pf isEqualToString:@"PF_FloatRGB"])
    return PF_FloatRGB;
  if ([pf isEqualToString:@"PF_FloatRGBA"])
    return PF_FloatRGBA;
  if ([pf isEqualToString:@"PF_DepthStencil"])
    return PF_DepthStencil;
  if ([pf isEqualToString:@"PF_ShadowDepth"])
    return PF_ShadowDepth;
  if ([pf isEqualToString:@"PF_FilteredShadowDepth"])
    return PF_FilteredShadowDepth;
  if ([pf isEqualToString:@"PF_R32F"])
    return PF_R32F;
  if ([pf isEqualToString:@"PF_G16R16"])
    return PF_G16R16;
  if ([pf isEqualToString:@"PF_G16R16F"])
    return PF_G16R16F;
  if ([pf isEqualToString:@"PF_G16R16F_FILTER"])
    return PF_G16R16F_FILTER;
  if ([pf isEqualToString:@"PF_G32R32F"])
    return PF_G32R32F;
  if ([pf isEqualToString:@"PF_A2B10G10R10"])
    return PF_A2B10G10R10;
  if ([pf isEqualToString:@"PF_A16B16G16R16"])
    return PF_A16B16G16R16;
  if ([pf isEqualToString:@"PF_D24"])
    return PF_D24;
  if ([pf isEqualToString:@"PF_R16F"])
    return PF_R16F;
  if ([pf isEqualToString:@"PF_R16F_FILTER"])
    return PF_R16F_FILTER;
  if ([pf isEqualToString:@"PF_BC5"])
    return PF_BC5;
  if ([pf isEqualToString:@"PF_V8U8"])
    return PF_V8U8;
  if ([pf isEqualToString:@"PF_A1"])
    return PF_A1;
  if ([pf isEqualToString:@"PF_FloatR11G11B10"])
    return PF_FloatR11G11B10;
  if ([pf isEqualToString:@"PF_None"])
    return PF_None;
  return PF_MAX;
}

int Unpack565(Byte *packed, int pidx, Byte *color, int cidx, BOOL dxtFlag);

NSImage *DecompressDDS(NSString *path, BOOL r, BOOL g, BOOL b, BOOL a)
{
  NSImage *image = nil;
  NSDictionary *mips = MipmapsFromDDS([NSURL fileURLWithPath:path],nil);
  if (mips[@"mips"])
  {
    Byte      *rgba;
    FMipMap *mip = [mips[@"mips"] firstObject];
    if (!mip)
      return nil;
    
    EPixelFormat pf = [mips[@"pf"] unsignedIntValue];
    
    if (pf == PF_None)
      return nil;
    
    NSData *bitmapData = [mip rawData];
    
    if (!bitmapData)
      return nil;
    
    int width = mip.width;
    int height = mip.height;
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
    
    rgba = malloc(width * height * 4);
    
    for (int y = 0; y < height; y += 4)
    {
      for (int x = 0; x < width; x += 4)
      {
        Byte targetRgba[64];
        if (pf == PF_DXT1)
        {
          DecompressColor(targetRgba, bitmapData, sourceBlock + 8, YES);
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
                if (channels[2] != 1) rgba[targetPixel - 2] = 0;    // r
                if (channels[3] != 1) rgba[targetPixel - 1] = 0xff; // a
              }
              else
              {
                if (!channels[0] && !channels[1] && !channels[2])
                {
                  rgba[targetPixel - 2] = rgba[targetPixel - 1];    // b
                  rgba[targetPixel - 3] = rgba[targetPixel - 1];    // g
                  rgba[targetPixel - 4] = rgba[targetPixel - 1];    // r
                  rgba[targetPixel - 1] = 0xff; // a
                }
                else
                {
                  if (channels[2] != 1) rgba[targetPixel - 2] = 0;    // b
                  if (channels[1] != 1) rgba[targetPixel - 3] = 0;    // g
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
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, width * height * 4, NULL);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = pf == PF_DXT1 ? kCGBitmapByteOrderDefault : channels[3] ? (kCGBitmapByteOrderDefault | kCGImageAlphaLast) : kCGBitmapByteOrderDefault;
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
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    image = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(width, height)];
    free(rgba);
    CGImageRelease(imageRef);
  }
  return image;
}

void DecompressAlphaDXT5(Byte *targetRGBA, NSData *bytes, int sourceOffset, int numTargetChannels, int channelOffset)
{
  Byte *block = (Byte *)[bytes bytes];
  // get the two alpha values
  int alpha0 = block[sourceOffset];
  int alpha1 = block[sourceOffset + 1];
  
  // compare the values to build the codebook
  Byte codes[8];
  codes[0] = (Byte)alpha0;
  codes[1] = (Byte)alpha1;
  
  if (alpha0 <= alpha1)
  {
    // use 5-alpha codebook
    for (int j = 1; j < 5; j++)
    {
      codes[(j + 1)] = (Byte)round(((5 - j) * alpha0 + j * alpha1) / 5.0f);
    }
    codes[6] = 0;
    codes[7] = 255;
  }
  else
  {
    // use 7-alpha codebook
    for (int j = 1; j < 7; j++)
    {
      codes[(j + 1)] = (Byte)round(((7 - j) * alpha0 + j * alpha1) / 7.0f);
    }
  }
  
  // decode the indices
  Byte indices[16];
  int src = sourceOffset + 2;
  int dest = 0;
  for (int j = 0; j < 2; j++)
  {
    // grab 3 bytes
    int value = 0;
    for (int k = 0; k < 3; k++)
    {
      int _byte = block[src];
      src++;
      int shift = 8 * k;
      int shifted = _byte << shift;
      value = value | shifted;
    }
    // unpack 8 3-bit values from it
    for (int k = 0; k < 8; k++)
    {
      int shift = 3 * k;
      int shifted = value >> shift;
      int index = shifted & 0x7;
      indices[dest] = (Byte)index;
      dest++;
    }
  }
  // write out the indexed codebook values
  for (int j = 0; j < 16; j++)
  {
    targetRGBA[numTargetChannels * j + channelOffset] = codes[indices[j]];
  }
}

void DecompressColor(Byte *targetRGBA, NSData *bytes, int srcOffset, BOOL dxtFlag)
{
  Byte codes[16];
  memset(codes, 0, 16);
  Byte *rawBytes = (Byte *)[bytes bytes];
  
  int a = Unpack565(rawBytes, srcOffset, codes, 0, dxtFlag);
  int b = Unpack565(rawBytes, srcOffset + 2, codes, 4, dxtFlag);
  
  // generate the midpoints
  for (int i = 0; i < 3; i++)
  {
    int c = codes[i];
    int d = codes[(4 + i)];
    
    if (dxtFlag && a <= b)
    {
      codes[8 + i] = (Byte)round(((double)c + (double)d) / 2.0f);
      codes[12 + i] = 0;
    }
    else
    {
      codes[8 + i] = (Byte)round((2.0f * (double)c + (double)d) / 3.0f);
      codes[12 + i] = (Byte)round(((double)c + 2.0f * (double)d) / 3.0f);
    }
  }
  
  // fill in alpha for the intermediate values
  codes[8 + 3] = 255;
  codes[12 + 3] = (Byte)((dxtFlag && a <= b) ? 0 : 255);
  
  // unpack the indices
  Byte indices[16];
  
  for (int i = 0; i < 4; i++)
  {
    int ind = 4 * i;
    Byte packed = rawBytes[(srcOffset + 4 + i)];
    
    indices[ind] = (Byte)(packed & 0x3);
    indices[(ind + 1)] = (Byte)((packed >> 2) & 0x3);
    indices[(ind + 2)] = (Byte)((packed >> 4) & 0x3);
    indices[(ind + 3)] = (Byte)((packed >> 6) & 0x3);
  }
  
  // store out the colors
  for (int i = 0; i < 16; i++)
  {
    Byte offset = (Byte)(4 * indices[i]);
    for (int j = 0; j < 4; j++)
    {
      targetRGBA[4 * i + j] = codes[offset + j];
    }
  }
}

int Unpack565(Byte *packed, int pidx, Byte *color, int cidx, BOOL dxtFlag)
{
  int value = (int)packed[pidx] | ((int)packed[(pidx + 1)] << 8);
  
  Byte red = (Byte)((value >> 11) & 0x1f);
  Byte green = (Byte)((value >> 5) & 0x3f);
  Byte blue = (Byte)(value & 0x1f);
  
  // scale up to 8 bits
  
  if (dxtFlag)
  {
    color[(cidx + 2)] = (Byte)((red << 3) | (red >> 2));
    color[(cidx + 1)] = (Byte)((green << 2) | (green >> 4));
    color[(cidx + 0)] = (Byte)((blue << 3) | (blue >> 2));
  }
  else
  {
    color[(cidx + 2)] = (Byte)((red << 3) | (red >> 2));
    color[(cidx + 1)] = (Byte)((green << 2) | (green >> 4));
    color[(cidx + 0)] = (Byte)((blue << 3) | (blue >> 2));
  }
  
  color[(cidx + 3)] = 255;
  
  return value;
}

NSDictionary *MipmapsFromNVTT(NSURL *url, UPackage *package, EPixelFormat pf, BOOL isNormalMap, BOOL sRGB, BOOL mipmaps)
{
  return CompressedMipmapsFromNVTT(url, package, pf, COMPRESSION_LZO, isNormalMap, sRGB, mipmaps);
}

NSDictionary *CompressedMipmapsFromNVTT(NSURL *url, UPackage *package, EPixelFormat pf, int compression, BOOL isNormalMap, BOOL sRGB, BOOL mipmaps)
{
  TextureCompiler *c = [TextureCompiler compilerWithOptions:@{@"Path" : url.path,
                                                              @"IsNormal" : @(isNormalMap),
                                                              @"sRGB" : @(sRGB),
                                                              @"Mips" : @(mipmaps),
                                                              @"PixelFormat" : @(pf)}];
  
  if ([c process])
  {
    NSMutableDictionary *result = [c result];
    NSMutableArray *mipData = result[@"mips"];
    NSMutableArray *mips = [NSMutableArray new];
    for (NSDictionary *data in mipData)
    {
      FMipMap *m = [FMipMap newWithPackage:package];
      m.width = [data[@"x"] intValue];
      m.height = [data[@"y"] intValue];
      m.compression = compression;
      m.rawData = data[@"data"];
      [mips addObject:m];
    }
    result[@"mips"] = mips;
    result[@"pf"] = @(pf);
    result[@"path"] = [url path];
    return result;
  }
  return nil;
}

NSDictionary *MipmapsFromDDS(NSURL *url, UPackage *package)
{
  return CompressedMipmapsFromDDS(url, package, COMPRESSION_LZO);
}

NSDictionary *CompressedMipmapsFromDDS(NSURL *url, UPackage *package, int compression)
{
  
  /*
  FIStream *s = [FIStream streamForUrl:url];
  if ([s readInt:NULL] != DDS_MAGIC)
  {
    return @{@"err" : @"Invalid DDS! File is corrupted!"};
  }
  if ([s readInt:NULL] != 124)
  {
    return @{@"err" : @"Unknown DDS! DDS header is unknown or corrupted!"};
  }
  
  uint flags = 0;
  int width = -1, height = -1, pitch = 0, depth = 0, mipmapsCount = 0;
  
  flags = [s readInt:NULL];
  height =[s readInt:NULL];
  width = [s readInt:NULL];
  pitch = [s readInt:NULL];
  depth = [s readInt:NULL];
  mipmapsCount = [s readInt:NULL];
  //uint *tb = [s readBytes:sizeof(uint)*11 error:NULL];
  s.position += 44;
  [s setPosition:s.position + 4];
  
  if ([s readInt:NULL] != DDPF_FOURCC) {
    return @{@"err" : @"Unsupported DDS! DDS image has unsupported pixel format!"};
  }
  
  int fcc;
  fcc = [s readInt:NULL];
  
  if (fcc != FCC_DXT1 && fcc != FCC_DXT5)
  {
    
    return @{@"err" : @"Unsupported DDS! DDS image has unsupported pixel format!"};
  }
  
  [s setPosition:s.position + 40];
  
  int bytesPerBlock = fcc == FCC_DXT1 ? 8 : 16;
  NSMutableArray *mips = [NSMutableArray new];
  for (int mipIdx = 0; mipIdx < mipmapsCount; ++mipIdx)
  {
    int length = MAX(1, ( (width + 3) / 4 ) ) * MAX(1, ( (height + 3) / 4 ) ) * bytesPerBlock;
    FMipMap *mip = [FMipMap newWithPackage:package];
    mip.width = width;
    mip.height = height;
    NSData *bitmap = [s readData:length];
    if (!bitmap)
    {
      break;
    }
    mip.compression = compression;
    mip.rawData = bitmap;
    [mips addObject:mip];
    width = MAX(width * .5f,1);
    height = MAX(height * .5f,1);
  }
  
  return @{@"mips" : mips,
           @"pf" : @(fcc),
           @"path" : [url path]};*/
  return nil;
}

NSMutableData *DDSHeader(EPixelFormat fmt, NSSize size,int mipmaps)
{
  NSMutableData *imageData = [NSMutableData data];
  
  [imageData writeInt:DDS_MAGIC];
  [imageData writeInt:124];
  [imageData writeInt:(DDSD_CAPS | DDSD_WIDTH | DDSD_HEIGHT | DDSD_PIXELFORMAT | DDSD_MIPMAPCOUNT | DDSD_LINEARSIZE)];
  [imageData writeInt:size.height];
  [imageData writeInt:size.width];
  [imageData writeInt:(size.width * size.height * 8) / 8];
  [imageData writeInt:0];
  [imageData writeInt:mipmaps];
  [imageData increaseLengthBy:sizeof(uint) * 11];
  
  // Pixel format
  DDPF_FLAGS flg = DDPF_FOURCC;
  unsigned rmask = 0;
  unsigned gmask = 0;
  unsigned bmask = 0;
  unsigned amask = 0;
  unsigned rgbBitCount = 0;
  FOURCC fcc = FCC_None;
  if (fmt == PF_A8R8G8B8)
  {
    flg = DDPF_RGB | DDPF_ALPHAPIXELS;
    amask = 0xff000000;
    rmask = 0x00ff0000;
    gmask = 0x0000ff00;
    bmask = 0x000000ff;
    rgbBitCount = sizeof(unsigned) * 8;
  }
  else if (fmt == PF_G8)
  {
    flg = DDPF_LUMINANCE;
    rmask = 0xff000000;
    rgbBitCount = 8;
  }
  else if (fmt == PF_DXT1)
  {
    fcc = FCC_DXT1;
  }
  else if (fmt == PF_DXT3)
  {
    fcc = FCC_DXT3;
  }
  else if (fmt == PF_DXT5)
  {
    fcc = FCC_DXT5;
  }
  
  [imageData writeInt:32];
  [imageData writeInt:flg];
  [imageData writeInt:fcc];
  [imageData writeInt:rgbBitCount];
  [imageData writeInt:rmask];
  [imageData writeInt:gmask];
  [imageData writeInt:bmask];
  [imageData writeInt:amask];
  
  [imageData writeInt:mipmaps == 1 ? DDSCAPS_NONE : (DDSCAPS_COMPLEX | DDSCAPS_MIPMAP)];
  [imageData writeInt:DDSCAPS2_NONE];
  [imageData writeInt:0];
  [imageData writeInt:0];
  
  [imageData writeInt:0];
  
  return imageData;
}

void WriteImageRef(CGImageRef img, NSString *path)
{
  if (!path.pathExtension.length)
  {
    path = [path stringByAppendingPathExtension:@"png"];
  }
  CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
  CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
  if (!destination)
  {
    return;
  }
  CGImageDestinationAddImage(destination, img, nil);
  if (!CGImageDestinationFinalize(destination))
  {
    CFRelease(destination);
    return;
  }
  CFRelease(destination);
}
