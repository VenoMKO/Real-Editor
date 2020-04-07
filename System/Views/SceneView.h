//
//  SceneView.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "UPackage.h"

@interface ModelView : SCNView {
  CGFloat             radius;
  CGFloat             minRadius;
}
@property (weak) UPackage             *package;
@property (weak) UObject              *selection;
@property (assign) SCNNode            *orbitNode;
@property (assign) SCNNode            *cameraNode;
@property (assign) SCNNode            *objectNode;
@property (assign) BOOL               locked;
@property (assign) BOOL               materialView;
@property (assign) BOOL               increaseFogDensity;
@property (assign) IBInspectable BOOL allowObjectSelection;

- (void)setup;
- (void)reset;

@end
