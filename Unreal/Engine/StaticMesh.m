//
//  StaticMesh.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 22/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "StaticMesh.h"
#import "FMesh.h"
#import "UPackage.h"
#import "FStream.h"

@implementation StaticMesh

- (BOOL)canExport
{
  return YES;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  if (!self.isDirty && offset == self.exportObject.originalOffset)
    return [super cooked:offset];
  
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self cookedProperties]];
  [d appendData:[self.sourceFile cooked:offset + d.length]];
  [d appendData:[self.bounds cooked:offset + d.length]];
  if (self.bodySetup)
    [d writeInt:[self.package indexForObject:self.bodySetup]];
  else
    [d increaseLengthBy:sizeof(int)];
  [d writeInt:sizeof(kDOPNode)];
  [d writeInt:self.kDOPNodeCount];
  [d appendBytes:self.kDOPNodes length:sizeof(kDOPNode) * self.kDOPNodeCount];
  [d writeInt:sizeof(long)];
  [d writeInt:self.kDOPTriangleCount];
  [d appendBytes:self.kDOPTriangles length:sizeof(long) * self.kDOPTriangleCount];
  [d writeInt:self.version];
  [d appendData:[self.strings cooked:offset + d.length]];
  [d appendData:[self.lodInfo cooked:offset + d.length]];
  [d writeInt:(int)self.lodInfo.count];
  [d appendData:[self.thumbnailAngle cooked:offset + d.length]];
  [d writeInt:self.thumbnailDistance];
  [d appendData:[self.physMeshScale3D cooked:offset + d.length]];
  [d writeInt:self.unk];
  return d;
}

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  
  self.sourceFile = [FString readFrom:s];
  self.bounds = [FBoxSphereBounds readFrom:s];
  self.bodySetup = [self.package objectForIndex:[s readInt:NULL]];
  
  int temp = [s readInt:NULL];
  if (temp != sizeof(kDOPNode))
  {
    DLog(@"Error! KDOPNode has wrong size!");
    return nil;
  }
  
  self.kDOPNodeCount = [s readInt:NULL];
  if (self.kDOPNodeCount)
  {
    self.kDOPNodes = [s readBytes:self.kDOPNodeCount * sizeof(kDOPNode) error:NULL];
  }
  
  temp = [s readInt:NULL];
  if (temp != sizeof(long))
  {
    DLog(@"Error! KDOPNode face has wrong size!");
    return nil;
  }
  
  self.kDOPTriangleCount = [s readInt:NULL];
  if (self.kDOPTriangleCount)
  {
    self.kDOPTriangles = [s readBytes:sizeof(long) * self.kDOPTriangleCount error:NULL];
  }
  
  self.version = [s readInt:NULL];
  self.strings = [FArray readFrom:s type:[FString class]];
  self.lodInfo = [FArray readFrom:s type:[FStaticLodInfo class]];
  temp = [s readInt:NULL];
  if (temp != self.lodInfo.count)
  {
    DThrow(@"Lod missmatch");
  }
  self.thumbnailAngle = [FRotator readFrom:s];
  self.thumbnailDistance = [s readInt:NULL];
  self.physMeshScale3D = [FArray readFrom:s type:[FVector3 class]];
  self.unk = [s readInt:NULL];
  if (self.exportObject.originalOffset + self.exportObject.serialSize != s.position)
    DThrow(@"Found unexpected data!");
  
  return s;
}

- (SCNNode *)renderNode:(NSUInteger)lodIndex
{
  if (!self.rawDataOffset)
    [self properties];
  if (self.lodInfo.count <= lodIndex)
    return nil;
  FStaticLodInfo *lod = self.lodInfo[lodIndex];
  GPUVertex *verts = malloc(sizeof(GPUVertex) * lod.numVerticies);
  GPUVertex *dst = verts;
  GenericVertex *src = [lod vertices];
  for (int vIdx = 0; vIdx < lod.numVerticies; vIdx++, ++dst)
  {
    //SceneKit World Space (Z,Y,X) from UE3 (X,Z,-Y)
    dst->position.x = src[vIdx].position.x; //-y
    dst->position.y = src[vIdx].position.y; //z
    dst->position.z = src[vIdx].position.z; //x
    
    GLKVector3 norm = src[vIdx].normal;
    
    dst->normal.x = norm.x; //-y
    dst->normal.y = norm.y;//z
    dst->normal.z = norm.z; //x
    
    dst->u = src[vIdx].uv[0].u;
    dst->v = src[vIdx].uv[0].v;
  }
  free(src);
  
  SCNGeometrySource *vSource = nil;
  SCNGeometrySource *nSource = nil;
  SCNGeometrySource *tSource = nil;
  NSData *data = [NSData dataWithBytes:verts length:sizeof(GPUVertex) * lod.numVerticies];
  free(verts);
  
  vSource = [SCNGeometrySource geometrySourceWithData:data
                                             semantic:SCNGeometrySourceSemanticVertex
                                          vectorCount:lod.numVerticies
                                      floatComponents:YES
                                  componentsPerVector:3
                                    bytesPerComponent:sizeof(float)
                                           dataOffset:offsetof(GPUVertex, position)
                                           dataStride:sizeof(GPUVertex)];
  nSource = [SCNGeometrySource geometrySourceWithData:data
                                             semantic:SCNGeometrySourceSemanticNormal
                                          vectorCount:lod.numVerticies
                                      floatComponents:YES
                                  componentsPerVector:3
                                    bytesPerComponent:sizeof(float)
                                           dataOffset:offsetof(GPUVertex, normal)
                                           dataStride:sizeof(GPUVertex)];
  tSource = [SCNGeometrySource geometrySourceWithData:data
                                             semantic:SCNGeometrySourceSemanticTexcoord
                                          vectorCount:lod.numVerticies
                                      floatComponents:YES
                                  componentsPerVector:2
                                    bytesPerComponent:sizeof(float)
                                           dataOffset:offsetof(GPUVertex, u)
                                           dataStride:sizeof(GPUVertex)];
  
  
  NSMutableArray  *elements = [NSMutableArray array];
  
  for (int sectionIndex = 0; sectionIndex < lod.sections.count; sectionIndex++)
  {
    FMeshSection *section = lod.sections[sectionIndex];
    int faceCount = section.faceCount;
    NSData *elementData = nil;
    // MultiSizeIndexContainer supposed to hold shorts or ints.
    if (lod.indexContainer.elementSize == sizeof(short))
    {
      unsigned short *indices = malloc(sizeof(short) * section.faceCount * 3);
      unsigned short *lodIndices = (unsigned short *)lod.indexContainer.rawData;
      for (int faceIndex = 0; faceIndex < faceCount; faceIndex++)
      {
        indices[faceIndex * 3 + 0] = lodIndices[section.firstIndex + ((faceIndex * 3) + 0)];
        indices[faceIndex * 3 + 2] = lodIndices[section.firstIndex + ((faceIndex * 3) + 1)];
        indices[faceIndex * 3 + 1] = lodIndices[section.firstIndex + ((faceIndex * 3) + 2)];
      }
      elementData = [NSData dataWithBytes:indices length:sizeof(short) * section.faceCount * 3];
      free(indices);
    }
    else
    {
      int *indices = malloc(sizeof(int) * section.faceCount * 3);
      int *lodIndices = (int *)lod.indexContainer.rawData;
      for (int faceIndex = 0; faceIndex < faceCount; faceIndex++)
      {
        indices[faceIndex * 3 + 0] = lodIndices[section.firstIndex + ((faceIndex * 3) + 0)];
        indices[faceIndex * 3 + 2] = lodIndices[section.firstIndex + ((faceIndex * 3) + 1)];
        indices[faceIndex * 3 + 1] = lodIndices[section.firstIndex + ((faceIndex * 3) + 2)];
      }
      elementData = [NSData dataWithBytes:indices length:sizeof(int) * section.faceCount * 3];
      free(indices);
    }
    
    SCNGeometryElement *sElement = [SCNGeometryElement geometryElementWithData:elementData
                                                                 primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                                primitiveCount:faceCount
                                                                 bytesPerIndex:lod.indexContainer.elementSize];
    [elements addObject:sElement];
  }
  SCNGeometry *geo = [SCNGeometry geometryWithSources:@[vSource,nSource,tSource] elements:elements];
  SCNNode *node = [SCNNode nodeWithGeometry:geo];
  int pitch = 0, yaw = 0, roll = 0;
  
  NSString *name = self.objectName;
  
  NSRange testRange = [name rangeOfString:@"_hair" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 90;
    pitch = -90;
    yaw = 89;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  } else
    testRange = [name rangeOfString:@"_face" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 90;
    pitch = -90;
    yaw = 90;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  } else
    testRange = [name rangeOfString:@"_tail" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 0;
    pitch = 0;
    yaw = -90;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  } else
    testRange = [name rangeOfString:@"Attach_" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 0;
    pitch = -90;
    yaw = -90;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  } else
    testRange = [name rangeOfString:@"Switch_" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 90;
    pitch = -90;
    yaw = 90;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  }
  else
  {
    roll = 0;
    pitch = 0;
    yaw = -90;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  }
  
  return node;
}

- (NSArray *)materials
{
  NSArray *materials = [self.lodInfo[0] materials];
  return materials;
}

@end
