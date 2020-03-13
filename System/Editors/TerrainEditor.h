//
//  TerrainEditor.h
//  Real Editor
//
//  Created by VenoMKO on 12.03.20.
//  Copyright © 2020 VenoMKO. All rights reserved.
//

#import "UObjectEditor.h"
#import "Terrain.h"

@interface TerrainEditor : UObjectEditor

@property (weak) Terrain *object;

@end
