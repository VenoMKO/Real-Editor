//
//  StaticMeshEditor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 23/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
#import "UObjectEditor.h"
#import "UObject.h"
#import "Prefab.h"

@interface PrefabEditor : UObjectEditor
@property (weak) Prefab   *object;

@end
