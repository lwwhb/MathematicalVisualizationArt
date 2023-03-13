Shader "MathematicalVisualizationArt/CosineRain"
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
                half2 uv1 = half2(uv.x-0.5f, (uv.y-0.5f) * (h / w));
                float t_s = 2.f;
                float tl = frac(time * t_s);
                //dlts 
                {
                    if(tl <= 0.5){
                        half2 uv3 = uv1;
                        uv3.y = uv3.y + 0.5 - tl;
                        half dlt = step(max(abs(uv3.x),abs(uv3.y) * 0.5), 0.02f);
                        c = dlt;
                    }
                }
                //dpl
                {   
                     if(tl >= 0.5f){
                        half2 uv2 = uv1;
                        uv2.x *= 0.6;
                        float uv2_l = length(uv2);
                        float ct = sin(tl - 0.5);
                        float dpl = step(ct* 0.5 - 0.03,uv2_l) -step(ct * 0.5, uv2_l) ;
                        c += dpl *half3(1,1,1);
                    }
                }
                //Spray
                {
                    if(tl >= 0.7f){
                    float2 poss[6] = {half2(0.2,0.3),half2(0.1,0.2),half2(0.01,0.1),half2(-0.12,0.1),half2(-0.01,0.3),half2(-0.2,0.2)};
                    for(uint i = 0;i< 6; i++){
                        float2 uv4 = uv1;
                        // float angle = frac(sin(i*780.2)*250.3) * 6.2831; //random 生成随机数
                        // float distance = lerp(0.2,0.4,frac(sin(i*722.2)*720.2));
                        //直线
                        // half2x2 ro = float2x2(cos(angle),-sin(angle),sin(angle),cos(angle)); 
                        // uv4 = mul(ro,uv4);
                        // uv4 = uv4.x >= 0 ? uv4 : 1;
                        // uv4 = sqrt(uv4.x*uv4.x+uv4.y*uv4.y) <= distance ? uv4 : 1;
                        //uv4.y = cos(uv4.x*3.14)*0.1+uv4.y;
                        //float r = frac(1-smoothstep(-0.01,0.01,abs(uv4.y)));
                        //c = uv4.y-cos(uv4.x*3.14*20);

                        //Cosine Interpolation from https://www.desmos.com/calculator/cfumbhj3yk
                        float2 pos = poss[i];//float2(sin(angle) * distance,cos(angle) * distance);
                        float2 p1 = float2(0,0); //pos.x > 0 ? float2(0,0) : pos;
                        float2 p2 = pos; //pos.x > 0 ? pos : float2(0,0);
                        float2 p3 = float2(0,0);
                        float2 t_d = float2(0,1);
                        if(pos.x > 0)
                        {
                            p3 = half2(pos.x + 0.1,lerp(1.,-0.2,abs(dot(t_d,normalize(pos)))));
                        }else
                        {
                            p1 = half2(pos.x - 0.1,lerp(1.,-0.2,abs(dot(t_d,normalize(pos)))));
                        }
                        
                        //uv4.y += (uv4.x-p1.x)*(p1.y-p2.y)/(p1.x-p2.x)+p1.y; 直线测试
                        //c = smoothstep(0.0,0.01,abs(uv4.y));
                        if(uv4.x <= p2.x && uv4.x > p1.x)
                        uv4.y += (cos((uv4.x-p1.x)/(p2.x-p1.x)*3.1415)-1)*0.5*(p1.y-p2.y)+p1.y;
                        if(uv4.x <= p3.x && uv4.x > p2.x)
                        uv4.y += (cos((uv4.x-p2.x)/(p3.x-p2.x)*3.1415)-1)*0.5*(p2.y-p3.y)+p2.y;
                        
                        if(!(uv4.x <= p3.x && uv4.x > p2.x) && !(uv4.x <= p2.x && uv4.x > p1.x))
                        uv4.y = 1;

                        if(1 > ((tl - 0.7)+ 0.05)/abs(uv4.x) || 1 < (tl - 0.7)/abs(uv4.x))
                        uv4.y = 1;
                        c = c+ step(0.1,1-smoothstep(0.00,0.02,abs(uv4.y)));
                    }
                    }
                }
                c = saturate(c);
               /* half2 p = half2(0.2,0);
                c = 0.001/length(uv1+p);*/
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
