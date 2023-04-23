Shader "MathematicalVisualizationArt/FlagStart5"
{
    Properties
    {
        _value("value",float) = 1
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
            
            float _value;
            //平移
            float3x3 move2d(float2 p)
            {
                return float3x3(1, 0, p.x, 0, 1, p.y, 0, 0, 1);
            }
            //旋转
            float3x3 rotate2d(float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float3x3(c, -s, 0, s, c, 0, 0, 0, 1);
            }
            //缩放
            float3x3 scale2d(float2 s)
            {
                return float3x3(1 / s.x, 0, 0, 0, 1 / s.y, 0, 0, 0, 1);
            }
            float sdStart5(float2 p, float r, float rf, float2 offset, float scalevalue, float rota)
            {
                p += offset; //mul(p,move2d(offset));
                p = mul(p, scale2d(float2(1, 1) * scalevalue));
                p = mul(p, rotate2d(rota));
                const float2 k1 = float2(0.809016994375, -0.587785252292);
                const float2 k2 = float2(-k1.x, k1.y);
                p.x = abs(p.x);
                p -= 2.0 * max(dot(k1, p), 0.0) * k1;
                p -= 2.0 * max(dot(k2, p), 0.0) * k2;
                p.x = abs(p.x);
                p.y -= r;
                float2 ba = rf * float2(-k1.y, k1.x) - float2(0.0, 1.0);
                float hh = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
                return length(p - ba * hh) * sign(p.y * ba.x - p.x * ba.y);
            }

            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                c = half3(1,0,0);
                float4 star_color = float4(1, 1, 0, 1);
                half co = w / h;
                uv = float2(uv.x * co, uv.y);
                uv -= float2(-0.8, -0.36);
                //绘制五角星
                float step_star = 1.0 / w;
                float star5 = 0;
                for (int count = 0; count < 5; count++)
                {
                    float3 scale = float3(uv, 1);
                    float tempStep =step(1,count);

                    float unitAngle = 30;
                    float radius = 0.3;
                    star5 += smoothstep(step_star, -step_star, sdStart5(scale.xy, 0.05, 0.4, float2(-1 + (cos(radians(100 + count * unitAngle)) * radius)* tempStep, -0.67 + (sin(radians(100 + count * unitAngle)) * radius)* tempStep), lerp(3, 1, tempStep),lerp(0.62,95.2, tempStep)));

                   // star5 += smoothstep(step_star, -step_star, sdStart5(scale.xy, 0.05, 0.4, float2(-1 + (cos((89.6 + count * unitAngle * 0.0174532924) * radius)), -0.67 + (sin((89.6 + count * unitAngle * 0.0174532924) * radius))), lerp(3,1,tempStep),lerp(0.62,9.6,tempStep)));

         /*           if (count == 0)
                    {
                        star5 = smoothstep(step_star, -step_star, sdStart5(scale.xy, 0.05, 0.4, float2(-1, -0.67), 3, 0.62));
                    }
                    else
                    {
                        star5 += smoothstep(step_star, -step_star, sdStart5(scale.xy, 0.05, 0.4, float2(-1+cos(89.6+count * unitAngle * 0.0174532924)* radius, -0.67+sin(89.6 +count * unitAngle * 0.0174532924)* radius), 1, 9.6));

                    }*/
                }
                c = lerp(c, star_color, star5);
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
