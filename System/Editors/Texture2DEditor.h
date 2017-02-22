//
//  UObjectEditor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UObjectEditor.h"
#import "UObject.h"
#import "Texture2D.h"

@interface Texture2DEditor : UObjectEditor
@property (weak) Texture2D   *object;
@end

@interface ShadowMapTexture2DEditor : Texture2DEditor
@end

@interface LightMapTexture2DEditor : Texture2DEditor
@end

@interface TerrainWeightMapTextureEditor : Texture2DEditor
@end
