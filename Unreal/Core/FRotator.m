//
//  FRotator.m
//  GPK-Man
//
//  Created by Vladislav Skachkov on 21/08/16.
//  Copyright © 2016 Vladislav Skachkov. All rights reserved.
//

#import "FRotator.h"

static float TrigFLOAT[16384];
enum {ANGLE_SHIFT 	= 2};		// Bits to right-shift to get lookup value.
enum {ANGLE_BITS	= 14};		// Number of valid bits in angles.
enum {NUM_ANGLES 	= 16384}; 	// Number of angles that are in lookup table.
enum {ANGLE_MASK    =  (((1<<ANGLE_BITS)-1)<<(16-ANGLE_BITS))};

int NormalizeAxis(int Angle)
{
  Angle &= 0xFFFF;
		if( Angle > 32767 )
    {
      Angle -= 0x10000;
    }
		return Angle;
}

inline __attribute__ ((always_inline)) float SinTab(int i)
{
  return TrigFLOAT[(( i >> ANGLE_SHIFT ) & ( NUM_ANGLES - 1 ))];
}

inline __attribute__ ((always_inline)) float CosTab(int i)
{
		return TrigFLOAT[((( i + 16384 ) >> ANGLE_SHIFT ) & ( NUM_ANGLES - 1 ))];
}

@implementation FRotator

+ (void)initialize
{
  [super initialize];
  for( int i=0; i<16384; i++ )
    TrigFLOAT[i] = sinf((float)i * 2.f * M_PI / (float)NUM_ANGLES);
}

+ (id)readFrom:(FIStream *)stream
{
  FRotator *r = [super readFrom:stream];
  r.pitch = [stream readInt:0];
  r.yaw = [stream readInt:0];
  r.roll = [stream readInt:0];
  return r;
}

- (FVector3 *)euler
{
  FRotator *n = [self normalized];
  FVector3 *v = [FVector3 newWithPackage:self.package];
  
  v.x = (float)n.roll  * (180.f / 32768.f);
  v.y = (float)n.pitch  * (180.f / 32768.f);
  v.z = (float)n.yaw  * (180.f / 32768.f);
  
  return v;
}

- (void)setEuler:(FVector3 *)euler
{
  self.pitch = (int)(euler.y * (32768.f / 180.f));
  self.yaw = (int)(euler.z * (32768.f / 180.f));
  self.roll = (int)(euler.x * (32768.f / 180.f));
}

- (SCNQuaternion)quaternion
{
  const float	SR	= SinTab(self.roll); // x
  const float	SP	= SinTab(self.pitch);// y
  const float	SY	= SinTab(self.yaw);  // z
  const float	CR	= CosTab(self.roll);
  const float	CP	= CosTab(self.pitch);
  const float	CY	= CosTab(self.yaw);
  
  float M[4][4] __attribute__((aligned(16)));
  
  M[0][0]	= CP * CY;
  M[0][1]	= CP * SY;
  M[0][2]	= SP;
  M[0][3]	= 0.f;
  
  M[1][0]	= SR * SP * CY - CR * SY;
  M[1][1]	= SR * SP * SY + CR * CY;
  M[1][2]	= - SR * CP;
  M[1][3]	= 0.f;
  
  M[2][0]	= -( CR * SP * CY + SR * SY );
  M[2][1]	= CY * SR - CR * SP * SY;
  M[2][2]	= CR * CP;
  M[2][3]	= 0.f;
  
  M[3][0]	= 0;
  M[3][1]	= 0;
  M[3][2]	= 0;
  M[3][3]	= 1.f;
  
  SCNQuaternion q;
  float	s;
  
  // Check diagonal (trace)
  const float tr = M[0][0] + M[1][1] + M[2][2];
  
  if (tr > 0.0f)
  {
    float InvS = 1.0f / sqrtf(tr + 1.f);
    q.w = 0.5f * (1.f / InvS);
    s = 0.5f * InvS;
    
    q.x = (M[1][2] - M[2][1]) * s;
    q.y = (M[2][0] - M[0][2]) * s;
    q.z = (M[0][1] - M[1][0]) * s;
  }
  else
  {
    // diagonal is negative
    int i = 0;
    
    if (M[1][1] > M[0][0])
      i = 1;
    
    if (M[2][2] > M[i][i])
      i = 2;
    
    static const int nxt[3] = { 1, 2, 0 };
    const int j = nxt[i];
    const int k = nxt[j];
    
    s = M[i][i] - M[j][j] - M[k][k] + 1.0f;
    
    float InvS = 1.0f / sqrtf(s);
    
    float qt[4];
    qt[i] = 0.5f * (1.f / InvS);
    
    s = 0.5f * InvS;
    
    qt[3] = (M[j][k] - M[k][j]) * s;
    qt[j] = (M[i][j] + M[j][i]) * s;
    qt[k] = (M[i][k] + M[k][i]) * s;
    
    q.x = qt[0];
    q.y = qt[1];
    q.z = qt[2];
    q.w = qt[3];
  }
  
  return q;
}

- (NSString *)description
{
  FVector3 *e = [self euler];
  return [NSString stringWithFormat:@"<%@> %f, %f, %f",self.className,e.x,e.y,e.z];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FRotator *r = [FRotator newWithPackage:self.package];
  r.pitch = self.pitch;
  r.yaw = self.yaw;
  r.roll = self.roll;
  
  return r;
}

- (NSMutableData *)cooked:(NSInteger)offset
{
  NSMutableData *data = [NSMutableData new];
  [data writeInt:self.pitch];
  [data writeInt:self.yaw];
  [data writeInt:self.roll];
  return data;
}

- (FRotator *)normalized
{
  FRotator *r = [FRotator new];
  r.package = self.package;
  r.pitch = NormalizeAxis(self.pitch);
  r.roll = NormalizeAxis(self.roll);
  r.yaw = NormalizeAxis(self.yaw);
  return r;
}

- (FRotator *)denormalized
{
  FRotator *r = [FRotator new];
  r.package = self.package;
  r.pitch = self.pitch & 0xFFFF;
  r.roll = self.roll & 0xFFFF;
  r.yaw = self.yaw & 0xFFFF;
  return r;
}

- (GLKVector3)glkVector3
{
  return GLKVector3Make(self.pitch, self.yaw, self.roll);
}

- (id)plist
{
  return @{@"pitch" : @(self.pitch), @"roll" : @(self.roll), @"yaw" : @(self.yaw)};
}

@end
