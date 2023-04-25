Shader "MathematicalVisualizationArt/PolarCoordinates"
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
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                float uvSizeScale = 5;
                //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限 (-1, 1)
                uv = (uv*2.0 -1.0)*uvSizeScale;
                //消除屏幕拉伸影响
                half co = w/h;
                uv = float2(uv.x*co, uv.y);
                 //绘制坐标轴
                half axis = smoothstep(0.01, 0.0, abs(uv.y/uvSizeScale)) + smoothstep(0.01, 0.0, abs(uv.x/uvSizeScale));
                //极径
                float r = length(uv);
                //极角
                float angle = atan2(uv.y,uv.x)+sin(time);
                //定义坐标系下的函数
                /*float a = 1, b = 0, k = 0;
                float f = b + a*cos(k*angle);
                 f = cos(angle*3.0);
                 f = abs(cos(angle*3.0));
                 f = abs(cos(angle*2.5))*0.5+0.3;
                 f = abs(cos(angle*12.0)*sin(a*3.0))*0.8+0.1;
                 f = smoothstep(-0.5,1.0, cos(angle*10.0))*0.2+0.5;
                 f = step(-0.5, cos(angle*10.0))*0.2+0.5;*/

                //心形函数
                float f = 2-2*sin(angle) + sin(angle)*sqrt(abs(cos(angle)))/(sin(angle) + 1.4);

                half plot = 1.0 - step(f, r);
                c = half3(axis, axis + plot, axis);
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
