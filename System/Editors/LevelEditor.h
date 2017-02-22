//
//  LevelEditor.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 01/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObjectEditor.h"
#import "Level.h"
@interface LevelEditor : UObjectEditor

@property (weak) Level   *object;
@end
