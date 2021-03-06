//
//  MaterialInstanceConstant.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "Material.h"
#import "FPropertyTag.h"
#import "UPackage.h"
#import "Texture2D.h"
#import <SceneKit/SceneKit.h>
#import "FMaterial.h"

static void GetWarpModesFromTexture(Texture2D *tex, SCNWrapMode *wrapX, SCNWrapMode *wrapY)
{
  FPropertyTag *tag = [tex propertyForName:@"AddressX"];
  if (tag && [tag.type isEqualToString:kPropTypeByte]) {
    if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Mirror"])
      *wrapX = SCNWrapModeMirror;
    else if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Clamp"])
      *wrapX = SCNWrapModeClamp;
  }
  tag = [tex propertyForName:@"AddressY"];
  if (tag && [tag.type isEqualToString:kPropTypeByte]) {
    if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Mirror"])
      *wrapY = SCNWrapModeMirror;
    else if ([[tag.object.package nameForIndex:[tag.value intValue]]  isEqualToString:@"TA_Clamp"])
      *wrapY = SCNWrapModeClamp;
  }
}

@interface Material ()
@property (strong) SCNMaterial *cached;
@end

@implementation Material

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [self cookedProperties];
  if (self.material)
    [d appendData:[self.material cooked:d.length + offset]];
  return d;
}

- (FIStream *)postProperties
{
  if (self.dataSize)
  {
    FIStream *stream = [self.package.stream copy];
    stream.position = [self rawDataOffset];
    self.material = [FMaterial readFrom:stream];
    if ([self.className isEqualToString:@"Material"] && self.dataSize != stream.position - self.rawDataOffset)
      DThrow(@"Found unexpected data!");
    return stream;
  }
  return nil;
}

- (FMaterial *)material
{
  if (!self.properties)
    [self readProperties];
  
  return _material;
}

- (BOOL)canExport
{
  return NO;
}

- (CGFloat)opacity
{
  FPropertyTag *prop = [self propertyForName:@"ScalarParameterValues"];
  for (NSArray *set in prop.value) {
    for (FPropertyTag *tag in set) {
      if ([tag.name isEqualToString:@"ParameterName"] &&
          [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"OpacityStr"]) {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        return [[(FPropertyTag *)set[elemIdx] value] doubleValue];
      }
    }
  }
  return 1.0f;
}

- (NSString *)parentMat
{
  FPropertyTag *prop = [self propertyForName:@"Parent"];
  if (prop)
  {
    UObject *obj = [prop.package objectForIndex:[prop.value intValue]];
    return [obj objectName];
  }
  return nil;
}

- (Texture2D *)diffuseMap
{
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadTextures])
    return nil;
  FPropertyTag *prop = [self propertyForName:@"TextureParameterValues"];
  int idx = INT32_MAX;
  int ppcIdx = INT32_MAX;
  
  for (NSArray *set in prop.value)
  {
    for (FPropertyTag *tag in set)
    {
      if ([tag.name isEqualToString:@"ParameterName"] && [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"DiffuseMap"] && ppcIdx == INT32_MAX)
      {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        idx = [[(FPropertyTag *)set[elemIdx] value] intValue];
        break;
      }
      else if ([tag.name isEqualToString:@"ParameterName"] && [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"PCC_HairDiffuseMap"])
      {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        ppcIdx = [[(FPropertyTag *)set[elemIdx] value] intValue];
        break;
      }
      else if ([tag.name isEqualToString:@"ParameterName"] && [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"Diffuse_01"])
      {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        ppcIdx = [[(FPropertyTag *)set[elemIdx] value] intValue];
        break;
      }
    }
  }
  
  Texture2D *obj = nil;
  
  if (ppcIdx != INT32_MAX)
    obj =  (Texture2D *)[self.package objectForIndex:ppcIdx];
  else if (idx != INT32_MAX)
    obj =  (Texture2D *)[self.package objectForIndex:idx];
  
  if (obj.importObject)
    obj = (Texture2D *)[self.package resolveImport:obj.importObject];
  
  return obj;
}

- (NSColor *)diffuseColor
{
  FPropertyTag *t = [self propertyForName:@"DiffuseColor"] ;
  if (!t)
    return nil;
  
  int idx = [(NSNumber *)[(FPropertyTag *)[(NSArray *)[t value] objectAtIndex:0] value] intValue];
  
  UObject *o = [self.package objectForIndex:idx];
  
  if (o)
  {
    CGFloat r = 1,g = 1,b = 1,a = 1;
    @try {
      t = [o propertyForName:@"R"];
      if (t && [t.value isKindOfClass:[NSNumber class]])
        r = [t.value doubleValue];
      
      t = [o propertyForName:@"G"];
      if (t && [t.value isKindOfClass:[NSNumber class]])
        g = [t.value doubleValue];
      
      t = [o propertyForName:@"B"];
      if (t && [t.value isKindOfClass:[NSNumber class]])
        b = [t.value doubleValue];
      
      t = [o propertyForName:@"A"];
      if (t && [t.value isKindOfClass:[NSNumber class]])
        a = [t.value doubleValue];
    } @catch (NSException *exception)
    {
      DLog(@"Error! %@ - %@",self, exception);
    }
    
    
    return [NSColor colorWithRed:r green:g blue:b alpha:a];
  }
  
  return nil;
}

- (NSColor *)specularColor
{
  FPropertyTag *t = [self propertyForName:@"SpecularColor"] ;
  if (!t)
    return nil;
  
  int idx = [(NSNumber *)[(FPropertyTag *)[(NSArray *)[t value] objectAtIndex:0] value] intValue];
  
  UObject *o = [self.package objectForIndex:idx];
  
  if (o)
  {
    CGFloat r = 1,g = 1,b = 1,a = 1;
    @try {
      t = [o propertyForName:@"R"];
      if (t)
        r = [t.value doubleValue];
      
      t = [o propertyForName:@"G"];
      if (t)
        g = [t.value doubleValue];
      
      t = [o propertyForName:@"B"];
      if (t)
        b = [t.value doubleValue];
      
      t = [o propertyForName:@"A"];
      if (t)
        a = [t.value doubleValue];
    } @catch (NSException *exception)
    {
      DLog(@"Error! %@ - %@",self, exception);
    }
    return [NSColor colorWithRed:r green:g blue:b alpha:a];
  }
  
  return nil;
}

- (Texture2D *)normalMap
{
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadTextures])
    return nil;
  FPropertyTag *prop = [self propertyForName:@"TextureParameterValues"];
  int idx = INT32_MAX;
  
  for (NSArray *set in prop.value)
  {
    for (FPropertyTag *tag in set)
    {
      if ([tag.name isEqualToString:@"ParameterName"] && ([[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"NormalMap"] || [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"Normal_01"]))
      {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        idx = [[(FPropertyTag *)set[elemIdx] value] intValue];
        Texture2D *obj = (Texture2D *)[self.package objectForIndex:idx];
        if (obj.importObject)
          obj = (Texture2D *)[self.package resolveImport:obj.importObject];
        return obj;
      }
    }
  }
  return nil;
}

- (Texture2D *)specularMap
{
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadTextures])
    return nil;
  FPropertyTag *prop = [self propertyForName:@"TextureParameterValues"];
  int idx = INT32_MAX;
  
  for (NSArray *set in prop.value)
  {
    for (FPropertyTag *tag in set)
    {
      if ([tag.name isEqualToString:@"ParameterName"] && ([[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"SpecularMap"] || [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"Specular_1"]))
      {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        idx = [[(FPropertyTag *)set[elemIdx] value] intValue];
        Texture2D *obj = (Texture2D *)[self.package objectForIndex:idx];
        if (obj.importObject)
          obj = (Texture2D *)[self.package resolveImport:obj.importObject];
        return obj;
      }
    }
  }
  return nil;
}

- (Texture2D *)emissiveMap
{
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsLoadTextures])
    return nil;
  FPropertyTag *prop = [self propertyForName:@"TextureParameterValues"];
  int idx = INT32_MAX;
  
  for (NSArray *set in prop.value)
  {
    for (FPropertyTag *tag in set)
    {
      if ([tag.name isEqualToString:@"ParameterName"] && [[self.package nameForIndex:[tag.value intValue]] isEqualToString:@"EmissiveMap"])
      {
        NSUInteger elemIdx = [set indexOfObject:tag] + 1;
        idx = [[(FPropertyTag *)set[elemIdx] value] intValue];
        Texture2D *obj = (Texture2D *)[self.package objectForIndex:idx];
        if (obj.importObject)
          obj = (Texture2D *)[self.package resolveImport:obj.importObject];
        return obj;
      }
    }
  }
  return nil;
}

- (void)configureMaterial:(SCNMaterialProperty *)materialProperty image:(NSImage *)tex
{
  NSImage *img = tex;
  materialProperty.contents = img;
}

- (SCNMaterial *)sceneMaterial
{
  if (self.cached)
    return self.cached;
  
  SCNMaterial *m = [SCNMaterial new];
  m.doubleSided = YES;
  m.locksAmbientWithDiffuse = YES;
  Texture2D *tex = nil;
  NSColor *col = nil;
  BOOL isValid = NO;
  
  if ((tex = [self diffuseMap]) || (tex = [self emissiveMap]))
  {
    BOOL a = !([[self parentMat] isEqualToString:@"MatTemplet0003"] || [[self parentMat] isEqualToString:@"MatTemplet0027"] || [[self parentMat] rangeOfString:@"_Blend"].location != NSNotFound);
    [self configureMaterial:m.diffuse image:[tex forceExportedRenderedImageR:YES G:YES B:YES A:a invert:NO]];
    SCNWrapMode wrapX = SCNWrapModeRepeat;
    SCNWrapMode wrapY = SCNWrapModeRepeat;
    
    GetWarpModesFromTexture(tex, &wrapX, &wrapY);
    
    m.diffuse.wrapS = wrapX;
    m.diffuse.wrapT = wrapY;
    m.transparencyMode = SCNTransparencyModeAOne;
    isValid = YES;
    
    tex = nil;
    if ((tex = [self normalMap]))
    {
      [self configureMaterial:m.normal image:[tex renderedImageR:YES G:YES B:YES A:NO]];
      SCNWrapMode wrapX = SCNWrapModeRepeat;
      SCNWrapMode wrapY = SCNWrapModeRepeat;
      
      GetWarpModesFromTexture(tex, &wrapX, &wrapY);
      
      m.normal.wrapS = wrapX;
      m.normal.wrapT = wrapY;
    }
    
    tex = nil;
    if ((tex = [self specularMap]))
    {
      [self configureMaterial:m.specular image:[tex renderedImageR:YES G:YES B:YES A:NO]];
      SCNWrapMode wrapX = SCNWrapModeRepeat;
      SCNWrapMode wrapY = SCNWrapModeRepeat;
      
      GetWarpModesFromTexture(tex, &wrapX, &wrapY);
      
      m.specular.wrapS = wrapX;
      m.specular.wrapT = wrapY;
      m.specular.intensity = .5f;
      isValid = YES;
    }
    else if ((col = [self specularColor]))
    {
      m.specular.contents = col;
    }
    
    tex = nil;
    if ((tex = [self emissiveMap]))
    {
      [self configureMaterial:m.emission image:[tex renderedImageR:YES G:YES B:YES A:YES]];
      SCNWrapMode wrapX = SCNWrapModeRepeat;
      SCNWrapMode wrapY = SCNWrapModeRepeat;
      
      GetWarpModesFromTexture(tex, &wrapX, &wrapY);
      
      m.emission.wrapS = wrapX;
      m.emission.wrapT = wrapY;
    }
  }
  else if ((col = [self diffuseColor]))
  {
    m.diffuse.contents = col;
    isValid = YES;
    
    col = [self specularColor];
    if (col)
      m.specular.contents = col;
  }
  
  if (!isValid)
    m.diffuse.contents = [NSImage imageNamed:@"tex0"];
  
  self.cached = m;
  return m;
}

- (NSImage *)icon
{
  return [NSImage imageNamed:@"MaterialIcon"];
}

- (BOOL)hasStaticPermutationResource
{
  FPropertyTag *tag = [self propertyForName:@"bHasStaticPermutationResource"];
  return [tag.value boolValue];
}

- (NSString *)lightingModel
{
  NSNumber *modelId = [self propertyValue:@"LightingModel"];
  if (modelId)
  {
    NSString *model = [[self.package nameForIndex:modelId.intValue] componentsSeparatedByString:@"_"].lastObject;
    if (model.length)
    {
      return model;
    }
    
  }
  return @"DefaultLit";
}

- (NSString *)blendMode
{
  NSNumber *modeId = [self propertyValue:@"BlendMode"];
  if (modeId)
  {
    NSString *mode = [[self.package nameForIndex:modeId.intValue] componentsSeparatedByString:@"_"].lastObject;
    if (mode.length)
    {
      return mode;
    }
  }
  return @"Opaque";
}

@end

@implementation MaterialInstance

- (NSString *)exportIncluding:(BOOL)textures to:(NSString *)dataPath
{
  NSMutableString *result = [NSMutableString new];
  [result appendFormat:@"%@(%@)\n", self.objectName, self.objectClass];
  
  {
    NSNumber *p = [self propertyValue:@"Parent"];
    if (p)
    {
      UObject *parent = [self.package objectForIndex:p.intValue];
      [result appendFormat:@"Parent: %@(%@)\n", parent.objectName, parent.objectClass];
    }
  }
   
  
  NSArray *parameters = [self propertyValue:@"TextureParameterValues"];
  NSMutableString *s = [NSMutableString new];
  for (NSArray *paramterSet in parameters)
  {
    for (FPropertyTag *parameter in paramterSet)
    {
      if ([parameter.name isEqualToString:kPropNameNone])
      {
        [s appendString:@"\n"];
      }
      else if ([parameter.name isEqualToString:@"ParameterName"])
      {
        id v = parameter.value;
        if ([v isKindOfClass:[NSNumber class]])
        {
          [s appendFormat:@"\t%@: ", [parameter.package nameForIndex:[v intValue]]];
        }
        else
        {
          [s appendFormat:@"\t%@: ", v];
        }
      }
      else if ([parameter.name isEqualToString:@"ParameterValue"])
      {
        if (![parameter.type isEqualToString:kPropTypeObj])
        {
          [s appendString:parameter.value];
          DThrow(@"Unknow texture parameter value type '%@'!", parameter.type);
        }
        else
        {
          NSString *contentPath = nil;
          UObject *obj = [parameter.package objectForIndex:[parameter.value intValue]];
          if (obj.importObject)
          {
            obj = [obj.package resolveImport:obj.importObject];
            if (!obj)
            {
              obj = [parameter.package objectForIndex:[parameter.value intValue]];
              [s appendFormat:@"[IMP]%@(Failed to resolve!)", [obj objectPath]];
              continue;
            }
            contentPath = [obj objectNetPath];
            if (!contentPath)
            {
              NSArray *pathComponents = [[[parameter.package objectForIndex:[parameter.value intValue]] objectPath] componentsSeparatedByString:@"."];
              contentPath = [pathComponents componentsJoinedByString:@"/"];
            }
            else
            {
              NSArray *pathComponents = [contentPath componentsSeparatedByString:@"."];
              NSString *objectPath = [[pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count - 1)] componentsJoinedByString:@"/"];
              pathComponents = [[[parameter.package objectForIndex:[parameter.value intValue]] objectPath] componentsSeparatedByString:@"."];
              NSString *packageName = pathComponents[1];
              contentPath = [packageName stringByAppendingPathComponent:objectPath];
            }
          }
          else if (obj.exportObject)
          {
            if (obj && obj.exportObject.exportFlags | EF_ForcedExport)
            {
              Texture2D *externalObj = (Texture2D*)[obj.package resolveForcedExport:obj.exportObject];
              if (externalObj)
              {
                obj = externalObj;
              }
              else
              {
                DThrow(@"Failed to find: %@", obj.objectPath);
              }
            }
            contentPath = [obj objectNetPath];
            if (!contentPath)
            {
              NSArray *pathComponents = [[[parameter.package objectForIndex:[parameter.value intValue]] objectPath] componentsSeparatedByString:@"."];
              contentPath = [[pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count-1)] componentsJoinedByString:@"/"];
            }
            else
            {
              NSArray *pathComponents = [contentPath componentsSeparatedByString:@"."];
              NSString *objectPath = [[pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count - 1)] componentsJoinedByString:@"/"];
              pathComponents = [[[parameter.package objectForIndex:[parameter.value intValue]] objectPath] componentsSeparatedByString:@"."];
              NSString *packageName = pathComponents[1];
              contentPath = [packageName stringByAppendingPathComponent:objectPath];
            }
          }
          [s appendString:contentPath];
          
          if (textures)
          {
            NSString *exportPath = [[dataPath stringByAppendingPathComponent:@"Textures/S1Data"] stringByAppendingFormat:@"/%@.tga", contentPath];
            if (![[NSFileManager defaultManager] fileExistsAtPath:exportPath])
            {
              [[NSFileManager defaultManager] createDirectoryAtPath:[exportPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
              [obj properties];
              [(Texture2D*)obj exportWithOptions:@{@"path" : exportPath, @"mode" : @(Texture2DExportOptionsTGA)}];
            }
          }
        }
      }
    }
  }
  if (s.length)
  {
    [result appendFormat:@"Texture Parameters:\n%@",s];
  }
  
  parameters = [self propertyValue:@"ScalarParameterValues"];
  s = [NSMutableString new];
  
  for (NSArray *paramterSet in parameters)
  {
    for (FPropertyTag *parameter in paramterSet)
    {
      if ([parameter.name isEqualToString:kPropNameNone])
      {
        [s appendString:@"\n"];
      }
      else if ([parameter.name isEqualToString:@"ParameterName"])
      {
        id v = parameter.value;
        if ([v isKindOfClass:[NSNumber class]])
        {
          [s appendFormat:@"\t%@: ", [parameter.package nameForIndex:[v intValue]]];
        }
        else
        {
          [s appendFormat:@"\t%@: ", v];
        }
      }
      else if ([parameter.name isEqualToString:@"ParameterValue"])
      {
        [s appendFormat:@"%@", parameter.value];
      }
    }
  }
  
  if (s.length)
  {
    [result appendFormat:@"Scalar Parameters:\n%@",s];
  }
  
  parameters = [self propertyValue:@"VectorParameterValues"];
  s = [NSMutableString new];
  
  for (NSArray *paramterSet in parameters)
  {
    for (FPropertyTag *parameter in paramterSet)
    {
      if ([parameter.name isEqualToString:kPropNameNone])
      {
        [s appendString:@"\n"];
      }
      else if ([parameter.name isEqualToString:@"ParameterName"])
      {
        id v = parameter.value;
        if ([v isKindOfClass:[NSNumber class]])
        {
          [s appendFormat:@"\t%@: ", [parameter.package nameForIndex:[v intValue]]];
        }
        else
        {
          [s appendFormat:@"\t%@: ", v];
        }
      }
      else if ([parameter.name isEqualToString:@"ParameterValue"])
      {
        [s appendFormat:@"%@", parameter.value];
      }
    }
  }
  
  if (s.length)
  {
    [result appendFormat:@"Vector Parameters:\n%@",s];
  }
  
  return result;
}


@end


@interface MaterialInstanceConstant ()

@end

@implementation MaterialInstanceConstant

- (FIStream *)postProperties
{
  FIStream *s = [super postProperties];
  if (self.dataSize)
  {
    if ([self hasStaticPermutationResource] && self.dataSize != s.position - self.rawDataOffset)
    {
      self.staticPermutationResource = [FStaticParameterSet readFrom:s];
    }
    if (self.dataSize != s.position - self.rawDataOffset)
      DThrow(@"Found unexpected data!");
  }
  return s;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [super cooked:offset];
  if (self.staticPermutationResource)
    [d appendData:[self.staticPermutationResource cooked:offset + d.length]];
  return d;
}

- (NSString *)exportIncluding:(BOOL)textures to:(NSString *)dataPath
{
  [self properties];
  NSMutableString *result = [NSMutableString new];
  [result appendString:[super exportIncluding:textures to:dataPath]];
  if (self.staticPermutationResource)
  {
    if (self.staticPermutationResource.staticSwitchParameters.count)
    {
      [result appendFormat:@"Static Switch Parameters:\n"];
    }
    for (FStaticSwitchParameter *p in self.staticPermutationResource.staticSwitchParameters)
    {
      [result appendFormat:@"\t%@: %@\n", p.parameterName.string, p.value ? @"True" : @"False"];
    }
    if (self.staticPermutationResource.staticComponentMaskParameters.count)
    {
      [result appendFormat:@"Static Component Mask Parameters:\n"];
    }
    for (FStaticComponentMaskParameter *p in self.staticPermutationResource.staticComponentMaskParameters)
    {
      NSString *components = @"";
      if (p.r)
      {
        components = [components stringByAppendingString:@"R "];
      }
      if (p.g)
      {
        components = [components stringByAppendingString:@"G "];
      }
      if (p.b)
      {
        components = [components stringByAppendingString:@"B "];
      }
      if (p.a)
      {
        components = [components stringByAppendingString:@"A "];
      }
      if (!components.length)
      {
        components = @"None";
      }
      [result appendFormat:@"\t%@: %@\n", p.parameterName.string, components];
    }
  }
  return result;
}


@end
