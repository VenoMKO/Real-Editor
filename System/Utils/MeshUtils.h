//
//  MeshUtils.h
//  GPK-Man
//
//  Created by Vladislav Skachkov on 20/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMesh.h"

unsigned short float2half(float a);
float half2float(int16_t h);
void SetBasisDeterminantSignByte(FPackedNormal *tangent,float sign);
float GetBasisDeterminantSignByte(FPackedNormal XAxis,FPackedNormal YAxis, FPackedNormal ZAxis);
