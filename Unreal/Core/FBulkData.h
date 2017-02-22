//
//  FBulkData.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"

@interface FBulkData : FReadable
@property (assign) int flags;
@property (assign) unsigned compressedSize;
@property (assign) unsigned decompressedSize;
@property (assign) unsigned compressedOffset;
@property (strong) NSData   *data;

+ (instancetype)emptyUnusedData;
- (NSData *)decompressedData;
- (void)setDecompressedData:(NSData *)data;
- (BOOL)isUnused;
- (void)setUnused:(BOOL)flag;
- (BOOL)isRemote;
- (void)setIsUnused:(BOOL)flag;
- (void)setCompression:(int)compression;
- (int)compression;
@end

@interface FByteBulkData : FReadable
@property (assign) int flags;
@property (assign) unsigned elementCount;
@property (readonly) int    elementSize;
@property (assign) unsigned compressedSize;
@property (assign) unsigned compressedOffset;
@property (strong) NSData   *data;

- (BOOL)isUnused;
- (void)setUnused:(BOOL)flag;
- (BOOL)isRemote;
- (void)setIsRemote:(BOOL)flag;
@end
