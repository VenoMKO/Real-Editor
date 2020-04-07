//
//  SkeletalMesh.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 11/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "SkeletalMesh.h"
#import "MeshUtils.h"
#import "Material.h"
#import "Texture2D.h"
#import "UPackage.h"
#import "FStream.h"
#import "FString.h"

@interface SkeletalMesh ()

@end

@implementation SkeletalMesh

- (BOOL)canExport
{
  return YES;
}

- (FIStream *)postProperties
{
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  
  self.bounds = [FBoxSphereBounds readFrom:s];
  self.materials = [FArray readFrom:s type:[UObject class]];
  self.origin = [FVector3 readFrom:s];
  self.rotaion = [FRotator readFrom:s];
  self.refSkeleton = [FArray readFrom:s type:[FMeshBone class]];
  self.skeletalDepth = [s readInt:0];
  self.lodInfo = [FArray readFrom:s type:[FLodInfo class]];
  self.nameMap = [FArray readFrom:s type:[FName class]];
  self.perPolyBoneKDOPs = [s readData:(int)(self.dataSize - (s.position - self.rawDataOffset))];
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  if (!self.isDirty && offset == self.exportObject.originalOffset)
    return [super cooked:offset];
  NSMutableData *d = [NSMutableData new];
  [d appendData:[self cookedProperties]];
  [d appendData:[self.bounds cooked:offset + d.length]];
  [d appendData:[self.materials cooked:offset + d.length]];
  [d appendData:[self.origin cooked:offset + d.length]];
  [d appendData:[self.rotaion cooked:offset + d.length]];
  [d appendData:[self.refSkeleton cooked:offset + d.length]];
  [d writeInt:self.skeletalDepth];
  [d appendData:[self.lodInfo cooked:offset + d.length]];
  [d appendData:[self.nameMap cooked:offset + d.length]];
  [d appendData:self.perPolyBoneKDOPs];
  return d;
}

- (SCNNode *)renderNode:(NSUInteger)lodIndex
{
  if (!self.rawDataOffset)
    [self properties];
  if (self.lodInfo.count <= lodIndex)
    return nil;
  FLodInfo *lod = self.lodInfo[lodIndex];
  GPUVertex *verts = malloc(sizeof(GPUVertex) * lod.vertexCount);
  GPUVertex *V = verts;
  
  // Converting to GPUVertex struct and SceneKit World Space (Z,Y,X) from UE3 (X,Z,-Y)
  for (FSkeletalMeshChunk *chunk in lod.chunks) {
    for (int vIdx = 0; vIdx < chunk.rigidVerticiesCount; vIdx++, V++) {
      
      V->position.x = chunk.rigidVerticies[vIdx].position.x; //-y
      V->position.y = chunk.rigidVerticies[vIdx].position.y; //z
      V->position.z = chunk.rigidVerticies[vIdx].position.z; //x
      
      GLKVector3 norm = UnpackNormal(chunk.rigidVerticies[vIdx].normal[2]);
      
      V->normal.x = norm.x; //-y
      V->normal.y = norm.y;//z
      V->normal.z = norm.z; //x
      
      V->u = chunk.rigidVerticies[vIdx].uv.u;
      V->v = chunk.rigidVerticies[vIdx].uv.v;
    }
    
    for (int vIdx = 0; vIdx < chunk.softVerticiesCount; vIdx++, V++) {
      
      V->position.x = chunk.softVerticies[vIdx].position.x;
      V->position.y = chunk.softVerticies[vIdx].position.y;
      V->position.z = chunk.softVerticies[vIdx].position.z;
      
      GLKVector3 norm = UnpackNormal(chunk.softVerticies[vIdx].normal[2]);
      
      V->normal.x = norm.x;
      V->normal.y = norm.y;
      V->normal.z = norm.z;
      
      V->u = chunk.softVerticies[vIdx].uv.u;
      V->v = chunk.softVerticies[vIdx].uv.v;
    }
  }
  
  SCNGeometrySource *vSource = nil;
  SCNGeometrySource *nSource = nil;
  SCNGeometrySource *tSource = nil;
  NSData *data = [NSData dataWithBytes:verts length:sizeof(GPUVertex) * lod.vertexCount];
  free(verts);
  
  vSource = [SCNGeometrySource geometrySourceWithData:data
                                             semantic:SCNGeometrySourceSemanticVertex
                                          vectorCount:lod.vertexCount
                                      floatComponents:YES
                                  componentsPerVector:3
                                    bytesPerComponent:sizeof(float)
                                           dataOffset:offsetof(GPUVertex, position)
                                           dataStride:sizeof(GPUVertex)];
  nSource = [SCNGeometrySource geometrySourceWithData:data
                                             semantic:SCNGeometrySourceSemanticNormal
                                          vectorCount:lod.vertexCount
                                      floatComponents:YES
                                  componentsPerVector:3
                                    bytesPerComponent:sizeof(float)
                                           dataOffset:offsetof(GPUVertex, normal)
                                           dataStride:sizeof(GPUVertex)];
  tSource = [SCNGeometrySource geometrySourceWithData:data
                                             semantic:SCNGeometrySourceSemanticTexcoord
                                          vectorCount:lod.vertexCount
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
    if (lod.indexContainter.elementSize == sizeof(short))
    {
      unsigned short *indices = malloc(sizeof(short) * section.faceCount * 3);
      unsigned short *lodIndices = (unsigned short *)lod.indexContainter.rawData;
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
      int *lodIndices = (int *)lod.indexContainter.rawData;
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
                                                                 bytesPerIndex:lod.indexContainter.elementSize];
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
    pitch = 0;
    yaw = 179;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  } else
    testRange = [name rangeOfString:@"_face" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 90;
    pitch = 0;
    yaw = 179;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
    testRange.location = NSNotFound;
  } else
    testRange = [name rangeOfString:@"_tail" options:NSCaseInsensitiveSearch];
  if (testRange.location != NSNotFound)
  {
    roll = 0;
    pitch = 90;
    yaw = 0;
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
    pitch = -90;
    yaw = -90;
    node.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(yaw),
                                      GLKMathDegreesToRadians(pitch),
                                      GLKMathDegreesToRadians(roll));
  }
  
  return node;
}

- (NSImage *)icon
{
  return [NSImage imageNamed:@"ModelIcon"];
}

@end

@implementation SkeletalMeshSocket

- (NSImage *)icon
{
  return [NSImage imageNamed:@"SocketIcon"];
}

@end
