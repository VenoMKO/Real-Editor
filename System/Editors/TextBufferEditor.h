//
//  TextBufferEditor.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 20/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObjectEditor.h"
#import "TextBuffer.h"

@interface TextBufferEditor : UObjectEditor
@property (weak) TextBuffer *object;
@end
