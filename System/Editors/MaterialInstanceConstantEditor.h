//
//  MaterialInstanceConstantEditor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 31/10/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UObjectEditor.h"
#import "Material.h"

@interface MaterialInstanceConstantEditor : UObjectEditor
@property (weak) MaterialInstanceConstant   *object;

@end
