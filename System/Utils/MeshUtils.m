//
//  MeshUtils.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 20/09/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "MeshUtils.h"

float half2float(int16_t h)
{
  unsigned int f;
  unsigned int sign = (unsigned int)(h >> 15);
  unsigned int exp  = (unsigned int)(h & 0x7C00);
  unsigned int mant = (unsigned int)(h & 0x03FF);
  
  if (exp == 0x7C00)
  {
				// we have a half-float NaN or Inf, we convert to a float Nan or Inf
				exp = (0xFF << 23);
				if (mant != 0) mant = ((1 << 23) - 1);
  }
  else
    if (exp == 0x00000000)
    {
      // denormalized or 0
      if (mant != 0)
      {
        mant <<= 1;
        exp = 0x38000000;
        while ((mant & ( 1 << 10)) == 0)
        {
          mant <<= 1;
          exp -= (1 << 23);
        }
        mant &= ((1 << 10) - 1); // keep the mantissa on 10 bits
        mant <<= 13; // and now shift it on 23 bits
      }
    }
    else
    {
      mant <<= 13; // mantissa on 23 bits
      exp = (exp << 13) + 0x38000000;
    }
  
  f = (sign << 31) | exp | mant;
  return *((float *)&f);
  /*
  union
  {
    float		f;
    unsigned	df;
  } f;
  
  int sign = (h >> 15) & 0x00000001;
  int exp  = (h >> 10) & 0x0000001F;
  int mant =  h        & 0x000003FF;
  
  exp  = exp + (127 - 15);
  f.df = (sign << 31) | (exp << 23) | (mant << 13);
  return f.f;
  */
}

unsigned short float2half(float a)
{
  unsigned short  h;
  unsigned int p = *(unsigned int *)&a;
  unsigned int s = (p >> 31);
  unsigned int e = p & 0x7F800000;
  unsigned int m = p & 0x007FFFFF;
  
  // the exponent of the received float will not fit in the 5 bits of
  // the half ? Either is > 15 or < -14
  if (e >= 0x47800000) // > 15
  {
				// If the original float is a Nan, make the half a Nan too
				// else make Inf
				m = (m != 0 && (e==0x7F800000)) ? ((1 << 23) - 1) : 0;
				h = (((unsigned short)s) << 15) | (unsigned short)((0x1F << 10)) | (unsigned short)(m >> 13);
  }
  else
    if (e <= 0x38000000) // <= -15
    {
      // denormalized, or 0 number.
      e = (0x38000000 - e) >> 23;
      m >>= (14 + e);
      h = (((unsigned short)s) << 15) | (unsigned short)(m);
    }
    else
    {
      // straight forward case
      h = (((unsigned short)s) << 15) | (unsigned short)((e-0x38000000) >> 13) | (unsigned short)(m >> 13);
    }
  return h;
  /*
  unsigned int i = *(unsigned int *)&a;
  short k = ((i>>16) & 0x8000) | ((((i & 0x7f800000)-0x38000000)>>13) & 0x7c00) | ((i>>13) & 0x03ff);
  return k;
   */
}

void SetBasisDeterminantSignByte(FPackedNormal *tangent,float sign)
{
  Byte *normal = (Byte *)tangent;
  normal[4] = (sign + 1.0f) * 127.5f;
}

float GetBasisDeterminantSignByte(FPackedNormal XAxis,FPackedNormal YAxis, FPackedNormal ZAxis)
{
  float M[4][4];
  GLKVector3
  vec = UnpackNormal(XAxis);
  
  M[0][0] = vec.x;
  M[0][1] = vec.y;
  M[0][2] = vec.z;
  M[0][3] = 0;
  
  vec = UnpackNormal(YAxis);
  
  M[1][0] = vec.x;
  M[1][1] = vec.y;
  M[1][2] = vec.z;
  M[1][3] = 0;
  
  vec = UnpackNormal(ZAxis);
  
  M[2][0] = vec.x;
  M[2][1] = vec.y;
  M[2][2] = vec.z;
  M[2][3] = 0;
  
  M[3][0] = 0;
  M[3][1] = 0;
  M[3][2] = 0;
  M[3][3] = 1;
  
  int k =
  M[0][0] * (
             M[1][1] * (M[2][2] * M[3][3] - M[2][3] * M[3][2]) -
             M[2][1] * (M[1][2] * M[3][3] - M[1][3] * M[3][2]) +
             M[3][1] * (M[1][2] * M[2][3] - M[1][3] * M[2][2])
             ) -
  M[1][0] * (
             M[0][1] * (M[2][2] * M[3][3] - M[2][3] * M[3][2]) -
             M[2][1] * (M[0][2] * M[3][3] - M[0][3] * M[3][2]) +
             M[3][1] * (M[0][2] * M[2][3] - M[0][3] * M[2][2])
             ) +
  M[2][0] * (
             M[0][1] * (M[1][2] * M[3][3] - M[1][3] * M[3][2]) -
             M[1][1] * (M[0][2] * M[3][3] - M[0][3] * M[3][2]) +
             M[3][1] * (M[0][2] * M[1][3] - M[0][3] * M[1][2])
             ) -
  M[3][0] * (
             M[0][1] * (M[1][2] * M[2][3] - M[1][3] * M[2][2]) -
             M[1][1] * (M[0][2] * M[2][3] - M[0][3] * M[2][2]) +
             M[2][1] * (M[0][2] * M[1][3] - M[0][3] * M[1][2])
             );
  return (k < 0) ? -1.0f : 1.0f;
}
