//
//  FPropertyTag.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PropertyController.h"
#import "FReadable.h"

FOUNDATION_EXPORT NSString *const kPropNameNone;
FOUNDATION_EXPORT NSString *const kPropTypeInt;
FOUNDATION_EXPORT NSString *const kPropTypeFloat;
FOUNDATION_EXPORT NSString *const kPropTypeObj;
FOUNDATION_EXPORT NSString *const kPropTypeName;
FOUNDATION_EXPORT NSString *const kPropTypeString;
FOUNDATION_EXPORT NSString *const kPropTypeStruct;
FOUNDATION_EXPORT NSString *const kPropTypeArray;
FOUNDATION_EXPORT NSString *const kPropTypeBool;
FOUNDATION_EXPORT NSString *const kPropTypeByte;
FOUNDATION_EXPORT NSString *const kPropTypeStructVector;
FOUNDATION_EXPORT NSString *const kPropTypeStructVector4;
FOUNDATION_EXPORT NSString *const kPropTypeStructColor;
FOUNDATION_EXPORT NSString *const kPropTypeStructLinearColor;
FOUNDATION_EXPORT NSString *const kPropTypeStructGuid;
FOUNDATION_EXPORT NSString *const kPropTypeStructRotator;
FOUNDATION_EXPORT NSString *const kPropTypeStructMatrix;
FOUNDATION_EXPORT NSString *const kPropTypeStructProperty;

@class UObject, FGUID, FName;
@interface FPropertyTag : FReadable 

@property (strong) FName                    *fname;
@property (strong) FName                    *ftype;
@property (strong) FName                    *fenum;
@property (assign) int                      dataSize;
@property (assign) int                      arrayIndex;
@property (assign) int                      elementCount;
@property (strong) FName                    *fstruct;

@property (nonatomic,strong) id             value;
@property (assign) UObject                  *object;
@property (strong) NSString                 *arrayType;
@property (nonatomic,strong) PropertyController *controller;
@property (assign) FPropertyTag             *parent;


+ (NSString *)propertyTypeForName:(NSString *)name ofClass:(NSString *)type;
+ (FPropertyTag *)propertyForName:(NSString *)aName from:(NSArray *)props;
+ (id)readFrom:(FIStream *)stream object:(UObject *)object;
+ (id)readFrom:(FIStream *)stream object:(UObject *)object parent:(FPropertyTag *)parent;
+ (id)intProperty:(int)value name:(NSString *)aName object:(UObject *)object;
+ (id)floatProperty:(float)value name:(NSString *)aName object:(UObject *)object;
+ (id)byteProperty:(long)value size:(int)size name:(NSString *)aName object:(UObject *)object;
+ (id)boolProperty:(BOOL)value name:(NSString *)aName object:(UObject *)object;
+ (id)nameProperty:(NSString *)value name:(NSString *)aName object:(UObject *)object;
+ (id)objectProperty:(UObject *)value name:(NSString *)aName object:(UObject *)object;
+ (id)stringProperty:(NSString *)value name:(NSString *)aName object:(UObject *)object;
+ (id)guidProperty:(FGUID *)guid name:(NSString *)aName object:(UObject *)object;
+ (id)linearColorProperty:(NSValue *)color name:(NSString *)aName object:(UObject *)object;
+ (id)colorProperty:(NSValue *)color name:(NSString *)aName object:(UObject *)object;
+ (id)rotatorProperty:(NSValue *)rotator name:(NSString *)aName object:(UObject *)object;
+ (id)vectorProperty:(NSValue *)vector name:(NSString *)aName object:(UObject *)object;
+ (id)vector4Property:(NSValue *)vector name:(NSString *)aName object:(UObject *)object;
+ (id)nonePropertyForObject:(UObject *)object;
- (NSDictionary *)dictionary;
- (NSData *)cooked;
- (void)recalculateSize;
- (NSString *)name;
- (NSString *)enumName;
- (NSString *)type;
- (NSString *)structName;
- (NSString *)xib;
- (BOOL)isNone;
- (id)formattedValue;

@end
