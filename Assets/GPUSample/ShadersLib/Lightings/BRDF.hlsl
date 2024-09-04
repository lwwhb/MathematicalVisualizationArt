#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

half pow5(half x) {
    half x2 = x * x;
    return x2 * x2 * x;
}

half D_GGX(half linearRoughness, half NoH, const float3 h) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    half oneMinusNoHSquared = 1.0 - NoH * NoH;
    half a = NoH * linearRoughness;
    half k = linearRoughness / (oneMinusNoHSquared + a * a);
    half d = k * k * (1.0 / PI);
    return d;
}

half V_SmithGGXCorrelated(half linearRoughness, half NoV, half NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    half a2 = linearRoughness * linearRoughness;
    half GGXV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
    half GGXL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    return 0.5 / (GGXV + GGXL);
}

half3 F_Schlick(const half3 f0, half VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (half3(1.0,1.0,1.0) - f0) * pow5(1.0 - VoH);
}

half F_Schlick(half f0, half f90, half VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

half Fd_Burley(half linearRoughness, half NoV, half NoL, half LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    half f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    half lightScatter = F_Schlick(1.0, f90, NoL);
    half viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / PI);
}

half Fd_Lambert() {
    return 1.0 / PI;
}

half3 UnityBRDFDiffuse(half3 albedo, half metallic, half linearRoughness, float NoV, float NoL, float LoH)
{
    half3 diffuseColor = (1 - metallic) * albedo;
    return diffuseColor * Fd_Burley(linearRoughness, NoV, NoL, LoH);
}
half3 UnityBRDFSpecular(half3 albedo, half metallic, half linearRoughness, float3 halfDir, float NoH, float NoV, float NoL, float LoH)
{
    half3 f0 = 0.04 * (1 - metallic) + albedo * metallic;
    
    half3 brdfSpecular = lerp(half3(0.04f, 0.04f, 0.04f), albedo, metallic);

    half D = D_GGX(linearRoughness, NoH, halfDir);
    half V = V_SmithGGXCorrelated(linearRoughness, NoV, NoL);
    half3  F = F_Schlick(f0, LoH);
    half3 Fr = (D * V) * F;
    return Fr;
}

#endif
