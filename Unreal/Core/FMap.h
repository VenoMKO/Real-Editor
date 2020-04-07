//
//  FMap.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"

@interface FMap : FReadable

+ (instancetype)readFrom:(FIStream *)stream keyType:(Class)keyType type:(Class)type;
+ (instancetype)readFrom:(FIStream *)stream keyType:(Class)keyType arrayType:(Class)type;

@end

@interface FMultiMap : FReadable
+ (instancetype)readFrom:(FIStream *)stream keyType:(Class)keyType type:(Class)type;
@end
