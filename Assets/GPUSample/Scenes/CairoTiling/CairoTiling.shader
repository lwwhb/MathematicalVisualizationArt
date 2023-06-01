Shader "MathematicalVisualizationArt/CairoTiling"
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
            
            half mod(half x, half y)
            {
              return x - y * floor(x/y);
            }
            half Hash21(half2 p)
            {
                p = frac(p*half2(123.234,234.34));
                p += dot(p,p+213.42);
                return frac(p.x*p.y);
            }
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                uv.y = 1 -uv.y;
                uv = uv - 0.5;
                uv *= 5.1;
                half pos = (sin(time)/2+1)/2;
                half2 id = floor(uv);
                //https://stackoverflow.com/questions/7610631/glsl-mod-vs-hlsl-fmod
                float check = mod(id.x + id.y,2.0); //0 或者 1
                //创建网格
                uv = frac(uv) -0.5;
                half2 p = abs(uv);
                if(check ==1.0) p = p.yx; 
                //将_pos映射到0.5~1
                half a = (pos*0.5+0.5) *PI;
                half2 n = half2(sin(a),cos(a));
                //p-0.5映射旋转点为右上角
                half d = dot(p-0.5,n);
                //这里确定id的方向来随机颜色
                //因为check会翻转p
                if(d * (check-0.5) <0.0){
                    id.x += sign(uv.x)*0.5;
                }else{
                    id.y += sign(uv.y)*0.5;
                }
                //根据距离比较 获取竖线
                d = min(d,p.x);
                 //根据距离比较 获取横线
                d = max(d,-p.y);
                d = abs(d);
                //根据相邻边计算方向,由于线旋转90度
                d = min(d,dot(p-0.5,half2(n.y,-n.x)));
                c += d;
                c *=1.0 + sin( Hash21(id)*2*PI+time);
                c += smoothstep(fwidth(d),0,d-0.005);//划线
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
