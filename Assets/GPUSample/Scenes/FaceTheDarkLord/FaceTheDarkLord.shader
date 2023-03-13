Shader "MathematicalVisualizationArt/FaceTheDarkLord"
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
                half2 uv1 = half2(uv.x-0.5f, (uv.y-0.5f) * (h / w));half2 p_c = half2(atan2(uv1.x,uv1.y)/3.1415926,length(uv1));
                half wd_a = p_c.x <= 0.74f && p_c.x >= 0.35f ? 1 : 0;
                half4 w_t = half4(uv,0,0);
                {w_t.y = dot(normalize(uv1), float2(0.,1.));w_t.x *= lerp(1,0,uv1.x) + 1.7;w_t.x -= time * 0.1;
                    w_t.x *= 5.;w_t.y *= 1.;float x_id = floor(w_t.x);float y_id = floor(w_t.y);
                    w_t = float4(frac(w_t.xy),x_id,y_id);}
                half r_a = p_c.x > -0.5 && p_c.x < 0. ? 1 : 0;
                half4 r_t = half4(uv,0,0);
                {r_t.x = dot(normalize(uv1), float2(1.,0.));r_t.y *= lerp(1,0,uv1.y) + 1.7;r_t.y -= time * 0.1;r_t.x *= 1.;
                    r_t.y *= 5.;float x_id = floor(r_t.x);float y_id = floor(r_t.y);
                    r_t = float4(frac(r_t.xy),x_id,y_id);r_t.x += 0.5f;}
                half r_l = p_c.x > -0.37 && p_c.x < -0.35 ? 1 : 0;
                r_l += p_c.x < 0. && p_c.x > -0.1 ? 1 : 0;
                half r = 0;
                {r_t.xy = r_t.xy * 2;half2 strk = smoothstep(0.1,0.1+0.01,frac(abs(r_t.x)));
                    strk *= smoothstep(0.1,0.1+0.01,frac(abs(r_t.y)));strk *= smoothstep(0.1,0.1+0.01,frac(-abs(r_t.x)));
                    strk *= smoothstep(0.1,0.1+0.01,frac(-abs(r_t.y)));r =  strk.x * strk.y;}
                half wd = 0;
                {w_t.xy = w_t.xy * 2;half2 strk = smoothstep(0.1,0.1+0.01,frac(abs(w_t.x)));
                    strk *= smoothstep(0.1,0.1+0.01,frac(abs(w_t.y)));strk *= smoothstep(0.1,0.1+0.01,frac(-abs(w_t.x)));
                    strk *= smoothstep(0.1,0.1+0.01,frac(-abs(w_t.y)));wd =  strk.x * strk.y;}
                c = (step(1., r * fmod(abs(r_t.a),2.0)) * r_a) * float3(uv1.y,0,uv1.x);c += (step(1., wd * fmod(abs(w_t.z),2.0)) * wd_a) * float3(uv1.x,0,uv1.y);
                c -= r_l != 0 ? c : 0;
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
