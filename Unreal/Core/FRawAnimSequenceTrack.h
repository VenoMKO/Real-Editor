//
//  FRawAnimSequenceTrack.h
//  Real Editor
//
//  Created by VenoMKO on 1.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "FReadable.h"
#import "FArray.h"

@interface FRawAnimSequenceTrack : FReadable

@property TArray *posKeys;
@property TArray *rotKeys;
@property TArray *timeKeys;


@end
