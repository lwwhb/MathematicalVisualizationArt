Shader "MathematicalVisualizationArt/FBM"
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
            //随机数
            float random (in half2 uv)
            {
                return frac(sin(dot(uv.xy, float2(12.9898,78.233)))*43758.5453123);
            }
            float2 random2( in half2 uv )
            {
                return frac(sin(float2(dot(uv.xy, float2(127.1,311.7)),dot(uv.xy,float2(269.5,183.3))))*43758.5453);
            }
            //梯度化噪声
            float gradientNoise (in half2 uv)
            {
                half2 iuv = floor(uv);
                half2 fuv = frac(uv);
                float a = random(iuv);
                float b = random(iuv + half2(1.0, 0.0));
                float c = random(iuv + half2(0.0, 1.0));
                float d = random(iuv + half2(1.0, 1.0));
                half2 u = fuv*fuv*(3.0-2.0*fuv);
                return lerp(a, b, u.x) +
                        (c - a)* u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y;
            }
            //voronoi噪声，计算最小距离
            float voronoiNoise(in half2 uv)
            {
                half2 iuv = floor(uv);
                half2 fuv = frac(uv);
                
                float minDist = 1.;  //最小距离

                for (int y= -1; y <= 1; y++) {
                    for (int x= -1; x <= 1; x++) {
                        // 邻居网格节点
                        float2 neighbor = float2(float(x),float(y));

                        // 在网格内从current+neighor位置来随机位置
                        float2 pt = random2(iuv + neighbor);

			            // 移动特征点
                        pt = 0.5 + 0.5*sin(time + 6.2831*pt);

			            // 像素到特征点的矢量
                        float2 diff = neighbor + pt - fuv;

                        // 计算到特征点的距离
                        float dist = length(diff);

                        // 计算最小距离
                        minDist = min(minDist, dist);
                    }
                }
                // 返回最小距离
                return  minDist;
            }
            //分形布朗运动
            #define OCTAVES 6
            float fbm (in half2 uv) {
                // Initial values
                float value = 0.0;
                float amplitude = .5;
                
                // Loop of octaves
                for (int i = 0; i < OCTAVES; i++) {
                    //value += amplitude * gradientNoise(uv);
                    
                    //湍流
                    value += amplitude * abs(voronoiNoise(uv)*2 - 1);
                    //
                    uv *= 2.;
                    amplitude *= .5;
                }
                // Sharpness
                //value = 1.0 - clamp(0, 1, value); 
                //value = value * value;
                //
                return value;
            }
            //翘曲域
            #define IterNum 3
            float domainWarping(in half2 uv)
            {
                float value = 0.0;
                for (int i = 0; i < IterNum; i++)
                    value = fbm( uv +value );
                return value;
            }
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                uv = uv*10;
                //分形布朗运动
                //c = fbm(uv + time);
                //翘曲域
                c = domainWarping(uv + time);
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
