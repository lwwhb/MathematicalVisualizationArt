Shader "MathematicalVisualizationArt/FuncVisualization"
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
                float uvSizeScale = 5;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                 //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限 (-5, 5)
                uv = (uv*2.0 -1.0)*uvSizeScale;
                //一象限 x在1-2，y在0-2区间
                //uv.y = uv.y*uvSizeScale;
                //uv.x = uv.x + 1;

                //绘制坐标轴
                half axis = smoothstep(0.01, 0.0, abs(uv.y/uvSizeScale)) + smoothstep(0.01, 0.0, abs(uv.x/uvSizeScale));
                //绘制坐标网格
                half mesh = 0;
                for (float i = -uvSizeScale; i <= uvSizeScale; i++)
                    mesh += smoothstep(0.01, -0.01, abs((uv.y+i)/uvSizeScale)) + smoothstep(0.01, -0.01, abs((uv.x+i)/uvSizeScale));
                //绘制y = x^5
                half func = uv.y - pow(uv.x,5);
                //绘制y = x*x*(2-x)
                //half func = uv.y - uv.x*uv.x*(2-uv.x);
                //绘制y = sin(x + t)
                //half func = uv.y - sin(uv.x + time);
                //绘制cos(y) = tan(x)
                //half func = cos(uv.y) - tan(uv.x);
                //绘制 |y| = sin(|x|) + log(|x|)^2
                //half func = abs(uv.y) - sin(abs(uv.x)) + pow(log(abs(uv.x)),2);
                //其他，公式不好打不写了
                //half func = pow(uv.y,2) + pow(uv.x,2) - sqrt(sqrt(uv.x*uv.y))*5;
                //half func =  pow(uv.y,2) + pow(uv.x,2) - abs(sqrt(abs(uv.y)) - sqrt(abs(uv.x)));
                //half func = uv.y - sin(uv.x)*log(uv.x*uv.x);
                //half func = uv.x*cos(uv.y) + uv.y*cos(uv.x);
                //half func = 1/uv.x + 1/uv.y - sin(exp(-uv.x*uv.y));
                //half func = sin(sin(uv.x) + cos(uv.y)) - cos(sin(uv.x * uv.y) + cos(uv.x));
                half plot = smoothstep(lerp(0.001, 0.02, length(uv)), 0.0, abs(func/uvSizeScale));
                return half3(axis + mesh, axis + mesh, axis + mesh) + half3(0, plot, 0);
                //
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
