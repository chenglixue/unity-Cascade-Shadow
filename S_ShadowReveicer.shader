 Shader "Elysia/S_Shadow_Reveicer"
{
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #include_with_pragmas "ShadowReveicer.hlsl"
            #pragma shader_feature _PCF_LOW _PCF_MIDDLE _PCF_HIGH
            #pragma enable_d3d11_debug_symbols
            #pragma glsl_es2
            #pragma vertex   ShadowReveicer_VS
            #pragma fragment ShadowReveicer_PS
            ENDHLSL
        }
    }
}
