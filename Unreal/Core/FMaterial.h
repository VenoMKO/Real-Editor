//
//  FMaterial.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 12/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FString.h"
#import "FArray.h"
#import "FMap.h"
#import "FGUID.h"
#import "FMaterialUniformExpression.h"

@interface FStaticSwitchParameter : FReadable
@property (strong) FName *parameterName;
@property (assign) BOOL value;
@property (assign) BOOL bOverride;
@property (strong) FGUID *expressionGUID;
@end

@interface FStaticComponentMaskParameter : FReadable
@property (assign) BOOL b;
@property (strong) FName *parameterName;
@property (assign) BOOL r;
@property (assign) BOOL g;
@property (assign) BOOL bOverride;
@property (assign) BOOL a;
@property (strong) FGUID *expressionGUID;
@end

@interface FStaticParameterSet : FReadable
@property (strong) FArray *staticComponentMaskParameters;
@property (strong) FArray *terrainLayerWeightParameters;
@property (strong) FGUID *baseMaterialId;
@property (strong) FArray *staticSwitchParameters;
@property (strong) FArray *normalParameters;
@end

@interface FShaderFrequencyUniformExpressions : FReadable
@property (strong) FArray *uniformScalarExpressions;
@property (strong) FArray *uniformVectorExpressions;
@property (strong) FArray *uniform2DTextureExpressions;
@end

@interface FUniformExpressionSet : FReadable
@property (strong) FShaderFrequencyUniformExpressions *pixelExpressions;
@property (strong) FArray *uniformCubeTextureExpressions;
@end

@interface FTextureLookup : FReadable
@property (assign) int texCoordIndex;
@property (assign) float uScale;
@property (assign) int textureIndex;
@property (assign) float vScale;
@end

@interface FMaterial : FReadable

@property (assign) int maxTextureDependencyLength;
@property (strong) FGUID *identifier;
@property (assign) unsigned int numUserTexCoords;
@property (strong) FMap *textureDependencyLengthMap;
@property (strong) FUniformExpressionSet *legacyUniformExpressions;
@property (assign) int usingTransforms;
@property (strong) FArray *textureLookups;
@property (assign) BOOL bUsesSceneColor;
@property (strong) FArray *compileErrors;
@property (assign) BOOL bUsesSceneDepth;
@property (assign) int dummyDroppedFallbackComponents;
@property (assign) BOOL bUsesDynamicParameter;

@end
