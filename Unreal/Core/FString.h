//
//  FString.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"

@interface FString : FReadable <NSCopying, NSCoding>
@property (strong, nonatomic) NSString          *string;

+ (id)stringWithString:(NSString *)string;
- (NSMutableData *)cooked;

@end

@interface FNamePair : FString <NSCopying>
@property (assign) RFObjectFlags flags;
- (int)index;
@end

@interface FName : FReadable
+ (instancetype)nameWithString:(NSString *)string flags:(int)flags package:(UPackage *)package;
- (NSString *)name;
- (void)setName:(NSString *)name forIndex:(int)index;
- (NSString *)string;
@end

@class FArray;
@interface FURL : FReadable
@property (strong) FString *protocol;
@property (strong) FString *host;
@property (assign) int port;
@property (strong) FString *map;
@property (strong) FArray *op;
@property (strong) FString *portal;
@property (assign) int valid;

@end
