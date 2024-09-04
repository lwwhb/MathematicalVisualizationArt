#ifndef LIGHTING_MODE_INCLUDED
#define LIGHTING_MODE_INCLUDED

#include "BRDF.hlsl"
#include "IndirectLightingMode.hlsl"
#include "../Materials/Materials.hlsl"

// Lambert光照模型
half3 Lambert(float NoL, half3 lightColor, half lightIntensity, half attenuation, half3 diffuseColor)
{
    return  (lightIntensity * attenuation * NoL) * lightColor * diffuseColor;
}
// HalfLambert光照模型
half3 HalfLambert(float NoL, half3 lightColor, half lightIntensity, half attenuation, half3 diffuseColor)
{
    return  (lightIntensity * attenuation * NoL) * lightColor * diffuseColor * 0.5 + 0.5;
}
// Phong光照模型
half3 Phong(float RoV, half3 lightColor, half shininess, half attenuation)
{
    return lightColor * pow(RoV * attenuation, shininess);
}
// BlinnPhong光照模型
half3 BlinnPhong(float NoH, half3 lightColor, half shininess, half attenuation)
{
    return lightColor * pow(NoH * attenuation, shininess);
}
//Cook-Torrance
half3 CookTorranceDirect(float NoV, float NoL, float NoH, float LoH, float3 halfDir, half3 f0, half3 diffuseColor, half linearRoughness)
{
    // specular BRDF
    half D = D_GGX(linearRoughness, NoH, halfDir);
    half V = V_SmithGGXCorrelated(linearRoughness, NoV, NoL);
    half3 F = F_Schlick(f0, LoH);
    half3 Fr = (D * V) * F;

    // diffuse BRDF
    half3 Fd = diffuseColor * Fd_Burley(linearRoughness, NoV, NoL, LoH);
    return Fd + Fr;
}

#endif
