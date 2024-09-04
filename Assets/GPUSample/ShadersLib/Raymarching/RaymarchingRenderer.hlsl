#ifndef RAYMARCHING_RENDERER_INCLUDED
#define RAYMARCHING_RENDERER_INCLUDED

#include "RaymarchingUtils.hlsl"
#include "../Lightings/LightingUtils.hlsl"
#include "../Shadows/ShadowUtils.hlsl"

//设置相机矩阵
float3x3 getCameraWorldMatrix(float3 origin, float3 target, float rotation )
{
    float3 forward = normalize(target - origin);
    float3 orientation = float3(sin(rotation), cos(rotation), 0.0);
    float3 left = normalize(cross(forward, orientation));
    float3 up = normalize(cross(left, forward));
    return float3x3( left, up, forward );
}

RaymarchingParams initRaymarching(float2 uv, float2 resolution, float3 camPos, float3 camTarget, float camRoll, float3 lightPos, float3 bgColor)
{
    //四象限转一象限
    uv.y = 1.0- uv.y;
    //转全象限
    uv = (uv*2.0 -1.0);
    //消除屏幕拉伸影响
    float co = resolution.x/resolution.y;
    uv = float2(uv.x*co, uv.y);
    
    RaymarchingParams params = (RaymarchingParams)0;
    params.bgColor = bgColor;
    params.camPos = camPos;
    params.camTarget = camTarget;
    params.camRoll = 0;
    params.lightPos = lightPos;
    float3x3 camWorldMat = getCameraWorldMatrix(params.camPos, params.camTarget, params.camRoll);
    params.rayDir = mul(normalize(float3(uv.x, uv.y, 1.0)), camWorldMat);
    float2 px = float2(1.0*co/resolution.x, 0.0);
    float2 py = float2(0.0, 1.0/resolution.y);
    const float fl = 2.5;
    params.raydx = mul(camWorldMat, normalize( float3(px,fl)));
    params.raydy = mul(camWorldMat, normalize( float3(py,fl)));

    return params;
}

//渲染场景
half3 render( RaymarchingParams params, float time )
{
    half3 color = params.bgColor - max(params.rayDir.y,0.0)*0.72;   //skyColor
    float4 hit = RayMarching(params.camPos, params.rayDir);
    float dist = hit.x;
    float materialIndex = hit.y;
    
    if(materialIndex > 0)
    {
        float3 position = params.camPos + dist*params.rayDir;
        float3 normal = GetNormal(position);
        half3 lightColor = half3(0.98, 0.92, 0.89);
        //float3 lightDirI = normalize(params.lightPos - position);
        float3 lightDirI = normalize(float3(0.6, 0.7, -0.7));
        half lightIntensity = 2.0f;
        half indirectLightIntensity = 0.64f;
        Material material = GetMaterial(materialIndex, position);
        half shadow = softshadowImprove(position, lightDirI, 0.05f);
        
        half3 diffuseAndSpecular = calculateLighting(position, lightDirI, normal, -params.rayDir, lightColor, lightIntensity, indirectLightIntensity,shadow, material, params.bgColor);
        float depth01 = 1 - clamp(dist / MAX_DIST, 0, 1);
        color = lerp(color, diffuseAndSpecular, depth01);
    }
    // Tone mapping
    color = Tonemap_ACES(color);
    
    // Exponential distance fog
    color = lerp(color, 0.8 * half3(0.7, 0.8, 1.0), 1.0 - exp2(-0.0011 * dist * dist));

    // Gamma compression
    color = OECF_sRGBFast(color);
    
    return color;
}

#endif
