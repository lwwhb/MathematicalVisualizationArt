#ifndef UTILITIES_INCLUDED
#define UTILITIES_INCLUDED

#include "../SDFScenes/SDFScene.hlsl"
#include "../Materials/Materials.hlsl"

half3 Tonemap_ACES(const half3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

half3 OECF_sRGBFast(const half3 linearColor) {
    return LinearToGamma22(linearColor);
}

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

Material GetMaterial(float materialIndex, float3 position)
{
    Material retMat = (Material)0;
    if(materialIndex < 2.0f)
    {
        float f = abs(fmod(floor(position.z) + floor(position.x), 2.0));
        const half3 baseColor = 0.4 + f * half3(0.6, 0.6, 0.6);
        retMat.albedo = baseColor;
        retMat.metallic = 0.0f;
        retMat.roughness = 0.1f;
    }
    else if(materialIndex < 3.0f)
    {
        retMat.albedo = float3(1, 0, 0);
        retMat.metallic = 0.1f;
        retMat.roughness = 0.1f;
    }
    else if(materialIndex < 4.0f)
    {
        retMat.albedo = float3(0, 1, 0);
        retMat.metallic = 0.9f;
        retMat.roughness = 0.2f;
    }
    else if(materialIndex < 5.0f)
    {
        retMat.albedo = float3(0, 0, 1);
        retMat.metallic = 0.7f;
        retMat.roughness = 1.0f;
    }
    return retMat;
}

#endif
