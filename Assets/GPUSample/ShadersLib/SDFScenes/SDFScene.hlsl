#ifndef SDF_SCENES_INCLUDED
#define SDF_SCENES_INCLUDED

#include "../SDF/SDFGeometory.hlsl"
#include "../SDF/SDFOperation.hlsl"
#include "../SDF/SDFOperationAdvance.hlsl"

float sdfScene(float3 p, float time)
{
    float result = 0.0f;
    //定义球体
    float3 spherePos = float3(-2.0, 0.0, 0.0);
    float sphereRadius = 1.0;
    float sphere = sdSphere(p - spherePos, sphereRadius);
    
    //定义圆角盒
    float3 boxPos = float3(2.0, 0.0, 0.0);
    float3 boxSize = float3(1.0, 0.5, 0.5);
    float boxRadius = 0.1;
    float box = sdRoundBox(p - boxPos, boxSize, boxRadius);

    result = opUnion(sphere, box);
    return result;
}

#endif
