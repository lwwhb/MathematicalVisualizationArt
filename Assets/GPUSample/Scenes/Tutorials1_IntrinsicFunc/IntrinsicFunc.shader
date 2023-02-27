Shader "MathematicalVisualizationArt/IntrinsicFunc"
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
                //四象限扩展（0.0到+10.0）
                const int uvScale = 5;
                uv = uv*uvScale + time;
                
                float2 uvInteger = floor(uv); //二维图案数组的索引
                float2 uvDecimal = frac(uv);    //0-1区间连续UV
                //将uv.x映射到颜色值的r通道上
                //c.rb =(uvDecimal.xy);///uvScale;

                //fmod方式按0-0.4区间划分处理
                //c.rb = fmod(uv, 0.4)*2.5;

                //使用modf方式划分处理
                //int2 uvd;
                //c.rb = modf(uv,uvd);

                //使用step函数画一个0.5半径的黑色圆
                //c = step(sqrt(pow(uv.y*2-1,2) + pow(uv.x*2-1,2)), 0.5);

                //做一个水平红色到绿色的颜色渐变过度
                c = lerp(half3(1, 0, 0), half3(0, 1, 0), uv.x);

                //做一个0.5半径大小的圆环，圆环部分要做光滑过度表现
                float d = sqrt(pow(uvDecimal.y*2-1,2) + pow(uvDecimal.x*2-1,2));
                c = smoothstep(0.3, 0.4, d)- smoothstep(0.4, 0.5, d);
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
