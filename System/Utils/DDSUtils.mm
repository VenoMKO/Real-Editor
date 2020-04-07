//
//  DDSUtils.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 12/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "DDSUtils.h"
#import "Texture2D.h"
#import "FMipMap.h"
#import <nvtt/nvtt.h>
using namespace nvtt;

struct FNVOutputHandler : public OutputHandler
{
public:
  ~FNVOutputHandler()
  {
  }
  void ReserveMemory(uint PreAllocateSize )
  {
    CompressedData = [[NSMutableData alloc] initWithCapacity:PreAllocateSize];
  }
  
  void beginImage(int size, int width, int height, int depth, int face, int miplevel) override
  {}
  
  bool writeData(const void *data, int size) override
  {
    [CompressedData appendBytes:data length:size];
    return true;
  }
  
  void endImage() override
  {}
  
  NSMutableData *CompressedData;
};

@interface TextureCompiler ()
{
  NSImage       *sourceImage;
  NSString      *originalPath;
  void          *sourceData;
  InputFormat   inputFormat;
  EPixelFormat  pixelFormat;
  AlphaMode     alphaMode;
  Format        textureFormat;
  NSString      *format;
  bool          sRGB;
  bool          isNormal;
  bool          generateMips;
  int           sizeX;
  int           sizeY;
  bool          sourceHasAlpha;
  int           sourceBitsPerPixel;
  
  InputOptions        InputOptions;
  CompressionOptions	CompressionOptions;
  OutputOptions       OutputOptions;
  Compressor          Compressor;
  FNVOutputHandler    OutputHandler;
}

@end

@implementation TextureCompiler

+ (instancetype)compilerWithOptions:(NSDictionary *)options
{
  TextureCompiler *cmp = [TextureCompiler new];
  cmp->isNormal = [options[@"IsNormal"] boolValue];
  cmp->sRGB = [options[@"sRGB"] boolValue];
  cmp->originalPath = options[@"Path"];
  cmp->generateMips = [options[@"Mips"] boolValue];
  cmp->pixelFormat = (unsigned int)[options[@"PixelFormat"] unsignedIntegerValue];
  [cmp loadImage:[[NSImage alloc] initWithContentsOfFile:cmp->originalPath]];
  [cmp setupOptions];
  return cmp;
}

- (BOOL)loadImage:(NSImage *)image
{
  sourceImage = image;
  
  if (!sourceImage || NSEqualSizes(NSZeroSize, sourceImage.size) || ![sourceImage isValid])
    return NO;
  
  NSBitmapImageRep *rep = (NSBitmapImageRep *)sourceImage.representations[0];
  NSBitmapFormat mfmt = [rep bitmapFormat];
  sizeX = (int)[rep pixelsWide];
  sizeY = (int)[rep pixelsHigh];
  sourceBitsPerPixel = (int)[rep bitsPerPixel];
  sourceHasAlpha = [rep hasAlpha];
  
  sourceData = (void *)[rep bitmapData];
  inputFormat = InputFormat_BGRA_8UB;
  if (mfmt & NSBitmapFormatFloatingPointSamples)
  {
    if ([rep bitsPerPixel] == 128)
      inputFormat = InputFormat_RGBA_32F;
    else
      inputFormat = InputFormat_RGBA_16F;
  }
  else
  {
    unsigned char *ptr = (unsigned char *)sourceData;
    unsigned step = (unsigned)sourceBitsPerPixel / 8;
    unsigned length = (unsigned)step * sizeX * sizeY;
    unsigned char *end = ptr + length;
    
    if (mfmt & NSBitmapFormatAlphaFirst)
    {
      while (ptr != end)
      {
        unsigned char a = ptr[0];
        unsigned char r = ptr[1];
        unsigned char g = ptr[2];
        unsigned char b = ptr[3];
        
        ptr[0] = b;
        ptr[1] = g;
        ptr[2] = r;
        ptr[3] = sourceHasAlpha ? a : 0xff;
        
        ptr+=step;
      }
    }
    else
    {
      while (ptr != end)
      {
        unsigned char r = ptr[0];
        unsigned char g = ptr[1];
        unsigned char b = ptr[2];
        unsigned char a = ptr[3];
        
        ptr[0] = b;
        ptr[1] = g;
        ptr[2] = r;
        ptr[3] = sourceHasAlpha ? a : 0xff;
        
        ptr+=step;
      }
    }
  }
  return YES;
}

- (NSImage *)resizeImageToSize:(NSSize)newSize
{
  NSImage* newImage = nil;
  
  if ([sourceImage isValid]){
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:NULL
                             pixelsWide:newSize.width
                             pixelsHigh:newSize.height
                             bitsPerSample:8
                             samplesPerPixel:4
                             hasAlpha:YES
                             isPlanar:NO
                             colorSpaceName:NSCalibratedRGBColorSpace
                             bytesPerRow:0
                             bitsPerPixel:0];
    rep.size = newSize;
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
    [sourceImage drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    newImage = [[NSImage alloc] initWithSize:newSize];
    [newImage addRepresentation:rep];
  }
  return newImage;
}

- (void)setupOptions
{
  if (pixelFormat == PF_None)
    pixelFormat = sourceHasAlpha ? PF_DXT5 : PF_DXT1;
  
  textureFormat = Format_DXT1;
  if (pixelFormat == PF_DXT1 && !sourceHasAlpha)
  {
    textureFormat = Format_DXT1;
    format = @"PF_DXT1";
    InputOptions.setAlphaMode(AlphaMode_None);
  }
  else if (pixelFormat == PF_DXT3)
  {
    textureFormat = Format_DXT3;
    format = @"PF_DXT3";
  }
  else if (pixelFormat == PF_DXT5)
  {
    textureFormat = Format_DXT5;
    format = @"PF_DXT5";
  }
  else if (pixelFormat == PF_A8R8G8B8)
  {
    textureFormat = Format_RGBA;
    format = @"PF_A8R8G8B8";
  }
  else if (pixelFormat == PF_BC5)
  {
    textureFormat = Format_BC5;
    format = @"PF_BC5";
  }
  else if (pixelFormat == PF_G8)
  {
    textureFormat = Format_RGB;
    format = @"PF_G5";
  }
  
  if (textureFormat != Format_Count) // Use NVTT only if we have DXT compression option
  {
    OutputHandler = FNVOutputHandler();
    InputOptions.reset();
    OutputOptions.reset();
    [self setupInput];
    [self setupOutput];
    [self setupCompression];
  }
  
}

- (void)setupInput
{
  InputOptions.setFormat(inputFormat);
  InputOptions.setTextureLayout(TextureType_2D, sizeX, sizeY);
  InputOptions.setMipmapGeneration(false, -1);
  if (sRGB)
  {
    InputOptions.setGamma(2.2f, 2.2f);
  }
  else
  {
    InputOptions.setGamma(1.0f, 1.0f);
  }
  InputOptions.setWrapMode(WrapMode_Mirror);
  CompressionOptions.setFormat(textureFormat);
  CompressionOptions.setQuality(isNormal ? Quality_Highest : Quality_Production);
  if (isNormal)
  {
    InputOptions.setNormalMap(true);
  }
  InputOptions.setMipmapData(sourceData, sizeX, sizeY);
}

- (void)setupOutput
{
  OutputHandler.ReserveMemory( Compressor.estimateSize(InputOptions, CompressionOptions) );
  OutputOptions.setOutputHeader(false);
  OutputOptions.setOutputHandler( &OutputHandler );
}

- (void)setupCompression
{
  if (isNormal)
  {
    CompressionOptions.setColorWeights(0.4f, 0.4f, 0.2f);
  }
  else
  {
    CompressionOptions.setColorWeights(1, 1, 1);
  }
  Compressor.enableCudaAcceleration(true);
}

- (BOOL)process
{
  _result = [NSMutableDictionary new];
  _result[@"format"] = format;
  _result[@"mips"] = [NSMutableArray new];
  _result[@"x"] = @(sizeX);
  _result[@"y"] = @(sizeY);
  
  if ([format isEqualToString:@"PF_G8"])
  {
    unsigned char *ptr = (unsigned char*)calloc(sizeY * sizeY,1);
    unsigned char *src = (unsigned char *)sourceData;
    unsigned step = (unsigned)sourceBitsPerPixel / 8;
    unsigned length = (unsigned)step * sizeX * sizeY;
    unsigned char *end = src + length;
    unsigned char *dst = ptr;
    
    while (src != end)
    {
      *dst = *src; // copy R value
      src += step;
      dst++;
    }
    [_result[@"mips"] addObject:[NSData dataWithBytes:ptr length:sizeX * sizeY]];
    
    free(ptr);
  }
  else if ([format isEqualToString:@"PF_A8R8G8B8"])
  {
    unsigned char *ptr = (unsigned char*)calloc(sizeY * sizeY,4);
    unsigned char *src = (unsigned char *)sourceData;
    unsigned step = (unsigned)sourceBitsPerPixel / 8;
    unsigned length = (unsigned)step * sizeX * sizeY;
    unsigned char *end = src + length;
    unsigned char *dst = ptr;
    
    while (src != end)
    {
      dst[0] = src[3];
      dst[1] = src[2];
      dst[2] = src[1];
      dst[3] = src[0];
      src += step;
      dst+=4;
    }
    [_result[@"mips"] addObject:@{@"data" : [NSData dataWithBytes:ptr length:sizeX * sizeY * 4],
                                  @"x" : @(sizeX),
                                  @"y" : @(sizeY)}];
    
    free(ptr);
  }
  else
  {
    if (Compressor.process(InputOptions, CompressionOptions, OutputOptions))
    {
      if (!OutputHandler.CompressedData)
        return NO;
      [_result[@"mips"] addObject:@{@"data" : OutputHandler.CompressedData,
                                    @"x" : @(sizeX),
                                    @"y" : @(sizeY)}];
      for (;generateMips;)
      {
        if (![self loadImage:[self resizeImageToSize:NSMakeSize(sizeX * .5f, sizeY * .5f)]])
          break;
        [self setupOptions];
        
        if (Compressor.process(InputOptions, CompressionOptions, OutputOptions))
        {
          if (!OutputHandler.CompressedData)
            break;
          [_result[@"mips"] addObject:@{@"data" : OutputHandler.CompressedData,
                                        @"x" : @(sizeX),
                                        @"y" : @(sizeY)}];
        }
        else
          break;
        
        if (sizeX == 1 || sizeY == 1)
          break;
      }
    }
    else
      return NO;
  }
  return YES;
}

@end

@implementation TextureDecompiler

+ (instancetype)decompilerWithTexture:(Texture2D *)texture
{
  TextureDecompiler *d = [TextureDecompiler new];
  d.texture = texture;
  return d;
}

- (void)saveTo:(NSString *)path
{
  EPixelFormat pf = [_texture pixelFormat];
  NSSize size = [_texture size];
  Surface surface;
  void *bytes = NULL;
  if (pf == PF_DXT1)
  {
    bytes = (void *)_texture.bestMipMap.rawData.bytes;
    
    if (!surface.setImage2D(Format_DXT1, Decoder_D3D10, (int)size.width, (int)size.height, bytes))
      NSAppError(_texture.package, @"Failed to save '%@'",path);
    if (_swizzle)
      surface.swizzle(0,1,0,0);
    if (!surface.save([path UTF8String],true))
        NSAppError(_texture.package, @"Failed to save '%@'",path);
  }
  else if (pf == PF_DXT3)
  {
    bytes = (void *)_texture.bestMipMap.rawData.bytes;
    
    if (!surface.setImage2D(Format_DXT3, Decoder_D3D10, (int)size.width, (int)size.height, bytes) || !surface.save([path UTF8String],true))
      NSAppError(_texture.package, @"Failed to save '%@'",path);
  }
  else if (pf == PF_DXT5)
  {
    bytes = (void *)_texture.bestMipMap.rawData.bytes;
    
    if (!surface.setImage2D(Format_DXT5, Decoder_D3D10, (int)size.width, (int)size.height, bytes) || !surface.save([path UTF8String],true))
      NSAppError(_texture.package, @"Failed to save '%@'",path);
  }
  else if (pf == PF_G8)
  {
    int max = size.width * size.height;
    unsigned char *c = (unsigned char *)_texture.bestMipMap.rawData.bytes;
    bytes = calloc(max, 4);
    unsigned char *ptr = (unsigned char *)bytes;
    for (int idx = 0; idx < max * 4; idx+=4)
    {
      ptr[idx  ] = *c;
      ptr[idx+1] = *c;
      ptr[idx+2] = *c;
      ptr[idx+3] = 0xff;
      c++;
    }
    if (!surface.setImage(InputFormat_BGRA_8UB, size.width, size.height, 1, bytes) || !surface.save([path UTF8String],true))
      NSAppError(_texture.package, @"Failed to save '%@'",path);
    free(bytes);
  }
  else if (pf == PF_A8R8G8B8)
  {
    int max = size.width * size.height;
    unsigned char *c = (unsigned char *)_texture.bestMipMap.rawData.bytes;
    bytes = calloc(max, 4);
    unsigned char *ptr = (unsigned char *)bytes;
    for (int idx = 0; idx < max * 4; idx+=4, c+=4)
    {
      ptr[idx  ] = c[3];
      ptr[idx+1] = c[2];
      ptr[idx+2] = c[1];
      ptr[idx+3] = c[0];
    }
    if (!surface.setImage(InputFormat_BGRA_8UB, size.width, size.height, 1, bytes) || !surface.save([path UTF8String],true))
      NSAppError(_texture.package, @"Failed to save '%@'",path);
    free(bytes);
  }
  else
  {
    NSAppError(_texture.package, @"Can't save '%@' due to unknown format!",[path lastPathComponent]);
  }
}

@end
