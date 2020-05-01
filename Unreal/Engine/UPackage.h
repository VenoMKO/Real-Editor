//
//  UPackage.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FReadable.h"
#import "Extensions.h"

NSArray *enumerateDirectory(NSURL *aUrl, int *validItems);

@interface RootExportObject : FObjectExport
+ (id)objectForPackage:(UPackage *)package;
@end

@interface RootImportObject : FObjectExport
+ (id)objectForPackage:(UPackage *)package;
@end

@class FIStream, FString, FGUID, FArray, PackageController;
@interface UPackage : NSObject

@property (strong) FIStream             *stream;
@property (assign) UGame                game;
@property (assign) int                  packageSource;
@property (strong, nonatomic) FGUID     *guid;
@property (assign) EPackageFlags        flags;
@property (assign) int                  compression;
@property (assign) short                fileVersion;
@property (assign) int                  cookedContentVersion;
@property (assign) int                  engineVersion;
@property (assign) short                licenseVersion;
@property (assign) int                  headerSize;
@property (retain) FString              *folderName;
@property (assign) int                  compressedChunksCount;
@property (assign) FCompressedChunk     *compressedChunks;
@property (strong) RootImportObject     *rootImports;
@property (strong) RootExportObject     *rootExports;
@property (strong) FArray               *generations;
@property (strong) NSMutableArray       *names;
@property (weak)   PackageController    *controller;
@property (strong) NSURL                *originalURL;
@property (strong) NSData               *cookedData;
@property (assign) BOOL                 isDirty;
@property (nonatomic, assign) int       namesOffset;
@property (nonatomic, assign) int       exportsOffset;
@property (nonatomic, assign) int       importsOffset;
@property (nonatomic, assign) int       dependsOffset;

+ (id)readFromURL:(NSURL *)url;
+ (id)readFromPath:(NSString *)path;
+ (id)readFrom:(FIStream *)stream;
- (NSString *)preheat;

- (UObject *)resolveImport:(FObjectImport *)import;
- (UObject *)resolveForcedExport:(FObjectExport *)object;
- (FObjectExport *)createExportObject:(NSString *)objectName class:(NSString *)objectClass;
- (void)addNewExportObject:(FObject *)object forParent:(FObject *)parent;

- (NSString *)nameForIndex:(NSInteger)index;
- (int)indexForName:(NSString *)name;

- (id)objectForIndex:(NSInteger)index;
- (id)objectForNetIndex:(int)index name:(NSString *)name;
- (int)indexForObject:(id)object;

- (id)fobjectForIndex:(NSInteger)index;
- (NSArray *)allObjectsOfClass:(NSString *)objectClass;
- (NSArray *)allExports;

- (NSString *)name;
- (NSString *)extension;

- (NSString *)cook:(NSDictionary *)options;

- (NSDictionary *)dummpExports;
@end
