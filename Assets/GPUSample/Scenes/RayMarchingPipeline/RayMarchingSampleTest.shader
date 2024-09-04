Shader "MathematicalVisualizationArt/RayMarchingSampleTest"
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
            #include "Assets/GPUSample/ShadersLib/Raymarching/RaymarchingRenderer.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 screenUV                 : TEXCOORD0;
            };

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.screenUV = ComputeScreenPos(vertexInput.positionCS).xy;
                #if UNITY_UV_STARTS_AT_TOP
                    output.screenUV = output.screenUV * float2(1.0, -1.0) + float2(0.0, 1.0);
                #endif
                return output;
            }

            #define time _Time.y
            
            half3 PixelColor(float2 uv)
            {
                //初始化
                float3 camPos = float3(0.0, 2.0, 0.0);
                float3 camTarget = float3(0.0, 0.0, 0.0);
                camPos.x += 5.0 * cos(time * 0.5);
                camPos.z += 5.0 * sin(time * 0.5);
                float3 lightPos = float3(5.0, 5.0, -5.0);
                float3 bgColor = float3(0.7, 0.7, 0.9);
                
                RaymarchingParams params = initRaymarching(uv, _ScreenParams.xy, camPos, camTarget, 0, lightPos, bgColor);
                //渲染
                return render(params, time);
            }

            half4 frag(Varyings input) : SV_Target 
            {
                half3 col = Gamma22ToLinear(PixelColor(input.screenUV));
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
