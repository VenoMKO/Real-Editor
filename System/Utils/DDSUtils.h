//
//  DDSUtils.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 12/11/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSType.h"

@interface TextureCompiler : NSObject
@property (readonly) NSMutableDictionary *result;
+ (instancetype)compilerWithOptions:(NSDictionary *)options;
- (BOOL)process;
@end

@class Texture2D;
@interface TextureDecompiler : NSObject
@property (weak)Texture2D  *texture;
@property BOOL swizzle;

+ (instancetype)decompilerWithTexture:(Texture2D *)texture;
- (void)saveTo:(NSString *)path;
@end
