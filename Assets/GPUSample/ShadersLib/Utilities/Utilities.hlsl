#ifndef UTILITIES_INCLUDED
#define UTILITIES_INCLUDED

#include "../SDFScenes/SDFScene.hlsl"
#include "../Materials/Materials.hlsl"

//Paulo Falcao的四面体技术优化
float3 GetNormal(float3 p)
{
    #if 0
        vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
        return normalize( e.xyy*map( pos + e.xyy ).x + 
                          e.yyx*map( pos + e.yyx ).x + 
                          e.yxy*map( pos + e.yxy ).x + 
                          e.xxx*map( pos + e.xxx ).x );
    #else
        // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
        float3 n = 0.0f;
        for( int i = 0; i < 4; i++ )
        {
            float3 e = 0.5773*(2.0*float3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
            n += e*sdfScene(p+0.0005*e).x;
        }
        return normalize(n);
    #endif
}

Material GetMaterial(float materialIndex)
{
    Material retMat = (Material)0;
    if(materialIndex < 2.0f)
    {
        retMat.albedo = float3(1, 1, 1);
        retMat.metallic = 1.0f;
        retMat.specular = float3(1, 1, 1);
        retMat.roughness = 1.0f;
    }
    else if(materialIndex < 3.0f)
    {
        retMat.albedo = float3(1, 0, 0);
        retMat.metallic = 0.1f;
        retMat.specular = float3(1, 1, 1);
        retMat.roughness = 0.5f;
    }
    else if(materialIndex < 4.0f)
    {
        retMat.albedo = float3(0, 1, 0);
        retMat.metallic = 0.9f;
        retMat.specular = float3(1, 1, 1);
        retMat.roughness = 0.2f;
    }
    else if(materialIndex < 5.0f)
    {
        retMat.albedo = float3(0, 0, 1);
        retMat.metallic = 0.7f;
        retMat.specular = float3(1, 1, 1);
        retMat.roughness = 1.0f;
    }
    return retMat;
}

#endif
