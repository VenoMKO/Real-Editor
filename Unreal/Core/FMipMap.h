//
//  FMipMap.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 06/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "DDSType.h"

@interface FMipMap : FReadable
@property (assign) unsigned  width;
@property (assign) unsigned  height;
+ (instancetype)unusedMip;
- (BOOL)isValid;
- (NSData *)rawData;
- (void)setRawData:(NSData *)data;
- (void)setCompression:(int)compression;
- (int)compression;
@end
