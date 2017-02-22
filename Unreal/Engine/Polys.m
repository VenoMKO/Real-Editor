//
//  Polys.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 22/12/2016.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "Polys.h"
#import "UObject.h"
#import "UPackage.h"
#import "FStream.h"
#import "FVector.h"

@interface Polys ()
{
  int dbNum;
  int dbMax;
  UObject *owner;
}
@end

@implementation Polys // FPoly or UPoly - probably

- (FIStream *)postProperties
{
  return [super postProperties];
  /*
  FIStream *s = [self.package.stream copy];
  [s setPosition:self.rawDataOffset];
  
  dbNum = [s readInt:NULL];
  dbMax = [s readInt:NULL];
  owner = [self.package objectForIndex:[s readInt:NULL]];
  
  for (int idx = 0; idx < dbNum; ++idx)
  {
    FVector3 *v = [FVector3 readFrom:s];
    v = [FVector3 readFrom:s];
    v = [FVector3 readFrom:s];
    v = [FVector3 readFrom:s];
  }
   */
}

@end
