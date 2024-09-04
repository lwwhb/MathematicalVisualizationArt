#ifndef RAYMARCHING_UTILS_INCLUDED
#define RAYMARCHING_UTILS_INCLUDED

#include "../Utilities/Utilities.hlsl"

#define MAX_MARCHING_STEPS 200
#define MIN_DIST  0.001
#define MAX_DIST  50.0
#define EPSILON  0.0001

struct RaymarchingParams
{
    float3 bgColor;         //背景颜色
    float3 camPos;          //相机位置
    float3 camTarget;       //相机目标点
    float  camRoll;         //相机横滚角
    float3 lightPos;        //光源位置
    float3 rayDir;          //射线方向
    float3 raydx;           //射线方向x方向的微分
    float3 raydy;           //射线方向y方向的微分
};

// RayMarch, 用于计算光线与物体的交点
float4 RayMarching(float3 ro, float3 rd)
{
    float dist = 0.0;
    float materialIndex = -1.0;
    for(int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float3 pos = ro + rd*dist;
        float2 step = sdfScene(pos);
        if(dist > MAX_DIST || step.x < MIN_DIST)
            break;
        dist += step.x;
        materialIndex = step.y;
    }
    if(dist > MAX_DIST)
        materialIndex = -1.0f;
    return float4(dist, materialIndex, 0, 0);     
}

#endif
