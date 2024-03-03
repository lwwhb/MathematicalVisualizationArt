#ifndef SDF_OPERATION_INCLUDED
#define SDF_OPERATION_INCLUDED

// sdf并集
float opU( float d1, float d2 )
{
    return min( d1, d2 );
}

// sdf交集
float opI( float d1, float d2 )
{
    return max( d1, d2 );
}

// sdf差集
float opS( float d1, float d2 )
{
    return max(-d1, d2);
}

// sdf反集
float opD( float d1, float d2 )
{
    return -d1;
}

// sdf圆角
// d: sdf
// r: 圆角半径
float opRound( float d, float r )
{
    return max( d, length( d ) - r );
}

// sdf扩展
// d: sdf
// r: 扩展半径
float opExtrude( float d, float r )
{
    return d - r;
}

// sdf旋转
// d: sdf
// a: 旋转角度
float opRotate( float d, float a )
{
    float c = cos( a );
    float s = sin( a );
    float2x2 m = float2x2( c, -s, s, c );
    float2 p = float2( d, 0.0 );
    return length( mul( m, p ) );
}

// sdf平移
// d: sdf
// p: 平移量
float opTranslate( float d, float3 p )
{
    return d - length( p );
}

// sdf重复
// d: sdf
// p: 重复间隔
float opRepeat( float d, float3 p )
{
    float3 q = abs( p ) - float3( 0.5, 0.5, 0.5 );
    return length( max( q, 0.0 ) ) + min( max( q.x, max( q.y, q.z ) ), 0.0 );
}

// sdf旋转重复
// d: sdf
// p: 重复间隔
// a: 旋转角度
float opRepeatRotate( float d, float3 p, float a )
{
    float c = cos( a );
    float s = sin( a );
    float2x2 m = float2x2( c, -s, s, c );
    float2 q = float2( length( p.xz ), p.y );
    return length( mul( m, q ) ) - d;
}

// sdf平移重复
// d: sdf
// p: 重复间隔
// a: 平移量
float opRepeatTranslate( float d, float3 p, float3 a )
{
    float3 q = abs( p ) - float3( 0.5, 0.5, 0.5 );
    return length( max( q, 0.0 ) ) + min( max( q.x, max( q.y, q.z ) ), 0.0 ) - length( a );
}

// sdf旋转平移重复
// d: sdf
// p: 重复间隔
// a: 旋转角度
// b: 平移量
float opRepeatRotateTranslate( float d, float3 p, float a, float3 b )
{
    float c = cos( a );
    float s = sin( a );
    float2x2 m = float2x2( c, -s, s, c );
    float2 q = float2( length( p.xz ), p.y );
    return length( mul( m, q ) ) - length( b ) - d;
}

// sdf平移旋转重复
// d: sdf
// p: 重复间隔
// a: 平移量
// b: 旋转角度
float opRepeatTranslateRotate( float d, float3 p, float3 a, float b )
{
    float c = cos( b );
    float s = sin( b );
    float2x2 m = float2x2( c, -s, s, c );
    float2 q = float2( length( p.xz ), p.y );
    return length( mul( m, q ) ) - length( a ) - d;
}

#endif
