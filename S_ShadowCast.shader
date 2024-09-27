Shader "Elysia/S_ShadowCast"
{
    SubShader
    {
        
        Pass
        {
            Cull Front
            HLSLPROGRAM
            #include "Assets/Materials/Shadow/ShadowCast.hlsl"

            #pragma enable_d3d11_debug_symbols
            #pragma glsl_es2
            #pragma vertex   VS
            #pragma fragment ShadowCast
            ENDHLSL
        }
    }
    
}
