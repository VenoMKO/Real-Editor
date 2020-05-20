//
//  LevelStreaming.h
//  Real Editor
//
//  Created by VenoMKO on 11.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "UObject.h"

@interface LevelStreamingDistance : UObject

- (NSString *)streamingPackageName;
- (int)zoneX;
- (int)zoneY;
- (float)streamingDistance;

@end

@interface LevelStreamingKismet : LevelStreamingDistance
@end

@interface S1LevelStreamingBaseLevel : LevelStreamingDistance
@end

@interface S1LevelStreamingVOID : LevelStreamingDistance
@end

@interface S1LevelStreamingSound : LevelStreamingDistance
@end
