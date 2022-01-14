//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************
// 光源数量
#ifndef NUM_DIR_LIGHTS
	#define NUM_DIR_LIGHTS 3
#endif 

#ifndef NUM_POINT_LIGHTS
	#define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
	#define NUM_SPOT_LIGHTS 0
#endif

#include "LightingUtils.hlsl"

cbuffer cbPerObject : register(b0)
{
    float4x4 gWorld; 
    float4x4 gInvWorld;
    float4x4 gTexTransform;
};
cbuffer cbMaterial : register(b1)
{
    float4 gDiffuseAlbedo;
    float3 gFresnelR0;
    float gRoughness;
    float4x4 gMatTransform;
};

// pass constant.
cbuffer cbPass : register(b2)
{
  float4x4 gView;
  float4x4 gInvView;
  float4x4 gProj;
  float4x4 gInvProj;
  float4x4 gViewProj;
  float4x4 gInvViewProj;
  float3   gEyePosw;
  float    cbPad1;
  float2   gRenderTargetSize;
  float2   gInvRenderTargetSize;
  float    gNearZ;
  float    gFarZ;
  float    gTotalTime;
  float    gDeltaTime;
    
    // 环境光和光源
    float4 gAmbientLight;
    Light gLights[MaxLights];
}

struct VertexIn
{
  float3 PosL  : POSITION;
  float3 NormalL: NORMAL;
    float2 TexC : TEXCOORD;
};

struct VertexOut
{
    float4 PosH  : SV_POSITION;
    float3 PosW : POSITION;
    float3 NormalW:NORMAL;
    float2 TexC : TEXCOORD;
};

Texture2D gDiffuseTex : register(t0);
SamplerState gsamPointWrap : register(s0);

VertexOut VS(VertexIn vin)
{
  VertexOut vout;
	float4 PosW = mul(float4(vin.PosL,1.0f),gWorld);
  // Transform to homogeneous clip space.
    vout.PosH = mul(PosW, gViewProj);
    vout.PosW = PosW;
    vout.NormalW = mul(vin.NormalL, transpose((float3x3) gInvWorld));
  // Just pass vertex color into the pixel shader.    
    float4 texC = mul(float4(vin.TexC, 0, 1), gTexTransform);
    vout.TexC = mul(texC, gMatTransform).xy;
  return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    float4 diffuseAlbedo = gDiffuseTex.Sample(gsamPointWrap, pin.TexC)*gDiffuseAlbedo*1;
    pin.NormalW = normalize(pin.NormalW);
    
    // toEye
    float3 toEye = normalize(gEyePosw - pin.PosW);
    
    // 间接光
    float4 ambient = gAmbientLight * diffuseAlbedo;
    
    // 直接光
    const float shiness = 1.0f - gRoughness;
    float3 shadowFactor = 1.0f;
    Material mat = { diffuseAlbedo, gFresnelR0, shiness };
    float4 directLight = ComputeLighting(gLights, mat, pin.PosW, pin.NormalW, toEye, shadowFactor);
    
    float4 litColor =(ambient + directLight);
    return litColor;
}


