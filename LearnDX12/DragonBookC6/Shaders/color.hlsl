//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************

cbuffer cbPerObject : register(b0)
{
  float4x4 gWorldViewProj;
  float4 gPulseColor;
  float gTime;
};

struct VertexIn
{
  float3 PosL  : POSITION;
  float4 Color : COLOR;
};

struct VertexOut
{
  float4 PosH  : SV_POSITION;
  float4 Color : COLOR;
};

VertexOut VS(VertexIn vin)
{
  VertexOut vout;
	
  // Transform to homogeneous clip space.
  vout.PosH = mul(float4(vin.PosL, 1.0f), gWorldViewProj);
	
  // Just pass vertex color into the pixel shader.
  vout.Color = vin.Color;
    
  return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
  const float pi = 3.14159;
  float s = 0.5f*sin(2*gTime)+0.5f;

  // 基于0~1之间的随时间变化的参数s，在Pin.Color与指定Color之间线性插值.
  float4 c = lerp(pin.Color,gPulseColor,s);
  return c;
}


