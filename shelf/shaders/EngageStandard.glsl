import lib-sampler.glsl
import lib-alpha.glsl
import lib-normal.glsl
import lib-emissive.glsl
import lib-vectors.glsl
import lib-utils.glsl

//: state cull_face off
//: state blend over

//: param auto main_light
uniform vec4 uniform_main_light;

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
//: param custom {"default": "", "default_color": [1.0, 1.0, 1.0, 1.0], "label": "Toon Ramp Metal", "usage": "texture" }
uniform sampler2D _ToonRampMetal;
//: param custom { "default": 0.0, "min": 0.0, "max": 1.0, "label": "Rim Light Blend" }
uniform float _RimLightBlend;
//: param custom { "default": 0.0, "min": 0.0, "max": 1.0, "label": "Rim Light Scale" }
uniform float _RimLightScale;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Rim Light Color Shadow" }
uniform vec3 _RimLightColorShadow;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Rim Light Color Light" }
uniform vec3 _RimLightColorLight;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Main Light Color"  }
uniform vec3 mainLightColor;

void shade(V2F inputs)
{
    mat3 TBN = transpose(mat3(normalize(inputs.tangent), normalize(inputs.bitangent), normalize(inputs.normal)));
    vec3 normal_vec = computeWSNormal(inputs.tex_coord, inputs.tangent, inputs.bitangent, inputs.normal);
    vec3 normal_map = textureSparse(normal_texture, inputs.sparse_coord).rgb;
    vec3 height_map = normalFromHeight(inputs.sparse_coord, textureSparse(height_texture, inputs.sparse_coord).r);
    vec3 normalDirTS = normalBlendOriented(normal_map, height_map);
    vec3 normalDirWS = normalize(normal_vec * normalDirTS);
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

    vec2 toonMetalRampUV = clamp(vec2(pow(NH01, 1-roughness), clamp(roughness, 0, 1)), 0.01, 0.99);
    vec3 toonMetalRamp = sRGB2linear(texture(_ToonRampMetal, toonMetalRampUV).rgb);

    vec3 finalRamp = mix(toonRamp, toonMetalRamp, vec3(metallic));

    float rimLightScale = smoothstep((1-_RimLightBlend), 1.0, 1-NV01) * sRGB2linear(_RimLightScale);
    vec3 rimLight = clamp(_RimLightColorShadow, _RimLightColorLight, vec3(NL01*occlusion)) * rimLightScale;

    vec3 finalColor = rimLight + finalRamp * baseMap * _BaseColor.rgb;
    finalColor = mix(finalColor, finalColor * (mainLightColor), 0.4);

    diffuseShadingOutput(finalColor);
    emissiveColorOutput(pbrComputeEmissive(emissive_tex, inputs.sparse_coord));
    alphaOutput(getOpacity(opacity_tex, inputs.sparse_coord));
}