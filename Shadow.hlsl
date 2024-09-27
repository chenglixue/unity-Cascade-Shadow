#pragma once
#include "Assets/Materials/Common.hlsl"
#include "Assets/Materials/Random.hlsl"

TEXTURE2D(_G_ShadowMap_Tex0);
TEXTURE2D(_G_ShadowMap_Tex1);
TEXTURE2D(_G_ShadowMap_Tex2);
TEXTURE2D(_G_ShadowMap_Tex3);
float4 _G_ShadowMap_TexSize;
float4x4 _G_Matrix_WorldToShadow[4];
float _G_Shadow_Intensity;
float _G_Shadow_DepthBias;
float _G_Shadow_NormalBias;
float4 _G_CSM_Split_Nears;
float4 _G_CSM_Split_Fars;

/// <summary>
/// 提高深度精度
/// </summary>
inline float4 EncodeFloatRGBA(float v)
{
    float4 enc = float4(1.0, 255.0, 65025.0, 16581375.0) * v;
    enc = frac(enc);
    enc -= enc.yzww * float4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
    
    return enc;
}
inline float DecodeFloatRGBA( float4 rgba )
{
    return dot( rgba, float4(1.0, 1/255.0, 1/65025.0, 1/16581375.0) );
}

inline float4 GetCSMWeights(float view_z)
{
    float4 near_z = float4(abs(view_z) >= _G_CSM_Split_Nears);
    float4 far_z = float4(abs(view_z) < _G_CSM_Split_Fars);
    float4 weights = near_z * far_z;

    return weights;
}

/// <summary>
/// 对阴影深度偏移，避免Shadow Acne
/// </summary>
inline float GetSlopeBias(float3 normalWS, float3 lightDirWS)
{
    float cosValue = 1.f - dot(normalWS, lightDirWS);

    return clamp(cosValue * 0.05f, 0, _G_Shadow_DepthBias);
}
/// <summary>
/// 坐标从world space 转换到 shadow space
/// </summary>
inline float3 TransformWorldToShadow(float3 posWS, float4x4 M_WorldToShadow)
{
    float4 shadowPos = mul(M_WorldToShadow, float4(posWS, 1.f));
    shadowPos.xyz /= shadowPos.w;
    shadowPos.xy = shadowPos.xy * 0.5f + 0.5f;

    return shadowPos;
}
/// <summary>
/// 计算PCF软阴影
/// </summary>
inline float PCF_Low(float2 shadowUV, float depth, Texture2D<float4> shadowTex)
{
    return shadowTex.SampleCmpLevelZero(sampler_LinearClampCompare, shadowUV, depth);
}
inline float PCF_Middle(float2 shadowUV, float depth, Texture2D<float4> shadowTex)
{
    float offset_u = _G_ShadowMap_TexSize.z * 0.5f;
    float offset_v = offset_u;

    float shadow = 0.f;
    for(int x = -1; x <= 1; x++)
    {
        for(int y = -1; y <= 1; y++)
        {
            float4 cameraShadow = shadowTex.Sample(Smp_RepeatU_RepeatV_Linear, shadowUV.xy + float2(x, y) * float2(offset_u, offset_v));
            float sampleShadow = DecodeFloatRGBA(cameraShadow);
            float shadowMask = sampleShadow > depth ? _G_Shadow_Intensity : 1.f;
            shadow += shadowMask;
        }
    }

    return shadow / 9;
}
inline float PCF_High(float2 shadowUV, float depth, Texture2D<float4> shadowTex)
{
    float sum = 0.f;
    poissonDiskSamples(shadowUV.xy);
    for(int i = 0; i < NUM_SAMPLES; ++i)
    {
        float4 cameraShadow = shadowTex.Sample(Smp_RepeatU_RepeatV_Linear, shadowUV.xy + disk[i] * 0.001f);
        float sampleShadow = DecodeFloatRGBA(cameraShadow);
        float shadowMask = sampleShadow > depth ? _G_Shadow_Intensity : 1.f;
        sum += shadowMask;
    }
    
    return sum;
}

/// <summary>
/// 得到最终的阴影
/// </summary>
inline float4 GetShadow(float3 posWS, float3 normalWS, float3 lightDirWS, float view_z)
{
    float4 CSMWeights = GetCSMWeights(view_z);
    float3 normalBias = normalWS * _G_Shadow_NormalBias;
    float3 shadowPos0 = TransformWorldToShadow(posWS + normalBias, _G_Matrix_WorldToShadow[0]);
    float3 shadowPos1 = TransformWorldToShadow(posWS + normalBias, _G_Matrix_WorldToShadow[1]);
    float3 shadowPos2 = TransformWorldToShadow(posWS + normalBias, _G_Matrix_WorldToShadow[2]);
    float3 shadowPos3 = TransformWorldToShadow(posWS + normalBias, _G_Matrix_WorldToShadow[3]);

    float bias = GetSlopeBias(normalWS, lightDirWS);
    float depth0 = shadowPos0.z + bias;
    float depth1 = shadowPos1.z + bias;
    float depth2 = shadowPos2.z + bias;
    float depth3 = shadowPos3.z + bias;

    float sum = 0;

    #if defined (_PCF_LOW)
        float shadow0 = PCF_Low(shadowPos0.xy, depth0, _G_ShadowMap_Tex0);
        float shadow1 = PCF_Low(shadowPos1.xy, depth1, _G_ShadowMap_Tex1);
        float shadow2 = PCF_Low(shadowPos2.xy, depth2, _G_ShadowMap_Tex2);
        float shadow3 = PCF_Low(shadowPos3.xy, depth3, _G_ShadowMap_Tex3);
        sum = shadow0 * CSMWeights[0] + shadow1 * CSMWeights[1] + shadow2 * CSMWeights[2] + shadow3 * CSMWeights[3];
    #elif defined(_PCF_MIDDLE)
        float shadow0 = PCF_Middle(shadowPos0.xy, depth0, _G_ShadowMap_Tex0);
        float shadow1 = PCF_Middle(shadowPos1.xy, depth1, _G_ShadowMap_Tex1);
        float shadow2 = PCF_Middle(shadowPos2.xy, depth2, _G_ShadowMap_Tex2);
        float shadow3 = PCF_Middle(shadowPos3.xy, depth3, _G_ShadowMap_Tex3);
        sum = shadow0 * CSMWeights[0] + shadow1 * CSMWeights[1] + shadow2 * CSMWeights[2] + shadow3 * CSMWeights[3];
    #elif defined(_PCF_HIGH)
        float shadow0 = PCF_High(shadowPos0.xy, depth0, _G_ShadowMap_Tex0);
        float shadow1 = PCF_High(shadowPos1.xy, depth1, _G_ShadowMap_Tex1);
        float shadow2 = PCF_High(shadowPos2.xy, depth2, _G_ShadowMap_Tex2);
        float shadow3 = PCF_High(shadowPos3.xy, depth3, _G_ShadowMap_Tex3);
        sum = shadow0 * CSMWeights[0] + shadow1 * CSMWeights[1] + shadow2 * CSMWeights[2] + shadow3 * CSMWeights[3];
    #endif

    return sum;
    return sum * CSMWeights;
}