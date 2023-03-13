Shader "MathematicalVisualizationArt/DrunkingWanderingMovingAboveCity"
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

            //Origin from http://www.jaharrison.me.uk/Brickwork/Sizes.html
            float3 brickTile(float2 _st, float x_zoom,float y_zoom){
                _st.x *= x_zoom;
                _st.y *= y_zoom;
                float id = floor(_st.x);
                // Here is where the offset is happening todo:要保证每一块砖头都是不一样的id
                _st.y = _st.y >= 0 ? _st.y : _st.y - 1.0f;
                _st.x += step(1., fmod(abs(_st.y),2.0)) * 0.5;
                return float3(frac(_st),id);
            }

            float3 tile(float2 _st, float x_zoom,float y_zoom){
                _st.x *= x_zoom;
                _st.y *= y_zoom;
                float id = floor(_st.x);
                return float3(frac(_st),id);
            }


            float box(half2 _st, half2 _size){
                float noise = frac(sin(780.2 * _st.x)*250.3) * 6.2831;
                _size = 0.5-_size*0.5;
                half2 uv = smoothstep(_size,_size+1e-4,_st);
                uv *= smoothstep(_size,_size+1e-4,1.0-_st);
                return uv.x*uv.y * noise;
            }

            float marble(half2 _st, half2 _size, half2 random){
                half2 uv = half2(1,1);
                float r = 0.;
                for(uint i = 0;i < 20;i++){
                    float angle = frac(sin(330.2 * i)*350.3) * 6.2831;
                    float displacement = lerp(0.2,0.4,frac(sin(722.2 * i)*720.2));
                    half2x2 ro = half2x2(cos(angle),-sin(angle),sin(angle),cos(angle)); 
                    half2 _st1 = mul(ro,_st);
                    r += frac(1-smoothstep(displacement,displacement-0.05,_st1.y));
                }
                _size = 0.5-_size*0.5;
                uv.y = smoothstep(_size,lerp(_size,_size+0.05,sin(_st.x*20*sin(random.y+0.5))*1+1),_st.y);
                uv.y *= smoothstep(_size,lerp(_size,_size+0.05,sin(_st.x*20*cos(random.y+0.5))*1+1),1.0-_st.y);
                _size = _size * 0.2;
                uv.x = smoothstep(_size,lerp(_size,_size+0.05,sin(_st.y*6*pow(random.y,2))*0.3+0.3),abs(_st.x-0.5));
               
                return step(1,uv.x*uv.y - r);
            }

            float fense(half2 _st, half2 _size, half2 random){
                half2 uv = half2(1,1);
                float r = 0.;
                //float2 chain_angle[2] = {float2(sin(_Time.y),cos(_Time.y)),float2(sin(_Time.y),-cos(_Time.y))};
                float2 chain_angle[2] = {float2(0.5,0.5),float2(0.5,-0.5)};
                for(int i = 0;i < 2;i++){
                    half chain = dot(_st - 0.5f,normalize(chain_angle[i]));
                    r += (1 - smoothstep(0.0,0.05,abs(chain)));
                }
                return  r;
            }

            
            float door(half2 _st){
                _st = _st * 2;
                half2 streak = smoothstep(0.1,0.1+0.01,frac(abs(_st.x)));
                streak *= smoothstep(0.1,0.1+0.01,frac(abs(_st.y)));
                streak *= smoothstep(0.1,0.1+0.01,frac(-abs(_st.x)));
                streak *= smoothstep(0.1,0.1+0.01,frac(-abs(_st.y)));
                return streak.x * streak.y ;
            }

            #define time _Time.y
            #define w _ScreenParams.x
            #define h _ScreenParams.y
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0., 0., 0.);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                c = half3(0., 0., 0.);
                half2 uv1 = half2(uv.x-0.5f, (uv.y-0.5f) * (h / w));
                // 弃用原有方法 切割场景 使用polar coodinate重写
                // half degree = uv1.x > 0 ? 0.1 : -0.1;
                // half2x2 ro = float2x2(cos(degree),-sin(degree),sin(degree),cos(degree));
                // half2 uv2 = mul(ro,uv1);
                // uv2.x *= 0.8;
                // half far_landscape = step(max(abs(uv1.x),abs(uv1.y * 1.08 +0.055)),0.1);
                // half wall_left = step(abs(uv2.y) + uv2.x + step(abs(uv1.x),0.06),0.);
                // half wall_right = step(abs(uv2.y) - uv2.x + step(abs(uv1.x),0.06),0.);
                // half ground = 1-wall_left-wall_right-far_landscape;
                // ground = step(1.,ground-step(uv1.y,0.));
                // half sky = step(1.,1-ground);

                half2 polar_coordinate = half2(atan2(uv1.x,uv1.y)/3.1415926,length(uv)); //-1~1
                //polar_coordinate.x =  frac((polar_coordinate.x + 0.125) * 4);
                half wall = abs(polar_coordinate.x) <= 0.74f && abs(polar_coordinate.x) >= 0.35f ? 1 : 0;
                half wall_line = abs(polar_coordinate.x) <= 0.75f && abs(polar_coordinate.x) >= 0.74f ? 1 : 0;
                
                // half wall_right_top = polar_coordinate.x <= 0.74f && polar_coordinate.x >= 0.45f ? 1 : 0;
                // half wall_right_bottom = polar_coordinate.x <= 0.45f && polar_coordinate.x >= 0.35f ? 1 : 0;
                half far_landscape = step(max(abs(uv1.x),abs(uv1.y * 1.08 +0.055)),0.1);
                half ground = polar_coordinate.x > -0.345 && polar_coordinate.x < 0.345 ? 1 : 0;
                half ground_line = abs(polar_coordinate.x) < 0.35 && abs(polar_coordinate.x) > 0.345 ? 1 : 0;
                half sky = polar_coordinate.x <= -0.75f || polar_coordinate.x >= 0.75f ? 1 : 0;

                half2 ground_tile = uv;
                //ground_tile.x = pow(pow(abs(uv1.x),0.5) + pow(abs(1-uv1.y),0.8),2);
                //ground_tile.x += (1-ground_tile.y)*lerp(-2.,2.,ground_tile.x) * 0.5;
                ground_tile.x = dot(normalize(uv1), float2(lerp(0.1,-0.1,sin(time)),1.)) * 0.99;
                ground_tile.y *= lerp(2,0,uv1.y) + 1.7;
                ground_tile.y -= time * 0.1; //奔跑效果
                ground_tile = brickTile(ground_tile,9.0,20.0).xy;
                float ground_tile_id = brickTile(ground_tile,9.0,20.0).z;
                //ground_tile.x = pow(ground_tile.x,2);

                // half2 wall_tile = uv;
                // wall_tile.y = dot(normalize(uv1), float2(0.,1.));
                // wall_tile.x *= lerp(2,0,uv1.x) + 1.7;
                // wall_tile.x -= time * 0.1;
                // wall_tile = brickTile(wall_tile,10.0,10.0).xy;
                // wall_tile.y *= 0.7f;

                half2 fense_tile = uv;
                fense_tile.y = dot(normalize(uv1), float2(0.,1.));
                fense_tile.x *= lerp(2,0,uv1.x) + 1.7;
                fense_tile.x += uv1.x > 0 ? -time * 0.1 : time * 0.1;
                fense_tile = tile(fense_tile,10.0,10.0).xy;

                
                half3 tower_tile = half3(0,uv1.x,uv1.y);
                tower_tile.z += (tower_tile.y > 0 ? sin(time * 10) * 0.05 : cos(time * 10) * 0.05);
                half cross = tower_tile.y > 0 ? 0.5 : 1;
                
                tower_tile.x = dot(normalize(tower_tile.yz) , float2(0.,1.)) * 0.99;
                float motionTime = time;
                half tower = 0;
                for(int i = 1; i < 5 ;i++){
                    motionTime += i;
                    motionTime = motionTime * i;
                    //大厦的侧面
                    tower += frac(motionTime * 0.1) * 0.4 * cross < abs(tower_tile.y) 
                    && abs(tower_tile.y) < frac(motionTime  * 0.1) * 0.5 * cross
                    && abs(tower_tile.x) < 0.9 && tower_tile.x < 100 ? 1 : 0;
                    
                    //大厦的正面
                    tower += abs(tower_tile.y) < frac(motionTime  * 0.1) * 0.8 * cross
                    && abs(tower_tile.y) > frac(motionTime  * 0.1) * 0.5 * cross
                    && tower_tile.z < 100 && abs(tower_tile.z) < frac(motionTime * 0.1) * 1.1 * cross ? 1 : 0;
                }

                // half door = frac(time * 0.1)*(0.5+0.1) < abs(tower_tile.y)
                //     && abs(tower_tile.y) < frac((time + 2)* 0.1)*(0.5+0.1)
                //     && abs(tower_tile.x) < 0.9 && tower_tile.x < 100 ? 1 : 0;

                half3 door_tile = half3(uv,0);
                door_tile.y = dot(normalize(uv1), float2(0.,1.));
                door_tile.x *= lerp(1,0,uv1.x) + 1.7;
                door_tile.x -= time * 0.1;
                door_tile = tile(door_tile,5.0,1.0);
                
                //todo: https://www.shadertoy.com/view/Wd3BRN cloud
                //todo: weight property 权重控制
               
                c =  wall * fense(fense_tile, 0.94, uv*length(uv)-0.4f);
                // float wall_right_top_c = wall_right_top.x * marble(wall_tile, 0.94, uv*length(uv)-0.4f);
                // c = c + wall_right_top_c;
                c += wall_line;
                c = c < 1 ? c + (tower * sky + tower * wall + tower * wall_line) * float3(uv1.x, 0, uv1.y) : c;
                c += ground * step(box(ground_tile,0.94),1) * float3(uv1.x,0, uv1.y) * 2;
                c += ground * step(1,box(ground_tile,0.94));
                c += ground_line;
                // c = (step(1., door(door_tile.xy) * fmod(abs(door_tile.z),2.0)) * wall_right_bottom) * float3(uv1.x,0,uv1.y)
                //  - step(1., door(door_tile.xy) *fmod(abs(door_tile.z),2.0)) * wall_right_top  * float3(uv1.x,0,uv1.y);
                // c = c + fmod(abs(door_tile.z),2.0) * wall_right_top * door(door_tile.xy) * float3(1,0,1) - fmod(abs(door_tile.z),2.0) * wall_right_top_c;
                // c = c - (step(1., door(door_tile.xy) * fmod(abs(door_tile.z),2.0)) * wall_right_bottom) * float3(1,0,1);
                //c = step(1., fmod(abs(door_tile.z),2.0));
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
