Shader "MathematicalVisualizationArt/Fur"
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
            #define R(x) frac(sin(dot(x,float2(12.9898, 78.233))) * 43758.5453)
            #define HAIR_LENGTH 20.0
            #define TOUSLE 0.15
            #define BORDER 1.5
            
            //#region fur from https://www.shadertoy.com/view/ttjyRc
            float noise (float2 st)
            {
                float2 i = floor(st);
                float2 f = frac(st);

                // Four corners in 2D of a tile
                float a = R(i);
                float b = R((i + float2(1.0, 0.0)));
                float c = R((i + float2(0.0, 1.0)));
                float d = R((i + float2(1.0, 1.0)));

                // Smooth Interpolation
                float2 u = smoothstep(0.,1.,f);

                // Mix 4 coorners percentages
                return (lerp(a, b, u.x) +
                        (c - a) * u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y) * 2.0 - 1.0;
            }

            float fbm(float2 x)
            {
                float v = 0.0;
                float a = 0.5;
                float2 shift = 100;
                float2x2 rot = float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
                for (int i = 0; i < 5; ++i) {
                    v += a * noise(x);
                    x = mul(rot ,x) * 2.0 + shift;
                    a *= 0.5;
                }
                return v;
            }

            float hairpatch(float2 u, float2 o, float a)
            {
                a += sin(R(o) * 5.0) * TOUSLE;
                float2 d = float2(1.0/HAIR_LENGTH, 0.5);
                float s = sin(a);
                float c = cos(a);
                float2x2 m = float2x2(c, -s, s, c);
                u=mul(m,u);
            
                float h = (fbm((u + o) * d * 70.0) + 1.0) / 2.0;
                
                h = smoothstep(0.0, 2.2, h);

                return max(0.0, 1.0 - min(1.0, 1.0 - h));
            }

            // as the hair is organized in patches, each patch has some
            // smooth falloff since patches are blended together dynamically
            float hair(float2 u, float2 d, float w, float a)
            {
                float hr = 0.0;
                u *= w * 4.0;
                u += d;
                float2 hp = frac(u) - 0.5;
                float h = hairpatch(hp, floor(u), a);
                return pow(h * max(1.-length(hp) * BORDER, 0.0),1.0 / 3.0);
            }

            float hairtexture(float2 uv, float scale, float angle)
            {
                float2 offsets[9] = {float2(0.0,0.0), float2(0.5,0.5), float2(-0.5,-0.5),float2(0.5,0.0), float2(-0.5,0.0),
                float2(0.0,0.5), float2(0.0,-0.5),float2(0.5,-0.5), float2(-0.5,0.5)};

                float f = 0.0;

                for(int i = 0; i < 9; i++)
                {
                    f = max(f, hair(uv, offsets[i], scale, angle));
                } 
                
                return smoothstep(0.0, 1.0, f);
            }

            float3 hyena(float2 uv)
            {
                float angle = (fbm(uv) + 2.0) * PI;
                float f = hairtexture(uv, 1.0f, angle);
                
                // apply color look and use fbm to create darker patches
                float3 col = lerp(float3(0.4, 0.3, 0.25) * f * lerp(2.0, 4.0, fbm(uv * 8.0)), 1.0, pow(f, 4.0));
                
                return col;
            }
            //#endregion

            #define w _ScreenParams.x
            #define h _ScreenParams.y
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                uv.y = 1 - uv.y;
                uv = uv * 2 - 1;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                c = hyena(uv * 1.0);
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
