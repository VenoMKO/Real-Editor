//
//  FStream.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UPackage;
@interface FIStream : NSObject

@property (retain) NSURL *url;
@property (weak) UPackage *package;
@property (assign, nonatomic) NSUInteger position;
@property (assign) UGame game;

+ (instancetype)streamForUrl:(NSURL *)url;
+ (instancetype)streamForPath:(NSString *)path;
+ (instancetype)streamForData:(NSData *)data;

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;
- (void *)readBytes:(int)length error:(BOOL *)error;
- (float)readFloat:(BOOL *)error;
- (float)readHalfFloat:(BOOL *)error;
- (int)readInt:(BOOL *)error;
- (long)readLong:(BOOL *)error;
- (short)readShort:(BOOL *)error;
- (Byte)readByte:(BOOL *)error;
- (NSData *)readData:(int)length;
- (id)copy;
- (void)close;

@end
