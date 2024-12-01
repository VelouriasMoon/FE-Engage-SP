import lib-sampler.glsl
import lib-alpha.glsl
import lib-normal.glsl
import lib-emissive.glsl
import lib-vectors.glsl
import lib-utils.glsl
import lib-env.glsl

//: state cull_face off
//: state blend over

//: param auto main_light
uniform vec4 uniform_main_light;
//: param auto mvp_matrix
uniform mat4 uniform_mvp_matrix;
//: param auto camera_view_matrix
uniform mat4 uniform_camera_view_matrix;
//: param auto world_eye_position
uniform vec3 uniform_world_eye_position;

//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;
//: param auto channel_ambientocclusion
uniform SamplerSparse ambientocclusion_tex;
//: param auto channel_user0
uniform SamplerSparse user0_tex;

//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Base Color"  }
uniform vec3 _BaseColor;
//: param custom { "default": 1.0, "min": 0.0, "max": 1.0, "label": "Occlusion Intensity" }
uniform float _OcclusionIntensity;
//: param custom {"default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Toon Ramp", "usage": "texture" }
uniform sampler2D _ToonRamp;


//: param custom {"default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Angel Ring Map", "usage": "texture", "group": "Angel Ring" }
uniform sampler2D _AngelRingMap;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Angel Ring Color", "group": "Angel Ring"  }
uniform vec3 _AngelRingColor;
//: param custom { "default": 0.0, "min": 0.0, "max": 1.0, "label": "Angel Ring Offset U", "group": "Angel Ring" }
uniform float _AngelRingOffsetU;
//: param custom { "default": 0.3, "min": 0.0, "max": 1.0, "label": "Angel Ring Offset V", "group": "Angel Ring" }
uniform float _AngelRingOffsetV;


//: param custom { "default": 0.0, "min": 0.0, "max": 1.0, "label": "Rim Light Blend", "group": "Rim Light" }
uniform float _RimLightBlend;
//: param custom { "default": 0.0, "min": 0.0, "max": 1.0, "label": "Rim Light Scale", "group": "Rim Light" }
uniform float _RimLightScale;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Rim Light Color Shadow", "group": "Rim Light" }
uniform vec3 _RimLightColorShadow;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Rim Light Color Light", "group": "Rim Light" }
uniform vec3 _RimLightColorLight;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Main Light Color", "group": "Rim Light"  }
uniform vec3 mainLightColor;

//: param custom { "default": 0, "label": "Time", "min": 0.0, "max":100, "visible" : true }
uniform float Time;

vec3 TransformWorldToViewDir(vec3 dirWS, bool doNormalize = false)
{
    vec3 dirVS = (uniform_camera_view_matrix * vec4(dirWS.x, dirWS.y, dirWS.z, 1.0)).xyz;
    if (doNormalize)
        return normalize(dirVS);

    return dirVS;
}

void shade(V2F inputs)
{
    mat3 TBN = transpose(mat3(normalize(inputs.tangent), normalize(inputs.bitangent), normalize(inputs.normal)));
    vec3 normal_vec = computeWSNormal(inputs.tex_coord, inputs.tangent, inputs.bitangent, inputs.normal);
    vec3 normal_map = textureSparse(normal_texture, inputs.sparse_coord).rgb;
    vec3 height_map = normalFromHeight(inputs.sparse_coord, textureSparse(height_texture, inputs.sparse_coord).r);
    vec3 normalDirTS = normalBlendOriented(normal_map, height_map);
    vec3 normalDirWS = normalize(normal_vec * normalDirTS);
    vec3 normalDirVS = TransformWorldToViewDir(normalDirWS, true);
    vec3 viewDirWS = normalize(camera_pos - inputs.position); //getEyeVec(inputs.position);
    vec3 lightDirWS = normalize(uniform_main_light.xyz - inputs.position);
    vec3 halfDirWS = normalize(viewDirWS + lightDirWS);

    float NL01 = dot(normalDirWS, lightDirWS) * 0.5 + 0.5;
    float NV01 = max(0.0, dot(normalDirWS, viewDirWS));
    float NH01 = max(0.0, dot(normalDirWS, halfDirWS));

    vec3 baseMap = getBaseColor(basecolor_tex, inputs.sparse_coord);
    float roughness = getRoughness(roughness_tex, inputs.sparse_coord);
    float metallic = getMetallic(metallic_tex, inputs.sparse_coord);
    float occlusion = mix(1, textureSparse(ambientocclusion_tex, inputs.sparse_coord).r, _OcclusionIntensity);
    float faceMask = textureSparse(user0_tex, inputs.sparse_coord).r;

    vec2 toonRampUV = clamp(vec2(NL01 * occlusion, 0.5), 0.01, 0.99);
    vec3 toonRamp = sRGB2linear(texture(_ToonRamp, toonRampUV).rgb);

    vec2 angelRingUV = mix(normalDirVS, vec3(0.0,0.0,1.0), _AngelRingOffsetU).xy * 0.5 + 0.5;
    angelRingUV.y = mix(inputs.multi_tex_coord[1].y, angelRingUV.y, _AngelRingOffsetV);
    vec3 angelRingMap = sRGB2linear(texture(_AngelRingMap, angelRingUV).rgb);
    vec3 angleRing = angelRingMap * _AngelRingColor;

    float rimLightScale = smoothstep((1-_RimLightBlend), 1.0, 1-NV01) * sRGB2linear(_RimLightScale);
    vec3 rimLight = clamp(_RimLightColorShadow, _RimLightColorLight, vec3(NL01*(1-occlusion))) * rimLightScale * inputs.color[0].r;

    vec3 finalColor = (angleRing + _BaseColor) * toonRamp + rimLight; 
    finalColor = mix(finalColor, finalColor * (mainLightColor), 0.4);

    diffuseShadingOutput(finalColor);
    emissiveColorOutput(pbrComputeEmissive(emissive_tex, inputs.sparse_coord));
    alphaOutput(getOpacity(opacity_tex, inputs.sparse_coord));
}