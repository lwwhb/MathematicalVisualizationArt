#ifndef SHADOWS_INCLUDED
#define SHADOWS_INCLUDED

#include "../Raymarching/RaymarchingUtils.hlsl"
//硬阴影
float hardShadow( float3 ro, float3 rd )
{
    float t = MIN_DIST;
    for( int i=0; i<MAX_MARCHING_STEPS && t<MAX_DIST; i++ )
    {
        float h = sdfScene(ro + rd*t).x;
        if( h<EPSILON )
            return 0.0;
        t += h;
    }
    return 1.0;
}

//软阴影
float softshadow( float3 ro, float3 rd, float k )
{
    float res = 1.0;
    float t = MIN_DIST;
    for( int i=0; i<MAX_MARCHING_STEPS && t<MAX_DIST; i++ )
    {
        float h = sdfScene(ro + rd*t).x;
        if( h < EPSILON )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

float softshadowImprove( float3 ro, float3 rd, float w )
{
    float res = 1.0;
    float ph = 1e20;
    float t = MIN_DIST;
    for( int i=0; i<MAX_MARCHING_STEPS && t<MAX_DIST; i++ )
    {
        float h = sdfScene(ro + rd*t).x;
        if( h<EPSILON )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, d/(w*max(0.0,t-y)) );
        ph = h;
        t += h;
    }
    return res;
}

#endif
