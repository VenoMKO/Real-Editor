//
//  FBoxSphereBounds.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 11/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FVector.h"

@interface FBox : FReadable
@property (strong) FVector3 *min;
@property (strong) FVector3 *max;
@end

@interface FSphereBounds : FReadable
@property (strong) FVector3 *center;
@property (assign) float    w;
@end

@interface FBoxSphereBounds : FReadable
@property (strong) FVector3 *origin;
@property (strong) FVector3 *extent;
@property (assign) float    radius;
- (FBox *)box;
@end

@interface FTerrainBV : FReadable
@property (strong) FBox *bounds;
@end

@interface FConvexVolume : FReadable
@property (strong) FArray *planes;
@property (strong) FArray *permutedPlanes;
@end
