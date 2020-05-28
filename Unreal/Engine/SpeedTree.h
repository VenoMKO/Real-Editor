//
//  SpeedTree.h
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "UObject.h"

@interface SpeedTree : UObject
@property NSData *sptData;

- (NSData *)materialMappedSpt;

- (UObject *)branchMaterial;
- (UObject *)frondMaterial;
- (UObject *)leafMaterial;

- (NSArray *)materials;
@end
