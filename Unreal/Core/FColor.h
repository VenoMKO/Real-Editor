//
//  FColor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"

@interface FLinearColor : FReadable <NSCopying>
@property (assign) double r;
@property (assign) double g;
@property (assign) double b;
@property (assign) double a;

+ (instancetype)linearColorWithColor:(NSColor *)color package:(UPackage *)package;
- (NSColor *)NSColor;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end

@interface FColor : FReadable <NSCopying>
@property (assign) Byte r;
@property (assign) Byte g;
@property (assign) Byte b;
@property (assign) Byte a;

+ (instancetype)colorWithColor:(NSColor *)color package:(UPackage *)package;
- (NSColor *)NSColor;

@end
