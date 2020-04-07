//
//  ObjectRedirector.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 04/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "UObject.h"

@interface ObjectRedirector : UObject
@property (weak) UObject    *reference;
@end
