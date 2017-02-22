//
//  FBXUtils.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 20/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FBXUtils.h"
#import "Actor.h"
#import "Level.h"
#import "SkeletalMesh.h"
#import "StaticMesh.h"
#import "FMesh.h"
#import "FStaticMesh.h"
#import "MeshComponent.h"
#import "MeshUtils.h"
#import "UObject.h"
#import "UPackage.h"
#import "Material.h"
#import "Common.h"
#import "Texture2D.h"
#import <fbxsdk.h>

static const float RelScale = .3f;

#define FAST_INVSQRT 0
FbxAMatrix ComputeTotalMatrix(FbxNode* Node, FbxScene *pScene);
BOOL IsOddNegativeScale(FbxAMatrix& TotalMatrix);
FbxNode *createSkeleton(const SkeletalMesh* skelMesh, FbxDynamicArray<FbxNode*>& boneNodes, FbxScene *pScene, BOOL prefix);
void AddNodeRecursively(FbxArray<FbxNode*>& pNodeArray, FbxNode* pNode);
void BuildSkeletonSystem(FbxDynamicArray<FbxCluster*>& ClusterArray, FbxDynamicArray<FbxNode*>& OutSortedLinks, FbxScene *pScene);
BOOL IsUnrealBone(FbxNode* Link);
void CreateBindPose(FbxNode* MeshRootNode, FbxScene *Scene);
float InvSqrt(float F);
bool NormalizeVector(FbxVector4 *vector);
GLKVector3 UnpackNormal(FPackedNormal normal);
FPackedNormal PackNormal(float x, float y, float z);

// Textured triangle.
struct VTriangle
{
  uint32   WedgeIndex[3];	 // Point to three vertices in the vertex list.
  uint8    MatIndex;	     // Materials can be anything.
  uint8    AuxMatIndex;    // Second material from exporter (unused)
  
  GLKVector3	TangentX[3];
  GLKVector3	TangentY[3];
  GLKVector3	TangentZ[3];
  
  
  VTriangle& operator=( const VTriangle& Other)
  {
    this->AuxMatIndex   = Other.AuxMatIndex;
    this->MatIndex      =  Other.MatIndex;
    this->WedgeIndex[0] =  Other.WedgeIndex[0];
    this->WedgeIndex[1] =  Other.WedgeIndex[1];
    this->WedgeIndex[2] =  Other.WedgeIndex[2];
    this->TangentX[0]   =  Other.TangentX[0];
    this->TangentX[1]   =  Other.TangentX[1];
    this->TangentX[2]   =  Other.TangentX[2];
    
    this->TangentY[0]   =  Other.TangentY[0];
    this->TangentY[1]   =  Other.TangentY[1];
    this->TangentY[2]   =  Other.TangentY[2];
    
    this->TangentZ[0]   =  Other.TangentZ[0];
    this->TangentZ[1]   =  Other.TangentZ[1];
    this->TangentZ[2]   =  Other.TangentZ[2];
    
    return *this;
  }
};

struct VVertex
{
  int      VertexIndex; // Index to a vertex.
  GLKVector2 UVs[4];
  short    MatIndex;    // At runtime, this one will be implied by the face that's pointing to us.
  short    Reserved;    // Top secret.
};

struct FVertInfluence
{
  float Weight;
  uint32 VertIndex;
  uint16 BoneIndex;
};

struct FMeshFace
{
  uint32		iWedge[3];			// Textured Vertex indices.
  uint16		MeshMaterialIndex;	// Source Material (= texture plus unique flags) index.
  
  GLKVector3	TangentX[3];
  GLKVector3	TangentY[3];
  GLKVector3	TangentZ[3];
  
};

struct FMeshWedge
{
  uint32			iVertex;			// Vertex index.
  GLKVector2		UVs[4];     // UVs.
};

struct VMaterial
{
  int             MaterialIndex;
  const char      *MaterialImportName;
};

@interface FBXUtils ()
{
  FbxManager  *pSdkManager;
  FbxScene    *pScene;
  NSMutableDictionary *_materials;
  FbxDynamicArray<FbxSurfaceMaterial*> FBXMaterials;
  NSMutableArray *textures;
}

@end

@implementation FBXUtils

- (void)exportStaticMesh:(StaticMesh *)sMesh options:(NSDictionary *)expOptions toFbxNode:(FbxNode **)meshNode
{
  int lodIdx = [expOptions[@"lodIdx"] intValue];
  FStaticLodInfo *sourceModel = sMesh.lodInfo[lodIdx];
  int vertexCount = sourceModel.numVerticies;
  
  *meshNode = FbxNode::Create(pScene, (const char *)[sMesh.objectName cStringUsingEncoding:NSASCIIStringEncoding]);
  FbxNode *node = *meshNode;
  
  FbxMesh *mesh = FbxMesh::Create(pScene,"geometry");
  GenericVertex *vertices = [sourceModel vertices];
  
  mesh->InitControlPoints(vertexCount);
  FbxVector4 *controlPoints = mesh->GetControlPoints();
  
  for (int vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++)
  {
    GLKVector3 pos = vertices[vertexIndex].position;
    controlPoints[vertexIndex] = FbxVector4(pos.x,
                                            pos.y * -1.f,
                                            pos.z);
  }
  
  FbxLayer *layer = mesh->GetLayer(0);
  if (!layer)
  {
    mesh->CreateLayer();
    layer = mesh->GetLayer(0);
    if (!layer)
    {
      DLog(@"Failed to get mesh layer!");
      return;
    }
    
  }
  //BOOL hasLightMap = NO;
  FbxLayerElementUV *uvDiffuseLayer = FbxLayerElementUV::Create(mesh, "DiffuseUV");
  //FbxLayerElementUV *uvLightMapLayer = FbxLayerElementUV::Create(mesh, "LightMapUV");
  FbxLayerElementNormal *layerElementNormal = FbxLayerElementNormal::Create(mesh, "");
  FbxLayerElementBinormal *layerElementBinormal = FbxLayerElementBinormal::Create(mesh, "");
  FbxLayerElementTangent *layerElementTangent = FbxLayerElementTangent::Create(mesh, "");
  
  uvDiffuseLayer->SetMappingMode(FbxLayerElement::eByControlPoint);
  uvDiffuseLayer->SetReferenceMode(FbxLayerElement::eDirect);
  
  layerElementNormal->SetMappingMode(FbxLayerElement::eByControlPoint);
  layerElementNormal->SetReferenceMode(FbxLayerElement::eDirect);
  layerElementBinormal->SetMappingMode(FbxLayerElement::eByControlPoint);
  layerElementBinormal->SetReferenceMode(FbxLayerElement::eDirect);
  layerElementTangent->SetMappingMode(FbxLayerElement::eByControlPoint);
  layerElementTangent->SetReferenceMode(FbxLayerElement::eDirect);
  
  for (int vertIndex = 0; vertIndex < vertexCount; ++vertIndex)
  {
    GLKVector3 XAxis = vertices[vertIndex].binormal;
    GLKVector3 YAxis = vertices[vertIndex].tangent;
    GLKVector3 ZAxis = vertices[vertIndex].normal;
    
    layerElementNormal->GetDirectArray().Add(FbxVector4(ZAxis.x, -ZAxis.y, ZAxis.z));
    layerElementTangent->GetDirectArray().Add(FbxVector4(YAxis.x, -YAxis.y, YAxis.z));
    layerElementBinormal->GetDirectArray().Add(FbxVector4(-XAxis.x, XAxis.y, -XAxis.z));
    
    float u = vertices[vertIndex].uv[0].u;
    float v = vertices[vertIndex].uv[0].v;
    uvDiffuseLayer->GetDirectArray().Add(FbxVector2(u, -v + 1.f));
    
    /*
    if (vertices[vertIndex].numUVs)
    {
      u = vertices[vertIndex].uv[1].u;
      v = vertices[vertIndex].uv[1].v;
      uvLightMapLayer->GetDirectArray().Add(FbxVector2(u, -v + 1.f));
      hasLightMap = YES;
    }
     */
  }
  
  layer->SetNormals(layerElementNormal);
  layer->SetBinormals(layerElementBinormal);
  layer->SetTangents(layerElementTangent);
  layer->SetUVs(uvDiffuseLayer, FbxLayerElement::eTextureDiffuse);
  //if (hasLightMap)
  //  layer->SetUVs(uvLightMapLayer, FbxLayerElement::eTextureDiffuse);
  
  free(vertices);
  
  FbxLayerElementMaterial* matLayer = FbxLayerElementMaterial::Create(mesh, "");
  matLayer->SetMappingMode(FbxLayerElement::eByPolygon);
  matLayer->SetReferenceMode(FbxLayerElement::eIndexToDirect);
  layer->SetMaterials(matLayer);
  
  int *indices = NULL;
  indices = (int *)malloc(sizeof(int) * sourceModel.indexContainer.elementCount);
  
  if (sourceModel.indexContainer.elementSize == sizeof(short))
  {
    unsigned short *shortIndices = (unsigned short *)sourceModel.indexContainer.rawData;
    for (int idx = 0; idx < sourceModel.indexContainer.elementCount; idx++)
    {
      indices[idx] = (int)shortIndices[idx];
    }
  }
  else
  {
    memcpy(indices, sourceModel.indexContainer.rawData, sizeof(int) * sourceModel.indexContainer.elementCount);
  }
  
  int sectionCount = (int)sourceModel.sections.count;
  uvDiffuseLayer->GetIndexArray().SetCount(sourceModel.indexContainer.elementCount);
  for (int sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++)
  {
    
    FStaticMeshSection *section = sourceModel.sections[sectionIndex];
    int matIndex2 = section.material;
    int faceCount = section.faceCount;
    
    Material *gpkMaterial = [sourceModel.package objectForIndex:matIndex2];
    int matIndex = (int)[sourceModel.materials indexOfObject:gpkMaterial];
    NSString *mp = [gpkMaterial objectPath];
    if (_materials[mp])
    {
      FbxSurfaceMaterial *m = FBXMaterials[[_materials[mp][@"idx"] intValue]];
      node->AddMaterial(m);
    }
    else
    {
      
      NSString *matName = nil;
      if (matIndex != -1)
        matName = [sourceModel.materials[matIndex] objectName];
      FbxString name = "GpkMaterial";
      if (matName)
        name = [matName cStringUsingEncoding:NSASCIIStringEncoding];
      else
        name += matIndex+1;
      
      FbxSurfaceLambert *fbxMaterial = FbxSurfaceLambert::Create(pScene, name);
      fbxMaterial->ShadingModel.Set("Lambert");
      fbxMaterial->Diffuse.Set(FbxDouble3(0.72, 0.72, 0.72));
      node->AddMaterial(fbxMaterial);
    }
    
    for (int faceIndex = 0; faceIndex < faceCount; faceIndex++)
    {
      mesh->BeginPolygon(matIndex);
      for (int pointIndex = 0; pointIndex < 3; pointIndex++)
      {
        int vertIndex = indices[section.firstIndex + ((faceIndex * 3) + pointIndex)];
        mesh->AddPolygon(vertIndex);
      }
      mesh->EndPolygon();
    }
  }
  node->SetNodeAttribute(mesh);
  free(indices);
}

- (void)exportStaticMesh:(StaticMesh *)sMesh options:(NSDictionary *)expOptions
{
  InitializeSdkObjects(pSdkManager, pScene);
  if (!pSdkManager || !pScene)
  {
    NSAppError(sMesh.package, @"Error! Failed to export the model! View log for more information.");
    return;
  }
  
  FbxDocumentInfo* sceneInfo = FbxDocumentInfo::Create(pSdkManager,"SceneInfo");
  sceneInfo->mTitle = (const char *)[sMesh.objectName cStringUsingEncoding:NSASCIIStringEncoding];
  sceneInfo->mAuthor = "yupimods.tumblr.com";
  pScene->SetSceneInfo(sceneInfo);
  
  
  FbxNode *meshNode = NULL;
  [self exportStaticMesh:sMesh options:expOptions toFbxNode:&meshNode];
  if (!meshNode)
    return;
  
  pScene->GetRootNode()->AddChild(meshNode);
  
  NSString *p = expOptions[@"path"];
  const char *path = (const char *)[p cStringUsingEncoding:NSASCIIStringEncoding];
  [self saveSceneTo:path type:[expOptions[@"type"] intValue]];
}

- (void)exportSkeletalMesh:(SkeletalMesh *)skelMesh options:(NSDictionary *)expOptions toNode:(FbxNode **)meshNode
{
  int lodIdx = [expOptions[@"lodIdx"] intValue];
  FLodInfo *sourceModel = skelMesh.lodInfo[lodIdx];
  int vertexCount = sourceModel.vertexCount;
  
  FbxMesh *mesh = FbxMesh::Create(pScene,"geometry");
  FSoftVertex *vertices = [sourceModel vertices];
  
  mesh->InitControlPoints(vertexCount);
  FbxVector4 *controlPoints = mesh->GetControlPoints();
  
  for (int vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++)
  {
    GLKVector3 pos = vertices[vertexIndex].position;
    controlPoints[vertexIndex] = FbxVector4(pos.x,
                                            pos.y * -1.f,
                                            pos.z);
  }
  
  FbxLayer *layer = mesh->GetLayer(0);
  if (!layer)
  {
    mesh->CreateLayer();
    layer = mesh->GetLayer(0);
    if (!layer)
    {
      DLog(@"[%@]Failed to get mesh layer!", skelMesh.package.name);
      return;
    }
    
  }
  FbxLayerElementUV *uvDiffuseLayer = FbxLayerElementUV::Create(mesh, "DiffuseUV");
  FbxLayerElementNormal *layerElementNormal = FbxLayerElementNormal::Create(mesh, "");
  FbxLayerElementBinormal *layerElementBinormal = FbxLayerElementBinormal::Create(mesh, "");
  FbxLayerElementTangent *layerElementTangent = FbxLayerElementTangent::Create(mesh, "");
  
  uvDiffuseLayer->SetMappingMode(FbxLayerElement::eByControlPoint);
  uvDiffuseLayer->SetReferenceMode(FbxLayerElement::eDirect);
  layerElementNormal->SetMappingMode(FbxLayerElement::eByControlPoint);
  layerElementNormal->SetReferenceMode(FbxLayerElement::eDirect);
  layerElementBinormal->SetMappingMode(FbxLayerElement::eByControlPoint);
  layerElementBinormal->SetReferenceMode(FbxLayerElement::eDirect);
  layerElementTangent->SetMappingMode(FbxLayerElement::eByControlPoint);
  layerElementTangent->SetReferenceMode(FbxLayerElement::eDirect);
  
  for (int vertIndex = 0; vertIndex < vertexCount; ++vertIndex)
  {
    GLKVector3 XAxis = UnpackNormal(vertices[vertIndex].normal[0]);
    GLKVector3 YAxis = UnpackNormal(vertices[vertIndex].normal[1]);
    GLKVector3 ZAxis = UnpackNormal(vertices[vertIndex].normal[2]);
    
    layerElementNormal->GetDirectArray().Add(FbxVector4(ZAxis.x,-ZAxis.y,ZAxis.z));
    layerElementTangent->GetDirectArray().Add(FbxVector4(YAxis.x,-YAxis.y,YAxis.z));
    layerElementBinormal->GetDirectArray().Add(FbxVector4(-XAxis.x,XAxis.y,-XAxis.z));
    
    float u = vertices[vertIndex].uv.u;
    float v = vertices[vertIndex].uv.v;
    
    uvDiffuseLayer->GetDirectArray().Add(FbxVector2(u, -v + 1.f));
  }
  
  layer->SetNormals(layerElementNormal);
  layer->SetBinormals(layerElementBinormal);
  layer->SetTangents(layerElementTangent);
  layer->SetUVs(uvDiffuseLayer, FbxLayerElement::eTextureDiffuse);
  
  free(vertices);
  
  FbxLayerElementMaterial* matLayer = FbxLayerElementMaterial::Create(mesh, "");
  matLayer->SetMappingMode(FbxLayerElement::eByPolygon);
  matLayer->SetReferenceMode(FbxLayerElement::eIndexToDirect);
  layer->SetMaterials(matLayer);
  
  int *indices = NULL;
  indices = (int *)malloc(sizeof(int) * sourceModel.indexContainter.elementCount);
  
  if (sourceModel.indexContainter.elementSize == sizeof(short))
  {
    unsigned short *shortIndices = (unsigned short *)sourceModel.indexContainter.rawData;
    for (int idx = 0; idx < sourceModel.indexContainter.elementCount; idx++)
    {
      indices[idx] = (int)shortIndices[idx];
    }
  }
  else
  {
    memcpy(indices, sourceModel.indexContainter.rawData, sizeof(int) * sourceModel.indexContainter.elementCount);
  }
  
  int sectionCount = (int)sourceModel.sections.count;
  uvDiffuseLayer->GetIndexArray().SetCount(sourceModel.indexContainter.elementCount);
  for (int sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++)
  {
    
    FMeshSection *section = sourceModel.sections[sectionIndex];
    int matIndex = section.material;
    int faceCount = section.faceCount;
    
    for (int faceIndex = 0; faceIndex < faceCount; faceIndex++)
    {
      mesh->BeginPolygon(matIndex);
      for (int pointIndex = 0; pointIndex < 3; pointIndex++)
      {
        int vertIndex = indices[section.firstIndex + ((faceIndex * 3) + pointIndex)];
        mesh->AddPolygon(vertIndex);
      }
      mesh->EndPolygon();
    }
  }
  *meshNode = FbxNode::Create(pScene, (const char *)[skelMesh.objectName cStringUsingEncoding:NSASCIIStringEncoding]);
  
  FbxNode *node = *meshNode;
  
  node->SetNodeAttribute(mesh);
  free(indices);
  int materialCount = (int)skelMesh.materials.count;
  
  for (int materialIndex = 0; materialIndex < materialCount; materialIndex++)
  {
    NSString *mp = [skelMesh.materials[materialIndex] objectPath];
    if (_materials[mp])
    {
      FbxSurfaceMaterial *m = FBXMaterials[[_materials[mp][@"idx"] intValue]];
      node->AddMaterial(m);
    }
    else
    {
      NSString *matName = [skelMesh.materials[materialIndex] objectName];
      FbxString name = "GpkMaterial";
      if (matName)
        name = [matName cStringUsingEncoding:NSASCIIStringEncoding];
      else
        name += materialIndex+1;
      
      FbxSurfaceMaterial *fbxMaterial = FbxSurfaceLambert::Create(pScene, name);
      ((FbxSurfaceLambert *)fbxMaterial)->Diffuse.Set(FbxDouble3(0.72, 0.72, 0.72));
      node->AddMaterial(fbxMaterial);
    }
  }
  
  if (![expOptions[@"skeleton"] boolValue])
  {
    return;
  }
  
  FbxDynamicArray<FbxNode*> bonesArray;
  FbxNode *skelRootNode = createSkeleton(skelMesh, bonesArray, pScene, [expOptions[@"prefix"] boolValue]);
  pScene->GetRootNode()->AddChild(skelRootNode);
  
  
  FbxAMatrix MeshMatrix;
  MeshMatrix = node->EvaluateGlobalTransform();
  
  FbxGeometry *meshAttribute = (FbxGeometry *)mesh;
  FbxSkin *skin = FbxSkin::Create(pScene,"");
  
  int boneCount = (int)skelMesh.refSkeleton.count;
  for (int boneIndex = 0; boneIndex < boneCount; boneIndex++)
  {
    FbxNode *boneNode = bonesArray[boneIndex];
    
    FbxCluster *currentCluster = FbxCluster::Create(pScene, "");
    currentCluster->SetLink(boneNode);
    currentCluster->SetLinkMode(FbxCluster::eTotalOne);
    
    int vertIndex = 0;
    int chunkCount = (int)sourceModel.chunks.count;
    
    for(int chunkIndex = 0; chunkIndex < chunkCount; chunkIndex++)
    {
      
      FSkeletalMeshChunk *chunk = sourceModel.chunks[chunkIndex];
      
      for (int rigidIndex = 0; rigidIndex < chunk.rigidVerticiesCount; rigidIndex++)
      {
        
        const FRigidVertex *V = &chunk.rigidVerticies[rigidIndex];
        
        int influenceBone = chunk.boneMap[V->boneIndex];
        float influenceWeight = 1.f;
        
        if (influenceBone == boneIndex && influenceWeight > 0.f)
          currentCluster->AddControlPointIndex(vertIndex, influenceWeight);
        
        ++vertIndex;
      }
      
      for (int softIndex = 0; softIndex < chunk.softVerticiesCount; softIndex++)
      {
        
        const FSoftVertex *V = &chunk.softVerticies[softIndex];
        
        for (int influenceIndex = 0; influenceIndex < 4; influenceIndex++)
        {
          
          int influenceBone = chunk.boneMap[V->boneIndex[influenceIndex]];
          float w = (float)V->boneWeight[influenceIndex];
          float influenceWeight = w / 255.0f;
          
          if (influenceBone == boneIndex && influenceWeight > 0.f)
            currentCluster->AddControlPointIndex(vertIndex, influenceWeight);
        }
        ++vertIndex;
      }
    }
    
    currentCluster->SetTransformMatrix(MeshMatrix);
    
    FbxAMatrix linkMatrix = boneNode->EvaluateGlobalTransform();
    currentCluster->SetTransformLinkMatrix(linkMatrix);
    skin->AddCluster(currentCluster);
  }
  
  meshAttribute->AddDeformer(skin);
  CreateBindPose(node, pScene);
}

- (void)exportLevel:(Level *)level options:(NSDictionary *)expOptions
{
  BOOL __unused loadFExports = [expOptions[@"FExports"] boolValue];
  BOOL __unused exportTextures = [expOptions[@"textures"] boolValue];
  BOOL __unused loadFExportTextures = [expOptions[@"FExportTextures"] boolValue];
  
  InitializeSdkObjects(pSdkManager, pScene);
  if (!pSdkManager || !pScene)
  {
    DLog(@"[%@]Error! Failed to export the model!", level.package.name);
    return;
  }
  textures = [NSMutableArray new];
  _materials = [NSMutableDictionary new];
  FBXMaterials = FbxDynamicArray<FbxSurfaceMaterial*>();
  FbxDocumentInfo* sceneInfo = FbxDocumentInfo::Create(pSdkManager, "SceneInfo");
  sceneInfo->mTitle = (const char *)[level.objectName cStringUsingEncoding:NSASCIIStringEncoding];
  sceneInfo->mAuthor = "yupimods.tumblr.com";
  pScene->SetSceneInfo(sceneInfo);
  
  for (Actor *actor in level.actors)
  {
    if (![actor isKindOfClass:[Actor class]])
      continue;
    
    MeshComponent *stComponent = (MeshComponent *)[actor component];
    if (![stComponent isKindOfClass:[MeshComponent class]])
      continue;
    id mesh = [stComponent mesh];
    if (!mesh)
      continue;
    
    NSArray *objectMaterials = [mesh materials];
    for (Material *m in objectMaterials)
    {
      if (!_materials[m.objectPath])
      {
        Texture2D *t = [m diffuseMap];
        if (t)
        {
          [textures addObject:t];
        }
        
        FbxSurfaceMaterial *lMaterial = FbxSurfaceLambert::Create(pScene, [m.objectName UTF8String]);
        ((FbxSurfaceLambert *)lMaterial)->Diffuse.Set(FbxDouble3(0.72, 0.72, 0.72));
        FBXMaterials.PushBack(lMaterial);
        
        if (t)
          _materials[m.objectPath] = @{@"idx" : @(FBXMaterials.Size() - 1), @"tex" : t};
        else
        {
          NSColor *c = [m diffuseColor];
          if (c)
            _materials[m.objectPath] = @{@"idx" : @(FBXMaterials.Size() - 1), @"tex" : c};
          else
            _materials[m.objectPath] = @{@"idx" : @(FBXMaterials.Size() - 1)};
        }
        
      }
    }
  }
  
  for (Actor *actor in level.actors)
  {
    FbxNode *actorNode = NULL;
    
    if (![actor isKindOfClass:[Actor class]])
      continue;
    
    MeshComponent *stComponent = (MeshComponent *)[actor component];
    if (![stComponent isKindOfClass:[MeshComponent class]])
      continue;
    id mesh = [stComponent mesh];
    if (!mesh)
      continue;
    
    if ([stComponent isKindOfClass:[SkeletalMeshComponent class]])
      [self exportSkeletalMesh:mesh options:NULL toNode:&actorNode];
    else
      [self exportStaticMesh:mesh options:NULL toFbxNode:&actorNode];
    
    if (actorNode)
    {
      
      GLKVector3 v = [actor absolutePostion];
      actorNode->LclTranslation.Set(FbxDouble3(v.x * RelScale, -v.y * RelScale, v.z * RelScale));
      v = [actor absoluteDrawScale3D];
      v = GLKVector3MultiplyScalar(v, [actor absoluteDrawScale]);
      actorNode->LclScaling.Set(FbxDouble3(v.x * RelScale, v.y * RelScale, v.z * RelScale));
      v = [actor absoluteRotation];
      actorNode->LclRotation.Set(FbxDouble3(v.x, -v.y, -v.z));
      
      pScene->GetRootNode()->AddChild(actorNode);
    }
  }
  
  NSString *p = expOptions[@"path"];
  NSString *texPath = [p stringByDeletingLastPathComponent];
  for (Texture2D *t in textures)
  {
    DLog(@"Exporting %@",[t objectName]);
    NSImage *i = [t forceExportedRenderedImageR:YES G:YES B:YES A:YES invert:NO];
    [[[i unscaledBitmapImageRep] representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:[texPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",[t objectName]]] atomically:NO];
  }
  
  for (NSString *k in _materials)
  {
    FbxSurfaceMaterial *lMaterial = FBXMaterials[[_materials[k][@"idx"] intValue]];
    Texture2D *t = _materials[k][@"tex"];
    if (!t)
      continue;
    
    if ([t isKindOfClass:[NSColor class]])
    {
      NSColor *c = (NSColor *)t;
      ((FbxSurfaceLambert *)lMaterial)->Diffuse.Set(FbxVector4(c.redComponent, c.greenComponent, c.blueComponent));
      continue;
    }
    
    FbxFileTexture* lTexture = nil;
    NSString *fName = [[t objectName] stringByAppendingString:@".png"];
    lTexture = FbxFileTexture::Create(pScene,[[t objectName] UTF8String]);;
    lTexture->SetFileName([fName UTF8String]); // Resource file is in current directory.
    lTexture->SetTextureUse(FbxTexture::eStandard);
    lTexture->SetMappingType(FbxTexture::eUV);
    lTexture->SetMaterialUse(FbxFileTexture::eModelMaterial);
    lTexture->SetSwapUV(false);
    lTexture->SetTranslation(0.0, 0.0);
    lTexture->SetScale(1.0, 1.0);
    lTexture->SetRotation(0.0, 0.0);
    ((FbxSurfaceLambert *)lMaterial)->Diffuse.ConnectSrcObject(lTexture);
    DLog(@"Mat: %@ Tex: %@",k,[t objectName]);
  }
  
  const char *path = (const char *)[p cStringUsingEncoding:NSASCIIStringEncoding];
  [self saveSceneTo:path type:[expOptions[@"type"] intValue]];
}

- (void)exportSkeletalMesh:(SkeletalMesh *)skelMesh options:(NSDictionary *)expOptions
{
  InitializeSdkObjects(pSdkManager, pScene);
  if (!pSdkManager || !pScene)
  {
    NSAppError(skelMesh.package, @"Error! Failed to export the model!");
    return;
  }
  
  FbxDocumentInfo* sceneInfo = FbxDocumentInfo::Create(pSdkManager, "SceneInfo");
  sceneInfo->mTitle = (const char *)[skelMesh.objectName cStringUsingEncoding:NSASCIIStringEncoding];
  sceneInfo->mAuthor = "yupimods.tumblr.com";
  pScene->SetSceneInfo(sceneInfo);
  
  FbxNode *meshNode = NULL;
  [self exportSkeletalMesh:skelMesh options:expOptions toNode:&meshNode];
  if (!meshNode)
    return;
  
  pScene->GetRootNode()->AddChild(meshNode);
  
  NSString *p = expOptions[@"path"];
  const char *path = (const char *)[p cStringUsingEncoding:NSASCIIStringEncoding];
  [self saveSceneTo:path type:[expOptions[@"type"] intValue]];
}

// TODO: cleanup
- (RawImportData *)importLodFromURL:(NSURL *)url forSkeletalMesh:(SkeletalMesh *)skelMesh options:(NSDictionary *)opts error:(NSString **)error
{
  InitializeSdkObjects(pSdkManager, pScene);
  const char *path = (const char *)[[url path] cStringUsingEncoding:NSASCIIStringEncoding];
  
  if (!LoadScene(pSdkManager, pScene, path))
  {
    if (error)
      *error = [NSString stringWithFormat:@"Error! Failed to open file '%@'", [url lastPathComponent]];
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  
  FbxAxisSystem::EFrontVector FrontVector = (FbxAxisSystem::EFrontVector)-FbxAxisSystem::eParityOdd;
  const FbxAxisSystem UnrealZUp(FbxAxisSystem::eZAxis, FrontVector, FbxAxisSystem::eRightHanded);
  UnrealZUp.ConvertScene(pScene);
  
  FbxSkeleton *skel = NULL;
  FbxNode *meshNode = NULL;
  FbxMesh *mesh = NULL;
  
  for(int i = 0; i< pScene->GetNodeCount(); i++)
  {
    
    FbxNode *node = pScene->GetNode(i);
    if (node->GetSkeleton())
    {
      skel = node->GetSkeleton();
      if (mesh && meshNode)
        break;
    }
    if (node->GetMesh() && node->GetMesh()->GetDeformerCount(FbxDeformer::eSkin))
    {
      meshNode = node;
      mesh = meshNode->GetMesh();
      if (skel)
        break;
    }
  }
  
  if (!skel)
  {
    if (error)
      *error = @"Error! Can't find skeleton!";
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  if (!mesh)
  {
    if (error)
      *error = @"Error! The scene has no geometry!";
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  
  if (!mesh->IsTriangleMesh())
  {
    if (error)
      *error = @"Error! Mesh is not triangulated!";
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  
  FbxDynamicArray<FbxCluster *> clusterArray = FbxDynamicArray<FbxCluster *>();
  FbxDynamicArray<FbxSurfaceMaterial*> fbxMaterials = FbxDynamicArray<FbxSurfaceMaterial*>();
  FbxDynamicArray<VMaterial> materials = FbxDynamicArray<VMaterial>();
  NSMutableArray *mats = [NSMutableArray array];
  
  for(int deformerIndex = 0; deformerIndex < mesh->GetDeformerCount(FbxDeformer::eSkin);deformerIndex++)
  {
    FbxSkin *skin = (FbxSkin *)mesh->GetDeformer(deformerIndex);
    if (skin->GetSkinningType() != fbxsdk::FbxSkin::eLinear && skin->GetSkinningType() != fbxsdk::FbxSkin::eRigid)
    {
      DestroySdkObjects(pSdkManager, 0);
      if (error)
        *error = @"Error! Model uses unsupported skin type!";
      return nil;
    }
    for (int clusterIndex = 0; clusterIndex < skin->GetClusterCount(); clusterIndex++)
    {
      clusterArray.PushBack(skin->GetCluster(clusterIndex));
    }
  }
  for (int i = 0; i < meshNode->GetMaterialCount(); i++)
  {
    FbxSurfaceMaterial *mat = meshNode->GetMaterial(i);
    if (fbxMaterials.Find(mat) == -1)
    {
      fbxMaterials.PushBack(mat);
      VMaterial vmat;
      vmat.MaterialImportName = mat->GetName();
      vmat.MaterialIndex = (int)fbxMaterials.Size()-1;
      [mats addObject:[NSString stringWithCString:mat->GetName() encoding:NSASCIIStringEncoding]];
      materials.PushBack(vmat);
    }
  }
  
  if (!clusterArray.Size())
  {
    if (error)
      *error = @"Error! Model has no skin!";
    
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  
  if (!materials.Size())
  {
    if (error)
      *error = @"Error! Model doesn't have assigned materials!";
    
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  
  FbxDynamicArray<FbxNode *>sortedLinks = FbxDynamicArray<FbxNode*>();
  BuildSkeletonSystem(clusterArray, sortedLinks, pScene);
  FbxDynamicArray<FbxAMatrix>globalsPerLink = FbxDynamicArray<FbxAMatrix>();
  
  if (sortedLinks.Size() > 128)
  {
    if (error)
      *error = @"Error! Too many bones! Maximum: 128";
    DestroySdkObjects(pSdkManager, 0);
    return nil;
  }
  
  for(int i = 0; i < sortedLinks.Size();i++)
  {
    globalsPerLink.PushBack(FbxAMatrix());
  }
  globalsPerLink[0].SetIdentity();
  
  BOOL globalLinkFoundFlag;
  BOOL nonIdentityScaleFound = NO;
  FbxVector4 localLinkT;
  FbxQuaternion localLinkQ;
  FbxNode *link = NULL;
  NSMutableArray *refBones = [NSMutableArray new];
  for(int linkIndex = 0;linkIndex<sortedLinks.Size();linkIndex++)
  {
    link = sortedLinks[linkIndex];
    [refBones addObject:[FMeshBone newWithPackage:skelMesh.package]];
    int parentIndex = 0;
    
    FbxNode *parent = link->GetParent();
    if (linkIndex)
    {
      for(int ll = 0;ll < linkIndex; ll++)
      {
        FbxNode *otherLink = sortedLinks[ll];
        if (otherLink == parent)
        {
          parentIndex = ll;
          break;
        }
      }
    }
    
    globalLinkFoundFlag = NO;
    
    if (!globalLinkFoundFlag)
    {
      for (int ClusterIndex=0; ClusterIndex<clusterArray.Size(); ClusterIndex++)
      {
        FbxCluster* Cluster = clusterArray[ClusterIndex];
        if (link == Cluster->GetLink())
        {
          Cluster->GetTransformLinkMatrix(globalsPerLink[linkIndex]);
          globalLinkFoundFlag = TRUE;
          break;
        }
      }
    }
    if (!globalLinkFoundFlag)
    {
      // if root bone is not in bindpose and cluster, it is correct to use the local matrix as global matrix
      FbxDouble3 R = link->LclRotation.Get();
      FbxAMatrix LocalMatrix;
      LocalMatrix.SetR(R);
      FbxAMatrix PostRotationMatrix, PreRotationMatrix;
      FbxVector4 PostRotation, PreRotation;
      PreRotation = link->GetPreRotation(FbxNode::eSourcePivot);
      PostRotation = link->GetPostRotation(FbxNode::eSourcePivot);
      PreRotationMatrix.SetR(PreRotation);
      PostRotationMatrix.SetR(PostRotation);
      
      LocalMatrix = PreRotationMatrix * LocalMatrix * PostRotationMatrix;
      
      localLinkT = link->LclTranslation.Get();
      // bake the rotate pivot to translation
      FbxVector4 RotatePivot = link->GetRotationPivot(FbxNode::eSourcePivot);
      localLinkT[0] += RotatePivot[0];
      localLinkT[1] += RotatePivot[1];
      localLinkT[2] += RotatePivot[2];
      localLinkQ = LocalMatrix.GetQ();
      
      // if this skeleton has no cluster, its children may have cluster, so still need to set the Globals matrix
      LocalMatrix.SetT(localLinkT);
      LocalMatrix.SetS(link->LclScaling.Get());
      globalsPerLink[linkIndex] = globalsPerLink[parentIndex] * LocalMatrix;
    }
    if (linkIndex)
    {
      FbxAMatrix	Matrix;
      Matrix = globalsPerLink[parentIndex].Inverse() * globalsPerLink[linkIndex];
      localLinkT = Matrix.GetT();
      localLinkQ = Matrix.GetQ();
    }
    else	// skeleton root
    {
      // for root, this is global coordinate
      localLinkT = globalsPerLink[linkIndex].GetT();
      localLinkQ = globalsPerLink[linkIndex].GetQ();
    }
    float SCALE_TOLERANCE = .1f;
    FbxVector4 GlobalLinkS = globalsPerLink[linkIndex].GetS();
    if ((GlobalLinkS[0] > 1.0 + SCALE_TOLERANCE || GlobalLinkS[1] < 1.0 - SCALE_TOLERANCE) ||
        (GlobalLinkS[0] > 1.0 + SCALE_TOLERANCE || GlobalLinkS[1] < 1.0 - SCALE_TOLERANCE) ||
        (GlobalLinkS[0] > 1.0 + SCALE_TOLERANCE || GlobalLinkS[1] < 1.0 - SCALE_TOLERANCE) )
    {
      nonIdentityScaleFound = TRUE;
    }
    
    FMeshBone *bone = refBones[linkIndex];
    
    NSString *boneName = nil;
    NSString *tName = [NSString stringWithCString:link->GetName() encoding:NSASCIIStringEncoding];
    tName = [[tName componentsSeparatedByString:@":"] lastObject];
    
    if ([opts[@"skel"] boolValue])
    {
      if ([tName hasPrefix:@"idx_"])
      {
        NSArray *comps = [tName componentsSeparatedByString:@"__"];
        boneName = comps[1];
        bone.nameIdx = (long)[skelMesh.package indexForName:boneName];
      }
      else
      {
        bone.nameIdx = (long)[skelMesh.package indexForName:tName];
      }
    }
    else
    {
      if ([tName hasPrefix:@"idx_"])
      {
        
        if (![opts[@"prfx"] boolValue])
        {
          int refIdx = 0;
          NSArray *comps = [tName componentsSeparatedByString:@"_"];
          refIdx = [comps[1] intValue] + 1;
          bone.nameIdx = refIdx * -1;
        }
        else
        {
          NSArray *comps = [tName componentsSeparatedByString:@"__"];
          boneName = comps[1];
          bone.nameIdx = (long)[skelMesh.package indexForName:boneName];
          if (bone.nameIdx == INT32_MAX)
          {
            DLog(@"Warning! Failed to find bone name: %s", link->GetName());
          }
        }
        
        
      }
      else
      {
        boneName = [[tName componentsSeparatedByString:@":"] lastObject];
        
        bone.nameIdx = (long)[skelMesh.package indexForName:boneName];
        if (bone.nameIdx == INT32_MAX)
        {
          DLog(@"Warning! Failed to find bone name: %s", link->GetName());
        }
      }
    }
    
    
    bone.parentIdx = parentIndex;
    bone.childrenCnt = 0;
    
    for(int childIndex = 0; childIndex < link->GetChildCount();childIndex++)
    {
      FbxNode *child = link->GetChild(childIndex);
      if (IsUnrealBone(child))
        bone.childrenCnt++;
    }
    
    float v;
    v = static_cast<float>(localLinkT.mData[0]);
    bone.position.x = v;
    v = static_cast<float>(localLinkT.mData[1]) * -1.f;
    bone.position.y = v;
    v = static_cast<float>(localLinkT.mData[2]);
    bone.position.z = v;
    
    
    v = static_cast<float>(localLinkQ.mData[0]);
    if (linkIndex)
      v *= -1.f;
    bone.orientation.x = v;
    
    v = static_cast<float>(localLinkQ.mData[1]);
    if (!linkIndex)
      v *= -1.f;
    bone.orientation.y = v;
    
    v = static_cast<float>(localLinkQ.mData[2]);
    if (linkIndex)
      v *= -1.f;
    bone.orientation.z = v;
    
    v = static_cast<float>(localLinkQ.mData[3]);
    bone.orientation.w = v;
    
    bone.unk = 0xFFFFFFFF;
  }
  
  FbxLayer *baseLayer = mesh->GetLayer(0);
  FbxSkin *skin = (FbxSkin*)static_cast<FbxGeometry*>(mesh)->GetDeformer(0, FbxDeformer::eSkin);
  
  NSMutableArray *UVSets = [NSMutableArray array];
  if (mesh->GetLayerCount() > 0)
  {
    int UVLayerIndex;
    for (UVLayerIndex = 0; UVLayerIndex<mesh->GetLayerCount(); UVLayerIndex++)
    {
      FbxLayer* lLayer = mesh->GetLayer(UVLayerIndex);
      int UVSetCount = lLayer->GetUVSetCount();
      if(UVSetCount)
      {
        FbxArray<FbxLayerElementUV const*> EleUVs = lLayer->GetUVSets();
        for (int UVIndex = 0; UVIndex<UVSetCount; UVIndex++)
        {
          FbxLayerElementUV const* ElementUV = EleUVs[UVIndex];
          if (ElementUV)
          {
            FbxString localuv = FbxString( ElementUV->GetName());
            bool f = NO;
            for (int i = 0; i < UVSets.count; i++)
            {
              if (!strcmp(localuv.Buffer(), [UVSets[i] cStringUsingEncoding:NSASCIIStringEncoding]))
              {
                f = YES;
                break;
              }
            }
            if (!f)
            {
              [UVSets addObject:[NSString stringWithCString:ElementUV->GetName() encoding:NSASCIIStringEncoding]];
            }
          }
        }
      }
    }
  }
  
  RawImportData *importData = [RawImportData new];
  
  int controlPointsCount = mesh->GetControlPointsCount();
  uint32 UniqueUVCount = (uint32)UVSets.count;
  FbxLayerElementUV** LayerElementUV = NULL;
  FbxLayerElement::EReferenceMode* UVReferenceMode = NULL;
  FbxLayerElement::EMappingMode* UVMappingMode = NULL;
  if (UniqueUVCount > 0)
  {
    LayerElementUV = new FbxLayerElementUV*[UniqueUVCount];
    UVReferenceMode = new FbxLayerElement::EReferenceMode[UniqueUVCount];
    UVMappingMode = new FbxLayerElement::EMappingMode[UniqueUVCount];
  }
  
  int LayerCount = mesh->GetLayerCount();
  for (uint32 UVIndex = 0; UVIndex < UniqueUVCount; UVIndex++)
  {
    LayerElementUV[UVIndex] = NULL;
    for (int UVLayerIndex = 0; UVLayerIndex<LayerCount; UVLayerIndex++)
    {
      FbxLayer* lLayer = mesh->GetLayer(UVLayerIndex);
      int UVSetCount = lLayer->GetUVSetCount();
      if(UVSetCount)
      {
        FbxArray<FbxLayerElementUV const*> EleUVs = lLayer->GetUVSets();
        for (int FbxUVIndex = 0; FbxUVIndex<UVSetCount; FbxUVIndex++)
        {
          FbxLayerElementUV const* ElementUV = EleUVs[FbxUVIndex];
          if (ElementUV)
          {
            const char* UVSetName = ElementUV->GetName();
            FbxString LocalUVSetName = FbxString(UVSetName);
            
            if (!LocalUVSetName.Compare([UVSets[UVIndex] cStringUsingEncoding:NSASCIIStringEncoding]))
            {
              LayerElementUV[UVIndex] = const_cast<FbxLayerElementUV*>(ElementUV);
              UVReferenceMode[UVIndex] = LayerElementUV[FbxUVIndex]->GetReferenceMode();
              UVMappingMode[UVIndex] = LayerElementUV[FbxUVIndex]->GetMappingMode();
              break;
            }
          }
        }
      }
    }
  }
  FbxLayerElementMaterial* LayerElementMaterial = baseLayer->GetMaterials();
  FbxLayerElement::EMappingMode MaterialMappingMode = LayerElementMaterial ?
  LayerElementMaterial->GetMappingMode() : FbxLayerElement::eByPolygon;
  
  UniqueUVCount = MIN(UniqueUVCount, 4);
  
  if (UniqueUVCount > 1)
  {
    if (*error)
      *error = @"Warning! There are more than 1 UV sets!";
  }
  
  FbxAMatrix TotalMatrix;
  FbxAMatrix TotalMatrixForNormal;
  TotalMatrix = ComputeTotalMatrix(meshNode, pScene);
  TotalMatrixForNormal = TotalMatrix.Inverse();
  TotalMatrixForNormal = TotalMatrixForNormal.Transpose();
  
  FbxLayerElementNormal* layerElementNormal = baseLayer->GetNormals();
  FbxLayerElementTangent* layerElementTangent = baseLayer->GetTangents();
  FbxLayerElementBinormal* layerElementBinormal = baseLayer->GetBinormals();
  FbxLayerElement::EReferenceMode normalReferenceMode(FbxLayerElement::eDirect);
  FbxLayerElement::EMappingMode normalMappingMode(FbxLayerElement::eByControlPoint);
  FbxLayerElement::EReferenceMode tangentReferenceMode(FbxLayerElement::eDirect);
  FbxLayerElement::EMappingMode tangentMappingMode(FbxLayerElement::eByControlPoint);
  
  if (layerElementNormal)
  {
    normalReferenceMode = layerElementNormal->GetReferenceMode();
    normalMappingMode = layerElementNormal->GetMappingMode();
  }
  
  if (layerElementTangent)
  {
    tangentReferenceMode = layerElementTangent->GetReferenceMode();
    tangentMappingMode = layerElementTangent->GetMappingMode();
  }
  
  bool bHasNormalInformation = layerElementNormal != NULL;
  bool bHasTangentInformation = layerElementTangent != NULL && layerElementBinormal != NULL;
  if (!bHasNormalInformation)
  {
    if (error)
      *error = @"Warning! The mesh has no normals!";
  }
  FbxDynamicArray<FbxVector4> points = FbxDynamicArray<FbxVector4>();
  for (int controlPointIndex = 0; controlPointIndex < controlPointsCount; controlPointIndex++)
  {
    FbxVector4 pos = mesh->GetControlPoints()[controlPointIndex];
    pos = TotalMatrix.MultT(pos);
    pos.mData[1] = static_cast<float>(pos.mData[1]) * -1.f;
    points.PushBack(pos);
  }
  
  BOOL oddNegativeScale = IsOddNegativeScale(TotalMatrix);
  
  int maxMaterialIndex = 0;
  int triangleCount = mesh->GetPolygonCount();
  VTriangle *faces = (VTriangle *)malloc(sizeof(VTriangle) * triangleCount);
  FbxDynamicArray<VVertex> wedges = FbxDynamicArray<VVertex>();
  VVertex tmpWedges[3];
  for (int triangleIndex = 0; triangleIndex < triangleCount; triangleIndex++)
  {
    VTriangle &triangle = faces[triangleIndex];
    
    for (int vertexIndex = 0; vertexIndex < 3; vertexIndex++)
    {
      int unrealVertexIndex = oddNegativeScale ? 2 - vertexIndex : vertexIndex;
      int controlPointIndex = mesh->GetPolygonVertex(triangleIndex, vertexIndex);
      
      if (bHasNormalInformation)
      {
        int tmpIndex = triangleIndex * 3 + vertexIndex;
        
        int normalMapIndex = (normalMappingMode == FbxLayerElement::eByControlPoint) ? controlPointIndex : tmpIndex;
        int normalValueIndex = (normalReferenceMode == FbxLayerElement::eDirect) ? normalMapIndex : layerElementNormal->GetIndexArray().GetAt(normalMapIndex);
        int tangentMapIndex = tmpIndex;
        
        FbxVector4 tempValue;
        
        // Normal
        
        tempValue = layerElementNormal->GetDirectArray().GetAt(normalValueIndex);
        tempValue = TotalMatrixForNormal.MultT(tempValue);
        
        float v = static_cast<float>(tempValue.mData[1]); // y -> -y
        tempValue.mData[1] = -v;
        
        NormalizeVector(&tempValue);
        
        v = static_cast<float>(tempValue.mData[0]);
        triangle.TangentZ[unrealVertexIndex].x = v;
        
        v = static_cast<float>(tempValue.mData[1]);
        triangle.TangentZ[unrealVertexIndex].y = v;
        
        v = static_cast<float>(tempValue.mData[2]);
        triangle.TangentZ[unrealVertexIndex].z = v;
        
        
        if (bHasTangentInformation && [opts[@"impTan"] boolValue])
        {
          tempValue = layerElementTangent->GetDirectArray().GetAt(tangentMapIndex);
          tempValue = TotalMatrixForNormal.MultT(tempValue);
          
          float v = static_cast<float>(tempValue.mData[1]); // y -> -y
          tempValue.mData[1] = -v;
          
          NormalizeVector(&tempValue);
          
          v = static_cast<float>(tempValue.mData[0]);
          triangle.TangentX[unrealVertexIndex].x = v;
          
          v = static_cast<float>(tempValue.mData[1]);
          triangle.TangentX[unrealVertexIndex].y = v;
          
          v = static_cast<float>(tempValue.mData[2]);
          triangle.TangentX[unrealVertexIndex].z = v;
          
          GLKVector3 tangent = GLKVector3Make(triangle.TangentX[unrealVertexIndex].x, triangle.TangentX[unrealVertexIndex].y, triangle.TangentX[unrealVertexIndex].z);
          GLKVector3 normal = GLKVector3Make(triangle.TangentZ[unrealVertexIndex].x, triangle.TangentZ[unrealVertexIndex].y, triangle.TangentZ[unrealVertexIndex].z);
          GLKVector3 binormal = GLKVector3CrossProduct(tangent, normal);
          
          tempValue.mData[0] = binormal.x;
          tempValue.mData[1] = binormal.y;
          tempValue.mData[2] = -binormal.z;
          
          NormalizeVector(&tempValue);
          
          v = static_cast<float>(tempValue.mData[0]);
          triangle.TangentY[unrealVertexIndex].x = v;
          
          v = static_cast<float>(tempValue.mData[1]);
          triangle.TangentY[unrealVertexIndex].y = v;
          
          v = static_cast<float>(tempValue.mData[2]);
          triangle.TangentY[unrealVertexIndex].z = v;
        }
      }
      else
      {
        triangle.TangentZ[unrealVertexIndex].x = 0;
        triangle.TangentZ[unrealVertexIndex].y = 0;
        triangle.TangentZ[unrealVertexIndex].z = 0;
        triangle.TangentY[unrealVertexIndex].x = 0;
        triangle.TangentY[unrealVertexIndex].y = 0;
        triangle.TangentY[unrealVertexIndex].z = 0;
        triangle.TangentX[unrealVertexIndex].x = 0;
        triangle.TangentX[unrealVertexIndex].y = 0;
        triangle.TangentX[unrealVertexIndex].z = 0;
      }
    }
    
    triangle.MatIndex = 0;
    for(int vertexIndex = 0; vertexIndex < 3; vertexIndex++)
    {
      if (LayerElementMaterial)
      {
        switch(MaterialMappingMode)
        {
          case FbxLayerElement::eAllSame:
          {
            triangle.MatIndex = materials[LayerElementMaterial->GetIndexArray().GetAt(0)].MaterialIndex;
          }break;
          case FbxLayerElement::eByPolygon:
          {
            int Index = LayerElementMaterial->GetIndexArray().GetAt(triangleIndex);
            triangle.MatIndex = materials[Index].MaterialIndex;
          }break;
          default:
            break;
        }
      }
    }
    maxMaterialIndex = MAX(maxMaterialIndex, triangle.MatIndex);
    
    for(int vertexIndex = 0; vertexIndex < 3; vertexIndex++)
    {
      int unrealVertexIndex = oddNegativeScale ? 2 - vertexIndex : vertexIndex;
      tmpWedges[unrealVertexIndex].MatIndex = triangle.MatIndex;
      tmpWedges[unrealVertexIndex].VertexIndex = mesh->GetPolygonVertex(triangleIndex, vertexIndex);
    }
    
    uint32 UVLayerIndex;
    BOOL hasUVs = NO;
    for ( UVLayerIndex = 0; UVLayerIndex< UniqueUVCount; UVLayerIndex++ )
    {
      if (LayerElementUV[UVLayerIndex] != NULL)
      {
        // Get each UV from the layer
        for (int VertexIndex=0;VertexIndex<3;VertexIndex++)
        {
          // If there are odd number negative scale, invert the vertex order for triangles
          int UnrealVertexIndex = oddNegativeScale ? 2 - VertexIndex : VertexIndex;
          int lControlPointIndex = mesh->GetPolygonVertex(triangleIndex, VertexIndex);
          int UVMapIndex = (UVMappingMode[UVLayerIndex] == FbxLayerElement::eByControlPoint) ? lControlPointIndex : triangleIndex*3+VertexIndex;
          int UVIndex = (UVReferenceMode[UVLayerIndex] == FbxLayerElement::eDirect) ? UVMapIndex : LayerElementUV[UVLayerIndex]->GetIndexArray().GetAt(UVMapIndex);
          FbxVector2	UVVector = LayerElementUV[UVLayerIndex]->GetDirectArray().GetAt(UVIndex);
          
          tmpWedges[UnrealVertexIndex].UVs[ UVLayerIndex ].x = static_cast<float>(UVVector.mData[0]);
          tmpWedges[UnrealVertexIndex].UVs[ UVLayerIndex ].y = 1.f - static_cast<float>(UVVector.mData[1]);
          
          if (!hasUVs && (UVVector.mData[0] || UVVector.mData[1]))
            hasUVs = YES;
        }
      }
      else if( UVLayerIndex == 0 )
      {
        // Set all UV's to zero.  If we are here the mesh had no UV sets so we only need to do this for the
        // first UV set which always exists.
        DLog(@"Warning! No UVs!");
        for (int VertexIndex=0; VertexIndex<3; VertexIndex++)
        {
          tmpWedges[VertexIndex].UVs[UVLayerIndex].x = 0.0f;
          tmpWedges[VertexIndex].UVs[UVLayerIndex].y = 0.0f;
        }
      }
    }
    
    if (!hasUVs)
    {
      if (error)
        *error = @"Error! All surfaces must have a UV set!";
      DestroySdkObjects(pSdkManager, 0);
      free(faces);
      return nil;
    }
    
    for (int vertexIndex = 0; vertexIndex < 3; vertexIndex++)
    {
      VVertex wedge;
      wedge.VertexIndex = tmpWedges[vertexIndex].VertexIndex;
      wedge.MatIndex = tmpWedges[vertexIndex].MatIndex;
      wedge.Reserved = 0;
      memcpy(wedge.UVs, tmpWedges[vertexIndex].UVs, sizeof(GLKVector2) * 4);
      wedges.PushBack(wedge);
      triangle.WedgeIndex[vertexIndex] = (int)wedges.Size() - 1;
    }
  }
  // weights
  FbxArray<FVertInfluence> influences = FbxArray<FVertInfluence>();
  if (skin)
  {
    int clusterIndex;
    for (clusterIndex = 0; clusterIndex < skin->GetClusterCount(); clusterIndex++)
    {
      FbxCluster *cluster = skin->GetCluster(clusterIndex);
      
      // When Maya plug-in exports rigid binding, it will generate "CompensationCluster" for each ancestor links.
      // FBX writes these "CompensationCluster" out. The CompensationCluster also has weight 1 for vertices.
      // Unreal importer should skip these clusters.
      if (strcmp(cluster->GetUserDataID(), "Maya_ClusterHint")==0 || strcmp(cluster->GetUserDataID(), "CompensationCluster")==0)
      {
        continue;
      }
      
      FbxNode *link = cluster->GetLink();
      int boneIndex = -1;
      for (int linkIndex = 0; linkIndex < sortedLinks.Size(); linkIndex++)
      {
        if (link == sortedLinks[linkIndex])
        {
          boneIndex = linkIndex;
          break;
        }
      }
      int controlPointIndicesCount = cluster->GetControlPointIndicesCount();
      int *controlPointIndices = cluster->GetControlPointIndices();
      double *weights = cluster->GetControlPointWeights();
      
      for (int controlPointIndex = 0; controlPointIndex < controlPointIndicesCount; controlPointIndex++)
      {
        FVertInfluence influence;
        influence.BoneIndex = boneIndex;
        influence.Weight = static_cast<float>(weights[controlPointIndex]);
        influence.VertIndex = controlPointIndices[controlPointIndex];
        influences.Add(influence);
      }
    }
  }
  else
  {
    // Rigid mesh
    int boneIndex = -1;
    for (int linkIndex = 0; linkIndex < sortedLinks.Size(); linkIndex++)
    {
      if (meshNode == sortedLinks[linkIndex])
      {
        boneIndex = linkIndex;
        break;
      }
    }
    for (int controlPointIndex = 0; controlPointIndex < controlPointsCount; controlPointIndex++)
    {
      FVertInfluence influence;
      influence.BoneIndex = boneIndex;
      influence.Weight = 1.0;
      influence.VertIndex = controlPointIndex;
      influences.Add(influence);
    }
    
  }
  
  importData.uvSetCount = 1;
  
  GLKVector3 *rPoint = (GLKVector3 *)malloc(sizeof(GLKVector3) * points.Size());
  importData.points = rPoint;
  importData.pointCount = (int)points.Size();
  for(int i = 0; i < (int)points.Size();i++)
  {
    rPoint->x = static_cast<float>(points[i].mData[0]);
    rPoint->y = static_cast<float>(points[i].mData[1]);
    rPoint->z = static_cast<float>(points[i].mData[2]);
    rPoint++;
  }
  
  RawWedge *rWedge = (RawWedge *)malloc(sizeof(RawWedge) * wedges.Size());
  importData.wedges = rWedge;
  importData.wedgeCount = (int)wedges.Size();
  for(int i = 0; i < (int)wedges.Size();i++)
  {
    rWedge->pointIndex = wedges[i].VertexIndex;
    rWedge->materialIndex = wedges[i].MatIndex;
    for(int j = 0; j < 4; j++)
    {
      rWedge->UV[j].x = wedges[i].UVs[j].x;
      rWedge->UV[j].y = wedges[i].UVs[j].y;
    }
    
    memcpy(rWedge->UV, wedges[i].UVs, sizeof(GLKVector2) * 4);
    rWedge++;
  }
  
  RawTriangle *rTriangle = (RawTriangle *)malloc(sizeof(RawTriangle) * triangleCount);
  importData.faces = rTriangle;
  importData.faceCount = triangleCount;
  
  GLKVector3 tan1[points.Size()];
  memset(&tan1, 0, sizeof(GLKVector3) * points.Size());
  GLKVector3 tan2[points.Size()];
  memset(&tan2, 0, sizeof(GLKVector3) * points.Size());
  
  for(int i = 0; i < triangleCount;i++)
  {
    
    rTriangle->materialIndex = faces[i].MatIndex;
    rTriangle->wedgeIndices[0] = (int)faces[i].WedgeIndex[0];
    rTriangle->wedgeIndices[1] = (int)faces[i].WedgeIndex[1];
    rTriangle->wedgeIndices[2] = (int)faces[i].WedgeIndex[2];
    memcpy(rTriangle->tangentX, faces[i].TangentX, sizeof(GLKVector3) * 3);
    memcpy(rTriangle->tangentY, faces[i].TangentY, sizeof(GLKVector3) * 3);
    memcpy(rTriangle->tangentZ, faces[i].TangentZ, sizeof(GLKVector3) * 3);
    
    if (![opts[@"impTan"] boolValue] || ([opts[@"impTan"] boolValue] && !bHasTangentInformation))
    {
      unsigned int i1 = importData.wedges[rTriangle->wedgeIndices[0]].pointIndex;
      unsigned int i2 = importData.wedges[rTriangle->wedgeIndices[1]].pointIndex;
      unsigned int i3 = importData.wedges[rTriangle->wedgeIndices[2]].pointIndex;
      
      GLKVector3 v1 = importData.points[i1];
      GLKVector3 v2 = importData.points[i2];
      GLKVector3 v3 = importData.points[i3];
      
      GLKVector2 w1 = GLKVector2Make(importData.wedges[rTriangle->wedgeIndices[0]].UV[0].x,
                                     importData.wedges[rTriangle->wedgeIndices[0]].UV[0].y);
      GLKVector2 w2 = GLKVector2Make(importData.wedges[rTriangle->wedgeIndices[1]].UV[0].x,
                                     importData.wedges[rTriangle->wedgeIndices[1]].UV[0].y);
      GLKVector2 w3 = GLKVector2Make(importData.wedges[rTriangle->wedgeIndices[2]].UV[0].x,
                                     importData.wedges[rTriangle->wedgeIndices[2]].UV[0].y);
      
      float x1 = v2.x - v1.x;
      float x2 = v3.x - v1.x;
      float y1 = v2.y - v1.y;
      float y2 = v3.y - v1.y;
      float z1 = v2.z - v1.z;
      float z2 = v3.z - v1.z;
      
      float s1 = w2.x - w1.x;
      float s2 = w3.x - w1.x;
      float t1 = w2.y - w1.y;
      float t2 = w3.y - w1.y;
      
      float div = s1 * t2 - s2 * t1;
      float r = div == 0.0f ? 0.0f : 1.0f / div;
      
      GLKVector3 sdir = GLKVector3Make((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
      GLKVector3 tdir = GLKVector3Make((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);
      
      tan1[i1] = GLKVector3Add(tan1[i1], sdir);
      tan1[i2] = GLKVector3Add(tan1[i2], sdir);
      tan1[i3] = GLKVector3Add(tan1[i3], sdir);
      
      tan2[i1] = GLKVector3Add(tan2[i1], tdir);
      tan2[i2] = GLKVector3Add(tan2[i2], tdir);
      tan2[i3] = GLKVector3Add(tan2[i3], tdir);
    }
    rTriangle++;
  }
  free(faces);
  
  if (![opts[@"impTan"] boolValue] || ([opts[@"impTan"] boolValue] && !bHasTangentInformation))
  {
    for(int i = 0; i < triangleCount; i++)
    {
      for(int j = 0; j < 3; j++)
      {
        GLKVector3 normal = importData.faces[i].tangentZ[j];
        GLKVector3 tangent = tan1[importData.wedges[importData.faces[i].wedgeIndices[j]].pointIndex];
        
        // Gram-Schmidt orthogonalize
        GLKVector3 ortho = GLKVector3Subtract(tangent, GLKVector3MultiplyScalar(normal, GLKVector3DotProduct(normal, tangent)));
        tangent = GLKVector3Normalize(ortho);
        importData.faces[i].tangentX[j] = tangent;
        importData.faces[i].basis[j] = GLKVector3DotProduct(GLKVector3CrossProduct(normal, tangent),
                                                            tan2[importData.wedges[importData.faces[i].wedgeIndices[j]].pointIndex]) < 0 ? -1.f : 1.f;
        GLKVector3 binormal = GLKVector3CrossProduct(tangent, normal);
        importData.faces[i].tangentY[j] = binormal;
      }
    }
  }
  importData.flipTangents = (![opts[@"impTan"] boolValue] || ([opts[@"impTan"] boolValue] && !bHasTangentInformation));
  
  
  RawInfluence *rInfluence = (RawInfluence *)malloc(sizeof(RawInfluence) * influences.Size());
  importData.influences = rInfluence;
  importData.influenceCount = (int)influences.Size();
  for (int i = 0; i < (int)influences.Size();i++)
  {
    rInfluence->weight = (float)influences[i].Weight;
    rInfluence->boneIndex = (int)influences[i].BoneIndex;
    rInfluence->vertexIndex = (int)influences[i].VertIndex;
    rInfluence++;
  }
  
  importData.materials = mats;
  
  importData.bones = refBones;
  importData.boneCount = (int)sortedLinks.Size();
  if ([opts[@"skel"] boolValue])
    importData.overrideSkel = YES;
  
  if (UniqueUVCount > 0)
  {
    free(LayerElementUV);
    free(UVReferenceMode);
    free(UVMappingMode);
  }
  DestroySdkObjects(pSdkManager, 1);
  return importData;
}

- (void)saveSceneTo:(const char *)url type:(int)type
{
  BOOL result = SaveScene(pSdkManager,pScene,url,type);
  if (!result)
    DLog(@"Error! Failed to save the scene! View the log for more information.");
  
  DestroySdkObjects(pSdkManager, result);
}

@end

FbxAMatrix ComputeTotalMatrix(FbxNode* Node, FbxScene *pScene)
{
  FbxAMatrix Geometry;
  FbxVector4 Translation, Rotation, Scaling;
  Translation = Node->GetGeometricTranslation(FbxNode::eSourcePivot);
  Rotation = Node->GetGeometricRotation(FbxNode::eSourcePivot);
  Scaling = Node->GetGeometricScaling(FbxNode::eSourcePivot);
  Geometry.SetT(Translation);
  Geometry.SetR(Rotation);
  Geometry.SetS(Scaling);
  
  //For Single Matrix situation, obtain transfrom matrix from eDESTINATION_SET, which include pivot offsets and pre/post rotations.
  FbxAMatrix& GlobalTransform = pScene->GetAnimationEvaluator()->GetNodeGlobalTransform(Node);
  
  FbxAMatrix TotalMatrix;
  TotalMatrix = GlobalTransform * Geometry;
  
  return TotalMatrix;
}

BOOL IsUnrealBone(FbxNode* Link)
{
  FbxNodeAttribute* Attr = Link->GetNodeAttribute();
  if (Attr)
  {
    FbxNodeAttribute::EType AttrType = Attr->GetAttributeType();
    if ( AttrType == FbxNodeAttribute::eSkeleton ||
        AttrType == FbxNodeAttribute::eMesh	 ||
        AttrType == FbxNodeAttribute::eNull )
    {
      return TRUE;
    }
  }
  
  return FALSE;
}

BOOL IsOddNegativeScale(FbxAMatrix& TotalMatrix)
{
  FbxVector4 Scale = TotalMatrix.GetS();
  int NegativeNum = 0;
  
  if (Scale[0] < 0) NegativeNum++;
  if (Scale[1] < 0) NegativeNum++;
  if (Scale[2] < 0) NegativeNum++;
  
  return NegativeNum == 1 || NegativeNum == 3;
}

FbxNode *GetRootSkeleton(FbxNode* Link, FbxScene *FbxScene)
{
  FbxNode* RootBone = Link;
  // get FBX skeleton root
  while (RootBone->GetParent() && RootBone->GetParent()->GetSkeleton())
  {
    RootBone = RootBone->GetParent();
  }
  
  // get Unreal skeleton root
  // mesh and dummy are used as bone if they are in the skeleton hierarchy
  while (RootBone->GetParent())
  {
    FbxNodeAttribute* Attr = RootBone->GetParent()->GetNodeAttribute();
    if (Attr &&
        (Attr->GetAttributeType() == FbxNodeAttribute::eMesh || Attr->GetAttributeType() == FbxNodeAttribute::eNull) &&
        RootBone->GetParent() != FbxScene->GetRootNode())
    {
      // in some case, skeletal mesh can be ancestor of bones
      // this avoids this situation
      if (Attr->GetAttributeType() == FbxNodeAttribute::eMesh )
      {
        FbxMesh *m = (FbxMesh*)Attr;
        if (m->GetDeformerCount(FbxDeformer::eSkin) > 0)
        {
          break;
        }
      }
      
      RootBone = RootBone->GetParent();
    }
    else
    {
      break;
    }
  }
  
  return RootBone;
}

void RecursiveBuildSkeleton(FbxNode* Link, FbxDynamicArray<FbxNode*>& OutSortedLinks)
{
  if (IsUnrealBone(Link))
  {
    OutSortedLinks.PushBack(Link);
    int ChildIndex;
    for (ChildIndex=0; ChildIndex<Link->GetChildCount(); ChildIndex++)
    {
      RecursiveBuildSkeleton(Link->GetChild(ChildIndex),OutSortedLinks);
    }
  }
}

void BuildSkeletonSystem(FbxDynamicArray<FbxCluster*>& ClusterArray, FbxDynamicArray<FbxNode*>& OutSortedLinks, FbxScene *pScene)
{
  FbxNode *link;
  FbxDynamicArray<FbxNode*> rootLinks;
  
  int clusterIndex = 0;
  int stop = 1;
  if (ClusterArray.Size() > 1)
    stop = (int)ClusterArray.Size() - 1;
  for (; clusterIndex < stop; clusterIndex++)
  {
    link = ClusterArray[clusterIndex]->GetLink();
    link = GetRootSkeleton(link,pScene);
    int linkIndex;
    for(linkIndex = 0; linkIndex < rootLinks.Size();linkIndex++)
    {
      if (link == rootLinks[linkIndex])
        break;
    }
    if (linkIndex == rootLinks.Size())
      rootLinks.PushBack(link);
  }
  
  for (int linkIndex = 0; linkIndex < rootLinks.Size();linkIndex++)
  {
    RecursiveBuildSkeleton(rootLinks[linkIndex], OutSortedLinks);
  }
}

// Recursive function to get a node's global default position.
// As a prerequisite, parent node's default local position must be already set.
FbxAMatrix GetGlobalDefaultPosition(FbxNode* pNode)
{
  FbxAMatrix lLocalPosition;
  FbxAMatrix lGlobalPosition;
  FbxAMatrix lParentGlobalPosition;
  
  lLocalPosition.SetT(pNode->LclTranslation.Get());
  lLocalPosition.SetR(pNode->LclRotation.Get());
  lLocalPosition.SetS(pNode->LclScaling.Get());
  
  if (pNode->GetParent())
  {
    lParentGlobalPosition = GetGlobalDefaultPosition(pNode->GetParent());
    lGlobalPosition = lParentGlobalPosition * lLocalPosition;
  }
  else
  {
    lGlobalPosition = lLocalPosition;
  }
  
  return lGlobalPosition;
}

// Function to get a node's global default position.
// As a prerequisite, parent node's default local position must be already set.
void SetGlobalDefaultPosition(FbxNode* pNode, FbxAMatrix pGlobalPosition)
{
  FbxAMatrix lLocalPosition;
  FbxAMatrix lParentGlobalPosition;
  
  if (pNode->GetParent())
  {
    lParentGlobalPosition = GetGlobalDefaultPosition(pNode->GetParent());
    lLocalPosition = lParentGlobalPosition.Inverse() * pGlobalPosition;
  }
  else
  {
    lLocalPosition = pGlobalPosition;
  }
  
  pNode->LclTranslation.Set(lLocalPosition.GetT());
  pNode->LclRotation.Set(lLocalPosition.GetR());
  pNode->LclScaling.Set(lLocalPosition.GetS());
}

FbxNode *createSkeleton(const SkeletalMesh* skelMesh, FbxDynamicArray<FbxNode*>& boneNodes, FbxScene *pScene, BOOL prefix)
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-getter-return-value"
  skelMesh.properties;
#pragma diagnostic pop
  if (!skelMesh.refSkeleton.count)
    return NULL;
  
  NSArray *refSkeleton = skelMesh.refSkeleton.nsarray;
  boneNodes.Reserve(skelMesh.refSkeleton.count);
  
  for(int boneIndex = 0; boneIndex < skelMesh.refSkeleton.count; boneIndex++)
  {
    
    FMeshBone *fbone = refSkeleton[boneIndex];
    FbxString name;
    if (prefix)
      name = [[NSString stringWithFormat:@"idx_%d__%@",boneIndex,[skelMesh.package nameForIndex:(int)fbone.nameIdx]] cStringUsingEncoding:NSASCIIStringEncoding];
    else
      name = [[skelMesh.package nameForIndex:(int)fbone.nameIdx] cStringUsingEncoding:NSASCIIStringEncoding];
    
    FbxSkeleton *skeletonAttribute = FbxSkeleton::Create(pScene, name.Buffer());
    
    if (!boneIndex && skelMesh.refSkeleton.count > 1)
    {
      skeletonAttribute->SetSkeletonType(FbxSkeleton::eRoot);
    }
    else
    {
      skeletonAttribute->SetSkeletonType(FbxSkeleton::eLimbNode);
    }
    
    FbxNode *boneNode = FbxNode::Create(pScene,name.Buffer());
    boneNode->SetNodeAttribute(skeletonAttribute);
    
    FbxVector4 lT = FbxVector4(fbone.position.x,fbone.position.y * -1.f,fbone.position.z);
    FbxQuaternion lQ = FbxQuaternion(fbone.orientation.x,fbone.orientation.y * -1.f,fbone.orientation.z,fbone.orientation.w * 1.f);
    lQ[3] *= -1.f;
    FbxAMatrix lGM;
    lGM.SetT(lT);
    lGM.SetQ(lQ);
    SetGlobalDefaultPosition(boneNode, lGM);
    
    if (boneIndex)
      boneNodes[fbone.parentIdx]->AddChild(boneNode);
    
    boneNodes.PushBack(boneNode);
  }
  return boneNodes[0];
}

void AddNodeRecursively(FbxArray<FbxNode*>& pNodeArray, FbxNode* pNode)
{
  if (pNode)
  {
    AddNodeRecursively(pNodeArray, pNode->GetParent());
    
    if (pNodeArray.Find(pNode) == -1)
    {
      // Node not in the list, add it
      pNodeArray.Add(pNode);
    }
  }
}

void CreateBindPose(FbxNode* MeshRootNode, FbxScene *Scene)
{
  FbxArray<FbxNode*> lClusteredFbxNodes;
  int i, j;
  
  if (MeshRootNode && MeshRootNode->GetNodeAttribute())
  {
    int lSkinCount=0;
    int lClusterCount=0;
    switch (MeshRootNode->GetNodeAttribute()->GetAttributeType())
    {
      case FbxNodeAttribute::eMesh:
      case FbxNodeAttribute::eNurbs:
      case FbxNodeAttribute::ePatch:
        
        lSkinCount = ((FbxGeometry*)MeshRootNode->GetNodeAttribute())->GetDeformerCount(FbxDeformer::eSkin);
        //Go through all the skins and count them
        //then go through each skin and get their cluster count
        for(i=0; i<lSkinCount; ++i)
        {
          FbxSkin *lSkin=(FbxSkin*)((FbxGeometry*)MeshRootNode->GetNodeAttribute())->GetDeformer(i, FbxDeformer::eSkin);
          lClusterCount+=lSkin->GetClusterCount();
        }
        break;
      default :
        break;
    }
    //if we found some clusters we must add the node
    if (lClusterCount)
    {
      //Again, go through all the skins get each cluster link and add them
      for (i=0; i<lSkinCount; ++i)
      {
        FbxSkin *lSkin=(FbxSkin*)((FbxGeometry*)MeshRootNode->GetNodeAttribute())->GetDeformer(i, FbxDeformer::eSkin);
        lClusterCount=lSkin->GetClusterCount();
        for (j=0; j<lClusterCount; ++j)
        {
          FbxNode* lClusterNode = lSkin->GetCluster(j)->GetLink();
          AddNodeRecursively(lClusteredFbxNodes, lClusterNode);
        }
        
      }
      
      // Add the patch to the pose
      lClusteredFbxNodes.Add(MeshRootNode);
    }
  }
  
  // Now create a bind pose with the link list
  if (lClusteredFbxNodes.GetCount())
  {
    // A pose must be named. Arbitrarily use the name of the patch node.
    FbxPose* lPose = FbxPose::Create(Scene, MeshRootNode->GetName());
    
    // default pose type is rest pose, so we need to set the type as bind pose
    lPose->SetIsBindPose(true);
    
    for (i=0; i<lClusteredFbxNodes.GetCount(); i++)
    {
      FbxNode*  lKFbxNode   = lClusteredFbxNodes.GetAt(i);
      FbxMatrix lBindMatrix = lKFbxNode->EvaluateGlobalTransform();
      
      lPose->Add(lKFbxNode, lBindMatrix);
    }
    
    // Add the pose to the scene
    Scene->AddPose(lPose);
  }
}

float InvSqrt(float F)
{
  return 1.0f / sqrtf(F);
}

bool NormalizeVector(FbxVector4 *vector)
{
  float X = static_cast<float>(vector->mData[0]);
  float Y = static_cast<float>(vector->mData[1]);
  float Z = static_cast<float>(vector->mData[2]);
  float Tolerance = 1.e-8f;
  const float SquareSum = X*X + Y*Y + Z*Z;
  if( SquareSum > Tolerance )
  {
    const float Scale = InvSqrt(SquareSum);
    X *= Scale; Y *= Scale; Z *= Scale;
    vector->mData[0] = X;
    vector->mData[1] = Y;
    vector->mData[2] = Z;
    return true;
  }
  return false;
}

GLKVector3 UnpackNormal(FPackedNormal normal)
{
  GLKVector3 vector;
  
  vector.x = normal.x / 127.5 - 1.f;
  vector.y = normal.y / 127.5 - 1.f;
  vector.z = normal.z / 127.5 - 1.f;
  
  return vector;
}

FPackedNormal PackNormal(float x, float y, float z)
{
  FPackedNormal normal;
  
  normal.x = (x + 1.0f) * 127.5f;
  normal.y = (y + 1.0f) * 127.5f;
  normal.z = (z + 1.0f) * 127.5f;
  normal.w = 0x7F;
  
  return normal;
}

void setupTextures(FbxSurfaceMaterial* material)
{
  
}
