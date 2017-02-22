//
//  SceneView.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 13/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//
#import "SceneView.h"
#import <GLKit/GLKit.h>

#define DEFAULT_RADIUS  50.f
#define ZOOM_STEP       400.0f
#define DEFAULT_CAM_X   -25.f
#define DEFAULT_CAM_Y   35.f
#define DEFAULT_CAM_Z   0.f

static CGFloat FovToUE3Fov(CGFloat fov)
{
  return fov * .5f;
}

@implementation ModelView

- (void)setup
{
  if (!self.scene) {
    self.antialiasingMode = SCNAntialiasingModeMultisampling16X;
    SCNAntialiasingMode mode;
    int aaMode = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsAAMode];
    switch (aaMode) {
      default:
      case 0:
        mode = SCNAntialiasingModeNone;
        break;
      case 1:
        mode = SCNAntialiasingModeMultisampling2X;
        break;
      case 2:
        mode = SCNAntialiasingModeMultisampling4X;
        break;
      case 3:
        mode = SCNAntialiasingModeMultisampling8X;
        break;
      case 4:
        mode = SCNAntialiasingModeMultisampling16X;
        break;
    }
#ifdef DEBUG
    self.antialiasingMode = SCNAntialiasingModeNone;
#else
    self.antialiasingMode = mode;
#endif
    
    SCNScene *scene = [SCNScene scene];
    self.scene = scene;
    
    SCNLight *ambient = [SCNLight light];
    ambient.type  = SCNLightTypeAmbient;
    ambient.color = [NSColor colorWithCalibratedWhite:1 alpha:1];
    scene.rootNode.light = ambient;
  }
  if (!self.orbitNode) {
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.camera.zNear = 1.0;
    cameraNode.camera.zFar = 300.0;
    CGFloat fov = [[NSUserDefaults standardUserDefaults] doubleForKey:kSettingsFov];
    cameraNode.camera.xFov = FovToUE3Fov(fov);
    cameraNode.camera.yFov = FovToUE3Fov(fov);
    self.cameraNode = cameraNode;
    SCNNode *orbitNode = [SCNNode node];
    [orbitNode addChildNode:cameraNode];
    self.orbitNode = orbitNode;
    [self.scene.rootNode addChildNode:orbitNode];
  }
  if (!self.objectNode) {
    SCNNode *objectNode = [SCNNode node];
    [self.scene.rootNode addChildNode:objectNode];
    self.objectNode = objectNode;
  }
}

- (void)dealloc
{
  [self cleanupNode:self.objectNode];
  [self dropNodes:self.objectNode];
}

- (void)cleanupNode:(SCNNode *)node
{
  NSArray *children = node.childNodes;
  for (SCNNode *n in children)
  {
    SCNGeometry *geo = n.geometry;
    for (SCNMaterial *m in geo.materials)
    {
      m.diffuse.contents = nil;
      m.specular.contents = nil;
      m.normal.contents = nil;
      m.emission.contents = nil;
    }
    geo.materials = @[];
    if (n.childNodes.count)
      [self cleanupNode:n];
  }
}

- (void)dropNodes:(SCNNode *)node
{
  NSArray *subNodes = [node.childNodes copy];
  
  for (SCNNode *n in subNodes)
  {
    [self dropNodes:n];
  }
  [node removeFromParentNode];
}

- (IBAction)resetView:(id)sender
{
  [self reset];
}

- (void)reset
{
  radius = DEFAULT_RADIUS;
  self.cameraNode.camera.zFar = DBL_MAX;
  if (self.materialView)
  {
    radius = 60;
    minRadius = radius * .01f;
  }
  else
  {
    if (self.objectNode.childNodes.count)
    {
      SCNVector3 center;
      float bck = radius;
      
      SCNVector3 max = SCNVector3Make(CGFLOAT_MIN, CGFLOAT_MIN, CGFLOAT_MIN);
      SCNVector3 min = SCNVector3Make(CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX);
      
      NSArray *nodes = self.objectNode.childNodes;
      for (SCNNode *n in nodes)
      {
        if (n.geometry)
        {
          SCNVector3 cen;
          if ([n.geometry getBoundingSphereCenter:&cen radius:NULL])
          {
            if (cen.x < min.x)
              min.x = cen.x;
            else if (cen.x > max.x)
              max.x = cen.x;
            
            if (cen.y < min.y)
              min.y = cen.y;
            else if (cen.y > max.y)
              max.y = cen.y;
            
            if (cen.z < min.z)
              min.z = cen.z;
            else if (cen.z > max.z)
              max.z = cen.z;
          }
        }
      }
      
      if (nodes.count > 1)
      {
        center = SCNVector3Make((min.x + max.x) * .5, (min.y + max.y) * .5f, (min.z + max.z) * .5);
      }
      else
      {
        [self.objectNode getBoundingSphereCenter:&center radius:NULL];
      }
      
      self.orbitNode.position = center;
      
      if ([self.objectNode getBoundingSphereCenter:&center radius:&radius])
      {
        if (!radius)
          radius = (bck != DEFAULT_RADIUS) ? bck : DEFAULT_RADIUS;
        if (bck == DEFAULT_RADIUS)
          radius *= 2.75f;
        minRadius = radius * .01f;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadFog])
        {
          self.scene.fogColor = self.backgroundColor;
          self.scene.fogStartDistance = radius * (self.increaseFogDensity ?  .75 : 2.0);
          self.scene.fogEndDistance = radius * (self.increaseFogDensity ?  4.0 : 7.0);
        }
      }
    }
  }
  
  
  self.cameraNode.position = SCNVector3Make(0, 0, radius);
  if (self.materialView)
  {
    self.orbitNode.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(0),
                                                GLKMathDegreesToRadians(0),
                                                GLKMathDegreesToRadians(0));
  }
  else
  {
    self.orbitNode.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(DEFAULT_CAM_X),
                                                GLKMathDegreesToRadians(DEFAULT_CAM_Y),
                                                GLKMathDegreesToRadians(DEFAULT_CAM_Z));
  }
  
}
/*
- (void)rightMouseDragged:(NSEvent *)theEvent
{
  if (_locked || !self.allowsCameraControl)
  {
    [super rightMouseDragged:theEvent];
    return;
  }
  SCNVector3 pos =  self.cameraNode.position;
  
  CGFloat baseRatio = radius / ZOOM_STEP * .005f;
  
  if (theEvent.modifierFlags & NSShiftKeyMask)
    baseRatio *= 3.f;
  
  baseRatio *= self.cameraNode.position.z / minRadius;
  
  
  pos.x += theEvent.deltaX * -baseRatio;
  pos.y += theEvent.deltaY * baseRatio;
  
  GLKVector3 L = GLKVector3Make(pos.x, pos.y, pos.z);
  GLKVector3 R = GLKVector3Make(self.cameraNode.position.x, self.cameraNode.position.y, self.cameraNode.position.z);
  GLKVector3 t = GLKVector3Subtract(L, R);
  SCNVector3 pos2 = SCNVector3Make(t.x, t.y, t.z);
  
  pos = self.orbitNode.position;
  pos.x += pos2.x;
  pos.y += pos2.y;
  pos.z += pos2.z;
  
  self.orbitNode.position = pos;
}
- (void)mouseDragged:(NSEvent *)theEvent
{
  if (_locked || !self.allowsCameraControl)
  {
    [super mouseDragged:theEvent];
    return;
  }
  
  SCNVector3 euler = self.orbitNode.eulerAngles;
  
  CGPoint delta;
  // Swap X & Y
  delta.x = theEvent.deltaY;
  delta.y = theEvent.deltaX;
  
  self.orbitNode.eulerAngles = SCNVector3Make(-M_2_PI * delta.x * .02f + euler.x,
                                              -M_2_PI * delta.y * .02f + euler.y,
                                              euler.z);
}

- (void)scrollWheel:(NSEvent *)theEvent
{
  if (_locked || !!self.allowsCameraControl)
  {
    [super scrollWheel:theEvent];
    return;
  }
  CGFloat delta = 0.f;
  if (theEvent.modifierFlags & NSShiftKeyMask)
    delta = theEvent.deltaX;
  else
    delta = theEvent.deltaY;
  
  CGFloat baseRatio = radius / ZOOM_STEP;
  CGFloat ratio = (theEvent.modifierFlags & NSShiftKeyMask) ? (baseRatio * 3.f) : baseRatio;
  SCNVector3 pos = self.cameraNode.position;
  pos.z += (delta * ratio);
  if (pos.z < minRadius)
    pos.z = minRadius;
  self.cameraNode.position = pos;
}*/

@end
