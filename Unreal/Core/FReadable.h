//
//  FReadable.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FStream.h"

@class FGUID, UObject, FArray;

@interface FReadable : NSObject

@property (weak) UPackage   *package;

+ (instancetype)newWithPackage:(UPackage *)package;
+ (instancetype)readFrom:(FIStream *)stream;
- (NSMutableData *)cooked:(NSInteger)offset;
- (id)plist;

@end

@interface FObject : FReadable

@property (assign) int      nameIdx;
@property (assign) long     classIdx;
@property (assign) int      parentIdx;
@property (retain) UObject  *object;
@property (assign) BOOL     isExpanded;
@property (retain) NSMutableArray *children;

- (NSString *)objectName;
- (NSString *)objectClass;
- (FObject *)parent;
- (NSImage *)icon;
- (void)addChild:(id)child;
- (void)removeChild:(id)child;
- (void)cleanup;
- (BOOL)visibleForSearch:(NSString *)search;
- (NSArray *)childrenForSearch:(NSString *)search;

@end

@interface FObjectExport : FObject

@property (assign) int      superIdx;
@property (assign) long     archetypeIdx;
@property (assign) RFObjectFlags     objectFlags;
@property (assign) unsigned serialSize;
@property (assign) unsigned serialOffset;
@property (assign) unsigned originalOffset;
@property (assign) EFExportFlags      exportFlags;
@property (retain) FArray  *generationNetObjectCount;
@property (retain) FGUID    *packageGuid;
@property (assign) EPackageFlags      packageFlags;

- (NSData *)cookedWithOptions:(NSDictionary *)options objectData:(NSMutableData *)objectData;
- (NSString *)objectPath;

@end

@interface FObjectImport : FObject

@property (assign) long     classPackage;
@property (assign) int      unkw;

- (void)serialize;
- (NSString *)objectPath;

@end

@interface FObjectRef : FReadable
@property (assign) int      value;
@end
