//
//  UPackage.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UPackage.h"
#import "Extensions.h"
#import "FStream.h"
#import "FString.h"
#import "FGUID.h"
#import "FArray.h"
#import "FReadable.h"
#import "UObject.h"
#import "PackageController.h"
#import <Cocoa/Cocoa.h>
#define PACKAGE_MAGIC               0x9E2A83C1
#define TERA_COOKER_V               76
#define TERA_ENGINE_V               4206
#define SUPPERTED_FV                @[@(610),@(864)] // 864 aka Bless not supported. just for testing
#define SUPPORTED_LV                @[@(13),@(14),@(9)]
#define CRC32_POLY                  0x04C11DB7

unsigned int CRCLookUpTable[256];
static BOOL crcInit = NO;

void InitCRCTable()
{
  for( unsigned int iCRC=0; iCRC<256; iCRC++ )
    for( unsigned int c=iCRC<<24, j=8; j!=0; j-- )
      CRCLookUpTable[iCRC] = c = c & 0x80000000 ? (c << 1) ^ CRC32_POLY : (c << 1);
}

unsigned int CRCForString( const char *Data , int Length)
{
  if (!crcInit)
    InitCRCTable();
  
  unsigned int CRC = 0xFFFFFFFF;
  
  for( int i=0; i<Length; i++ )
  {
    char C    = toupper(Data[i]);
    int   CL  = (C&0xFF);
    CRC       = (CRC << 8) ^ CRCLookUpTable[(CRC >> 24) ^ CL];
    int   CH  = (C>>8)&0xFF;
    CRC       = (CRC << 8) ^ CRCLookUpTable[(CRC >> 24) ^ CH];
  }
  return ~CRC;
}

@interface FGeneration : FReadable
@property (assign) int              exports;
@property (assign) int              names;
@property (assign) int              imports;
@end

@implementation FGeneration

+ (instancetype)readFrom:(FIStream *)stream
{
  FGeneration *gen = [super readFrom:stream];
  BOOL err = NO;
  gen.exports = [stream readInt:&err];
  gen.names = [stream readInt:&err];
  gen.imports = [stream readInt:&err];
  if (err)
  {
    DThrow(kErrorUnexpectedEnd);
    return nil;
  }
  return gen;
}

- (NSData *)cooked:(NSInteger)offset
{
  NSMutableData *d = [NSMutableData data];
  [d writeInt:self.exports];
  [d writeInt:self.names];
  [d writeInt:self.imports];
  return d;
}

@end

@interface UPackage ()

@property (assign) int              namesCount;
@property (assign) int              exportsCount;
@property (assign) int              importsCount;
@property (strong) FArray           *additionalPackagesToCook;
@property (retain) NSMutableArray   *dependentPackages;
@property (retain) NSMutableArray   *failedToLoadPackages;

@property (retain) NSMutableArray   *imports;
@property (retain) NSMutableArray   *topImports;
@property (retain) NSMutableArray   *exports;
@property (retain) NSMutableArray   *topExports;
@property (retain) NSMutableArray   *depends;

@property (assign) int              compressionChunkOffset;

@end

#pragma mark - Package

@implementation UPackage

- (void)dealloc
{
  self.dependentPackages = nil;
  if (self.originalURL)
    [[NSFileManager defaultManager] removeItemAtPath:self.stream.url.path error:NULL];
}

#pragma mark - Constructing

+ (id)readFromURL:(NSURL *)url
{
  FIStream *stream = [FIStream streamForUrl:url];
  return [self readFrom:stream];
}

+ (id)readFromPath:(NSString *)path
{
  FIStream *stream = [FIStream streamForPath:path];
  return [self readFrom:stream];
}

+ (id)readFrom:(FIStream *)stream
{
  UPackage *p = [UPackage new];
  NSString *error = [p readFrom:stream];
  
  if (error)
  {
    NSAppError(p, error);
    return nil;
  }
  
  return p;
}

- (NSString *)name
{
  if (self.originalURL)
    return [[self.originalURL lastPathComponent] stringByDeletingPathExtension];
  return [[self.stream.url lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)extension
{
  return [[self.stream.url lastPathComponent] pathExtension];
}

- (NSString *)readFrom:(FIStream *)s
{
  self.stream = s;
  s.package = self;
  return [self readHeader];
}

- (NSString *)validateFVLV
{
  BOOL validFV = NO;
  BOOL validLV = NO;
  
  for (NSNumber *vFV in SUPPERTED_FV)
  {
    if ([vFV intValue] == self.fileVersion)
    {
      validFV = YES;
      break;
    }
  }
  
  for (NSNumber *vLV in SUPPORTED_LV)
  {
    if ([vLV intValue] == self.licenseVersion)
    {
      validLV = YES;
      break;
    }
  }
  
  if (!validFV || !validLV)
    return [NSString stringWithFormat:@"Unknown package version: %d/%d",self.fileVersion,self.licenseVersion];
  return nil;
}

- (NSString *)readHeader
{
  BOOL err = NO;
  NSString *error = nil;
  FIStream *s = self.stream;
  s.position = 0;
  if ([s readInt:&err] != PACKAGE_MAGIC)
    return @"Unsupported package!";
  
  self.fileVersion = [s readShort:&err];
  self.licenseVersion = [s readShort:&err];
  
  if ((error = [self validateFVLV]))
    return error;
  
  if (self.fileVersion == 864 && self.licenseVersion == 9) // just for tests
  {
    self.game = UGameBless;
  }
  else
  {
    self.game = UGameTera;
  }
  s.game = self.game;
  self.headerSize = [s readInt:&err];
  self.folderName = [FString readFrom:s];
  self.flags = [s readInt:&err];
  self.namesCount = [s readInt:&err];
  self.namesOffset = [s readInt:&err];
  self.exportsCount = [s readInt:&err];
  self.exportsOffset = [s readInt:&err];
  self.importsCount = [s readInt:&err];
  self.importsOffset = [s readInt:&err];
  self.dependsOffset = [s readInt:&err];
  if (self.game == UGameBless)
  {
    [s readInt:&err];
    [s readInt:&err];
    [s readInt:&err];
    [s readInt:&err];
  }
  self.guid = [FGUID readFrom:s];
  self.generations = [FArray readFrom:s type:[FGeneration class]];
  if (!self.generations)
    return @"Failed to read!";
  self.engineVersion = [s readInt:&err];
  self.cookedContentVersion = [s readInt:&err];
  self.compression = [s readInt:&err];
  self.compressedChunksCount = [s readInt:&err];
  if (self.compressedChunksCount)
    self.compressedChunks = [s readBytes:sizeof(FCompressedChunk) * self.compressedChunksCount error:&err];
  
  self.packageSource = [s readInt:&err];
  
  // For compressed packages we don't want to read this coz it constains unknown value
  if (!self.additionalPackagesToCook) // TODO: this check should not exists in the first place. What kind of value is this after decompression?
    self.additionalPackagesToCook = [FArray readFrom:s type:[FString class]];
  
  if (self.flags & PKG_StoreCompressed)
  {
    if (![self decompress])
    {
      NSString *err = [self readHeader];
      return err ? [NSString stringWithFormat:@"Failed to decompress: %@",err] : nil; // Read header again to check if decompressed successfuly
    }
    else
      return @"Failed to decompress!";
  }
  
  if (self.game == UGameTera && self.licenseVersion == 14 && self.fileVersion == 610 && self.cookedContentVersion) //Tera obfuscation
    self.namesCount -= self.namesOffset;
  
  {
    if (err)
      return kErrorUnexpectedEnd;
  }
  
  return nil;
}

- (NSString *)readTables
{
  FIStream *s = self.stream;
  
  s.position = self.namesOffset;
  self.names = [NSMutableArray readFrom:s class:[FNamePair class] length:self.namesCount];
  if (!self.names)
    return @"Error! Failed to read names table";
  
  s.position = self.importsOffset;
  self.imports = [NSMutableArray readFrom:s class:[FObjectImport class] length:self.importsCount];
  if (!self.imports)
    return @"Error! Failed to read imports table";
  
  s.position = self.exportsOffset;
  self.exports = [NSMutableArray readFrom:s class:[FObjectExport class] length:self.exportsCount];
  if (!self.imports)
    return @"Error! Failed to read exports table";
  
  s.position = self.dependsOffset;
  self.depends = [NSMutableArray readFrom:s class:[FObjectRef class] length:self.exportsCount];
  
  return nil;
}

- (void)buildObjectTrees
{
  self.topImports = [NSMutableArray new];
  for (int i = 0; i < self.imports.count; i++)
    [self.imports[i] serialize];
  for (int i = 0; i < self.imports.count; i++)
    if (![self.imports[i] parent])
      [self.topImports addObject:self.imports[i]];
  
  self.topExports = [NSMutableArray new];
  for (int i = 0; i < self.exports.count; i++)
    [self.exports[i] serialize];
  for (int i = 0; i < self.exports.count; i++)
    if (![self.exports[i] parent])
      [self.topExports addObject:self.exports[i]];
}

- (NSString *)preheat
{
  NSString *error = [self readTables];
  if (!error)
  {
    self.rootExports = [RootExportObject objectForPackage:self];
    self.rootImports = [RootImportObject objectForPackage:self];
    [self buildObjectTrees];
#if DEBUG
    NSArray *arg = [[NSProcessInfo processInfo] arguments];
    if ([arg indexOfObject:@"-fullRead"] != NSNotFound || [arg indexOfObject:@"-testCook"] != NSNotFound)
    {
      DLog(@"Found FullRead flag!");
      for (FObjectExport *export in self.exports)
      {
        DLog(@"Reading %@(%@)",export.objectName,export.objectClass);
        [export.object readProperties];
      }
    }
    
    if ([arg indexOfObject:@"-testCook"] != NSNotFound)
    {
      DLog(@"Found TestCook flag!");
      for (FObjectExport *export in self.exports)
      {
        DLog(@"Testing %@(%@)",export.objectName,export.objectClass);
        @try {
          [export.object testCook];
        } @catch (NSException *exception) {
          
        }
      }
    }
#endif
  }
  
  return error;
}


- (BOOL)decompress
{
  FIStream *s = self.stream;
  if (self.flags & PKG_StoreCompressed)
  {
    int totalCompressedSize = 0;
    int totalDecompressedSize = 0;
    int startOffset = INT32_MAX;
    int startOffset2 = INT32_MAX;
    
    for (int i = 0; i < self.compressedChunksCount; i++)
    {
      totalCompressedSize += self.compressedChunks[i].compressedSize;
      totalDecompressedSize += self.compressedChunks[i].decompressedSize;
      startOffset = MIN(startOffset,self.compressedChunks[i].decompressedOffset);
      startOffset2 = MIN(startOffset2,self.compressedChunks[i].compressedOffset);
    }
    
    NSMutableData *decompressedData = [NSMutableData dataWithLength:totalDecompressedSize + startOffset];
    s.position = 0;
    NSData *header = [s readData:startOffset];
    [decompressedData replaceBytesInRange:NSMakeRange(0, startOffset) withBytes:header.bytes];
    
    int nFlags = self.flags;
    nFlags &= ~PKG_StoreCompressed;
    int flagsOffset = 12 + (int)[[self.folderName cooked] length];
    [decompressedData replaceBytesInRange:NSMakeRange(flagsOffset, 4) withBytes:&nFlags];
    
    for (int i = 0; i < self.compressedChunksCount; i++)
    {
      [s setPosition:self.compressedChunks[i].compressedOffset];
      
      if (self.compression == COMPRESSION_LZO || self.compression == COMPRESSION_ZLIB) {
        
        uint8_t *tBuf = malloc(self.compressedChunks[i].compressedSize);
        [s read:tBuf maxLength:self.compressedChunks[i].compressedSize];
        
        NSMutableData *decompressedChunk = [NSMutableData data];
        
        BOOL r = NO;
        
        if (self.compression == COMPRESSION_LZO)
          r = decompressLZO(tBuf, decompressedChunk);
        else
          r = decompressZLib(tBuf, decompressedChunk);
        
        if (r)
        {
          [decompressedData replaceBytesInRange:NSMakeRange(self.compressedChunks[i].decompressedOffset, self.compressedChunks[i].decompressedSize) withBytes:decompressedChunk.bytes];
          free(tBuf);
        }
        else
        {
          decompressedData = nil;
          free(tBuf);
          break;
        }
        
      }
      else
      {
        NSAppError(self,@"Error! Not supported compression(0x%08X)!",self.compression);
        return YES;
      }
    }
    
    free(self.compressedChunks);
    
    self.compressedChunks = nil;
    self.compressedChunksCount = 0;
    
    if (!decompressedData)
      return YES;
    
    NSString *newName = [[self.stream.url lastPathComponent] stringByDeletingPathExtension];
    
    newName = [NSTemporaryDirectory() stringByAppendingPathComponent:newName];
    newName = [[newName stringByAppendingFormat:@"_temp_%@",[[NSUUID UUID] UUIDString]] stringByAppendingPathExtension:[self.stream.url pathExtension]];
    [decompressedData writeToFile:newName atomically:NO];
    
    self.originalURL = self.stream.url;
    self.stream = [FIStream streamForPath:newName];
    self.stream.package = self;
    return NO;
  }
  return NO;
}

- (int)calculateNamesSize
{
  int size = 0;
  for (FName *name in self.names)
  {
    size+=[[name cooked:0] length];// flags
  }
  return size;
}

- (int)calculateImportsSize
{
  return 28 * self.importsCount;
}

- (int)calculateDependsSize
{
  return 4 * (int)self.exports.count + 4;
}

- (int)calculateExportsSize
{
  int size = 0;
  for (FObjectExport *exp in self.exports)
  {
    size+=64;
    if (exp.serialSize)
      size+=4;
    if (exp.generationNetObjectCount.count)
      size += exp.generationNetObjectCount.count * 4;
  }
  return size;
}

- (int)calculateHeaderSize
{
  int size = 80;//default size
  size += [[self.folderName cooked] length];
  size += [self calculateNamesSize];
  size += [self calculateExportsSize];
  size += [self calculateImportsSize];
  size += [self calculateDependsSize];
  size += [self.generations cooked:0].length; // generations
  size += self.compressedChunksCount * sizeof(FCompressedChunk); // compression chunks
  return size;
}

- (NSMutableData *)cookedHeaderSummery
{
  NSMutableData *data = [NSMutableData data];
  BOOL useHeaderData = self.exports ? NO : YES; // Use header data if we have not loaded tables yet
  
  [data writeInt:PACKAGE_MAGIC];
  [data writeShort:self.fileVersion];
  [data writeShort:self.licenseVersion];
  [data writeInt:useHeaderData ? self.headerSize : [self calculateHeaderSize]];
  [data appendData:[self.folderName cooked]];
  [data writeInt:self.flags];

  
  if (!useHeaderData)
  {
    int tableOffset = 84;
    tableOffset += (int)[[self.folderName cooked] length] + 4;
    tableOffset += self.generations.count * 12;
    tableOffset += self.compressedChunksCount * sizeof(FCompressedChunk); // compression chunks
    
    self.namesOffset = tableOffset;
    if (self.licenseVersion == 14 && self.fileVersion == 610)
      [data writeInt:(int)self.names.count + tableOffset];
    else
      [data writeInt:(int)self.names.count];
    [data writeInt:tableOffset];
    
    tableOffset += [self calculateImportsSize] + [self calculateNamesSize];
    self.exportsOffset = tableOffset;
    [data writeInt:(int)self.exports.count];
    [data writeInt:tableOffset];
    
    tableOffset -= [self calculateImportsSize];
    self.importsOffset = tableOffset;
    [data writeInt:(int)self.imports.count];
    [data writeInt:tableOffset];
    
    tableOffset += [self calculateExportsSize] + [self calculateImportsSize];
    self.dependsOffset = tableOffset;
    [data writeInt:tableOffset];
  }
  else
  {
    [data writeInt:self.namesCount];
    [data writeInt:self.namesOffset];
    [data writeInt:self.exportsCount];
    [data writeInt:self.exportsOffset];
    [data writeInt:self.importsCount];
    [data writeInt:self.importsOffset];
    [data writeInt:self.dependsOffset];
  }
  
  
  [data appendData:[self.guid cooked]];
  
  [data appendData:[self.generations cooked:0]];
  
  [data writeInt:self.engineVersion];
  [data writeInt:self.cookedContentVersion];
  
  [data writeInt:self.compression];
  [data writeInt:self.compressedChunksCount];
  if (self.compressedChunksCount)
  {
    // Stub
    // Chunks will be overwritten after export cooking phase
    self.compressionChunkOffset = (int)[data length];
    [data appendBytes:self.compressedChunks length:sizeof(FCompressedChunk) * self.compressedChunksCount];
  }
  else
    self.compressionChunkOffset = -1;
  
  [data writeInt:self.packageSource];
  [data appendData:[self.additionalPackagesToCook cooked:0]];
  
  return data;
}

- (NSString *)cook:(NSDictionary *)options
{
  self.folderName = [FString stringWithString:@"yupimods.tumblr.com"];
  if ([options[@"UpdateGen"] boolValue])
  {
    FGeneration *g = [FGeneration newWithPackage:self];
    g.names = (int)self.names.count;
    g.exports = (int)self.exports.count;
    g.imports = (int)self.imports.count;
    [self.generations addObject:g];
  }
  
  if ([options[@"CRC"] boolValue] && [options[@"Name"] length])
  {
    self.packageSource = CRCForString([options[@"Name"] UTF8String], (int)[options[@"Name"] length]);
  }
  
  self.compression = [options[@"Compression"] intValue];
  if (self.compressedChunks)
  {
    free(self.compressedChunks);
    self.compressedChunks = 0;
    self.compressedChunksCount = 0;
  }
  
  if (self.compression)
  {
    if (!(self.flags & PKG_StoreCompressed))
      self.flags |= PKG_StoreCompressed;
    self.compressedChunksCount = [options[@"SingleChunk"] boolValue] ? 1 : (ceilf((float)self.exports.count / 10.0f) + 1);
    self.compressedChunks = calloc(self.compressedChunksCount, sizeof(FCompressedChunk));
  }
  
  NSMutableData *cookedHeader = [NSMutableData data];
  
  [cookedHeader appendData:[self cookedHeaderSummery]];
  self.cookedData = cookedHeader;
  self.headerSize = (int)cookedHeader.length;
  NSUInteger testOffset = cookedHeader.length;
  
  if(testOffset != self.namesOffset)
    return [NSString stringWithFormat:@"Invalid names offset %lu expected %d",(unsigned long)testOffset,self.namesOffset];
  
  NSMutableData *cookedNames = [NSMutableData data];
  for (FName *name in self.names)
    [cookedNames appendData:[name cooked:0]];
  
  testOffset = cookedHeader.length + cookedNames.length;
  if(testOffset != self.importsOffset)
    return [NSString stringWithFormat:@"Invalid imports offset %lu expected %d",(unsigned long)testOffset,self.importsOffset];
  
  NSMutableData *cookedImports = [NSMutableData data];
  for (FObjectImport *import in self.imports)
    [cookedImports appendData:[import cooked:0]];
  
  testOffset = cookedHeader.length + cookedNames.length + cookedImports.length;
  if(testOffset != self.exportsOffset)
    [NSString stringWithFormat:@"Invalid exports offset %lu expected %d",(unsigned long)testOffset,self.exportsOffset];
    
  NSMutableData *cookedExports = [NSMutableData data];
  
  if (self.depends.count != self.exports.count)
  {
    int additionalDepends = (int)(self.exports.count - self.depends.count);
    for (int i = 0; i < additionalDepends; i++)
    {
      FObjectRef *ref = [FObjectRef newWithPackage:self];
      ref.value = 0;
      [self.depends addObject:ref];
    }
  }
  
  [self.controller setMaxProgress:self.exports.count];
  [self.controller setProgressValue:0];
  [self.controller setProgressDescriptionValue:@"Cooking..."];
  [self.controller setProgressStateValue:@""];
  
  NSMutableData *objectData = [NSMutableData data];
  int objectDataOffset = self.exportsOffset + [self calculateExportsSize] + (int)(self.depends.count * 4);
  int progressIndex = 0;
  
  NSString *err = nil;
  for (FObjectExport *export in self.exports)
  {
    @autoreleasepool
    {
      [self.controller setProgressStateValue:export.objectName];
      
      NSMutableData *oData = [NSMutableData data];
      export.serialOffset = objectDataOffset;
      NSData *expData = nil;
      if (!(expData = [export cookedWithOptions:@{} objectData:oData]))
      {
        err = [NSString stringWithFormat:@"Failed to cook %@",export.objectName];
        break;
      }
      
      [cookedExports appendData:expData];
      objectDataOffset += (int)[oData length];
      [objectData appendData:oData];
      [self.controller setProgressValue:progressIndex++];
      
      if (self.controller.progressCanceled)
        break;
      
    }
  }
  
  if (err)
    return err;
  
  if (self.controller.progressCanceled)
    return nil;
  
  testOffset = cookedHeader.length + cookedNames.length + cookedImports.length + cookedExports.length;
  if(testOffset != self.dependsOffset)
    return [NSString stringWithFormat:@"Invalid exports offset %lu expected %d",testOffset,self.dependsOffset];
    
  NSMutableData *cookedDepends = [NSMutableData data];
  for (FObjectRef *ref in self.depends)
    [cookedDepends appendData:[ref cooked:0]];
  
  NSMutableData *packageData = [NSMutableData dataWithData:cookedNames];
  [packageData appendData:cookedImports];
  [packageData appendData:cookedExports];
  [packageData appendData:cookedDepends];
  [packageData appendData:objectData];
  
  if (self.compression)
  {
    int chunkIndex = 0;
    int offset = 0;
    int compressedOffset = self.headerSize;
    [self.controller setMaxProgress:self.compressedChunksCount];
    [self.controller setProgressValue:chunkIndex];
    [self.controller setProgressDescriptionValue:@"Compressing..."];
    [self.controller setProgressStateValue:@""];
    
    NSMutableData *chunks = [NSMutableData new];
    
    for (; chunkIndex < self.compressedChunksCount; ++chunkIndex)
    {
      [self.controller setProgressValue:chunkIndex];
      NSInteger length = 0;
      
      if (self.compressedChunksCount == 1)
      {
        length = packageData.length;
      }
      else
      {
        if (!chunkIndex) // First chunk contains all tables (exports, imports, depends, names) but no objects
        {
          length = [self.exports[0] serialOffset] - self.headerSize;
        }
        else
        {
          int objectIndex = (int)MIN(self.exports.count - 1,chunkIndex * 10); // Each chunk should contain 10 objects
          length = [self.exports[objectIndex] serialOffset] - offset - self.headerSize;
          if (objectIndex == (self.exports.count - 1))
            length += [self.exports[objectIndex] serialSize];
        }
      }
      NSData *raw = [packageData subdataWithRange:NSMakeRange(offset, length)];
      if (chunkIndex+1 == self.compressedChunksCount)
        assert(offset+length == packageData.length);
      NSMutableData *compressedData = [NSMutableData new];
      if (self.compression & COMPRESSION_LZO)
      {
        if (!compressLZO(raw, compressedData))
          return @"Error! Failed to compress package!";
      }
      else if (self.compression & COMPRESSION_ZLIB)
      {
        if (!compressZLib(raw, compressedData))
          return @"Error! Failed to compress package!";
      }
      
      FCompressedChunk *chunk = &self.compressedChunks[chunkIndex];
      chunk->decompressedOffset = offset + self.headerSize;
      chunk->decompressedSize = (int)length;
      chunk->compressedSize = (int)compressedData.length;
      chunk->compressedOffset = compressedOffset;
      
      compressedOffset += (int)compressedData.length;
      offset += length;
      [chunks appendData:compressedData];
      
      if (self.controller.progressCanceled)
        return nil;
    }
    
    cookedHeader = [self cookedHeaderSummery];
    if (cookedHeader.length != self.headerSize)
      return @"Error! Compression size missmatch!";
    [cookedHeader appendData:chunks];
    self.cookedData = cookedHeader;
  }
  else
  {
    [cookedHeader appendData:packageData];
  }
  return nil;
}
#ifdef DEBUG
- (UObject *)_legacyResolveImport:(FObjectImport *)import at:(NSURL *)url
{
  FObjectImport *imp = import;
  
  while (imp.parent)
  {
    imp = (FObjectImport *)imp.parent;
  }
  
  if (imp) {
    for (UPackage *p in self.dependentPackages) {
      NSString *n = [p name];
      if ([n isEqualToString:imp.objectName]) {
        for (FObjectExport *e in p.exports) {
          if ([e.objectName isEqualToString:import.objectName]) {
            if (!e.object) {
              assert(0);
            }
            return e.object;
          }
        }
      }
    }
    int cnt = 0;
    NSArray *items = enumerateDirectory(url, &cnt);
    NSURL *packagePath = nil;
    for (NSURL *path in items) {
      NSString *n = [[path lastPathComponent] stringByDeletingPathExtension];
      if ([n isEqualToString:imp.objectName]) {
        packagePath = path;
        break;
      }
    }
    if (packagePath) {
      UPackage *p = [UPackage readFromURL:packagePath];
      [p preheat];
      
      [self.dependentPackages addObject:p];
      for (FObjectExport *e in p.exports) {
        if ([e.objectName isEqualToString:import.objectName]) {
          UObject *o = e.object;
          [o readProperties];
          return o;
        }
      }
    }
  }
  return nil;
}
#endif

- (UObject *)resolveImport:(FObjectImport *)import at:(NSURL *)url
{
  NSURL *packagePath = nil;
  NSString *objectPath = [import objectPath];
  NSArray *pathComponents = [objectPath componentsSeparatedByString:@"."];
  @synchronized (self)
  {
    if (self.failedToLoadPackages && [self.failedToLoadPackages indexOfObject:[pathComponents firstObject]] != NSNotFound)
      return nil;
    if (!self.dependentPackages)
      self.dependentPackages = [NSMutableArray new];
    
    for (UPackage *package in self.dependentPackages)
    {
      NSString *n = [package name];
      if ([n isEqualToString:pathComponents[0]])
      {
        return [package objectForPath:objectPath];
      }
    }
    
    int cnt = 0;
    NSArray *items = enumerateDirectory(url, &cnt);
    for (NSURL *itemURl in items)
    {
      NSString *n = [[itemURl.path lastPathComponent] stringByDeletingPathExtension];
      if ([n compare:[pathComponents firstObject] options:NSCaseInsensitiveSearch] == NSOrderedSame)
      {
        
        packagePath = itemURl;
        break;
      }
    }
    
    if (!packagePath)
    {
      if (!self.failedToLoadPackages)
      {
        self.failedToLoadPackages = [NSMutableArray new];
        [self.failedToLoadPackages addObject:[pathComponents firstObject]];
      }
      DLog(@"Failed to find package '%@'", [pathComponents firstObject]);
      return nil;
    }
    
    UPackage *package = [UPackage readFromURL:packagePath];
    if (!package)
      return nil;
    [package preheat];
    [self.dependentPackages addObject:package];
    return [package objectForPath:objectPath];
  }
}

- (UObject *)resolveImport:(FObjectImport *)import
{
  // TODO: should consider import's class when resolving import
  NSUserDefaults *d  = [NSUserDefaults standardUserDefaults];
  if (![d boolForKey:kSettingsLookForDepends])
    return nil;
  
  UObject *ret = nil;
  NSString *path = [d stringForKey:kSettingsProjectDir];
  if (path)
    ret = [self resolveImport:import at:[NSURL fileURLWithPath:path]];
  
  if (!ret)
  {
    if (self.originalURL)
      path = [[self originalURL] path];
    else
      path = [self.stream.url path];
    path = [path stringByDeletingLastPathComponent];
    ret = [self resolveImport:import at:[NSURL fileURLWithPath:path]];
  }
  
  return ret;
}

- (UObject *)objectForPath:(NSString *)path
{
  NSArray *components = [path componentsSeparatedByString:@"."];
  UObject *obj = nil;
  NSArray *allExports = self.allExports;
  for (int idx = 1; idx < components.count; ++idx)
  {
    NSString *itemName = components[idx];
    NSArray *children = obj.children;
    BOOL found = NO;
    if (obj.children)
    {
      for (UObject *o in children)
      {
        if ([o.objectName isEqualToString:itemName])
        {
          obj = o;
          found = YES;
          break;
        }
      }
      
      if (!found)
        return nil;
    }
    else if (idx == 1)
    {
      for (UObject *o in allExports)
      {
        if ([o.objectName isEqualToString:itemName])
        {
          obj = o;
          break;
        }
      }
    }
  }
  if ([obj isKindOfClass:[FObject class]])
    obj = [(FObject *)obj object];
  return obj;
}

- (FObjectExport *)createExportObject:(NSString *)objectName class:(NSString *)objectClass
{
  FObjectExport *obj = [FObjectExport newWithPackage:self];
  obj.nameIdx = [self indexForName:objectName];
  NSInteger idx = NSNotFound;
  for (FObjectImport *imp in self.imports)
  {
    if ([imp.objectName isEqualToString:objectClass] && [imp.objectClass isEqualToString:kClass])
    {
      idx = [self indexForObject:imp];
      break;
    }
  }
  if (idx == NSNotFound)
  {
    //TODO: create new class object
    DThrow(@"Class do not exist! TODO: create new class object");
    return nil;
  }
  obj.classIdx = idx;
  return obj;
}

- (void)addNewExportObject:(FObject *)object forParent:(FObject *)parent
{
  [self.exports addObject:object];
  if (!parent.children)
    parent.children = [NSMutableArray new];
  [parent.children addObject:object];
  object.parentIdx = [self indexForObject:parent];
  self.exportsCount += 1;
}

#pragma mark - Helpers

- (NSString *)nameForIndex:(NSInteger)index
{
  if (index >= self.names.count)
  {
    DThrow(@"Warning! Incorrect name index %ld!",index);
    return nil;
  }
  return [self.names[index] string];
}

- (int)indexForName:(NSString *)name
{
  if ([name isKindOfClass:[FName class]]) {
    NSInteger idx = [self.names indexOfObject:name];
    if (idx == NSNotFound)
      [self.names addObject:name];
    return (int)[self.names indexOfObject:name];
  } else {
    for (int i = 0; i < self.names.count; i++) {
      if ([[self.names[i] string] isEqualToString:name])
        return i;
    }
    FNamePair *newStr = [FNamePair stringWithString:name];
    newStr.flags = 0x0007001000000000;
    [self.names addObject:newStr];
    self.namesCount++;
    [self.controller updateNames];
    return (int)[self.names indexOfObject:newStr];
  }
}

- (id)objectForIndex:(NSInteger)index
{
  if (index < 0 && (-index - 1) < self.imports.count) {
    return [self.imports[-index - 1] object];
  } else {
    if (index - 1 >= 0 && index <= self.exports.count)
      return [self.exports[index - 1] object];
    
    if (index)
    {
      DThrow(@"Failed to resolve object with index: %ld",index);
    }
    return nil;
  }
}

- (id)fobjectForIndex:(NSInteger)index
{
  if (index < 0) {
    return self.imports[-index - 1];
  } else {
    if (index - 1 >= 0)
      return self.exports[index - 1];
    else
    {
      
      if (index)
      {
        DThrow(@"Failed to resolve object with index: %ld",index);
      }
      return nil;
    }
  }
}

- (int)indexForObject:(id)object
{
  FObjectExport *exp = nil;
  FObjectImport *imp = nil;
  if ([object isKindOfClass:[FObjectExport class]])
    exp = object;
  else if ([object isKindOfClass:[FObjectImport class]])
    imp = object;
  else
  {
    
    if ([(UObject *)object importObject])
      imp = [(UObject *)object importObject];
    else if ([(UObject *)object exportObject])
      exp = [(UObject *)object exportObject];
     
  }
  
  if (!exp && !imp)
    return INT32_MAX;
  
  return exp ? (int)[self.exports indexOfObject:exp] + 1 : -(int)[self.imports indexOfObject:imp] - 1;
}

- (NSArray *)allObjectsOfClass:(NSString *)objectClass
{
  NSMutableArray *arr = [NSMutableArray new];
  
  for (FObjectExport *expObject in self.exports)
  {
    if ((!objectClass || [objectClass isEqualToString:expObject.objectClass]) &&
        ![expObject.objectClass isEqualToString:kClassPackage])
      [arr addObject:[expObject object]];
  }
  
  for (FObjectImport *impObject in self.imports)
  {
    if ((!objectClass || [objectClass isEqualToString:impObject.objectClass]) &&
        ![impObject.objectClass isEqualToString:@"Class"] &&
        ![impObject.objectClass isEqualToString:kClassPackage])
      [arr addObject:[impObject object]];
  }
  
  return arr;
}

- (NSArray *)allExports
{
  NSMutableArray *arr = [NSMutableArray new];
  
  for (FObjectExport *expObject in self.exports)
  {
    [arr addObject:[expObject object]];
  }
  return arr;
}

- (NSDictionary *)dummpExports
{
#if DEBUG
  NSMutableDictionary *result = [NSMutableDictionary new];
  
  for (FObjectExport *export in self.exports)
  {
    result[[NSString stringWithFormat:@"%d %@ BEGIN",[self indexForObject:export],export.objectName]] = [NSString stringWithFormat:@"%d",export.originalOffset];
    result[[NSString stringWithFormat:@"%d %@ END",[self indexForObject:export],export.objectName]] = [NSString stringWithFormat:@"%d",export.originalOffset + export.serialSize];
  }
  
  return result;
#else
  return nil;
#endif
}

@end

@implementation RootExportObject

+ (id)objectForPackage:(UPackage *)package
{
  RootExportObject *obj = [RootExportObject newWithPackage:package];
  return obj;
}

- (NSString *)objectName
{
  return self.package.name;
}

- (NSString *)objectClass
{
  return kClassPackage;
}

- (NSArray *)children
{
  return self.package.topExports;
}

- (NSImage *)icon
{
  return [UObject systemIcon:kGenericFloppyIcon];
}

- (BOOL)canHaveChildOfClass:(NSString *)className
{
  return YES;
}

@end

@implementation RootImportObject

+ (id)objectForPackage:(UPackage *)package
{
  RootImportObject *obj = [RootImportObject newWithPackage:package];
  return obj;
}

- (NSString *)objectName
{
  return self.package.name;
}

- (NSString *)objectClass
{
  return kClassPackage;
}

- (NSArray *)children
{
  return self.package.topImports;
}

- (NSImage *)icon
{
  return [UObject systemIcon:kGenericRemovableMediaIcon];
}

@end

NSArray *enumerateDirectory(NSURL *aUrl, int *validItems)
{
  NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:aUrl
                                                        includingPropertiesForKeys:@[@"NSURLIsDirectoryKey"]
                                                                           options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                      errorHandler:NULL];
  [dirEnum skipDescendants];
  NSMutableArray *array = [NSMutableArray array];
  NSURL *pathName;
  NSArray *validExts = @[@"gpk", @"gmp", @"upk", @"umap", @"u"];
  while (pathName = [dirEnum nextObject])
  {
    id isDir;
    [pathName getResourceValue:&isDir forKey:@"NSURLIsDirectoryKey" error:nil];
    if ([isDir boolValue])
    {
      int vItems = 0;
      [array addObjectsFromArray:enumerateDirectory(pathName,&vItems)];
    }
    else if ([validExts indexOfObject:[pathName pathExtension]] != NSNotFound)
    {
      [array addObject:pathName];
    }
  }
  
  return array;
}
