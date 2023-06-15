Shader "MathematicalVisualizationArt/LowPolyCat"
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

            #define time _Time.y
            #define Max_Dist 20
            #define Min_Dist 0.5
            #define Max_Time 256
            #define iTimeDelta unity_DeltaTime.x
            #define iFrame ((int)(_Time.y / iTimeDelta))
            #define pi 3.14159265359
            #define R(x) frac(sin(dot(x,float2(12.9898, 78.233))) * 43758.5453)
            #define HAIR_LENGTH 20.0
            #define TOUSLE 0.15
            #define BORDER 1.5

            /*
            SDF - https://iquilezles.org/articles/distfunctions/
            reference - https://www.shadertoy.com/view/3lsSzf
            texture from https://www.shadertoy.com/view/ttjyRc
            */
            float smin( float a, float b, float k )
            {
                float h = max(k-abs(a-b),0.0);
                return min(a, b) - h*h*0.25/k;
            }

            //#region rotation
            float3x3 rotateX(float theta) {
                float c = cos(theta);
                float s = sin(theta);
                return float3x3(
                    float3(1, 0, 0),
                    float3(0, c, -s),
                    float3(0, s, c)
                );
            }

            float3x3 rotateY(float theta) {
                float c = cos(theta);
                float s = sin(theta);
                return float3x3(
                    float3(c, 0, s),
                    float3(0, 1, 0),
                    float3(-s, 0, c)
                );
            }

            float3x3 rotateZ(float theta) {
                float c = cos(theta);
                float s = sin(theta);
                return float3x3(
                    float3(c, -s, 0),
                    float3(s, c, 0),
                    float3(0, 0, 1)
                );
            }

            float3x3 identity() {
                return float3x3(
                    float3(1, 0, 0),
                    float3(0, 1, 0),
                    float3(0, 0, 1)
                );
            }
            //#endregion

            //#region SDF
            float sdSphere(float3 p,float radio)
            {
                return length(p) - radio;
            }

            float sdEllipsoid( in float3 p, in float3 r )
            {
                float k0 = length(p/r);
                float k1 = length(p/(r*r));
                return k0*(k0-1.0)/k1;
            }

            float sdBox(in float3 p,in float3 b )
            {
                float3 q = abs(p) - b;
                return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }

            float sdRoundBox(in float3 p,in float3 b,in float r )
            {
                return  sdBox(p,b) - r;
            }
            float sdRoundCone( float3 p, float r1, float r2, float h )
            {
                // sampling independent computations (only depend on shape)
                float b = (r1-r2)/h;
                float a = sqrt(1.0-b*b);

                // sampling dependant computations
                float2 q = float2( length(p.xz), p.y );
                float k = dot(q,float2(-b,a));
                if( k<0.0 ) return length(q) - r1;
                if( k>a*h ) return length(q-float2(0.0,h)) - r2;
                return dot(q, float2(a,b) ) - r1;
            }
            //#endregion

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

            float3 hyena(float2 uv,half3 color)
            {
                float angle = (fbm(uv) + 2.0) * PI;
                float f = hairtexture(uv, 1.0f, angle);
                
                // apply color look and use fbm to create darker patches
                float3 col = lerp(color * f * lerp(2.0, 4.0, fbm(uv * 10.0)), 1.0, pow(f, 4.0));
                
                return col;
            }
            //#endregion

            float2 opU(in float2 d1, in float2 d2 )
            {
                return (d1.x<d2.x) ? d1 : d2;
            }

            float3 tranformCat(in float3 p)
            {
                //p = mul(rotateY(pi * 1.5),p);
                p = mul(rotateY(pi * 1.5 + pi*0.25*floor(time*5*3)),p);
                p = mul(rotateZ(pi * (frac(time*1.25*3) * 2 - 1) * 0.05),p);
                p.y += sin(time*5)*0.4;
                return p;
            }

            float2 map(in float3 pos)
            {
                float2 res = 0;
                //body
                float3 cat_pos = tranformCat(pos);
                float cat=0,body=0,head=0;
                {
                    float3 body_pos = cat_pos;
                    body_pos.y -= step(0.,cat_pos.y)* sin(cat_pos.x*3) * 0.15;
                    body_pos.x -= step(cat_pos.x,0.0)* cos(cat_pos.y*7+0.5) * 0.1;
                    body = sdRoundBox(body_pos,float3(0.65,0.15,0.1),0.5)* 0.5;
                    res = float2(body,2.0);
                }
                //head
                {
                    float3 head_pos = mul(rotateY(pi *-0.1),mul(rotateZ(pi *-0.15),cat_pos+ float3(1.,-0.5,0.0)));
                    float3 head_radian = float3(0.6,0.5 - smoothstep(0.,-1.0,head_pos.x) *0.1,0.6 - smoothstep(0.1,-0.6,head_pos.x)*0.1); 
                    head = smin(sdEllipsoid(head_pos, head_radian),sdSphere(head_pos - float3(0.14,0.02,0), 0.53),0.02);
                }
                res.x = smin(head, body.x,0.1);
                //ear
                float3 ear_pos = cat_pos;
                {
                    ear_pos = mul(rotateY(pi * 0.5),ear_pos);
                    ear_pos.x = abs(ear_pos.x);
                    ear_pos.y = -ear_pos.y;
                    ear_pos -= float3(0.45,-1.0,1.0);
                    ear_pos.z *= 1.5;
                    ear_pos = mul(rotateZ(pi * -1.3),mul(rotateY(pi * -1.7),ear_pos));
                    float ear = sdRoundCone(ear_pos,0.15,0.05,0.3);
                    res.x = smin(ear,res.x,0.36);
                }
                //eye
                {
                    res.y = opU(res,float2(sdSphere(ear_pos - float3(-0.44,0.1,0.4), 0.1),3.0)).y;
                }
                //ground
                {
                    float ground = pos.y + 1.1;
                    float d = min(res.x,ground);
                    if( d<res.x ){res = float2(d,1.0);}
                }
                return res;
            }

            //计算射线
            float2 castRay(in float3 ro, in half3 rd)
            {
                float2 res = float2(-1.0,-1.0);
                float t = Min_Dist;
                for(int i = 0; i < Max_Time && t<Max_Dist; i++)
                {
                    float3 p = ro+t*rd;
                    float2 h = map(p);
                    t += h.x;
                    if (h.x < 0.001f)
                    {
                        res = float2(t,h.y);
                        break;
                    }
                }
                return res; 
            }        

            //normal from iq
            float3 calcNormal(in float3 pos)
            {
                float3 n = 0.0;
                for( int i=min(iFrame,0); i<4; i++ )
                {
                    float3 e = 0.5773*(2.0*float3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
                    n += e*map(pos+0.0005*e).x;
                }
                return normalize(n); 
            }

            half3 triplanerMapping(float3 col_xz,float3 col_xy,float3 col_yz,float3 nor,half3 col) 
            {
                nor = abs(nor);
                nor *= pow(nor,1);
                nor /= nor.x+nor.y+nor.z;
                col *= col_xz * nor.y + col_xy * nor.z + col_yz * nor.x;
                return col;
            }

            float3 render(in float3 ro, in half3 rd)
            {
                half3 col = 1.0;
                float2 res = castRay(ro,rd);
                half3 rainbow = half3(abs(sin(time+pi*0.3333*10)),abs(sin(time+pi*0.6666*10)),abs(sin(time*10)));
                if(res.x > 0.0)
                {
                  float3 pos = ro + res.x*rd;
                  half3  sun_lig = normalize(float3(-0.2, 0.35, 0.5) );
                  float3 nor = calcNormal(pos);
                  float sun_dif = clamp(dot( nor, sun_lig ), 0.0, 1.0 );
                  float sun_sha = step(castRay( pos+0.001*nor, sun_lig).x,0.0);

                  float3 transformed_nor = tranformCat(nor);
                  float3 transformed_pos = tranformCat(pos);
                  half3 lin = 0.0;
                  
                  //三平面映射
                  float3 col_xz = hyena(transformed_pos.xz * 1.0, float3(0.2, 0.172, 0.172));
                  float3 col_xy = hyena(transformed_pos.xy * 1.0, float3(0.2, 0.172, 0.172));
                  float3 col_yz = hyena(transformed_pos.yz * 1.0, float3(0.2, 0.172, 0.172));
                  col = triplanerMapping(col_xz,col_xy,col_yz,nor,col);
                  if(res.y > 2.5)
                  {
                     //eye
                     col = half3(0.,0.,0.);
                     lin = sun_dif*col*sun_sha;
                  }else if(res.y > 1.5)
                  {
                    col = lerp(1.0, col,smoothstep(-1,-0.7,transformed_nor.x));
                    col = lerp(1.0, col,smoothstep(-1,-0.2,transformed_nor.y));
                    //lin += sun_dif*col*sun_sha;
                    lin +=col;
                  }else if(res.y > 0.5)
                  {
                    lin = rainbow;
                    lin += 1-sun_sha;
                  }
                  
                  col = lin;
                }else
                {
                    col = rainbow;
                }
                
                return col;
            }    

            #define w _ScreenParams.x
            #define h _ScreenParams.y
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                uv.y = 1 - uv.y;
                // half4 col = tex2D(_MainTex, uv);
                // c = col;
                uv = float2(uv.x-0.5f, (uv.y-0.5f)*(h/w));
                uv = floor(uv * 100)/100;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                float3 ro = float3(0,0,7);
                half3 rd = normalize(half3(uv,-1));
                
                c = render(ro, rd);
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
