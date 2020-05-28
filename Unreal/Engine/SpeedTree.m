//
//  SpeedTree.m
//  Real Editor
//
//  Created by VenoMKO on 28.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "SpeedTree.h"
#import "UPackage.h"
#import "Extensions.h"

@implementation SpeedTree

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  s.position = self.rawDataOffset;
  int numBytes = [s readInt:NULL];
  self.sptData = [s readData:numBytes];
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self cookedProperties];
  [d writeInt:(int)self.sptData.length];
  [d appendData:self.sptData];
  return d;
}

- (NSData *)exportWithOptions:(NSDictionary *)options
{
  if (!self.sptData)
  {
    [self properties];
  }
  if ([options[@"expMaterials"] boolValue])
  {
    return [self materialMappedSpt];
  }
  return self.sptData;
}

- (NSData *)materialMappedSpt
{
  UObject *branchMaterial = [self branchMaterial];
  UObject *frondMaterial = [self frondMaterial];
  UObject *leafMaterial = [self leafMaterial];

  NSString *branch = nil;
  NSString *frond = nil;
  NSString *leaf = nil;
  if (branchMaterial)
  {
    NSString *name = [branchMaterial objectNetPath];
    if (!name)
    {
      name = [branchMaterial objectPath];
    }
    name = [name componentsSeparatedByString:@"."].lastObject;
    if (name.length)
    {
      branch = name;
    }
  }
  
  if (frondMaterial)
  {
    if (frondMaterial == branchMaterial)
    {
      frond = [branch stringByAppendingFormat:@"_frond"];
    }
    else
    {
      NSString *name = [frondMaterial objectNetPath];
      if (!name)
      {
        name = [frondMaterial objectPath];
      }
      name = [name componentsSeparatedByString:@"."].lastObject;
      if (name.length)
      {
        frond = name;
      }
    }
  }
  
  if (leafMaterial)
  {
    if (leafMaterial == frondMaterial)
    {
      leaf = [frond stringByAppendingFormat:@"_leaf"];
    }
    else if (leafMaterial == branchMaterial)
    {
      leaf = [branch stringByAppendingFormat:@"_leaf"];
    }
    else
    {
      NSString *name = [leafMaterial objectNetPath];
      if (!name)
      {
        name = [leafMaterial objectPath];
      }
      name = [name componentsSeparatedByString:@"."].lastObject;
      if (name.length)
      {
        leaf = name;
      }
    }
  }
  
  // Add materials into the UserData section.
  // This will be used by the Spt2Fbx to name materials
  NSMutableData *buffer = [self.sptData mutableCopy];
  if (branch.length || frond.length || leaf.length)
  {
    [buffer writeInt:19000]; // UserDataBegin
    [buffer writeInt:19002]; // UserData
    NSMutableData *userData = [NSMutableData new];
    [userData writeByte:'$'];
    if (branch.length)
    {
      [userData writeByte:'b'];
      [userData writeByte:branch.length];
      [userData appendData:[branch dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if (frond.length)
    {
      [userData writeByte:'f'];
      [userData writeByte:frond.length];
      [userData appendData:[frond dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if (leaf.length)
    {
      [userData writeByte:'l'];
      [userData writeByte:leaf.length];
      [userData appendData:[leaf dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [userData writeByte:'\0'];
    NSString *s = [[NSString alloc] initWithData:userData encoding:NSUTF8StringEncoding];
    [buffer writeString:s];
    [buffer writeInt:19001]; // UserDataEnd
  }
  return buffer;
}

- (UObject *)branchMaterial
{
  [self properties];
  NSNumber *objIdx = [self propertyValue:@"BranchMaterial"];
  if (!objIdx)
  {
    return nil;
  }
  UObject *obj = [self.package objectForIndex:objIdx.intValue];
  if (obj.importObject)
  {
    return [self.package resolveImport:obj.importObject];
  }
  return obj;
}

- (UObject *)frondMaterial
{
  [self properties];
  NSNumber *objIdx = [self propertyValue:@"FrondMaterial"];
  if (!objIdx)
  {
    return nil;
  }
  UObject *obj = [self.package objectForIndex:objIdx.intValue];
  if (obj.importObject)
  {
    return [self.package resolveImport:obj.importObject];
  }
  return obj;
}

- (UObject *)leafMaterial
{
  [self properties];
  NSNumber *objIdx = [self propertyValue:@"LeafMaterial"];
  if (!objIdx)
  {
    return nil;
  }
  UObject *obj = [self.package objectForIndex:objIdx.intValue];
  if (obj.importObject)
  {
    return [self.package resolveImport:obj.importObject];
  }
  return obj;
}

- (NSArray *)materials
{
  NSMutableArray *result = [NSMutableArray new];
  UObject *m = [self branchMaterial];
  if (m)
  {
    [result addObject:m];
  }
  m = [self frondMaterial];
  if (m)
  {
    [result addObject:m];
  }
  m = [self leafMaterial];
  if (m)
  {
    [result addObject:m];
  }
  return result;
}

@end
