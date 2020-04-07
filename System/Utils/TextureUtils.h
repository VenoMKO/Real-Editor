//
//  TextureUtils.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 08/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSType.h"

EPixelFormat NSStringToPixelFormat(NSString *pf);
NSString *NSStringFromPixelFormat(EPixelFormat pf);

@class UPackage;
NSImage *DecompressDDS(NSString *path, BOOL r, BOOL g, BOOL b, BOOL a);
NSDictionary *MipmapsFromDDS(NSURL *url, UPackage *package);
NSDictionary *CompressedMipmapsFromDDS(NSURL *url, UPackage *package, int compression);
NSDictionary *MipmapsFromNVTT(NSURL *url, UPackage *package, EPixelFormat pf, BOOL isNormalMap, BOOL sRGB, BOOL mipmaps);
NSDictionary *CompressedMipmapsFromNVTT(NSURL *url, UPackage *package, EPixelFormat pf, int compression, BOOL isNormalMap, BOOL sRGB, BOOL mipmaps);

void DecompressAlphaDXT5(Byte *targetRGBA, NSData *bytes, int sourceOffset, int numTargetChannels, int channelOffset);
void DecompressColor(Byte *targetRGBA, NSData *bytes, int srcOffset, BOOL dxtFlag);
int Unpack565(Byte *packed, int pidx, Byte *color, int cidx, BOOL dxtFlag);
NSMutableData *DDSHeader(EPixelFormat fmt, NSSize size,int mipmaps);
