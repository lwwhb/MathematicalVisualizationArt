#ifndef LIGHTING_UTILS_INCLUDED
#define LIGHTING_UTILS_INCLUDED

#include "LightingMode.hlsl"
#include "IndirectLightingMode.hlsl"

half3 calculateLighting(float3 position, float3 lightDirI, float3 normal, float3 viewDirI, half3 lightColor, half lightIntensity, half indirectLightIntensity, half attenuation, Material material, half3 bgColor)
{
    float3 halfDir = normalize(viewDirI + lightDirI);                //半程向量
    float3 reflectDir = normalize(reflect(-viewDirI, normal));      //反射向量
    float NoV = abs(dot(normal, viewDirI)) + 1e-5;
    float NoL = saturate(dot(normal, lightDirI));
    float NoH = saturate(dot(normal, halfDir));
    float LoH = saturate(dot(lightDirI, halfDir));
    half linearRoughness = material.roughness * material.roughness;
    half3 diffuseColor = (1.0 - material.metallic) * material.albedo;
    half3 f0 = 0.04 * (1.0 - material.metallic) + material.albedo * material.metallic;

    //half3 diffuse = Lambert(NoL, lightColor, lightIntensity, attenuation, material.albedo);
    //half3 specular = BlinnPhong(NoH, lightColor, 32.0f, attenuation);
    //half3 directColor = diffuse + specular;
    
    half3 diffuseAndSpecular = CookTorranceDirect(NoV, NoL, NoH, LoH, halfDir, f0, diffuseColor, linearRoughness);
    half3 directColor = Lambert(NoL,lightColor,lightIntensity,attenuation, diffuseAndSpecular);
    half3 indirectColor = LightingIndirect(position, normal, reflectDir, NoV, indirectLightIntensity, f0, diffuseColor, material.roughness, bgColor);
    return  directColor + indirectColor;
}

#endif
