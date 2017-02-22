//
//  SceneView.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface ModelView : SCNView {
  CGFloat             radius;
  CGFloat             minRadius;
}
@property (assign) SCNNode          *orbitNode;
@property (assign) SCNNode          *cameraNode;
@property (assign) SCNNode          *objectNode;
@property (assign) BOOL             locked;
@property (assign) BOOL             materialView;
@property (assign) BOOL             increaseFogDensity;

- (void)setup;
- (void)reset;

@end
