#ifndef SDF_GEOMETORY_INCLUDED
#define SDF_GEOMETORY_INCLUDED

// 平面sdf
// p: 点
// n: 法线
// h: 点线法距离
float sdfPlane( float3 p, float3 n, float h )
{
    // n must be normalized
    n = normalize(n);
    return dot(p,n) + h;
}

// 球体sdf
// r: 球体半径
// p: 点
float sdfSphere( float3 p, float r )
{
    return length(p)-r;
}

// 长方体sdf
// b: 长方体的半边长
// p: 点
float sdfBox( float3 p, float3 b )
{
    float3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// 圆角长方体sdf
// b: 长方体的半边长
// r: 圆角半径
// p: 点
float sdfRoundBox( float3 p, float3 b, float r )
{
    float3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)) - r;
}

// 圆柱体sdf
// h: 高度
// r: 半径
// p: 点
float sdfCylinder( float3 p, float h, float r )
{
    float2 d = abs(float2(length(p.xz),p.y)) - float2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// 带盖圆锥体sdf
// h: 高度
// r1: 底部半径
// r2: 顶部半径
// p: 点
float sdfCappedCone( float3 p, float h, float r1, float r2 )
{
    float2 q = float2(length(p.xz),p.y);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(q,float2(-b,a));
    if( k < 0.0 ) return length(q) - r1;
    if( k > a*h ) return length(q-float2(0.0,h)) - r2;
    return dot(q,float2(a,b)) - r1;
}
#endif
