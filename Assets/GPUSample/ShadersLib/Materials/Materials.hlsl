#ifndef MATERIALS_INCLUDED
#define MATERIALS_INCLUDED

struct Material
{
    half3  albedo;       
    half   metallic;       
    half3  specular;
    half   roughness;
    half   alpha;
};

#endif
