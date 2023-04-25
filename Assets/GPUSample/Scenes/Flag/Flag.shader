Shader "MathematicalVisualizationArt/Flag"
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

            //SDF Star5
            float sdStar5( float2 p, float r, float rf)
            {
                const float2 k1 = float2(0.8, -0.57);
                const float2 k2 = float2(-k1.x,k1.y);
                p.x = abs(p.x);
                p -= 2.0*max(dot(k1,p),0.0)*k1;
                p -= 2.0*max(dot(k2,p),0.0)*k2;
                p.x = abs(p.x);
                p.y -= r;
                float2 ba = rf*float2(-k1.y,k1.x) - float2(0,1);
                float hh = clamp( dot(p,ba)/dot(ba,ba), 0.0, r );
                return length(p-ba*hh) * sign(p.y*ba.x-p.x*ba.y);
            }

            #define time _Time.y
            #define w _ScreenParams.x
            #define h _ScreenParams.y
            #define T 6.283185307
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                uv = float2(uv.x, 1-uv.y);
                // half4 col = tex2D(_MainTex, uv);
                // c = col.xyz;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                
                float t = uv.x*7.-2.*time+uv.y*3.;
                //flowing effect from https://www.youtube.com/watch?v=t4XnK50ocMk&ab_channel=TheArtofCode
                uv.y += sin(t)*.05;  //不要漂的效果可以去掉
                uv = uv*2.0 -1.0;
                half co = w/h;
                float step = 1.0/w;
                uv = float2(uv.x*co, uv.y);
                c = abs(uv.y) <= 1.0f ? float3(0.737,0,0) : 0;
                float3x3 movement =  float3x3(1, 0, 1.06, 0, 1, -0.51, 0, 0, 1);
                {
                    //MainStar
                    float3x3 rotation = float3x3(1,0,0,0,1,0,0,0,1);
                    float3x3 scaling = float3x3(3.3, 0, 0, 0, 3.3, 0, 0, 0, 1);
                    float3x3 transform = mul(scaling,mul(movement,rotation));
                    float star5 = smoothstep(step,-step, sdStar5(mul(transform,float3(uv,1.0)), 1.0, 0.4));
                    c = lerp(c,float3(1.0,0.88,0), star5);
                }
                {
                    //ViceStars
                    //通过网上图片算出每个角的角度
                    //从上到下第一个角 0.540419500271-0.141897054604 第二个角 0.141897054604+0.278299659005 第三个角 0.674740942224-0.278299659005
                    float angles[4] = {-0.540419500271,0.540419500271-0.141897054604, 0.141897054604+0.278299659005, 0.674740942224-0.278299659005};
                    //每个星到大星的距离5.8309518948453,7.071067811865475,7.280109889280518,6.403124237432849
                    float disrates[4] = {0.8009428406336273,0.9712858623572642,1,0.8795367562872955};
                    float a = 0;
                    float a2 = T/20;
                    for(int i = 0;i < 4; i++)
                    {
                        a -= angles[i];
                        float cosine = cos(a);
                        float sine = sin(a);
                        float3x3 reflection = float3x3(-1,0,0,0,1,0,0,0,1);
                        float3x3 rotation = float3x3(cosine, sine, 0, -sine, cosine, 0, 0, 0, 1);
                        float3x3 movement2 = float3x3(1, 0, 0.755 * disrates[i], 0, 1, 0, 0, 0, 1);
                        float3x3 scaling = float3x3(10, 0, 0, 0, 10, 0, 0, 0, 1);
                        float cosine2 = cos(a2);
                        float sine2 = sin(a2);
                        float3x3 rotation2 = float3x3(cosine2, -sine2, 0, sine2, cosine2, 0, 0, 0, 1);
                        //(顺序很重要)先移动到大星的位置再旋转再反转再向着新的x轴移动再缩小再旋转到合适的位置
                        float3x3 transform = mul(rotation2,mul(scaling,mul(movement2,mul(mul(reflection,rotation),movement))));
                        float star5 = smoothstep(step,-step, sdStar5(mul(transform,float3(uv,1.0)), 1.0, 0.4));
                        c = lerp(c,float3(1.0,0.88,0), star5);
                    }
                }
                
                c *= .7+cos(t)*.3; //不要漂的效果可以去掉
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
