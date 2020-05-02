//
//  AnimSequence.h
//  Real Editor
//
//  Created by VenoMKO on 1.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "UObject.h"
#import "FArray.h"

@interface AnimSet : UObject

- (NSArray *)trackBoneNames;
- (UObject *)previewMesh;
- (NSArray *)sequences;

@end

@interface AnimSequence : UObject

@property FArray *rawAnimationData;
@property NSData *compressedData;

- (NSArray *)compressedTrackOffsets;
- (NSString *)keyEncodingFormat;
- (NSString *)sequenceName;
- (float)sequenceLength;
- (int)numFrames;

@end
