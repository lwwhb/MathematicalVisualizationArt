#ifndef INDIRECT_LIGHTING_MODE_INCLUDED
#define INDIRECT_LIGHTING_MODE_INCLUDED

#include "BRDF.hlsl"
#include "../Raymarching/RaymarchingUtils.hlsl"

half3 Irradiance_SphericalHarmonics(const float3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          half3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + half3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + half3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + half3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

half2 PrefilteredDFG_Karis(half roughness, half NoV) {
    // Karis 2014, "Physically Based Material on Mobile"
    const half4 c0 = half4(-1.0, -0.0275, -0.572,  0.022);
    const half4 c1 = half4( 1.0,  0.0425,  1.040, -0.040);

    half4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return half2(-1.04, 1.04) * a004 + r.zw;
}

half3 LightingIndirect(float3 position, float3 normal, float3 reflectDir, float NoV, half indirectIntensity, half3 f0, half3 diffuseColor, half roughness, half3 bgColor)
{
    // diffuse indirect
    half3 indirectDiffuse = Irradiance_SphericalHarmonics(normal) * Fd_Lambert();

    float4 indirectHit = RayMarching(position, reflectDir);
    half3 indirectSpecular = bgColor + reflectDir.y * 0.72;
    float materialIndex = indirectHit.y;
    if (materialIndex > 0.0)
    {
        float3 indirectPosition = position + indirectHit.x * reflectDir;
        Material material = GetMaterial(materialIndex, indirectPosition);
        indirectSpecular = material.albedo;
    }
    
    // indirect contribution
    half2 dfg = PrefilteredDFG_Karis(roughness, NoV);
    half3 specularColor = f0 * dfg.x + dfg.y;
    half3 ibl = diffuseColor * indirectDiffuse + indirectSpecular * specularColor;
    return ibl * indirectIntensity;
}

#endif
