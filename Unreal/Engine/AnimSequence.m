//
//  AnimSequence.m
//  Real Editor
//
//  Created by VenoMKO on 1.05.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "AnimSequence.h"
#import "FString.h"
#import "FRawAnimSequenceTrack.h"
#import "UPackage.h"

@implementation AnimSet

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  return s;
}

- (NSArray *)trackBoneNames
{
  NSMutableArray *names = [NSMutableArray new];
  NSArray *tmp = [self propertyValue:@"TrackBoneNames"];
  for (FName *name in tmp)
  {
    [names addObject:[name name]];
  }
  return names;
}

- (UObject *)previewMesh
{
  NSString *meshPath = [self.package nameForIndex:[[self propertyValue:@"PreviewSkelMeshName"] intValue]];
  return [self.package externalObjectForPath:meshPath];
}

- (NSArray *)sequences
{
  NSArray *objIndecies = [self propertyValue:@"Sequences"];
  NSMutableArray *result = [NSMutableArray new];
  for (NSNumber *num in objIndecies)
  {
    [result addObject:[self.package objectForIndex:[num intValue]]];
  }
  return result;
}

@end

@implementation AnimSequence

- (AnimSet *)animSet
{
  if ([self.parent isKindOfClass:[AnimSet class]])
  {
    return self.parent;
  }
  return nil;
}

- (NSArray *)compressedTrackOffsets
{
  return [self propertyValue:@"CompressedTrackOffsets"];
}

- (NSString *)keyEncodingFormat
{
  NSNumber *prop = [self propertyValue:@"KeyEncodingFormat"];
  if (!prop)
  {
    return @"AKF_ConstantKeyLerp";
  }
  return [self.package nameForIndex:[prop intValue]];
}

- (NSString *)rotationCompressionFormat
{
  NSNumber *prop = [self propertyValue:@"RotationCompressionFormat"];
  return [self.package nameForIndex:[prop intValue]];
}

- (int)numFrames
{
  return [[self propertyValue:@"NumFrames"] intValue];
}

- (NSString *)sequenceName
{
  return [(FName*)[self propertyValue:@"SequenceName"] name];
}

- (float)sequenceLength
{
  return [[self propertyValue:@"NumFrames"] floatValue];
}

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  self.rawAnimationData = [TArray readFrom:s type:[FRawAnimSequenceTrack class]];
  int numBytes = [s readInt:NULL];
  self.compressedData = [s readData:numBytes];
  return s;
}

@end
