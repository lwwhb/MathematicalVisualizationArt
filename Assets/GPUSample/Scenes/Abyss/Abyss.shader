Shader "MathematicalVisualizationArt/Abyss"
{
    Properties
    {
    }
    
    SubShader
    {
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "DefaultPass"
            
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float4 positionCS               : SV_POSITION;
                float4 screenPos                : TEXCOORD1;
            };

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.uv = input.uv;
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }

            #define time _Time.y
            #define w _ScreenParams.x
            #define h _ScreenParams.y
            
            half3 PixelColor(float2 uv)
            {
                half3 c;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                half s[10] = {0.1,0.15,0.23,0.3,0.37,0.41,0.47,0.5,0.55,0.6};
                half l[10] = {1,2,2,3,2.55,1.3,1.3,2,0.4,2.33};
                half3 orbit = 0;
                for(uint i=0; i < 400; i++) {
                    half a = (1 - pow(cos(atan2(uv.yyy - 0.5f, uv.xxx - 0.5f) / 2.0f + l[i%10] + pow(i*0.1,3) + (_Time.x * (1 + l[i%10] * 0.001))), 2.0f)) < 0.01f ? 1:0;
                    //half o1 = saturate(floor((s[i%10] - (i * 0.001))/ length(float2(uv.x - 0.5f, (uv.y - 0.5f) * (h / w))))) * a;
                    half o1 = saturate((s[i%10] - (i * 0.001))/ length(float2(uv.x - 0.5f, (uv.y - 0.5f) * (h / w)))) * a;
                    half o2 = saturate((s[i%10] - (i * 0.001) - 0.003) / length(float2(uv.x - 0.5f, (uv.y - 0.5f) * (h / w)))) * a;
                    orbit = orbit + (o2 - o1);
                } 
                float edge = 0.35;
                float smooth = 0.5;
                c = float3(0.035,0.223,0.4) * saturate(smoothstep(length(float2(uv.x - 0.5f, (uv.y - 0.5f) * (h / w))) - smooth, length(float2(uv.x - 0.5f, (uv.y - 0.5f) * (h / w))) + smooth, edge));
                c = saturate(c - orbit);
                //---
                return c;
            }

            half4 frag(Varyings input) : SV_Target 
            {
                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                #if UNITY_UV_STARTS_AT_TOP
                screenUV = screenUV * float2(1.0, -1.0) + float2(0.0, 1.0);
                #endif
                half3 col = Gamma22ToLinear(PixelColor(screenUV));
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
