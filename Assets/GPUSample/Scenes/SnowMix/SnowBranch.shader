Shader "MathematicalVisualizationArt/SnowBranch"
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
            #define pi 3.14159265359
             
            //https://iquilezles.org/articles/distfunctions2d/
            float sdSegment( in half2 p, in half2 a, in half2 b )
            {
                half2 pa = p-a, ba = b-a;
                float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
                return length( pa - ba*h );
            }

            float random(float i) {
                return frac(sin(i)*42258.867523);
            }

            float branch3p(in float2 uv,in float2 pa,in float2 pb,in float2 pc,in int NUM_SEGS,
            in float thickness,out float snow,in float snow_thickness,in float snow_threshold,in float random_id)
            {
                float r = 0.0;
                //float2 pabc = lerp(lerp(pa,pb,frac(time)),lerp(pb,pc,frac(time)),frac(time));
                float2 p,pp = pa;
                float2 sp,psp = pa;
                float2 d = 0.0;
                float bcr = random(73.1768*random_id);
                float c_count = bcr > 0.33333 ? bcr > 0.66666 ? 5 : 3 : 2.5;
                snow= 0;
                for(int i=1;i<=NUM_SEGS;i++){
                    float t = float(i)/float(NUM_SEGS);
                    p = lerp(lerp(pa,pb,t),lerp(pb,pc,t),t);
                    r += step(0,0.2*thickness -sdSegment(uv,p,pp)-0.1*t*t);
                    if(fmod(i,c_count) == 0)
                    {
                        sp = p;
                        float2x2 rotation = float2x2(cos(pi*-0.5), sin(pi*-0.5), -sin(pi*-0.5), cos(pi*-0.5));
                        d = mul(rotation,normalize(sp-psp));
                        float s_t =0.2*snow_thickness*lerp(((random(psp*1218.11f*random_id)*2-1)*0.3+1),((random(sp*1218.11f*random_id)*2-1)*0.3+1),0.9);
                        if(s_t < snow_threshold)
                        {
                         float sp_change = lerp(0.025+lerp(random(sp*312.266*random_id)*0.1, random(psp*77.191f*random_id)*0.1,0.5) - t*0.1,t*0.1,t);
                         float psp_change = lerp(0.025+lerp(random(sp*77.191f*random_id)*0.1, random(psp*89.11f*random_id)*0.1,0.5) - t*0.1, t * 0.1,t);
                         snow += step(0,s_t - sdSegment(uv,sp+sp_change*d,
                         psp+psp_change*d)-0.01*t);
                        }
                        psp = sp;
                        bcr = random(23.8768*i+3.2);
                        c_count = bcr > 0.33333 ? bcr > 0.66666 ? 5 : 3 : 2.5;
                    }
                    pp = p;
                }
                //r += step(0,0.2-length(uv1-pabc));
                return r;
            }

            float2 branch3pPosition(in float2 pa,in float2 pb,in float2 pc,in float t,in int NUM_SEGS,out float2 d)
            {
                float s = 1.0/float(NUM_SEGS);
                float2 p = lerp(lerp(pa,pb,t),lerp(pb,pc,frac(t)),t);
                float2 np = lerp(lerp(pa,pb,t),lerp(pb,pc,frac(t)),t);
                d = np - p; 
                return p;
            }

            float branch4p(in float2 uv,in float2 pa,in float2 pb,in float2 pc,in float2 pd,
            in int NUM_SEGS,in float thickness,out float snow,float snow_thickness, float snow_threshold,float random_id)
            {
                float3 result = 0.0;
                float2 p,preview_p = pa;
                float2 sp,psp = pa;
                float2 d = 0.0;
                float pace_random = random(23.8768*random_id);
                float pace = pace_random > 0.33333 ? pace_random > 0.66666 ? 6 : 5 : 2.5;
                snow = 0;
                for(int i=1;i<=NUM_SEGS;i++){
                    float t = float(i)/float(NUM_SEGS);
                    p = lerp(lerp(lerp(pa,pb,t),lerp(pb,pc,t),t), lerp(lerp(pb,pc,t),lerp(pc,pd,t),t),t);
                    result += step(0,0.2*thickness -sdSegment(uv,p,preview_p)-0.1*t*t);
                    if(fmod(i,pace) == 0)
                    {
                        sp = p;
                        float2x2 rotation = float2x2(cos(pi*-0.5), sin(pi*-0.5), -sin(pi*-0.5), cos(pi*-0.5));
                        d = mul(rotation,normalize(sp-psp));
                        float s_t = 0.2*snow_thickness*lerp(((random(psp*128.11f*random_id)*2-1)*0.3+1.0),((random(sp*128.11f*random_id)*2-1)*0.3+1.0),0.9);
                        if(s_t > snow_threshold){
                            float sp_change = lerp((0.1+lerp(random(sp*12.11f*random_id)*0.5, random(psp*32.11f*random_id)*0.5,0.5)),t*0.1,t);
                            float psp_change = lerp((0.1+lerp(random(sp*32.11f*random_id)*0.5, random(psp*15.221f*random_id)*0.5,0.5)),t*0.1,t);
                            sp_change = t < 0.1 ? lerp(0.2,sp_change,t): sp_change;
                            psp_change = t < 0.1 ? lerp(0.2,psp_change,t): psp_change;
                            snow += step(0,s_t
                            - sdSegment(uv,sp + sp_change*d,
                            psp + psp_change*d)-0.1*t*t);
                        }
                        psp = sp;
                        pace_random = random(23.8768*i+3.2);
                        pace = pace_random > 0.33333 ? pace_random > 0.66666 ? 6 : 5 : 2.5;
                    }
                    preview_p = p;
                }
                return saturate(result);
            }

            float2 branch4pPosition(in float2 pa,in float2 pb,in float2 pc,in float2 pd,in float t,in int NUM_SEGS,out float2 d)
            {
                float s = 1.0/float(NUM_SEGS);
                float2 p = lerp(lerp(lerp(pa,pb,t),lerp(pb,pc,t),t), lerp(lerp(pb,pc,t),lerp(pc,pd,t),t),t);
                float2 np = lerp(lerp(lerp(pa,pb,t+s),lerp(pb,pc,t+s),t+s), lerp(lerp(pb,pc,t+s),lerp(pc,pd,t+s),t+s),t+s);
                d = np - p; 
                return p;
            }

            float2 polarToCartesian(float2 p)
            {
                return float2(cos(p.x),sin(p.x))*p.y;
            }

            float3 branch(float2 uv,float random_id,float radian,half3 color)
            {
                half3 c = 0;
                float snow_sum = 0,snow = 0;

                //先用polar coordinate 生成两个个随机数把值角度限制和长度限制做限制
                float2 bapa = float2(0.0,0.0); //branch a point a
                float2 bapd = float2(radian,random(98.2311*random_id)*5+9.0);
                float2 bapc = float2(bapd.x+(random(21.8768*random_id)*2-1)*pi*0.16666666,bapd.y * random(223.322*random_id)*0.6);
                float2 bapb = float2(bapc.x+(random(221.8768*random_id)*2-1)*pi*0.16666666,bapc.y * random(23.322*random_id)*0.6);
                bapc = bapa + polarToCartesian(bapc);
                bapb = bapa + polarToCartesian(bapb);
                bapd = bapa + polarToCartesian(bapd);

                c = branch4p(uv, bapa, bapb, bapc, bapd,120,1.0,snow,0.9,0.13,random_id);
                snow_sum+=snow;

                float bbr = random(13.8768*random_id);
                int branch_b_count = bbr > 0.25 ? bbr > 0.5 ? bbr > 0.75 ? 5 : 4 : 3 : 2;
                for(int i = 1; i <= branch_b_count;i++)
                {
                    float2 derivative = 0;
                    float2 bbpa = branch4pPosition(bapa,bapb,bapc,bapd,(random(124.2221*i*random_id)*(1.0/branch_b_count)+((i-1.0)/branch_b_count))*0.9,60,derivative);
                    derivative = normalize(derivative);
                    float r = random(191.8768*i*random_id) * 2 - 1;
                    r += (r >= 0 ? 0.2 : -0.2);
                    float2 bbpd = float2(atan2(derivative.y,derivative.x) + r * pi * 0.2,random(921.2311*i*random_id)*2.0+3.0);
                    float2 bbpc = float2(bbpd.x + (random(24.2221*i*random_id)*2-1)*pi*0.08333333,bapd.y * random(19.122*i*random_id));
                    float2 bbpb = float2(bbpc.x + (random(41.8768*i*random_id)*2-1)*pi*0.08333333,bapc.y * random(213.322*i*random_id));
                    bbpc = bbpa + polarToCartesian(bbpc);
                    bbpb = bbpa + polarToCartesian(bbpb);
                    bbpd = bbpa + polarToCartesian(bbpd);
                    c += branch4p(uv, bbpa, bbpb, bbpc, bbpd,60,0.8,snow,0.7,0.1,random_id);
                    snow_sum+=snow;
                    float bcr = random(213.8768*i*random_id);
                    int  branch_c_count = bcr > 0.33333 ? bcr > 0.66666 ? 2 : 1 : 1;
                    for(int j = 1; j <= branch_c_count;j++)
                    {
                        float2 cd = 0;
                        float2 bcpa = branch4pPosition(bbpa,bbpb,bbpc,bbpd,(random(24.2221*i*random_id)*(1.0/branch_c_count)+((j-1.0)/branch_c_count))*0.9,30,derivative);
                        derivative = normalize(derivative);
                        r = random(221.8768*j*random_id) * 2 - 1;
                        r += (r >= 0 ? 0.2 : -0.2);
                        float2 bcpc = float2(atan2(derivative.y,derivative.x) + r * pi * 0.2,random(91.2311*i*random_id)*1.5+0.2);
                        float2 bcpb = float2(bcpc.x + (random(41.8768*i*random_id)*2-1)*pi*0.08333333,bcpc.y * random(213.322*i));
                        bcpc = bcpa + polarToCartesian(bcpc);
                        bcpb = bcpa + polarToCartesian(bcpb);
                        c += branch3p(uv, bcpa, bcpb, bcpc ,30,0.5,snow,0.3,0.1,random_id);
                        snow_sum+=snow;
                    }
                }
                c = saturate(c) * color + saturate(snow_sum);
                return c;
            }

            #define w _ScreenParams.x
            #define h _ScreenParams.y
           

            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                uv.y = 1 - uv.y;
                uv = uv * 2 - 1;
                uv *= 7.;
                half co = w/h;
                half4 col = 0.0;//;tex2D(_MainTex, uv);
                float2 uv1 = float2(uv.x*co, uv.y);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                //每过三秒都能生成一种新的随机树枝
                c = branch(uv1, floor(time/3)*0.922+1, 0.1*pi,half3(0.6235,0.6235,0.8901));
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
