//
//  ObjectRedirectorEditor.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 04/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObjectEditor.h"
#import "ObjectRedirector.h"

@interface ObjectRedirectorEditor : UObjectEditor
@property (weak) ObjectRedirector *object;
@end
