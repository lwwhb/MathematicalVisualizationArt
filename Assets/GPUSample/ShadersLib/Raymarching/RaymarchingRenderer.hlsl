#ifndef RAYMARCHING_RENDERER_INCLUDED
#define RAYMARCHING_RENDERER_INCLUDED

#include "../SDFScenes/SDFScene.hlsl"

#define MAX_MARCHING_STEPS 100
#define MIN_DIST  0.01
#define MAX_DIST  100.0
#define EPSILON  0.0001

struct RaymarchingParams
{
    float3 bgColor;         //背景颜色
    float3 camPos;          //相机位置
    float3 camTarget;       //相机目标点
    float  camRoll;         //相机横滚角
    float3 rayDir;          //射线方向
    float3 raydx;           //射线方向x方向的微分
    float3 raydy;           //射线方向y方向的微分
};
//设置相机矩阵
float3x3 getCameraWorldMatrix(float3 ro, float3 ta, float cr )
{
    float3 cw = normalize(ta-ro);
    float3 cp = float3(sin(cr), cos(cr),0.0);
    float3 cu = normalize( cross(cw,cp) );
    float3 cv = normalize( cross(cu,cw) );
    return float3x3( cu, cv, cw );
}

RaymarchingParams initRaymarching(float2 uv, float2 resolution, float3 camPos, float3 camTarget, float camRoll, float3 bgColor)
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
    float3x3 camWorldMat = getCameraWorldMatrix(params.camPos, params.camTarget, params.camRoll);
    params.rayDir = mul(camWorldMat, normalize(float3(uv.x, uv.y, 1.0)));
    float2 px = float2(1.0*co/resolution.x, 0.0);
    float2 py = float2(0.0, 1.0/resolution.y);
    const float fl = 2.5;
    params.raydx = mul(camWorldMat, normalize( float3(px,fl)));
    params.raydy = mul(camWorldMat, normalize( float3(py,fl)));

    return params;
}

// RayMarch, 用于计算光线与物体的交点
float4 RayMarching(float3 ro, float3 rd, float time)
{
    float4 result = float4(0.0, 0.0, 0.0, 0.0);
    float dist = 0.0;
    for(int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float3 pos = ro + rd*dist;
        float step = sdfScene(pos, time);
        if(dist > MAX_DIST || step < MIN_DIST)
        {
            result = dist;
            break;
        }
        dist += step;
    }
    return result;     
}

//渲染场景
float3 render( float3 ro, float3 rd, float3 rdx, float3 rdy, float3 bgColor, float time )
{
    float3 color = bgColor - max(rd.y,0.0)*0.6;
    float dist = RayMarching(ro, rd, time).x;
    float depth01 = 1 - clamp(dist / MAX_DIST, 0, 1);
    half3 depthColor = half3(depth01, depth01, depth01);
    return lerp(color, depthColor, depth01);
}

#endif
