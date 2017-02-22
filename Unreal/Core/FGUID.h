//
//  FGUID.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"

@interface FGUID : FReadable <NSCopying, NSCoding>
@property (strong, nonatomic) NSMutableData           *data;

+ (id)guid;
+ (id)readFrom:(FIStream *)stream;
+ (id)guidFromString:(NSString *)string;
+ (id)guidFromLEString:(NSString *)string;
- (NSString *)string;
- (NSMutableData *)cooked;

@end
