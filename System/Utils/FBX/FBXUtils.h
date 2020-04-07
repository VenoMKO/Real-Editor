//
//  FBXUtils.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 20/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RawImportData.h"

@class SkeletalMesh, StaticMesh, Level;

@interface FBXUtils : NSObject

- (void)exportStaticMesh:(StaticMesh *)sMesh options:(NSDictionary *)expOptions;
- (void)exportSkeletalMesh:(SkeletalMesh *)skelMesh options:(NSDictionary *)expOptions;
- (RawImportData *)importLodFromURL:(NSURL *)url forSkeletalMesh:(SkeletalMesh *)skelMesh options:(NSDictionary *)opts error:(NSString **)error;
- (void)exportLevel:(Level *)level options:(NSDictionary *)expOptions;

@end
