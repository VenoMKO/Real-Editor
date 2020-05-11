//
//  LevelStreaming.h
//  Real Editor
//
//  Created by VenoMKO on 11.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "UObject.h"

@interface LevelStreaminDistance : UObject

- (NSString *)streamingPackageName;
- (int)zoneX;
- (int)zoneY;
- (float)streamingDistance;

@end

@interface KismetStreamingDistance : LevelStreaminDistance
@end

@interface S1LevelStreamingBaseLevel : LevelStreaminDistance
@end

@interface S1LevelStreamingVOID : LevelStreaminDistance
@end

@interface S1LevelStreamingSound : LevelStreaminDistance
@end
