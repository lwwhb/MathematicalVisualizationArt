Shader "MathematicalVisualizationArt/SnowMix"
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
                half4 positionOS : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                half2 uv                       : TEXCOORD0;
                half4 positionCS               : SV_POSITION;
                half4 screenPos                : TEXCOORD1;
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

            half random(half i) {
                return frac(sin(i)*428.8675);
            }

            //#region snow
            //from https://iquilezles.org/articles/distfunctions2d/
            half sdHexagon( in half2 p, in half r)
            {
                const half3 k = half3(-0.866025404,0.5,0.577350269);
                p = abs(p);
                p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
                p -= half2(clamp(p.x, -k.z*r, k.z*r), r);
                return length(p)*sign(p.y);
            }

            
            //from https://iquilezles.org/articles/distfunctions2d/
            half sdStar(in half2 p, in half r, in int n, in half m)
            {
                // next 4 lines can be precomputed for a given shape
                half an = 3.141593/half(n);
                half en = 3.141593/m;  // m is between 2 and n
                half2  acs = half2(cos(an),sin(an));
                half2  ecs = half2(cos(en),sin(en)); // ecs=half2(0,1) for regular polygon

                half bn = fmod(atan2(p.x,p.y),2.0*an) - an;
                p = length(p)*half2(cos(bn),abs(sin(bn)));
                p -= r*acs;
                p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
                return length(p)*sign(p.x);
            }

            //https://iquilezles.org/articles/distfunctions2d/
            half sdSegment( in half2 p, in half2 a, in half2 b )
            {
                half2 pa = p-a, ba = b-a;
                half h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
                return length( pa - ba*h );
            }

            half flake1(half2 p){ 
                half2 p_c = half2(atan2(p.x,p.y),length(p));
                half flake_1 =  smoothstep(0.,1.4,abs(sin(p_c.x*3.0))) + 0.5;
                flake_1 = smoothstep(flake_1,flake_1+0.02,p_c.y);
                half hex = saturate(sdHexagon(p,0.8));
                flake_1 = step(1.0,1. - max(flake_1, hex));
                return flake_1;
            }

            half flake2(half2 p){
                p.x -= 3.;
                half2 p_c = half2(atan2(p.x,p.y),length(p));
                half flake_2 = 0.0;
                    for(int i = 1;i < 8;i++)
                    {
                        half a = pi / 8 + i * pi * 0.25;
                        flake_2 += step(0,0.03 - sdSegment(p,half2(cos(a),sin(a)),half2(cos(a+pi),sin(a+pi)))); 
                    }
                flake_2 = max(flake_2, step(p_c.y,0.3) - step(p_c.y,0.25));
                half star = sdStar(abs(p), 0.8, 8, 3.2);
                flake_2 += (1 - step((step(star,0.07) - step(star,0.02)),1 - step(abs(cos(p_c.x * 4 )),0.9)));
                flake_2 += (1 - step((step(star,0.18) - step(star,0.13)),1 - step(abs(cos(p_c.x * 4 )),0.7)));
                flake_2 += (1 - step((step(star,0.28) - step(star,0.23)),1 - step(abs(cos(p_c.x * 4 )),0.5)));
                return saturate(flake_2);
            }

            half flake3(half2 p){
                p.x += 6.;
                half2 p_c = half2(atan2(p.x,p.y),length(p));
                half flake_3 = 0.0;
                for(int i = 1;i < 8;i++)
                {
                    half a = pi / 8 + i * pi * 0.25;
                    flake_3 += step(0,0.03 - sdSegment(p,half2(cos(a),sin(a)),half2(cos(a+pi),sin(a+pi)))); 
                }
                half star = sdStar(abs(p), 0.8, 8 , 3.2);
                flake_3 += step(star,-0.18) - step(star,-0.23);
                flake_3 += (1 - step(step(star,-0.06) - step(star,-0.1),1 - step(abs(cos(p_c.x * 4 )),0.92)));
                flake_3 += (1 - step(step(star,0.06) - step(star,0.02),1 - step(abs(cos(p_c.x * 4 )),0.96)));
                return flake_3;
            }
            //#endregion snow
            
            //#region branch
            
      

            half branch3p(in half2 uv,in half2 pa,in half2 pb,in half2 pc,in int NUM_SEGS,
            in half thickness,out half snow,in half snow_thickness,in half snow_threshold,in half random_id)
            {
                half r = 0.0;
                //half2 pabc = lerp(lerp(pa,pb,frac(time)),lerp(pb,pc,frac(time)),frac(time));
                half2 p,pp = pa;
                half2 sp,psp = pa;
                half2 d = 0.0;
                half bcr = random(73.1768+random_id);
                half c_count = bcr > 0.33333 ? bcr > 0.66666 ? 5 : 3 : 2.5;
                snow= 0;
                for(int i=1;i<=NUM_SEGS;i++){
                    half t = half(i)/half(NUM_SEGS);
                    p = lerp(lerp(pa,pb,t),lerp(pb,pc,t),t);
                    r += step(0,0.2*thickness -sdSegment(uv,p,pp)-0.1*t*t);
                    if(fmod(i,c_count) == 0)
                    {
                        sp = p;
                        half2x2 rotation = half2x2(cos(pi*-0.5), sin(pi*-0.5), -sin(pi*-0.5), cos(pi*-0.5));
                        d = mul(rotation,normalize(sp-psp));
                        half s_t =0.2*snow_thickness*lerp(((random(psp+12.11f+random_id)*2-1)*0.3+1),((random(sp+12.11f+random_id)*2-1)*0.3+1),0.9);
                        if(s_t < snow_threshold)
                        {
                         half sp_change = lerp(0.025+lerp(random(sp+312.266+random_id)*0.1, random(psp+77.191f+random_id)*0.1,0.5) - t*0.1,t*0.1,t);
                         half psp_change = lerp(0.025+lerp(random(sp+77.191f+random_id)*0.1, random(psp+89.11f+random_id)*0.1,0.5) - t*0.1, t * 0.1,t);
                         snow += step(0,s_t - sdSegment(uv,sp+sp_change*d,
                         psp+psp_change*d)-0.01*t);
                        }
                        psp = sp;
                        bcr = random(23.8768+i+3.2);
                        c_count = bcr > 0.33333 ? bcr > 0.66666 ? 5 : 3 : 2.5;
                    }
                    pp = p;
                }
                //r += step(0,0.2-length(uv1-pabc));
                return r;
            }

            half2 branch3pPosition(in half2 pa,in half2 pb,in half2 pc,in half2 t,in int NUM_SEGS,out half2 d)
            {
                half s = 1.0/half(NUM_SEGS);
                half2 p = lerp(lerp(pa,pb,t),lerp(pb,pc,frac(t)),t);
                half2 np = lerp(lerp(pa,pb,t),lerp(pb,pc,frac(t)),t);
                d = np - p; 
                return p;
            }

            half branch4p(in half2 uv,in half2 pa,in half2 pb,in half2 pc,in half2 pd,
            in int NUM_SEGS,in half thickness,out half snow,half snow_thickness, half snow_threshold,half random_id)
            {
                half3 result = 0.0;
                half2 p,preview_p = pa;
                half2 sp,psp = pa;
                half2 d = 0.0;
                half pace_random = random(23.8768+random_id);
                half pace = pace_random > 0.33333 ? pace_random > 0.66666 ? 6 : 5 : 2.5;
                snow = 0;
                for(int i=1;i<=NUM_SEGS;i++){
                    half t = half(i)/half(NUM_SEGS);
                    p = lerp(lerp(lerp(pa,pb,t),lerp(pb,pc,t),t), lerp(lerp(pb,pc,t),lerp(pc,pd,t),t),t);
                    result += step(0,0.2*thickness -sdSegment(uv,p,preview_p)-0.1*t*t);
                    if(fmod(i,pace) == 0)
                    {
                        sp = p;
                        half2x2 rotation = half2x2(cos(pi*-0.5), sin(pi*-0.5), -sin(pi*-0.5), cos(pi*-0.5));
                        d = mul(rotation,normalize(sp-psp));
                        half s_t = 0.2*snow_thickness*lerp(((random(psp+128.11f+random_id)*2-1)*0.3+1.0),((random(sp+128.11f+random_id)*2-1)*0.3+1.0),0.9);
                        if(s_t > snow_threshold){
                            half sp_change = lerp((0.1+lerp(random(sp+12.11f+random_id)*0.5, random(psp+32.11f+random_id)*0.5,0.5)),t*0.1,t);
                            half psp_change = lerp((0.1+lerp(random(sp+32.11f+random_id)*0.5, random(psp+15.221f+random_id)*0.5,0.5)),t*0.1,t);
                            sp_change = t < 0.1 ? lerp(0.2,sp_change,t): sp_change;
                            psp_change = t < 0.1 ? lerp(0.2,psp_change,t): psp_change;
                            snow += step(0,s_t- sdSegment(uv,sp + sp_change*d, psp + psp_change*d)-0.1*t*t);
                        }
                        psp = sp;
                        pace_random = random(23.8768+i);
                        pace = 3;
                    }
                    preview_p = p;
                }
                return saturate(result);
            }

            half2 branch4pPosition(in half2 pa,in half2 pb,in half2 pc,in half2 pd,in half t,in int NUM_SEGS,out half2 d)
            {
                half s = 1.0/half(NUM_SEGS);
                half2 p = lerp(lerp(lerp(pa,pb,t),lerp(pb,pc,t),t), lerp(lerp(pb,pc,t),lerp(pc,pd,t),t),t);
                half2 np = lerp(lerp(lerp(pa,pb,t+s),lerp(pb,pc,t+s),t+s), lerp(lerp(pb,pc,t+s),lerp(pc,pd,t+s),t+s),t+s);
                d = np - p; 
                return p;
            }

            half2 polarToCartesian(half2 p)
            {
                return half2(cos(p.x),sin(p.x))*p.y;
            }

            half3 branch(half2 uv,half random_id,half radian,half3 color,half l)
            {
                half3 c = 0;
                half snow_sum = 0,snow = 0;

                //先用polar coordinate 生成两个个随机数把值角度限制和长度限制做限制
                half2 bapa = half2(0.0,0.0); //branch a point a
                half2 bapd = half2(radian,random(98.2311+random_id)*5+9.0+l);
                half2 bapc = half2(bapd.x+(random(21.8768+random_id)*2-1)*pi*0.16666666,bapd.y * random(223.322+random_id)*0.6);
                half2 bapb = half2(bapc.x+(random(221.8768+random_id)*2-1)*pi*0.16666666,bapc.y * random(23.322+random_id)*0.6);
                bapc = bapa + polarToCartesian(bapc);
                bapb = bapa + polarToCartesian(bapb);
                bapd = bapa + polarToCartesian(bapd);

                c = branch4p(uv, bapa, bapb, bapc, bapd,15,1.0,snow,0.9,0.13,random_id);
                snow_sum+=snow;

                //half bbr = random(13.8768+random_id);
                int branch_b_count = 2;
                for(int i = 1; i <= branch_b_count;i++)
                {
                    half2 derivative = 0;
                    half2 bbpa = branch4pPosition(bapa,bapb,bapc,bapd,(random(124.2221+i+random_id)*(1.0/branch_b_count)+((i-1.0)/branch_b_count))*0.9,15,derivative);
                    derivative = normalize(derivative);
                    half r = random(11.8768+i+random_id) * 2 - 1;
                    r += (r >= 0 ? 0.2 : -0.2);
                    half2 bbpd = half2(atan2(derivative.y,derivative.x) + r * pi * 0.2,random(11.2311+i+random_id)*2.0+3.0);
                    half2 bbpc = half2(bbpd.x + (random(24.2221+i+random_id)*2-1)*pi*0.08333333,bapd.y * random(19.122+i+random_id));
                    half2 bbpb = half2(bbpc.x + (random(41.8768+i+random_id)*2-1)*pi*0.08333333,bapc.y * random(213.322+i+random_id));
                    bbpc = bbpa + polarToCartesian(bbpc);
                    bbpb = bbpa + polarToCartesian(bbpb);
                    bbpd = bbpa + polarToCartesian(bbpd);
                    c += branch4p(uv, bbpa, bbpb, bbpc, bbpd,60,0.8,snow,0.7,0.1,random_id);
                    snow_sum+=snow;
                    // half bcr = random(213.8768+i+random_id);
                    // int  branch_c_count = bcr > 0.33333 ? bcr > 0.66666 ? 2 : 1 : 1;
                    // for(int j = 1; j <= branch_c_count;j++)
                    // {
                    //     half2 cd = 0;
                    //     half2 bcpa = branch4pPosition(bbpa,bbpb,bbpc,bbpd,(random(24.2221+i+random_id)*(1.0/branch_c_count)+((j-1.0)/branch_c_count))*0.9,15,derivative);
                    //     derivative = normalize(derivative);
                    //     r = random(221.8768+j+random_id) * 2 - 1;
                    //     r += (r >= 0 ? 0.2 : -0.2);
                    //     half2 bcpc = half2(atan2(derivative.y,derivative.x) + r * pi * 0.2,random(91.2311+i+random_id)*1.5+0.2);
                    //     half2 bcpb = half2(bcpc.x + (random(41.8768+i+random_id)*2-1)*pi*0.08333333,bcpc.y * random(213.322+i));
                    //     bcpc = bcpa + polarToCartesian(bcpc);
                    //     bcpb = bcpa + polarToCartesian(bcpb);
                    //     c += branch3p(uv, bcpa, bcpb, bcpc ,15,0.5,snow,0.3,0.1,random_id);
                    //     snow_sum+=snow;
                    // }
                }
                c = saturate(c) * color + saturate(snow_sum);
                return c;
            }
            //#endregion
            
            //#region other
            half dot2(in half2 v)
            {
                return dot(v,v);
            }

            half sdRoundedCross( in half2 p, in half h )
            {
                half k = 0.5*(h+1.0/h); // k should be const at modeling time
                p = abs(p);
                return ( p.x<1.0 && p.y<p.x*(k-h)+h ) ? 
                        k-sqrt(dot2(p-half2(1,k)))  :
                    sqrt(min(dot2(p-half2(0,h)),
                                dot2(p-half2(1,0))));
            }

            half random (half2 st) {
                return frac(sin(dot(st.xy,
                                    half2(12.9898,78.233)))*
                    43758.5453123);
            }
            //#endregion

            #define w _ScreenParams.x
            #define h _ScreenParams.y
            
            half3 PixelColor(half2 uv)
            {
                half3 c = half3(0, 0, 0);
                uv = uv * 2 - 1;
                half co = w/h;
                half2 uv1 = half2(uv.x*co, uv.y);
                half2 uv2 = uv1*3.5;
                half stage_a = 5.0;
                half timeline = frac(time*0.05);
                half timeline_b = timeline > 0.5 ? (timeline - 0.5) * 2 : 0;
                half timeline_a = timeline < 0.5 ?  timeline * 2 : 0;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                
                //a场景
                if(timeline <= 0.5)
                {
                    //zoom in
                    uv2 = uv2 * lerp(1.0,0.9,timeline*2);
                     //background
                    {
                        half2 f = uv1;
                        f.x *= 0.3;
                        f.y += 1.3;
                        f *= 0.5;
                        half l = length(f);
                        c += lerp(lerp(half3(1,1,1),half3(1,0,0),max(l*l,0.1)),half3(0.3813,0.4549,0.7411),min(length(f*half2(1,1.05)),1));
                    }
                     //tree
                    {
                        half3 b = 0;
                        for(uint i = 1; i <= 4;i++)
                        {
                            half3x3 reflection = half3x3(1,0,0,0,-1,0,0,0,1);
                            if(i<3)
                            {
                                reflection = half3x3(-1,0,0,0,-1,0,0,0,1);
                            }
                            half2 p = uv2;

                            half3x3 movement = half3x3(1, 0, 7, 0, 1, 1 + (fmod(i,2) == 0 ? 0 : 2.5), 0, 0, 1);
                            half3x3 scaling = half3x3(3 , 0, 0, 0, 3 , 0, 0, 0, 1);
                            half3x3 transform = mul(scaling,mul(movement,reflection));
                            half3 b = branch(mul(transform,half3(p,1)), i, 0.2*pi,half3(0.6235,0.6235,0.8901),0);
                            c = b.r > 0 ? b : c;
                        }
                        for(uint i = 1; i <= 6;i++)
                        {
                            half3x3 reflection = half3x3(1,0,0,0,-1,0,0,0,1);
                            half slope = 0.0;
                            if(i<4)
                            {
                                reflection = half3x3(-1,0,0,0,-1,0,0,0,1);
                            }
                            half2 p = uv2;

                            half3x3 movement = half3x3(1, 0, 6.5, 0, 1, 1.5 - 1.5*fmod(i,3)+(random(i+1.0)*2-1), 0, 0, 1);
                         
                            half3x3 scaling = half3x3(3 , 0, 0, 0, 3 , 0, 0, 0, 1);
                            half3x3 transform = mul(scaling,mul(movement,reflection));
                            half3 b = branch(mul(transform,half3(p,1)), i*16.9, 0.1*pi,half3(0.2588,0.3450,0.5882),2);
                            c = b.r > 0 ? b : c;
                        }
                    }
                }
                else
                {
                    
                    //background
                    {
                        half2 f = uv1;
                        f.x *= 0.3;
                        f.y += 1.;
                        f *= 0.2;
                        half l = length(f);
                        //0.6550,0.2217,0.2117 -> 0.7294,0.5529,0.4823
                        half3 dawn = lerp(half3(0.6550,0.2217,0.2117),half3(0.9829,0.6529,0.5823),timeline_b < 0.3 ? timeline_b * 3.3333: 1);
                        c = lerp(half3(0.0784,0.0823,0.2176),dawn,min(length(f*half2(1,2.0)),1));
                    }
                    //roundedCross
                    if(timeline_b < 0.3)
                    {
                        half2 movements[6] = {half2(5,9),half2(5.5,-8),half2(1,5),half2(-2.5,-4),half2(-6,-11),half2(-4,11.5)};
                        for(int i =0;i<6;i++)
                        {
                            half2 p = uv2.yx*lerp(3,2,timeline_b < 0.05 ? timeline_b * 20: 1) + movements[i];
                            p *= 0.8;
                            p += p*(1/(half(i*i)+1));
                            p.x -= timeline_b > 0.05 ? (timeline_b - 0.05) * 100 : 0;
                            half roundedCross = 0;
                            half d = sdRoundedCross(p, 0.5);
                            roundedCross = step(0,-d);
                            roundedCross += clamp(0.001/d, 0., 1.) * 12.;
                            c += roundedCross;
                        }
                    }
                     //star
                    if(timeline_b >= 0.25)
                    {
                        {
                            half2 p = uv1;
                            half cosine = cos(time*0.1);
                            half sine = sin(time *0.1);
                            p.y+=1.5;
                            half2x2 rotation = half2x2(cosine, sine,  -sine, cosine);
                            p = mul(rotation,p);
                            half rnd = random(floor(p*200)*0.777);
                            half transparent = 1.0;
                            if(uv1.y > 0.2)
                            {
                                transparent *= smoothstep(3,-3,uv1.y*2.5);
                            }
                            if(timeline_b < 0.35)
                            {
                                transparent *= lerp(0.1,1,(timeline_b-0.25)*10); 
                            }
                            c+=step(0.995,rnd)*transparent;

                            //大一点的星星 重复上面的方法
                            half2 p1 = uv1;
                            cosine = cos(time*0.11);
                            sine = sin(time *0.11);
                            p1.y+=1.5;
                            rotation = half2x2(cosine, sine,  -sine, cosine);
                            p1 = mul(rotation,p1);
                            half rnd1 = random(floor(p1*100)*0.444);
                            transparent = 1.0;
                            if(uv1.y > 0.2)
                            {
                                transparent = smoothstep(3,-3,uv1.y*2.5);
                            }
                            c+=step(0.997,rnd1)*transparent;
                        }
                    }
                }

                if(timeline_b >= 0.25 || timeline_a >= 0.25)
                {
                    //snow
                    {
                        half transparent = smoothstep(3,1,uv2.y);
                        if(timeline_b >= 0.25 && timeline_b < 0.35)
                        {
                             transparent *= lerp(0.1,1,(timeline_b-0.25)*10); 
                        }else if(timeline_a >= 0.25 && timeline_a < 0.35)
                        {
                             transparent *= lerp(0.1,1,(timeline_a-0.25)*10); 
                        }
                        for(int i = 1;i <= 20;i++)
                        {
                            half velocity = time*max(random(i+21.22)*3,0.8);
                            half2 p = half2( (random(i*2.22)*2-1)*7.0,(random(i+11.22)*2-1)*7.0 - velocity);
                            p.y = fmod(p.y,8)+4;
                            p.x += sin(time*random(19.11+i)+random(29.11+i))*lerp(0,0.2,random(89.11+i));
                            half a = random(i+28.9798)*pi*2 + lerp(0,0.3,random(66.989*i))*time;
                            half cosine = cos(a);
                            half sine = sin(a);
                            half3x3 movement = half3x3(1, 0, p.x, 0, 1, p.y, 0, 0, 1);
                            half3x3 scaling = half3x3(5 + (random(i+31.22) * 2 -1) + 0.2 * abs(p.x), 0, 0, 0, 5 + (random(i+31.22) * 2 -1)+  0.2 * abs(p.x), 0, 0, 0, 1);
                            half3x3 rotation = half3x3(cosine, sine, 0, -sine, cosine, 0, 0, 0, 1);
                            half3x3 transform = mul(rotation,mul(scaling,movement));
                            half2 t = mul(transform,half3(uv2,1.0)).xy;
                            c += flake1(t) * transparent;
                        }
                        for(int i = 1;i <= 20;i++)
                        {
                            half velocity = time*max(random(i+12.88)*3,0.8);
                            half2 p = half2( (random(i+32.12)*2-1)*7.0,(random(i+5.22)*2-1)*7.0 - velocity);
                            p.y = fmod(p.y,14)+7;
                            p.x += sin(time*random(198.1+i)+random(229.11+i))*lerp(0,0.2,random(89.11+i));
                            half a = random(i+281.12)*pi*2 + lerp(0,0.3,random(66.989+i))*time;;
                            half cosine = cos(a);
                            half sine = sin(a);
                            half3x3 movement = half3x3(1, 0, p.x, 0, 1, p.y, 0, 0, 1);
                            half3x3 scaling = half3x3(5 + (random(i+99.22) * 2 -1) * 5 + 0.2 * abs(p.x), 0, 0, 0, 5 + (random(i+99.22) * 2 -1) * 5+  0.2 * abs(p.x), 0, 0, 0, 1);
                            half3x3 rotation = half3x3(cosine, sine, 0, -sine, cosine, 0, 0, 0, 1);
                            half3x3 transform = mul(rotation,mul(scaling,movement));
                            half2 t = mul(transform,half3(uv2,1.0)).xy;
                            c += flake2(t) * transparent;
                        }
                        for(int i = 1;i <= 20;i++)
                        {
                            half velocity = time*max(random(i+82.88)*3,0.8);
                            half2 p = half2( (random(i+38.12)*2-1)*7.0,(random(i+11.282)*2-1)*7.0 - velocity);
                            p.y = fmod(p.y,14)+7;
                            p.x += sin(time*random(18.31+i)+random(28.11+i))*lerp(0,0.2,random(89.11+i));
                            half a = random(i+81.12)*pi*2 + lerp(0,0.3,random(96.919+i))*time;;
                            half cosine = cos(a);
                            half sine = sin(a);
                            half3x3 movement = half3x3(1, 0, p.x, 0, 1, p.y, 0, 0, 1);
                            half3x3 scaling = half3x3(5 + (random(i+87.22) * 2 -1) * 5+ 0.2 * abs(p.x), 0, 0, 0, 5 + (random(i+87.22) * 2 -1) * 5+  0.2 * abs(p.x), 0, 0, 0, 1);
                            half3x3 rotation = half3x3(cosine, sine, 0, -sine, cosine, 0, 0, 0, 1);
                            half3x3 transform = mul(rotation,mul(scaling,movement));
                            half2 t = mul(transform,half3(uv2,1.0)).xy;
                            c += flake3(t) * transparent;
                        }
                    }
                }

                //interval & light
                {
                if(timeline_a > 0.0)
                {
                    half2 p = (uv+1)/2;
                    half blank = 0;
                    p.x = (1-p.x)*2+p.y;
                    if(timeline_a > 0.9)
                    {
                       p += lerp(0,-4,(timeline_a - 0.9) * 10);
                    }
                    blank = saturate(1-max(p.x,p.y));
                    c += blank*0.5;
                }
                if(timeline_b > 0 && timeline_b < 0.1)
                {
                    c = lerp(1, c , timeline_b * 10);
                }
                if(timeline_b > 0 && timeline_b > 0.9)
                {
                    c = lerp(c, half3(0.0784,0.0823,0.2176) , (timeline_b-0.9) * 10);
                }
                if(timeline_a > 0 && timeline_a < 0.1)
                {
                    c = lerp(half3(0.0784,0.0823,0.2176), c , timeline_a * 10);
                }
                }
                //
                return c;
            }

            half4 frag(Varyings input) : SV_Target 
            {
                half2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                #if UNITY_UV_STARTS_AT_TOP
                screenUV = screenUV * half2(1.0, -1.0) + half2(0.0, 1.0);
                #endif
                half3 col = Gamma22ToLinear(PixelColor(screenUV));
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
