//
//  FVector.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import <GLKit/GLKit.h>

@interface FVector2D : FReadable <NSCopying> //unreal FVector2D
@property (assign) double x;
@property (assign) double y;
@end

@interface FVector3 : FReadable <NSCopying> //unreal FVector
@property (assign) double x;
@property (assign) double y;
@property (assign) double z;
- (GLKVector3)glkVector3;
@end

@interface FVector4 : FVector3 <NSCopying>
@property (assign) double w;
- (GLKVector4)glkVector4;
@end

@interface FPlane : FVector4
@end

@interface FDVector3 : FReadable <NSCopying>
@property (assign) int    x;
@property (assign) int    y;
@property (assign) int    z;
@end

@interface FDVector4 : FDVector3 <NSCopying>
@property (assign) int    w;
@end
