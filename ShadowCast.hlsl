#pragma once
#include "Assets/Materials/Common.hlsl"
#include "Assets/Materials/Shadow.hlsl"

#pragma region Variable

struct VSInput
{
    float2 uv         : TEXCOORD0;
    
    float3 positionOS : POSITION;
};

struct PSInput
{
    float2 uv         : TEXCOORD0;

    float4 positionCS : SV_POSITION;
};

struct PSOutput
{
    float4 color : SV_TARGET;
};
#pragma endregion

#pragma region ShadowMapping
PSInput VS(VSInput i)
{
    PSInput o = (PSInput)0;
    
    o.positionCS = mul(UNITY_MATRIX_MVP, float4(i.positionOS, 1.f));

    o.uv = i.uv;
    #if defined(UNITY_UV_STARTS_AT_TOP)
        o.uv.y = 1.f - o.uv.y;
    #endif

    return o;
}

PSOutput ShadowCast(PSInput i)
{
    PSOutput o = (PSOutput)0;
    
    float depth = i.positionCS.z / i.positionCS.w;
    #if defined (SHADER_TARGET_GLSL)
        depth = depth * 0.5f + 0.5f;
    #elif defined(UNITY_REVERSED_Z)
        depth = 1.f - depth;
    #endif
    
    o.color = EncodeFloatRGBA(depth);
    
    return o;
}
#pragma endregion 