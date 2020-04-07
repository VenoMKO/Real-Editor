//
//  FStreamableTextureInstance.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FBoxSphereBounds.h"

@interface FStreamableTextureInstance : FReadable
@property (strong) FSphereBounds *boundingSphere;
@property (assign) float texelFactor;
@end
