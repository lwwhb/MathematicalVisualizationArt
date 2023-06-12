Shader "MathematicalVisualizationArt/3DBase"
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
            
            #define MAX_MARCHING_STEPS 100
            #define MIN_DIST  0.01
            #define MAX_DIST  100.0
            #define EPSILON  0.0001

            // 球体sdf
            float sdSphere( float3 p, float r )
            {
                return length(p)-r;
            }
            // 平面sdf
            float sdPlane( float3 p, float3 n, float h )
            {
                // n must be normalized
                n = normalize(n);
                return dot(p,n) + h;
            }
            // scene sdf
            float sdScene(float3 p)
            {
                //定义球体
                float3 spherePos = float3(0.0, 1.0, 0.0);
                float sphereRadius = 1.0;
                float3 sphereNormal = normalize( p - spherePos );
                //定义平面
                float3 planePos = float3(0.0, 0.0, 0.0);
                float3 planeNormal = float3(0.0, 1.0, 0.0);
                //求交集
                float sphereDist = sdSphere(p - spherePos, sphereRadius);
                float planeDist = sdPlane(p - planePos, planeNormal, 0.0);
                return min(sphereDist, planeDist);
            }
            // RayMarch, 用于计算光线与物体的交点
            float RayMarch(float3 ro, float3 rd)
            {
                float depth = 0.0;
                for(int i = 0; i < MAX_MARCHING_STEPS; i++)
                {
                    float3 p = ro + rd*depth;
                    float dist = sdScene(p);
                    depth+=dist;
                    if(depth > MAX_DIST || dist < MIN_DIST) 
                        break;           
                }
                return depth;     
            }
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                float uvSizeScale = 1;
                 //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限 (-5, 5)
                uv = (uv*2.0 -1.0)*uvSizeScale;
                //消除屏幕拉伸影响
                half co = width/height;
                uv = float2(uv.x*co, uv.y);

                //定义摄像机
                float3 camPos = float3(0.0, 1.0, -5.0);
	            float3 lightDir = normalize( float3(uv,1.0) );
                
	            float dist = RayMarch(camPos, lightDir);
                c = half3(dist/(20-time), dist/(20-time), dist/(20-time));
                /*if (dist > MAX_DIST - EPSILON) {
                    // Didn't hit anything
                    c = float4(0.0, 0.0, 0.0, 1.0);
                }
                else
                {
                    c = float4(1.0, 0.0, 0.0, 1.0);
                }*/
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
