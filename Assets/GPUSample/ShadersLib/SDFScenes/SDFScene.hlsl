#ifndef SDF_SCENES_INCLUDED
#define SDF_SCENES_INCLUDED

#include "../SDF/SDFGeometory.hlsl"
#include "../SDF/SDFOperation.hlsl"
#include "../SDF/SDFOperationAdvance.hlsl"

float4 sdfScene(float3 p, float time)
{
    float4 result = float4(p.y, 0.0, 0.0, 0.0);
    //定义球体
    float3 spherePos = float3(0.0, 3.0, 0.0);
    float sphereRadius = 1.0;
    float sphere = sdSphere(p - spherePos, sphereRadius);
    //定义圆角盒
    float3 boxPos = float3(0.0, 3.0, 0.0);
    float3 boxSize = float3(1.0, 0.5, 0.5);
    float boxRadius = 0.1;
    float box = sdRoundBox(p - boxPos, boxSize, boxRadius);

    result.x = opU(sphere, box);
    result.y = opU(result.y, 27.9f);
    return result;
}

#endif
