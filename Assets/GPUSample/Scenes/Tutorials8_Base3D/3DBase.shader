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

            float2x2 rotate(float a)
            {
                float c = cos(a), s = sin(a);
                return float2x2(c,s,-s,c);
            }
            float3x3 rotate(float3 n, float a)
            {
                float s = sin(a), c = cos(a), k = 1.0 - c;
                
                return float3x3(n.x*n.x*k + c    , n.y*n.x*k - s*n.z, n.z*n.x*k + s*n.y,
                                n.x*n.y*k + s*n.z, n.y*n.y*k + c    , n.z*n.y*k - s*n.x,
                                n.x*n.z*k - s*n.y, n.y*n.z*k + s*n.x, n.z*n.z*k + c    );
            }
            //定义摄像机相关属性
            float3 getLookTarget()
            {
                return float3(0.0, 1.0, 0.0);
            }
            float3 getCameraPos()
            {
                //return float3(0.0, 1.0, -5.0);
                return float3(6.0f*cos(0.5*time), 1.0, 6.0f*sin(0.5*time));
            }
            float getDefaultCamerRoll()
            {
                return 0.0;
            }
            float3x3 getCameraWorldMat( float3 camPos, float3 lookTarget, float cr )
            {
	            float3 cw = normalize(lookTarget - camPos);
	            float3 cp = float3(sin(cr), cos(cr), 0.0);
	            float3 cu = normalize(cross(cw, cp));
	            float3 cv = normalize(cross(cu, cw));
                return float3x3(cu, cv, cw);
            }
            //
            
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
            // 圆环sdf
            float sdTorus( float3 p, float2 t )
            {
                float2 q = float2(length(p.xz)-t.x,p.y);
                return length(q)-t.y;
            }
            // 圆锥sdf
            float sdCone( float3 p, float2 c, float h )
            {
                // c is the sin/cos of the angle, h is height
                // Alternatively pass q instead of (c,h),
                // which is the point at the base in 2D
                float2 q = h*float2(c.x/c.y,-1.0);

                float2 w = float2( length(p.xz), p.y );
                float2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
                float2 b = w - q*float2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
                float k = sign( q.y );
                float d = min(dot( a, a ),dot(b, b));
                float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
                return sqrt(d)*sign(s);
            }
            // 圆角盒sdf
            float sdRoundBox( float3 p, float3 b, float r )
            {
                float3 q = abs(p) - b;
                return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
            }
            
            // scene sdf
            float sdScene(float3 p)
            {
                //定义球体
                float3 spherePos = float3(1.5, 1.0, 0.0);
                float sphereRadius = 1.0;
                float3 sphereNormal = normalize( p - spherePos );
                //定义圆角盒
                float3 boxPos = float3(-1.5, 0.5, 0.0);
                float3 boxSize = float3(1.0, 0.5, 0.5);
                float boxRadius = 0.1;
                //定义圆环
                float3 torusPos = float3(5.0, 1.0, 0.0);
                float2 torusRadius = float2(0.8, 0.3);
                //定义圆锥
                float3 conePos = float3(-5.0, 2.0, 0.0);
                float2 coneRadius = float2(0.1, 0.3);
                float coneHeight = 2.0;
                //定义平面
                float3 planePos = float3(0.0, 0.0, 0.0);
                float3 planeNormal = float3(0.0, 1.0, 0.0);
                //求交集
                float sphereDist = sdSphere(p - spherePos, sphereRadius);
                float torusDist = sdTorus(p - torusPos, torusRadius);
                float coneDist = sdCone(p - conePos, coneRadius, coneHeight);
                float planeDist = sdPlane(p - planePos, planeNormal, 0.0);
                float boxDist = sdRoundBox(p - boxPos, boxSize, boxRadius);
                return min(min(min(min(sphereDist, boxDist),coneDist),torusDist),planeDist);
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

            //通过中心差异的到的比较精确的值
            float3 GetNormal1(float3 p)
            {
                float2 e = float2(EPSILON,0.0);
                float fdx = sdScene(p+e.xyy) - sdScene(p-e.xyy);
                float fdy = sdScene(p+e.yxy) - sdScene(p-e.yxy);
                float fdz = sdScene(p+e.yyx) - sdScene(p-e.yyx);
                return normalize(float3(fdx,fdy,fdz));
            }
            
            //利用前向微分
            float3 GetNormal2(float3 p)
            {
                float d = sdScene(p);
                float2 e = float2(EPSILON,0.0);
                float fdx = sdScene(p+e.xyy) - d;
                float fdy = sdScene(p+e.yxy) - d;
                float fdz = sdScene(p+e.yyx) - d;
                return normalize(float3(fdx,fdy,fdz));
            }
            
            //Paulo Falcao的四面体技术优化
            float3 GetNormal3(float3 p)
            {
                float2 k = float2(1, -1);
                return normalize(k.xyy*sdScene(p+k.xyy*EPSILON)
                    + k.yxy*sdScene(p+k.yxy*EPSILON)
                    + k.yyx*sdScene(p+k.yyx*EPSILON)
                    + k.xxx*sdScene(p+k.xxx*EPSILON));
            }
            // Lambert光照模型
            float3 Lambert(float3 lightDir, float3 normal, float3 lightColor, float3 diffuseColor)
            {
                return lightColor * diffuseColor * max(0.0, dot(normal, lightDir));
            }
            // HalfLambert光照模型
            float3 HalfLambert(float3 lightDir, float3 normal, float3 lightColor, float3 diffuseColor)
            {
                return lightColor * diffuseColor * max(0.0, dot(normal, lightDir)*0.5 + 0.5);
            }
            // Phong光照模型
            float3 Phong(float3 lightDir, float3 normal, float3 viewDir, float shininess, float3 lightColor, float3 specularColor)
            {
                float3 reflectDir = reflect(-lightDir, normal);
                return lightColor * specularColor * pow(max(0.0, dot(reflectDir, viewDir)), shininess);
            }
            // BlinnPhong光照模型
            float3 BlinnPhong(float3 lightDir, float3 normal, float3 viewDir, float shininess, float3 lightColor, float3 specularColor)
            {
                float3 halfDir = normalize(lightDir + viewDir);
                return lightColor * specularColor * pow(max(0.0, dot(normal, halfDir)), shininess);
            }

            //硬阴影
            float hardShadow( float3 ro, float3 rd )
            {
                float t = MIN_DIST;
                for( int i=0; i<MAX_MARCHING_STEPS && t<MAX_DIST; i++ )
                {
                    float h = sdScene(ro + rd*t);
                    if( h<EPSILON )
                        return 0.0;
                    t += h;
                }
                return 1.0;
            }

            //软阴影
            float softshadow( float3 ro, float3 rd, float k )
            {
                float res = 1.0;
                float t = MIN_DIST;
                for( int i=0; i<MAX_MARCHING_STEPS && t<MAX_DIST; i++ )
                {
                    float h = sdScene(ro + rd*t);
                    if( h < EPSILON )
                        return 0.0;
                    res = min( res, k*h/t );
                    t += h;
                }
                return res;
            }

            float softshadowImprove( float3 ro, float3 rd, float w )
            {
                float res = 1.0;
                float ph = 1e20;
                float t = MIN_DIST;
                for( int i=0; i<MAX_MARCHING_STEPS && t<MAX_DIST; i++ )
                {
                    float h = sdScene(ro + rd*t);
                    if( h<EPSILON )
                        return 0.0;
                    float y = h*h/(2.0*ph);
                    float d = sqrt(h*h-y*y);
                    res = min( res, d/(w*max(0.0,t-y)) );
                    ph = h;
                    t += h;
                }
                return res;
            }
            
            float calculateAO( float3 p, float3 n )
            {
	            float occ = 0.0;
                float scale = 0.5;
                float k = 5.0;
                float step = 0.05;
                for( int i=1; i<=5; i++ )
                {
                    float distDelta = step*i;
                    float distField = sdScene( p + distDelta*n ); 
                    occ += (distDelta-distField)*scale;
                    scale *= 0.5;
                    if(occ > 0.2)
                        break;
                }
                return clamp( (1.0 - k*occ), 0.0, 1.0 );
            }

            //SSAO
            /*#define SAMPLENUM 16
            #define INTENSITY 1.1
            #define BIAS 0.05
            float3 random(float2 uv)
            {
                half2 iUV = floor(uv);
                float3 rand;
                rand.r = frac(sin(dot(iUV.xy,float2(12.9898,78.233)))*43758.5453123);
                rand.b = frac(sin(dot(iUV.xy,float2(46.7615,197.334)))*43758.5453123);
                rand.g = frac(sin(dot(iUV.xy,float2(78.8831,123.6512)))*43758.5453123);
                return rand;
            }
            float3 getPosition(float2 uv)
            {
                float3 camPos = getCameraPos();
                float3 lookTarget = getLookTarget();
                float roll = getDefaultCamerRoll();
                float3x3 camWorldMat = getCameraWorldMat(camPos, lookTarget, roll);
	            float3 localViewDir = normalize( float3(uv,1.0) );
                float3 rayDir = mul(camWorldMat, localViewDir);
	            float dist = RayMarch(camPos, rayDir);
                return camPos + rayDir*dist;//dist/MAX_DIST;
            }
            float calculateSSAO( float2 uv, float3 normal, float depth)
            {
                float3 p = getPosition(uv);
                float radius = 0.001;
                float scale = radius / depth;
                float ao = 0.0;
                for(int i = 0; i < SAMPLENUM; i++)
                {
                    float2 randUv = uv*_ScreenParams + (23.71 * float(i));
                    float3 randNor = random(randUv) * 2.0 - 1.0;
                    if(dot(normal, randNor) < 0.0)
                        randNor *= -1.0;
                    
                    float2 offset = randNor.xy * scale;
                    float3 samplePoint = getPosition(uv + offset);
                    float3 diff = normalize(samplePoint - p);
                    float occ = INTENSITY * max(0.0, dot(normalize(normal), normalize(diff)) - BIAS) / (length(diff) + 1.0);
                    ao += 1.0 - occ;
                } 
                ao /= float(SAMPLENUM);
                return ao;
            }*/

            //简化版SSAO
            #define INTENSITY 1.1
            #define SCALE 2.5
            #define BIAS 0.05
            #define SAMPLE_RADIUS 0.03
            //#define DIS_CONSTRAINT 1.2
            float2 getRandom(float2 uv)
            {
                half2 iUV = floor(uv);
                float2 rand;
                rand.x = frac(sin(dot(iUV.xy,float2(12.9898,78.233)))*43758.5453123);
                rand.y = frac(sin(dot(iUV.xy,float2(46.7615,197.334)))*43758.5453123);
                return normalize(rand*2.0 -1.0);
            }
            float3 getPosition(float2 uv) 
            {
                float3 camPos = getCameraPos();
                float3 lookTarget = getLookTarget();
                float roll = getDefaultCamerRoll();
                float3x3 camWorldMat = getCameraWorldMat(camPos, lookTarget, roll);
	            float3 localViewDir = normalize( float3(uv,1.0) );
                float3 rayDir = mul(camWorldMat, localViewDir);
	            float dist = RayMarch(camPos, rayDir);
                return camPos + rayDir * dist;
            }
            float doAmbientOcclusion(float2 uv, float2 offset, float3 p, float3 n)
            {
                 float3 diff = getPosition(offset + uv) - p;
                 float3 v = normalize(diff);
                 float d = length(v) * SCALE;
                 float ao = max(0.0, dot(n, v) - BIAS) * (1.0 / (1.0 + d)) * INTENSITY;
                 //float l = length(diff);
                 //ao *= smoothstep(DIS_CONSTRAINT, DIS_CONSTRAINT * 0.5, l);
                 return ao;
            }
            float calculateSSAO(float2 uv, float3 normal, float depth)
            {
                const float2 dire[4] = { float2(1, 0), float2(-1, 0), float2(0, 1), float2(0,-1) };
                float3 p = getPosition(uv);
                float3 n = normal;
                float2 rand = getRandom(uv);
                
                float ssao = 0.0;
                int iterations = 4;
                for(int i = 0; i < iterations; i++)
                {
                    float2 coord1 = reflect(dire[i], rand) * SAMPLE_RADIUS;
                    float2 coord2 = float2(coord1.x * cos(radians(45.0)) - coord1.y * sin(radians(45.0)), 
                                       coord1.x * cos(radians(45.0)) + coord1.y * sin(radians(45.0)));
                                       
                    ssao += doAmbientOcclusion(uv, coord1 * 0.25, p, n);
                    ssao += doAmbientOcclusion(uv, coord2 * 0.5, p, n);
                    ssao += doAmbientOcclusion(uv, coord1 * 0.75, p, n);
                    ssao += doAmbientOcclusion(uv, coord2, p, n);
                }
                ssao = ssao / (float(iterations)*2.0);
                ssao = 1.0 - ssao * INTENSITY;
                return ssao;
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
                float3 camPos = getCameraPos();
                float3 lookTarget = getLookTarget();
                float3 roll = getDefaultCamerRoll();
	            float3 localViewDir = normalize( float3(uv,1.0) );
                
                float3x3 camWorldMat = getCameraWorldMat(camPos, lookTarget, roll);
                float3 rayDir = mul(camWorldMat, localViewDir);
                
	            float dist = RayMarch(camPos, rayDir);
                c = half3(dist/MAX_DIST, dist/MAX_DIST, dist/MAX_DIST);
                
                if(dist<MAX_DIST)
                {
                    float3 p = camPos+rayDir*dist;
                    float3 lightPos = float3(3.0,5.0,-5.0);
                    float3 lightdirI = normalize(lightPos-p);
                    float3 n = GetNormal3(p);
                    
                    float3 matColor = float3(0.5, 0.5, 0.5); 
                    float3 lightColor = float3(1.0, 1.0, 1.0);
                    float3 ambient = float3(0.2, 0.2, 0.2);
                    float3 diffuse = Lambert(lightdirI, n, lightColor, matColor);
                    float3 specular = BlinnPhong(lightdirI, n, -rayDir, 32.0, lightColor, matColor);

                    //计算硬阴影
                    //diffuse *= hardShadow(p,lightdir);
                    //计算软阴影
                    //diffuse *= softshadow(p, lightdir, 8.0);
                    //计算改进软阴影
                    diffuse *= softshadowImprove(p, lightdirI, 0.05f);
                    //计算AO
                    ambient *= calculateAO(p, n);
                    //计算SSAO
                    //ambient *= calculateSSAO(uv, n, dist/MAX_DIST);
                    c+= ambient + diffuse + specular;

                    //Debug AO
                    //c = calculateSSAO(uv, n, dist/MAX_DIST);
                    //c = normalize(getPosition(uv));
                }
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
