//
//  TextBuffer.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 18/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"
#import "FString.h"

@interface TextBuffer : UObject
@property (assign) int pos;
@property (assign) int top;
@property (strong) FString *text;
@end
