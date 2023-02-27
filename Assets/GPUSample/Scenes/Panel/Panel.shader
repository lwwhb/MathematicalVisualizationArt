Shader "MathematicalVisualizationArt/Panel"
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
                half3 c;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                c = half3(0,0,0);
                uv = half2(uv.x-0.5f, (uv.y-0.5f)*(h/w));
                uint t = 8;
                //pivot coodinate
                half2 p = half2((atan2(uv.x,uv.y)/ 6.2831852 + 0.5) * t ,length(uv));
                float unit = sin(p.y) * 2;
                p.x = p.x + unit;
                //circle
                float cir[4];
                float cirl[4];
                for(uint j = 0; j < 4; j++)
                {
                    float tr = time + j * 3.1415926 / 4;
                    uint tc = tr / 3.1415926;
                    tc = fmod(tc,2);
                    float ct = cos((tc == 1 ? tr : tr + 3.1415926)) * 0.5 + 0.5;
                    cirl[j] = ct;
                    cir[j] = step(ct, p.y) - step(ct-0.05, p.y);
                }
                float sciro = step(0.5, p.y);
                float scir = sciro - step(0.5-0.05, p.y);
                //paint color
                float i;
                for(i = 0;i <= p.x;i++)
                {   
                    if(i <= p.x && p.x <= i + 1 )
                    {
                        break;
                    }
                }
                uint index = fmod(i, 4) == 0 ? 0 : fmod(i, 2) == 0 ? 1 : (fmod(i, 3) == 0  || i ==7) ? 2 : 3;
                 c = index == 0 ? float3(0.321,0.8,0.937) : 
                 index == 1 ? float3(0.878,0.596,0.168) :
                 index == 2 ? float3(0.807,0.262,0.207) : float3(0.968,0.862,0.380);

                 c = cir[index] != 0 && cirl[index] < 0.5f ? cir[index] 
                 * lerp(1,float3(0,1,0),p.y*2) : 0.6f > cirl[index] && cirl[index] >= 0.5f ? float3(1,2,1) : c;
                c =  scir + (1 - sciro) * c ;
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
