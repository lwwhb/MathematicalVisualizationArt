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
                float k = 3.0;
                float step = 0.03;
                for( int i=1; i<=5; i++ )
                {
                    float distDelta = step*i;
                    float distField = sdScene( p + distDelta*n ); 
                    occ += (distDelta-distField)*scale;
                }
                return clamp( (1.0 - k*occ), 0.0, 1.0 );
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
	            float3 rayDir = normalize( float3(uv,1.0) );
                
	            float dist = RayMarch(camPos, rayDir);
                c = half3(dist/MAX_DIST, dist/MAX_DIST, dist/MAX_DIST);
                
                if(dist<MAX_DIST)
                {
                    float3 p = camPos+rayDir*dist;
                    float3 lightPos = float3(3.0,5.0,-5.0);
                    float3 lightdir = normalize(lightPos-p);
                    float3 n = GetNormal3(p);
                    
                    float3 matColor = float3(0.5, 0.5, 0.5); 
                    float3 lightColor = float3(1.0, 1.0, 1.0);
                    float3 ambient = float3(0.2, 0.2, 0.2);
                    float3 diffuse = Lambert(lightdir, n, lightColor, matColor);
                    float3 specular = BlinnPhong(lightdir, n, -rayDir, 32.0, lightColor, matColor);

                    //计算硬阴影
                    //diffuse *= hardShadow(p,lightdir);
                    //计算软阴影
                    //diffuse *= softshadow(p, lightdir, 8.0);
                    //计算改进软阴影
                    diffuse *= softshadowImprove(p, lightdir, 0.05f);
                    //计算AO
                    ambient *= calculateAO(p, n);
                    c+= ambient + diffuse + specular;
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
