/****************************************************************************************
 
 Copyright (C) 2014 Autodesk, Inc.
 All rights reserved.
 
 Use of this software is subject to the terms of the Autodesk license agreement
 provided at the time of installation or download, or which otherwise accompanies
 this software in either electronic or hard copy form.
 
 ****************************************************************************************/

#include "Common.h"

#ifdef IOS_REF
#undef  IOS_REF
#define IOS_REF (*(pManager->GetIOSettings()))
#endif

const char *extension(const char *filename) {
  const char *dot = strrchr(filename, '.');
  if(!dot || dot == filename) return NULL;
  return dot + 1;
}


void InitializeSdkObjects(FbxManager*& pManager, FbxScene*& pScene)
{
  //The first thing to do is to create the FBX Manager which is the object allocator for almost all the classes in the SDK
  pManager = FbxManager::Create();
  if( !pManager )
  {
    FBXSDK_printf("Error: Unable to create FBX Manager!\n");
    return;
  }
  
  //Create an IOSettings object. This object holds all import/export settings.
  FbxIOSettings* ios = FbxIOSettings::Create(pManager, IOSROOT);
  pManager->SetIOSettings(ios);
  
  //Load plugins from the executable directory (optional)
  FbxString lPath = FbxGetApplicationDirectory();
  pManager->LoadPluginsDirectory(lPath.Buffer());
  
  //Create an FBX scene. This object holds most objects imported/exported from/to files.
  pScene = FbxScene::Create(pManager, "");
  if( !pScene )
  {
    FBXSDK_printf("Error: Unable to create FBX scene!\n");
    return;
  }
  FbxAxisSystem::EFrontVector FrontVector = (FbxAxisSystem::EFrontVector)-FbxAxisSystem::eParityOdd;
  const FbxAxisSystem UnrealZUp(FbxAxisSystem::eZAxis,FrontVector,FbxAxisSystem::eRightHanded);
  pScene->GetGlobalSettings().SetAxisSystem(UnrealZUp);
  pScene->GetGlobalSettings().SetOriginalUpAxis(UnrealZUp);
  pScene->GetGlobalSettings().SetSystemUnit(FbxSystemUnit::cm);
}

void DestroySdkObjects(FbxManager* pManager, bool pExitStatus)
{
  //Delete the FBX Manager. All the objects that have been allocated using the FBX Manager and that haven't been explicitly destroyed are also automatically destroyed.
  if( pManager ) pManager->Destroy();
}

bool SaveScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename, int pFileFormat, bool pEmbedMedia)
{
  int lMajor, lMinor, lRevision;
  bool lStatus = true;
  
  const char *ext = extension(pFilename);
  
  
  // Create an exporter.
  FbxExporter* lExporter = FbxExporter::Create(pManager, "");
  
  if( pFileFormat < 0 || pFileFormat >= pManager->GetIOPluginRegistry()->GetWriterFormatCount() )
  {
    // Write in fall back format in less no ASCII format found
    pFileFormat = pManager->GetIOPluginRegistry()->GetNativeWriterFormat();
    
    //Try to format
    int lFormatIndex, lFormatCount = pManager->GetIOPluginRegistry()->GetWriterFormatCount();
    bool found = false;
    for (lFormatIndex=0; lFormatIndex<lFormatCount; lFormatIndex++)
    {
      FbxString lDesc =pManager->GetIOPluginRegistry()->GetWriterFormatDescription(lFormatIndex);
      const char *lASCII = ext ? ext : "FBX binary";
      if (lDesc.GetLen() && lDesc.Find(lASCII)>=0)
      {
        pFileFormat = lFormatIndex;
        found = true;
        break;
      }
    }
    
    // Use Fbx binary if we couldn't resolve the extension format
    if (!found)
      lFormatIndex = 0;
  }
  
  // Set the export states. By default, the export states are always set to
  // true except for the option eEXPORT_TEXTURE_AS_EMBEDDED. The code below
  // shows how to change these states.
  IOS_REF.SetBoolProp(EXP_FBX_MATERIAL,        true);
  IOS_REF.SetBoolProp(EXP_FBX_TEXTURE,         false);
  IOS_REF.SetBoolProp(EXP_FBX_EMBEDDED,        pEmbedMedia);
  IOS_REF.SetBoolProp(EXP_FBX_SHAPE,           true);
  IOS_REF.SetBoolProp(EXP_FBX_GOBO,            false);
  IOS_REF.SetBoolProp(EXP_FBX_ANIMATION,       false);
  IOS_REF.SetBoolProp(EXP_FBX_GLOBAL_SETTINGS, true);
  
  // Initialize the exporter by providing a filename.
  if(lExporter->Initialize(pFilename, pFileFormat, pManager->GetIOSettings()) == false)
  {
    FBXSDK_printf("Call to FbxExporter::Initialize() failed.\n");
    FBXSDK_printf("Error returned: %s\n\n", lExporter->GetStatus().GetErrorString());
    return false;
  }
  
  FbxManager::GetFileFormatVersion(lMajor, lMinor, lRevision);
  
  // Export the scene.
  lStatus = lExporter->Export(pScene);
  
  // Destroy the exporter.
  lExporter->Destroy();
  return lStatus;
}

bool LoadScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename)
{
  int lFileMajor, lFileMinor, lFileRevision;
  int lSDKMajor,  lSDKMinor,  lSDKRevision;
  bool lStatus;
  
  // Get the file version number generate by the FBX SDK.
  FbxManager::GetFileFormatVersion(lSDKMajor, lSDKMinor, lSDKRevision);
  
  // Create an importer.
  FbxImporter* lImporter = FbxImporter::Create(pManager,"");
  
  // Initialize the importer by providing a filename.
  const bool lImportStatus = lImporter->Initialize(pFilename, -1, pManager->GetIOSettings());
  lImporter->GetFileVersion(lFileMajor, lFileMinor, lFileRevision);
  
  if( !lImportStatus )
  {
    FbxString error = lImporter->GetStatus().GetErrorString();
    FBXSDK_printf("Call to FbxImporter::Initialize() failed.\n");
    FBXSDK_printf("Error returned: %s\n\n", error.Buffer());
    
    if (lImporter->GetStatus().GetCode() == FbxStatus::eInvalidFileVersion)
    {
      FBXSDK_printf("FBX file format version for this FBX SDK is %d.%d.%d\n", lSDKMajor, lSDKMinor, lSDKRevision);
      FBXSDK_printf("FBX file format version for file '%s' is %d.%d.%d\n\n", pFilename, lFileMajor, lFileMinor, lFileRevision);
    }
    
    return false;
  }
  
  if (lImporter->IsFBX())
  {
    
    // From this point, it is possible to access animation stack information without
    // the expense of loading the entire file.
    
    // Set the import states. By default, the import states are always set to
    // true. The code below shows how to change these states.
    IOS_REF.SetBoolProp(IMP_FBX_MATERIAL,        true);
    IOS_REF.SetBoolProp(IMP_FBX_TEXTURE,         true);
    IOS_REF.SetBoolProp(IMP_FBX_LINK,            true);
    IOS_REF.SetBoolProp(IMP_FBX_SHAPE,           true);
    IOS_REF.SetBoolProp(IMP_FBX_GOBO,            true);
    IOS_REF.SetBoolProp(IMP_FBX_ANIMATION,       true);
    IOS_REF.SetBoolProp(IMP_FBX_GLOBAL_SETTINGS, true);
  }
  
  // Import the scene.
  lStatus = lImporter->Import(pScene);
  
  if(lStatus == false && lImporter->GetStatus().GetCode() == FbxStatus::ePasswordError)
  {
    FBXSDK_printf("Error! File has password proptection!");
  } else if (lStatus == false && lImporter->GetStatus().GetCode()) {
    FBXSDK_printf("%s",lImporter->GetStatus().GetErrorString());
  }
  // Destroy the importer.
  lImporter->Destroy();
  
  return lStatus;
}
