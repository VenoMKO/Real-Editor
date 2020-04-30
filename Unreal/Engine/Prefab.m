//
//  Prefab.m
//  Real Editor
//
//  Created by VenoMKO on 29.04.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "Prefab.h"
#import "UPackage.h"
#import "StaticMesh.h"
#import "MeshActor.h"

@implementation Prefab

- (FIStream *)postProperties
{
  [self prefabArchetypes];
  return nil;
}

- (NSArray *)prefabArchetypes
{
  [self properties];
  NSArray *archetypeIndices = [self propertyValue:@"PrefabArchetypes"];
  NSMutableArray *objects = [NSMutableArray new];
  for (NSNumber *index in archetypeIndices)
  {
    UObject *object = [self.package objectForIndex:index.intValue];
    if (object.exportObject.exportFlags | EF_ForcedExport)
    {
      UObject *tobj = [self.package resolveForcedExport:object.exportObject];
      if (tobj)
      {
        object = tobj;
      }
    }
    else if (object.importObject)
    {
      UObject *tobj = [self.package resolveImport:object.importObject];
      if (tobj)
      {
        object = tobj;
      }
    }
    if (object)
    {
      [objects addObject:object];
    }
    else
    {
      DThrow(@"Failed to get a prefab archetype %d!", index.intValue);
    }
  }
  return objects;
}

- (SCNNode *)renderNode:(NSUInteger)lodIndex
{
  SCNNode *rootNode = [SCNNode new];
  NSArray *objects = [self prefabArchetypes];
  
  for (MeshActor *actor in objects)
  {
    if (![actor respondsToSelector:@selector(mesh)])
    {
      DThrow(@"Skipping non-render actor %@", actor.displayName);
      continue;
    }
    [actor properties];
    UObject *mesh = [actor mesh];
    if (![mesh respondsToSelector:@selector(renderNode:)])
    {
      DThrow(@"Skipping prefab archetype %@", actor.displayName);
      continue;
    }
    SCNNode *node = [(StaticMesh*)mesh renderNode:lodIndex];
    if (node)
    {
      GLKVector3 pos = [actor absolutePostion];
      node.position = SCNVector3Make(pos.x, pos.y, pos.z);
      GLKVector3 scaleVec = [actor absoluteDrawScale3D];
      node.scale = SCNVector3Make(scaleVec.x, scaleVec.y, scaleVec.z);
      GLKVector3 rotator = [[[actor absoluteRotator] euler] glkVector3];
      node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-rotator.x), GLKMathDegreesToRadians(-rotator.y), GLKMathDegreesToRadians(rotator.z));
      [rootNode addChildNode:node];
    }
  }
  return rootNode;
}

@end
