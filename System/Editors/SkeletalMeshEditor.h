//
//  UObjectEditor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 26/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
#import "UObjectEditor.h"
#import "UObject.h"
#import "SkeletalMesh.h"

@interface SkeletalMeshEditor : UObjectEditor <NSTableViewDataSource>
@property (weak) SkeletalMesh   *object;


@end
