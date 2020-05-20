//
//  Material.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"

@class Texture2D, FMaterial, FStaticParameterSet, SCNMaterial;

@interface Material : UObject
@property (nonatomic, strong) FMaterial *material;
- (CGFloat)opacity;
- (NSString *)parentMat;
- (Texture2D *)diffuseMap;
- (Texture2D *)normalMap;
- (Texture2D *)specularMap;
- (Texture2D *)emissiveMap;
- (SCNMaterial *)sceneMaterial;
- (NSColor *)diffuseColor;
@end

@interface MaterialInstance : Material
- (NSString *)exportIncluding:(BOOL)textures to:(NSString *)dataPath;
@end

@interface MaterialInstanceConstant : MaterialInstance
@property (nonatomic, strong) FStaticParameterSet *staticPermutationResource;
@end
