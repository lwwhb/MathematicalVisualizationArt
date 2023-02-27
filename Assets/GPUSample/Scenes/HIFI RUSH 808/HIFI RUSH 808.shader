Shader "MathematicalVisualizationArt/HIFI RUSH 808"
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

            struct Surface {
                float sd; // signed distance value
                float3 col; // color
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


            Surface minWithColor(Surface obj1, Surface obj2) {
                if (obj2.sd < obj1.sd) return obj2;
                return obj1;
            }

            float opUnion(float d1, float d2) { 
                return min(d1, d2);
            }

            float opSubtraction(float d1, float d2 ) {
                return max(-d1, d2);
            }

           float opSmoothSubtraction(float d1, float d2, float k) {
                float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
                return lerp(d2, -d1, h ) + k*h*(1.0-h);
            }

            Surface sdSphere(float3 p,float radio, float3 color, float3 offset)
            {
                Surface sphere;
                sphere.sd = length(p - offset) - radio;
                sphere.col = color;
                return sphere;
            }
            
            Surface sdBox( float3 p, float3 b,float3 color,float3 offset,float3x3 rotate)
            {
                    
                Surface box;
                p = mul(rotate, (p - offset));
                float3 q = abs(p) - b;
                box.sd = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
                box.col = color;
                return box;
            }

            float sdCone(float3 p, float2 c, float h, float3 offset,float3x3 rotate)
            {
                p = mul(rotate, (p - offset));
                float2 q = h*float2(c.x/c.y,-1.0);
    
                float2 w = float2( length(p.xz), p.y );
                float2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
                float2 b = w - q*float2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
                float k = sign( q.y );
                float d = min(dot( a, a ),dot(b, b));
                float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y));
                return sqrt(d)*sign(s);
            }

            float udTriangle( float3 p, float3 a, float3 b, float3 c )
            {
            float3 ba = b - a; float3 pa = p - a;
            float3 cb = c - b; float3 pb = p - b;
            float3 ac = a - c; float3 pc = p - c;
            float3 nor = cross( ba, ac );

            return sqrt(
                (sign(dot(cross(ba,nor),pa)) +
                sign(dot(cross(cb,nor),pb)) +
                sign(dot(cross(ac,nor),pc))<2.0)
                ?
                min(min(
                dot(ba*clamp(dot(ba,pa)/dot(ba,ba),0.0,1.0)-pa,ba*clamp(dot(ba,pa)/dot(ba,ba),0.0,1.0)-pa),
                dot(cb*clamp(dot(cb,pb)/dot(cb,cb),0.0,1.0)-pb,cb*clamp(dot(cb,pb)/dot(cb,cb),0.0,1.0)-pb) ),
                dot(ac*clamp(dot(ac,pc)/dot(ac,ac),0.0,1.0)-pc,ac*clamp(dot(ac,pc)/dot(ac,ac),0.0,1.0)-pc) )
                :
                dot(nor,pa)*dot(nor,pa)/dot(nor,nor) );
            }

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

            Surface opSmoothUnion(Surface d1, Surface d2, float k) {
                Surface r;
                float h = clamp( 0.5 + 0.5*(d2.sd-d1.sd)/k, 0.0, 1.0 );
                r.sd = lerp( d2.sd, d1.sd, h ) - k*h*(1.0-h);
                r.col = lerp(d2.col, d1.col, h);
                return r;
            }

            float opIntersection(float d1, float d2) {
              return max(d1,d2);
            }

            float sdRoundedCylinder( float3 p, float ra, float rb, float h, float3 offset,float3x3 rotate,float2 wh)
            {
                p = mul(rotate, (p - offset));
                float2 d = float2( length(float2(p.x*wh.x,p.z*wh.y))-2.0*ra+rb, abs(p.y) - h );
                return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
            }

            Surface sdScene(float3 p) {
                float3 mCol = float3(0.184f, 0.211f, 0.254f);
                //head
                Surface co;
                Surface head = sdSphere(p, 1,mCol,float3(0,0,0));
                co = head;

                //ears
                float3 leftEarOffset = float3(-1.2,-1.7,0);
                float3 rightEarOffset = leftEarOffset;
                rightEarOffset.x = -rightEarOffset.x;
                float leftEarP1 = sdCone(p, float2(0.08,0.23),1.2,leftEarOffset,rotateZ(-2.55));
                float leftEarP2 = sdCone(p, float2(0.08,0.29),1.23,leftEarOffset,mul(rotateZ(-2.55),rotateY(0.2)));
                leftEarP2 = leftEarP2 + sin(p.y)*sin(p.x) * cos(1.6);
                Surface leftEar;
                leftEar.sd = opSmoothSubtraction( leftEarP2, leftEarP1, 0.04);
                leftEar.col = mCol;
                co = minWithColor(co, leftEar);
                float rightEarP1 = sdCone(p, float2(0.08,0.23),1.2,rightEarOffset,rotateZ(2.55));
                float rightEarP2 = sdCone(p, float2(0.08,0.29),1.23,rightEarOffset,mul(rotateZ(2.55),rotateY(-0.2)));
                rightEarP2 = rightEarP2 + sin(p.y)*sin(-p.x) * cos(1.6);
                Surface rightEar;
                rightEar.sd = opSmoothSubtraction( rightEarP2, rightEarP1, 0.04);
                rightEar.col = mCol;
                co = minWithColor(co, rightEar);

                //eyes 
                float3 leftEyeP = float3(-0.38,-0.15,0.85);
                float3 rightEyeP = leftEyeP;
                rightEyeP.x = -rightEyeP.x;
                float leftEye = sdRoundedCylinder(p, 0.13,0.1,0.05,leftEyeP,rotateX(1.57),float2(1,1));
                co.sd = opSubtraction(leftEye,co.sd);
                float rightEye = sdRoundedCylinder(p, 0.13,0.1,0.05,rightEyeP,rotateX(1.57),float2(1,1));
                co.sd = opSubtraction(rightEye,co.sd);
                float rightEyeLength = 1 - saturate(pow(length(p - rightEyeP) * 4,4));
                float3 rightEyeColor = rightEyeLength < 0.6 ? float3(1,1,1) : float3(0.78,0.662,0.411);
                
                float leftEyeLength = 1 - saturate(pow(length(p - leftEyeP) * 4,4));
                float3 leftEyeColor = leftEyeLength < 0.6 ? float3(1,1,1) : float3(0.78,0.662,0.411);
                
                float rightEyeInnerLength = 1 - saturate(pow(length(p - rightEyeP - float3(-0.02,0,0)) * 4,4.5));
                float leftEyeInnerLength = 1 - saturate(pow(length(p - leftEyeP  - float3(0.02,0,0)) * 4,4.5));
                rightEyeColor = rightEyeInnerLength > 0.83 ?  float3(0,0.894,1) : rightEyeColor;
                leftEyeColor = leftEyeInnerLength > 0.83 ?  float3(0,0.894,1) : leftEyeColor;

                float rightEyeSpecLength = 1 - saturate(pow(length(p - rightEyeP - float3(-0.04,-0.01,0)) * 4,4.9));
                float leftEyeSpecLength = 1 - saturate(pow(length(p - leftEyeP  - float3(0.0,-0.01,0)) * 4,4.9));
                rightEyeColor = rightEyeSpecLength > 0.91 ? float3(1,1,1) : rightEyeColor;
                leftEyeColor = leftEyeSpecLength > 0.91 ? float3(1,1,1) : leftEyeColor;

                co.col = rightEye < 0 && rightEyeLength > 0.1 ? rightEyeColor : co.col;
                co.col = leftEye < 0 && leftEyeLength > 0.1 ? leftEyeColor : co.col;

                //eyes lid
                Surface leftEyeLid = sdBox(p, float3(0.3,lerp(0.15,0.30,sin(_Time.y/2)),0.02), mCol,float3(0.38,lerp(-0.3,-0.15,sin(_Time.y/2)),0.76),rotateY(-0.3));
                leftEyeLid.sd = opIntersection(leftEyeLid.sd,head.sd);
                co = minWithColor(co, leftEyeLid);
                Surface rightEyeLid = sdBox(p, float3(0.3,lerp(0.15,0.30,sin(_Time.y/2)),0.02), mCol,float3(-0.38,lerp(-0.3,-0.15,sin(_Time.y/2)),0.76),rotateY(0.3));
                rightEyeLid.sd = opIntersection(rightEyeLid.sd,head.sd);
                co = minWithColor(co, rightEyeLid);

                //nose
                Surface nose;
                float noseSD = udTriangle(p,float3(-0.025, 0.05, sqrt(1-dot(float2(-0.025, 0.05),float2(-0.025, 0.05)))),
                float3(0.025, 0.05, sqrt(1.1-dot(float2(0.025, 0.05),float2(0.025, 0.05)))),
                float3(0 , 0.075,sqrt( 1.11-dot(float2(0.0, 0.075),float2(0,  0.075)))));
                // float noseP2 = udTriangle(p,float3(-0.05, 0.1, sqrt(1.1-dot(float2(-0.05, 0.1),float2(-0.05, 0.1)))),
                // float3(0.05,0.1,sqrt( 1.1-dot(float2(0.05, 0.1),float2(0.05, 0.1)))),
                // float3(0 , 0.06, sqrt(1.1-dot(float2(0, 0.06),float2(0, 0.06)))));
                nose.sd = noseSD;//opUnion(noseP1, noseP2);
                nose.col = float3(0,0,0);
                co = opSmoothUnion(co, nose,0.08);

                //beard & border
                //float border = head.sd < 0.001f ? 1-(1-step(((p.x + p.y / 2.8) - 0.8),0.06) + step(((p.x + p.y / 2.8) - 0.8),0.02)) : 0;
                float borderR = head.sd < 0.001f ? smoothstep(0.1,0.2, (sign(p.x + p.y / 8 - 0.7) * frac(p.x + p.y / 8 - 0.7) ) ) : 0;
                float borderL = head.sd < 0.001f ? smoothstep(0.1,0.2, (sign(-p.x + p.y / 8- 0.7) * frac(-p.x + p.y / 8- 0.7) ) ) : 0;
                float border = (1-abs((borderR - 0.5) * 2))/1.5 + (1-abs((borderL - 0.5) * 2))/1.5;
                co.col = border > 0.5 ? float3(0,0.894,1) : border > 0 ? co.col + border * float3(0,0.894,1) : co.col;

                float leash =  step(((p.y * 2) - 1.4),0) - step(((p.y * 2) - 1.7),0);
                co.col = leash  ?  float3(0.768,0.188,0.105) : co.col;
                float leashB = step(((p.y * 2) - 1.72),0) - step(((p.y * 2) - 1.77),0);
                 co.col = leashB  ?  float3(0,0.894,1) : co.col;

                return co;
            }
      
            float3 calcNormal(in float3 p) {
                float2 e = float2(1.0, -1.0) * 1e-3; // epsilon
                return normalize(
                e.xyy * sdScene(p + e.xyy).sd +
                e.yyx * sdScene(p + e.yyx).sd +
                e.yxy * sdScene(p + e.yxy).sd +
                e.xxx * sdScene(p + e.xxx).sd);
            }

            #define time _Time.y
            #define w _ScreenParams.x
            #define h _ScreenParams.y

            half3 PixelColor(float2 uv)
            {
                half3 c;
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                float Max_DIST = 100.0;

                c = float3(0.235, 0.235, 0.235); //background
                uv = float2(uv.x-0.5f, (uv.y-0.5f)*(h/w));
                float3 ro = float3(0,0,5);
                half3 rd = normalize(half3(uv,-1));
                // float3 ro = float3(5,0,0);
                // half3 rd = normalize(half3(-1,uv.y,uv.x));
                float depth = 0;
                Surface co;
                for(int i = 0; i < 255; i++)
                {
                    float3 p = ro+depth*rd;
                    //p = mul(rotateY(time),p);
                    co = sdScene(p);
                    depth += co.sd;
                    if (co.sd < 0.001f) break;
                    if (depth > Max_DIST){ return c;}
                }
                float3 p = ro + rd * depth;
                //p = mul(rotateY(time),p);
                half3 normal = calcNormal(p);
                float3 light_position =  float3(-1,1,-1);
                half3 light_direction = normalize(p - light_position);
                half3 dif = saturate(dot(normal, light_direction));
                dif = saturate((dif-0.05) * 10);
                half3 final_color = co.col * dif; 
                c = final_color;
                //---
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
