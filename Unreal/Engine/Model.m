//
//  Model.m
//  Real Editor
//
//  Created by Vladislav Skachkov on 11/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "Model.h"
#import "UPackage.h"
#import "FStaticMesh.h"

enum {MAX_NODE_VERTICES=255};	// Max vertices in a Bsp node.
enum {MAX_ZONES=64};			// Max zones per level.

@interface FBspNode ()
{
  
}

@end

@implementation FBspNode

+ (id)readFrom:(FIStream *)stream
{
  FBspNode *n = [super readFrom:stream];
  n.plane = [FPlane readFrom:stream];
  n.iVertPool = [stream readInt:0];
  n.iSurf = [stream readInt:0];
  n.iVertexIndex = [stream readInt:0];
  n.componentIndex = [stream readShort:0];
  n.componentNodeIndex = [stream readShort:0];
  n.componentElementIndex = [stream readShort:0];
  return n;
}

@end

@implementation Model

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  self.bounds = [FBoxSphereBounds readFrom:s];
  self.vectors = [TransFArray readFrom:s type:[FVector3 class]];
  self.points = [TransFArray readFrom:s type:[FVector3 class]];
  //self.nodes = [TransFArray readFrom:s type:[FBspNode class]];
  return s;
}

@end
