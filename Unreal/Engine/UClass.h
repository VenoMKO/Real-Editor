//
//  UField.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 18/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FMap.h"
#import "FArray.h"
#import "TextBuffer.h"
#import "FString.h"

@class UObject;

@interface FImplementedInterface : FReadable
@property (weak) UObject *objectClass;
@property (weak) UObject *pointerProperty;
@end

@interface UField : UObject
@property (weak) UField *superfield;
@property (weak) UField *next;
@end

@interface UStruct : UField
@property (weak) TextBuffer *cppText;
@property (weak) TextBuffer *scriptText;
@property (weak) UField *children;
@property (assign) int line;
@property (assign) int textPos;
@property (strong) NSData *scriptData;
@end

@interface UState : UStruct
@property (assign) int unk;
@property (assign) uint32_t probeMask;
@property (assign) uint32_t stateFlags;
@property (assign) short labelTableOffset;
@property (assign) uint64_t igonreMask;
@property (strong) FMap *funcMap;
@end

@interface UClass : UState
@property (assign) uint32_t classFlags;
@property (assign) int classUnique;
@property (weak) UClass *classWithin;
@property (strong) FName *classConfigName;
@property (strong) FMap *componentNameToDefaultObjectMap;
@property (strong) FArray *interfaces;
@property (strong) FArray *hideCategories;
@property (strong) FArray *autoExpandCategories;
@property (weak) UObject *classDefaultObject;
@end

@interface FStateFrame : FReadable
@property (weak) UState *node;
@property (weak) UState *stateNode;
@property (assign) uint64_t probeMask;
@property (assign) uint16_t latentAction;
@property (strong) FArray *stateStack;
@property (assign) int offset;
@end

@interface FPushedState : FReadable
@property (weak) UState   *state;
@property (weak) UStruct  *node;
@end
