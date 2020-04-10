//
//  MeshComponent.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 25/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "MeshComponent.h"
#import "FStaticMesh.h"
#import "UPackage.h"
#import "ObjectRedirector.h"

@implementation MeshComponent

- (FIStream *)postProperties
{
  return [super postProperties];
}

@end

@implementation StaticMeshComponent

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  self.mesh = [self.package objectForIndex:[[[self propertyForName:@"StaticMesh"] value] intValue]];
  self.lodInfo = [FArray readFrom:s type:[FStaticMeshComponentLODInfo class]];
  if (s.position - self.rawDataOffset != self.dataSize)
    DThrow(@"end missmatch!");
  if (self.mesh)
  {
    [self.mesh properties];
    if ([self.mesh isKindOfClass:[ObjectRedirector class]])
    {
      self.mesh = [(ObjectRedirector*)self.mesh reference];
      [self.mesh properties];
    }
  }
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  [d appendData:[self.lodInfo cooked:0]];
  return d;
}

@end

@implementation SkeletalMeshComponent

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  self.mesh = [self.package objectForIndex:[[[self propertyForName:@"SkeletalMesh"] value] intValue]];
  if (self.mesh)
  {
    [self.mesh properties];
    if ([self.mesh isKindOfClass:[ObjectRedirector class]])
    {
      self.mesh = [(ObjectRedirector*)self.mesh reference];
      [self.mesh properties];
    }
  }
  return s;
}

@end
