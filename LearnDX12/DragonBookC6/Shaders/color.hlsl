//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************

// 光源数量
#ifndef NUM_DIR_LIGHTS
	#define NUM_DIR_LIGHTS 1
#endif 

#ifndef NUM_POINT_LIGHTS
	#define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
	#define NUM_SPOT_LIGHTS 0
#endif

#include "LightingUtils.hlsl"

// object constant.
cbuffer cbPerObject : register(b0)
{
    float4x4 gWorld; 
    float4x4 gTexTransform;
};

// material constant.
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
    
    // 环境光
    float4 gAmbientLight;

    // 雾效
    float4 gFogColor;
    float  gFogStart;
    float  gFogRange;
    float2 cbPad2;
    // 光源
    Light gLights[MaxLights];
}

// 纹理
Texture2D gDiffuseMap : register(t0);
SamplerState gSampler : register(s0);
// 采样器
struct VertexIn
{
    float3 PosL  : POSITION;
    float3 NormalL : NORMAL;
    float2 TexC : TEXCOORD;
};

struct VertexOut
{
    float4 PosH  : SV_POSITION;
    float3 PosW  : POSITION;
    float3 NormalW : NORMAL;
    float2 TexC : TEXCOORD;
};

VertexOut VS(VertexIn vin)
{
    VertexOut vout;
	float4 PosW = mul(float4(vin.PosL,1.0f),gWorld);
    // Transform to homogeneous clip space.
    vout.PosH = mul(PosW, gViewProj);
    // Just pass vertex color into the pixel shader.
    vout.PosW = PosW;
    // 假设这里是等比缩放，这样的化变化矩阵就是世界矩阵本身，否则要用逆转矩阵.
    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);
    
    vout.TexC = mul(mul(float4(vin.TexC, 0, 1), gTexTransform),gMatTransform).xy;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{

    float4 diffuseAlpbedo = gDiffuseMap.Sample(gSampler, pin.TexC)*gDiffuseAlbedo;

#ifdef ALPHA_TEST
    // alpha 小于0 则剔除
    clip(diffuseAlpbedo.a - 0.1f);
#endif

    // 顶点法线插值后可能非规范化
    pin.NormalW = normalize(pin.NormalW);
    
    // toEye 
    float3 toEye = normalize(gEyePosw - pin.PosW);
    
    // 间接光
    float4 ambient = gAmbientLight * diffuseAlpbedo;
    
    // 直接光
    const float shininess = 1.0f - gRoughness;
    Material mat = { diffuseAlpbedo, gFresnelR0, shininess };
    
    float3 shadowFactor = 1.0f;
    float4 directLight = ComputeLighting(gLights, mat,pin.PosW, pin.NormalW, toEye,shadowFactor);
    float4 litColor = ambient + directLight;

    // 处理雾效
	float fogAmount = saturate(length(pin.PosW - gEyePosw) / (gFogRange));
	litColor = lerp(litColor, gFogColor,fogAmount);
    
    litColor.a = diffuseAlpbedo.a;
    
	return litColor;
}


