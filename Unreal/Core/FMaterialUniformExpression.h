//
//  FMaterialUniformExpression.h
//  Real Editor
//
//  Created by Vladislav Skachkov on 12/01/2017.
//  Copyright © 2017 Vladislav Skachkov. All rights reserved.
//

#import "FReadable.h"
#import "FColor.h"
#import "UObject.h"

@interface FMaterialUniformExpression : FReadable
@property (assign) int typeFlags;
@property (strong) NSString *parameterName;
@property (assign) int parameterNameFlags;
@property (strong) id defaultValue;
- (id)value;
@end

@interface FMaterialUniformExpressionScalarParameter : FMaterialUniformExpression
@end

@interface FMaterialUniformExpressionVectorParameter : FMaterialUniformExpression
@end

@interface FMaterialUniformExpressionTexture : FMaterialUniformExpression
@end

@interface FMaterialUniformExpressionTextureParameter : FMaterialUniformExpression
@end

@interface FMaterialUniformExpressionTime : FMaterialUniformExpression
@end

@interface FMaterialUniformExpressionAppendVector : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *a;
@property (strong) FMaterialUniformExpression *b;
@property (assign) unsigned int numComponentsA;
@end

@interface FMaterialUniformExpressionPeriodic : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *x;
@end

@interface FMaterialUniformExpressionFoldedMath : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *a;
@property (strong) FMaterialUniformExpression *b;
@property (assign) Byte op;
@end

@interface FMaterialUniformExpressionConstant : FMaterialUniformExpression
@property (assign) Byte type;
@end

@interface FMaterialUniformExpressionSine : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *x;
@property (assign) BOOL isCosine;
@end

@interface FMaterialUniformExpressionClamp : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *input;
@property (strong) FMaterialUniformExpression *min;
@property (strong) FMaterialUniformExpression *max;
@end

@interface FMaterialUniformExpressionRealTime : FMaterialUniformExpression

@end

@interface FMaterialUniformExpressionFrac : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *x;
@end

@interface FMaterialUniformExpressionFlipBookTextureParameter : FMaterialUniformExpression
@end

@interface FMaterialUniformExpressionFloor : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *x;
@end

@interface FMaterialUniformExpressionCeil : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *x;
@end

@interface FMaterialUniformExpressionMax : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *a;
@property (strong) FMaterialUniformExpression *b;
@end

@interface FMaterialUniformExpressionAbs : FMaterialUniformExpression
@property (strong) FMaterialUniformExpression *x;
@end
