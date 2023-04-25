Shader "MathematicalVisualizationArt/Transform"
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

            //SDF Star5
            float sdStar5( float2 p, float r, float rf)
            {
                const float2 k1 = float2(0.809016994375, -0.587785252292);
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
                return float3x3(1/s.x, 0, 0, 0, 1/s.y, 0, 0, 0, 1);
            }
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                float uvSizeScale = 15;
                 //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限 (-5, 5)
                uv = (uv*2.0 -1.0)*uvSizeScale;
                //消除屏幕拉伸影响
                half co = w/h;
                uv = float2(uv.x*co, uv.y);
                //绘制五角星
                float step = 1.0/w;

                //平移
                float3 pos = mul(move2d(float2(cos(time),sin(time))*5),float3(uv,1));
                //旋转
                pos = mul(rotate2d(cos(time)*5),pos);
                //缩放
                pos = mul(scale2d(float2(cos(time)+2,cos(time)+2)),pos);
                float star5 = smoothstep(step,-step, sdStar5(pos.xy,1,2.5) );
                c = lerp(c,float3(1.0,1.0,1.0), star5);
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
