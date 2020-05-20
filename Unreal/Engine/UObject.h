//
//  UObject.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 18/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPropertyTag.h"
#import "FReadable.h"

typedef NS_ENUM(int, UObjectExportOptions)
{
  UObjectExportOptionsData = 0,
  UObjectExportOptionsAll = 1,
  UObjectExportOptionsProperties = 2
};

@class UObjectEditor, FPropertyTag, FStateFrame;
@interface UObject : FReadable
@property (strong) UObject        *native;
@property (assign) UObject        *archetype;
@property (assign) int            netIndex;
@property (assign) int            expressionIndex;
@property (assign) unsigned       dataSize;
@property (assign) unsigned       rawDataOffset;
@property (nonatomic,strong) NSMutableArray *properties;
@property (weak) FObjectExport    *exportObject;
@property (weak) FObjectImport    *importObject;
@property (nonatomic,strong) UObjectEditor   *editor;
@property (strong) NSData         *customData;
@property (assign) BOOL isZero;
@property (weak) id externalObject;

@property (strong) FStateFrame     *stateFrame;

+ (BOOL)isNative;
+ (id)zero;
- (BOOL)canExport;
+ (NSImage *)systemIcon:(OSType)iconCode;
- (NSImage *)icon;
- (FObject *)fObject;
- (NSString *)objectName;
- (NSString *)objectClass;
- (NSString *)displayName;
- (NSArray *)children;
- (BOOL)canHaveChildOfClass:(NSString *)className;
- (id)parent;

- (NSUInteger)bytesToEnd:(FIStream *)stream;

+ (id)objectForClass:(NSString *)className;
- (void)readProperties;
- (FIStream *)postProperties;
- (BOOL)isDirty;
- (void)setDirty:(BOOL)flag;

- (NSData *)exportWithOptions:(NSDictionary *)options;
- (NSMutableData *)cookedProperties;
- (NSMutableData *)cooked:(NSInteger)offset options:(NSDictionary *)options;
- (NSMutableData *)cookedIndex;
- (NSInteger)objectIndex;
- (NSString *)objectPath;
- (NSString *)objectNetPath;

- (FPropertyTag *)propertyForName:(NSString *)aName;
- (id)propertyValue:(NSString *)name;

- (void)cleanup;
- (void)testCook;
- (NSArray *)propertiesToPlist;

@end
