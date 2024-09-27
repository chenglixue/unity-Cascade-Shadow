#pragma once
#include "Assets/Materials/Shadow.hlsl"
#include "Assets/Materials/Common.hlsl"

struct VSInput
{
    float3 positionOS : POSITION;
    
    float3 normalOS : NORMAL;
    
    float2 uv         : TEXCOORD0;
};

struct PSInput
{
    float2 uv         : TEXCOORD0;
    
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD1;

    float3 normalWS   : NORMAL;
};

struct PSOutput
{
    float4 color : SV_TARGET;
};
#pragma endregion

#pragma region ShadowReveicer
PSInput ShadowReveicer_VS(VSInput i)
{
    PSInput o = (PSInput)0;
    
    o.positionCS = TransformObjectToHClip(i.positionOS);
    o.positionWS = mul(unity_ObjectToWorld, float4(i.positionOS, 1.f));

    o.normalWS = TransformObjectToWorldNormal(i.normalOS, true);
    
    o.uv = i.uv;
    
    return o;
}

PSOutput ShadowReveicer_PS(PSInput i)
{
    PSOutput o = (PSOutput)0;

    float4 shadow = GetShadow(i.positionWS, i.normalWS, GetMainLight().direction, i.positionCS.w);
    o.color = shadow;

    return o;
}
#pragma endregion