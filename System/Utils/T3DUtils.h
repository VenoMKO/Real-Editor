//
//  T3DUtils.h
//  Real Editor
//
//  Created by VenoMKO on 19.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import <Foundation/Foundation.h>

void T3DAddLine(NSMutableString *source, unsigned padding, NSString *line, ...);
NSString *T3DBeginObject(NSString *objectType, NSString *objectName, NSString *objectClass);
NSString *T3DEndObject(NSString *objectType);

@class T3DLandscapeCollisionComponent;
@interface T3DLandscapeComponent : NSObject
@property int index;
@property int baseX;
@property int baseY;
@property int componentSizeQuads;
@property int subsectionSizeQuads;
@property int numSubsections;
@property float HeightmapScaleBiasX;
@property float HeightmapScaleBiasY;
@property float HeightmapScaleBiasZ;
@property float HeightmapScaleBiasW;
@property (weak) T3DLandscapeCollisionComponent *collisionComponent;
@property NSMutableData *heightData;

- (void)t3dForward:(NSMutableString*)result padding:(unsigned)padding;
- (void)t3d:(NSMutableString*)result padding:(unsigned)padding;
- (NSString *)objectName;
@end

@interface T3DLandscapeCollisionComponent : NSObject
@property int index;
@property (weak) T3DLandscapeComponent *renderComponent;
@property NSMutableData *collisionData;

- (void)t3dForward:(NSMutableString*)result padding:(unsigned)padding;
- (void)t3d:(NSMutableString*)result padding:(unsigned)padding;
- (NSString *)objectName;
@end
