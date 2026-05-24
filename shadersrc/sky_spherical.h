#include "common_ps_fxc.h"

sampler2D SkyTexture            : register(s0);
const float4 Constants0         : register(c0);
#define brightness      Constants0.x
const float4x4 matInvProjViewrot      : register(c11);

static const float PI       = 3.1415926f;
static const float PI2      = PI * 2.0f;
static const float INV_PI   = 1 / PI;
static const float INV_PI2  = 1 / PI2;

struct PS_INPUT {
    float2 P            : VPOS;
    float2 uv           : TEXCOORD0;
};

float4 main( PS_INPUT i ) : COLOR
{
    float2 texCoord = i.uv;

    float4 cameraRay = float4(texCoord * 2.0f - 1.0f, 1.0f, 1.0f);

    float4 viewPos = mul(cameraRay, matInvProjViewrot);
    
    float3 viewDirection = viewPos.xyz /= viewPos.w;

    #if defined(REFLECT_VIEW_RAY)
        viewDirection.z = -viewDirection.z;
    #endif

    viewDirection = normalize(viewDirection);

    float2 uv = float2( atan2( -viewDirection.x, viewDirection.y ) * INV_PI2 + 0.5f, acos( viewDirection.z ) * INV_PI );

    #if defined(MIRROR_SKY)
        uv.y = 1.0 - abs(uv.y * 2.0 - 1.0);
        uv.y = min(0.999, uv.y);
    #endif
    
    float3 sky = tex2D( SkyTexture, uv ).rgb * brightness * LINEAR_LIGHT_SCALE; // HDR_INPUT_MAP_SCALE
    return half4(sky, 1);
}

// https://www.dmitrex.com/publications/Enhancing%20the%20looks%20of%20Source%20Engine%20in%20Military%20Conflict%20Vietnam.pdf