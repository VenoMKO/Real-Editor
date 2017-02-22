//
//  FArray.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 14/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"

@interface FArray : FReadable <NSCoding>

+ (instancetype)readFrom:(FIStream *)stream type:(Class)type;
+ (instancetype)arrayWithArray:(NSArray *)nsarray package:(UPackage *)package;

- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;
- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len;
- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)reverseObjectEnumerator;
- (NSInteger)indexOfObject:(id)anObject;
- (NSArray *)nsarray;

@end

@interface TransFArray : FArray
@property (weak) UObject *owner;
@end

@interface FByteArray : FReadable
@property (strong) NSData *data;
@property (assign) int elementSize;
@property (assign) int elementCount;
@end
