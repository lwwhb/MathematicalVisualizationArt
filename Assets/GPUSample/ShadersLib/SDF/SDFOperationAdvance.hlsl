#ifndef SDF_OPERATION_ADVANCE_INCLUDED
#define SDF_OPERATION_ADVANCE_INCLUDED

// sdf多项式平滑并集 (k=32)
// d1: sdf1
// d2: sdf2
// k: 平滑系数
float opSmoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

// sdf多项式平滑交集 (k=32)
// d1: sdf1
// d2: sdf2
// k: 平滑系数
float opSmoothIntersect(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) + k * h * (1.0 - h);
}

// sdf多项式平滑差集 (k=32)
// d1: sdf1
// d2: sdf2
// k: 平滑系数
float opSmoothSubtract(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

// sdf多项式平滑反集 (k=32)
// d: sdf
// k: 平滑系数
float opSmoothReverse(float d, float k)
{
    return -d - k * (1.0 - exp(-d * k));
}

/*// exponential smooth min (k=32) 满足交换率，其余不满足
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

// power smooth min (k=8)
float smin( float a, float b, float k )
{
    a = pow( a, k ); b = pow( b, k );
    return pow( (a*b)/(a+b), 1.0/k );
}

// root smooth min (k=0.01)
float smin( float a, float b, float k )
{
    float h = a-b;
    return 0.5*( (a+b) - sqrt(h*h+k) );
}

// polynomial smooth min 2 (k=0.1)
float sminopt( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

// polynomial smooth min
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}
*/

#endif
