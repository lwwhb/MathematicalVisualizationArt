Shader "MathematicalVisualizationArt/2DSDF"
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
            #define width _ScreenParams.x
            #define height _ScreenParams.y
            //SDF Circle
            float sdCircle( float2 p, float r )
            {
                return length(p) - r;
            }
            //SDF Rect
            float sdRect( float2 p, float2 b )
            {
                float2 d = abs(p) - b;
                return min(max(d.x,d.y),0.0) + length(max(d,0.0));
            }
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
            //SDF Hexagon
            float sdHexagon( float2 p,  float r )
            {
                const float3 k = float3(-0.866025404,0.5,0.577350269);
                p = abs(p);
                p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
                p -= float2(clamp(p.x, -k.z*r, k.z*r), r);
                return length(p)*sign(p.y);
            }
            //圆角
            float opRound( float sdf,  float r )
            {
                return sdf - r;
            }
            //圆环
            float opAnnular( float sdf,  float r )
            {
                return abs(sdf) - r;
            }

            float smin( float a, float b, float k )
            {
                float s = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - s*s*k*(1.0/4.0);
            }
            float smax(float a,float b,float k){
                return -smin(-a,-b,k);
            }
            float sminCubic( float a, float b, float k )
            {
                float s = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - s*s*s*k*(1.0/6.0);
            }

            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                float uvSizeScale = 10;
                 //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限 (-5, 5)
                uv = (uv*2.0 -1.0)*uvSizeScale;
                //消除屏幕拉伸影响
                half co = width/height;
                uv = float2(uv.x*co, uv.y);

                float step = 1.0/width;
    
                //float circle= smoothstep(step,-step, sdCircle(uv-float2(5.0, 0),1.5) );
                //float rect = smoothstep(step,-step, sdRect(uv,float2(2,1)) );
                //float star5 = smoothstep(step,-step, sdStar5(uv+ float2(5.0, 0),1,2.5) );
                //float hexagon = smoothstep(step,-step, sdHexagon(uv + float2(10.0, 0),1.5));
                
                //圆角
                //float circle= smoothstep(step,-step, opRound(sdCircle(uv-float2(5.0, 0),1.5), 0.5) );
                //float rect = smoothstep(step,-step, opRound(sdRect(uv,float2(2,1)),0.5) );
                //float star5 = smoothstep(step,-step, opRound(sdStar5(uv+ float2(5.0, 0),1,2.5), 0.2) );
                //float hexagon = smoothstep(step,-step, opRound(sdHexagon(uv + float2(10.0, 0),1.5), 0.5));
                
                //环形
                //float circle= smoothstep(step,-step, opAnnular(sdCircle(uv-float2(5.0, 0),1.5), 0.5) );
                //float rect = smoothstep(step,-step, opAnnular(sdRect(uv,float2(2,1)),0.5) );
                //float star5 = smoothstep(step,-step, opAnnular(sdStar5(uv+ float2(5.0, 0),1,2.5), 0.2) );
                //float hexagon = smoothstep(step,-step, opAnnular(sdHexagon(uv + float2(10.0, 0),1.5), 0.5));

                //float final= circle + rect + star5 + hexagon;
                //c = lerp(c,float3(1.0,1.0,1.0), final);

                // smooth min融合
                float circle= sdCircle(uv-float2(5.0, 0),1.5);
                float rect = sdRect(uv,float2(2,1));
                float star5 = sdStar5(uv+ float2(5.0, 0),1,2.5);
                float hexagon = sdHexagon(uv + float2(10.0*sin(time), 0),1.5);
                
                float final =  smin(smin(smin(hexagon, rect, 0.5),circle, 0.5), star5, 0.5);
                c = lerp(c,float3(1.0,1.0,1.0), smoothstep(step, -step, final));
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
