#ifndef SDF_SCENES_INCLUDED
#define SDF_SCENES_INCLUDED

#include "../SDF/SDFGeometory.hlsl"
#include "../SDF/SDFOperation.hlsl"
#include "../SDF/SDFOperationAdvance.hlsl"

// x 代表sdf, y 代表材质
float2 sdfScene(float3 p)
{
    float2 scene;
    //定义地面
    float3 planePos = float3(0.0, 0.0, 0.0);
    float3 planeNormal = float3(0.0, 1.0, 0.0);
    float planeDistance = 0.0;
    float planeMaterialIndex = 1.0f;
    float2 plane = float2(sdfPlane(p - planePos, planeNormal, planeDistance), planeMaterialIndex);
    
    //定义球体
    float3 spherePos = float3(2.0*cos(_Time.y), 1.0, 0.0);
    float sphereRadius = 1.0;
    float sphereMaterialIndex = 2.0f;
    float2 sphere = float2(sdfSphere(p - spherePos, sphereRadius), sphereMaterialIndex);
    
    //定义圆角盒
    float3 boxPos = float3(2.0*sin(_Time.y), 1.0, 0.0);
    float3 boxSize = float3(1.0, 0.5, 0.5);
    float boxRadius = 0.1;
    float boxMaterialIndex = 3.0f;
    float2 box = float2(sdfRoundBox(p - boxPos, boxSize, boxRadius), boxMaterialIndex);

    scene = opUnion(opSmoothUnion(sphere, box, 0.5), plane);
    return scene;
}

#endif
