Shader "MathematicalVisualizationArt/Random"
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
            //绘制
            half3 drawPattern(half2 tile)
            {
                //绘制迷宫图案
                //return smoothstep(tile.x-0.3,tile.x,tile.y)-smoothstep(tile.x,tile.x+0.3,tile.y);
                //绘制圆形图案
                return (step(length(tile),0.6) - step(length(tile),0.4) ) + (step(length(tile-float2(1, 1)),0.6) - step(length(tile-float2(1,1)),0.4) );
                //绘制三角形图案
                //return step(tile.x,tile.y);
            }
            //制定规则
            half2 makeRule(in half2 fUV, in half index)
            {
                half uv = frac(((index-0.5)*2.0));
                if (index > 0.75) {
                    fUV = half2(1.0,1.0) - fUV;
                } else if (index > 0.5) {
                    fUV = half2(1.0-fUV.x,fUV.y);
                } else if (index > 0.25) {
                    fUV = 1.0-half2(1.0-fUV.x,fUV.y);
                }
                return fUV;
            }
            //伪随机函数
            float random (in half2 uv)
            {
                return frac(sin(dot(uv.xy, float2(12.9898,78.233)))*43758.5453123);
            }
            float2 random2( in half2 uv )
            {
                return frac(sin(float2(dot(uv.xy, float2(127.1,311.7)),dot(uv.xy,float2(269.5,183.3))))*43758.5453);
            }
            //梯度化
            float gradientNoise (in half2 iuv, in half2 fuv)
            {
                // Four corners in 2D of a tile
                float a = random(iuv);
                float b = random(iuv + half2(1.0, 0.0));
                float c = random(iuv + half2(0.0, 1.0));
                float d = random(iuv + half2(1.0, 1.0));

                // Smooth Interpolation
                // Cubic Hermine Curve.  Same as SmoothStep()
                //half2 u = f*f*(3.0-2.0*f);
                half2 u = smoothstep(0.,1.,fuv);

                // Mix 4 coorners percentages
                return lerp(a, b, u.x) +
                        (c - a)* u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y;
            }
            //voronoi噪声，计算最小距离
            float voronoiNoise(in half2 iuv, in half2 fuv)
            {
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
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                uv = uv*10;
                half2 iUV = floor(uv);
                half2 fUV = frac(uv);
                //绘制白噪声
                //c = random(fUV);
                
                //绘制彩色动态值噪声
                //c.r = frac(sin(dot(iUV.xy,float2(12.9898,78.233)))*43758.5453123*time);
                //c.b = frac(sin(dot(iUV.xy,float2(46.7615,197.334)))*43758.5453123*time);
                //c.g = frac(sin(dot(iUV.xy,float2(78.8831,123.6512)))*43758.5453123*time);
                
                //绘制值噪声
                //c = random(iUV);
                
                //绘制梯度化值噪声
                //c = gradientNoise(iUV, fUV);
                
                //绘制voronoi噪声
                float dist = voronoiNoise(iUV, fUV);
                c += dist;
                //绘制voronoi cell center
                //c += 1.-step(.02, dist);
                //绘制网格
                //c.r += step(.98, fUV.x) + step(.98, fUV.y);
                //
                
                //绘制Pattern图形
                //制定随机值后的计算规则
                //half2 tile = makeRule(fUV, random(iUV));
                //绘制图形
                //c = drawPattern(tile);
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
