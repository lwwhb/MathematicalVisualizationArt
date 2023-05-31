Shader "MathematicalVisualizationArt/SnowFlakes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            sampler2D _MainTex;

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
            #define pi 3.14159265359

            //#region snowflake
            //from https://iquilezles.org/articles/distfunctions2d/
            float sdHexagon( in float2 p, in float r )
            {
                const float3 k = float3(-0.866025404,0.5,0.577350269);
                p = abs(p);
                p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
                p -= float2(clamp(p.x, -k.z*r, k.z*r), r);
                return length(p)*sign(p.y);
            }

            //from https://iquilezles.org/articles/distfunctions2d/
            float sdStar(in float2 p, in float r, in int n, in float m)
            {
                // next 4 lines can be precomputed for a given shape
                float an = 3.141593/float(n);
                float en = 3.141593/m;  // m is between 2 and n
                half2  acs = half2(cos(an),sin(an));
                half2  ecs = half2(cos(en),sin(en)); // ecs=half2(0,1) for regular polygon

                float bn = fmod(atan2(p.x,p.y),2.0*an) - an;
                p = length(p)*half2(cos(bn),abs(sin(bn)));
                p -= r*acs;
                p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
                return length(p)*sign(p.x);
            }

            //https://iquilezles.org/articles/distfunctions2d/
            float sdSegment( in half2 p, in half2 a, in half2 b )
            {
                half2 pa = p-a, ba = b-a;
                float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
                return length( pa - ba*h );
            }
            //#endregion

       
            #define w _ScreenParams.x
            #define h _ScreenParams.y
           
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                uv.y = 1 - uv.y;
                uv = uv * 2 - 1;
                uv *= 3.5;
                half co = w/h;
                half4 col = 0.0;//;tex2D(_MainTex, uv);
                float2 uv1 = float2(uv.x*co, uv.y);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                {
                    half2 p_c = half2(atan2(uv1.x,uv1.y),length(uv1));
                    half flake_1 =  smoothstep(0.,1.4,abs(sin(p_c.x*3.0))) + 0.5;
                    flake_1 = smoothstep(flake_1,flake_1+0.02,p_c.y);
                    half hex = saturate(sdHexagon(uv1,0.8));
                    flake_1 = step(1.0,1. - max(flake_1, hex));
                    c = flake_1;
                }
                {
                    uv1.x -= 3.;
                    half2 p_c = half2(atan2(uv1.x,uv1.y),length(uv1));
                    half flake_2 = 0.0;
                    for(int i = 1;i < 8;i++)
                    {
                        float a = pi / 8 + i * pi * 0.25;
                        flake_2 += step(0,0.03 - sdSegment(uv1,half2(cos(a),sin(a)),half2(cos(a+pi),sin(a+pi)))); 
                    }
                    flake_2 = max(flake_2, step(p_c.y,0.3) - step(p_c.y,0.25));
                    half star = sdStar(abs(uv1), 0.8, 8, 3.2);
                    flake_2 += (1 - step((step(star,0.07) - step(star,0.02)),1 - step(abs(cos(p_c.x * 4 )),0.9)));
                    flake_2 += (1 - step((step(star,0.18) - step(star,0.13)),1 - step(abs(cos(p_c.x * 4 )),0.7)));
                    flake_2 += (1 - step((step(star,0.28) - step(star,0.23)),1 - step(abs(cos(p_c.x * 4 )),0.5)));
                    c += flake_2;
                }
                {
                    uv1.x += 6.;
                    half2 p_c = half2(atan2(uv1.x,uv1.y),length(uv1));
                    half flake_3 = 0.0;
                    for(int i = 1;i < 8;i++)
                    {
                        float a = pi / 8 + i * pi * 0.25;
                        flake_3 += step(0,0.03 - sdSegment(uv1,half2(cos(a),sin(a)),half2(cos(a+pi),sin(a+pi)))); 
                    }
                    half star = sdStar(abs(uv1), 0.8, 8 , 3.2);
                    flake_3 += step(star,-0.18) - step(star,-0.23);
                    flake_3 += (1 - step(step(star,-0.06) - step(star,-0.1),1 - step(abs(cos(p_c.x * 4 )),0.92)));
                    flake_3 += (1 - step(step(star,0.06) - step(star,0.02),1 - step(abs(cos(p_c.x * 4 )),0.96)));
                    c += flake_3;
                }
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
