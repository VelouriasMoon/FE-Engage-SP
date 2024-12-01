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


//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Main Light Color"  }
uniform vec3 mainLightColor;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Base Color"  }
uniform vec3 _BaseColor;
//: param custom { "default": 0, "label": "Color RGB", "widget": "color", "label": "Black Color"  }
uniform vec3 _BlackColor;
//: param custom { "default": 0.0, "min": 0.0, "max": 1.0, "label": "Decal Rate" }
uniform float _DecalRate;

//: param custom {"default": "", "default_color": [0, 0, 0, 0], "label": "Decal 1 Map", "usage": "texture", "group": "Decal 1" }
uniform sampler2D _DecalTex1;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Decal 1 Color", "group": "Decal 1"  }
uniform vec3 _DecalColor1;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 1 Center X", "group": "Decal 1" }
uniform float _DecalCenterX1;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 1 Center Y", "group": "Decal 1" }
uniform float _DecalCenterY1;
//: param custom { "default": 0.1, "min": 0.0, "max": 1.0, "label": "Decal 1 Scale", "group": "Decal 1" }
uniform float _DecalScale1;

//: param custom {"default": "", "default_color": [0, 0, 0, 0], "label": "Decal 2 Map", "usage": "texture", "group": "Decal 2" }
uniform sampler2D _DecalTex2;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Decal 2 Color", "group": "Decal 2"  }
uniform vec3 _DecalColor2;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 2 Center X", "group": "Decal 2" }
uniform float _DecalCenterX2;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 2 Center Y", "group": "Decal 2" }
uniform float _DecalCenterY2;
//: param custom { "default": 0.1, "min": 0.0, "max": 1.0, "label": "Decal 2 Scale", "group": "Decal 2" }
uniform float _DecalScale2;

//: param custom {"default": "", "default_color": [0, 0, 0, 0], "label": "Decal 3 Map", "usage": "texture", "group": "Decal 3" }
uniform sampler2D _DecalTex3;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Decal 3 Color", "group": "Decal 3"  }
uniform vec3 _DecalColor3;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 3 Center X", "group": "Decal 3" }
uniform float _DecalCenterX3;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 3 Center Y", "group": "Decal 3" }
uniform float _DecalCenterY3;
//: param custom { "default": 0.1, "min": 0.0, "max": 1.0, "label": "Decal 3 Scale", "group": "Decal 3" }
uniform float _DecalScale3;

//: param custom {"default": "", "default_color": [0, 0, 0, 0], "label": "Decal 4 Map", "usage": "texture", "group": "Decal 4" }
uniform sampler2D _DecalTex4;
//: param custom { "default": 1, "label": "Color RGB", "widget": "color", "label": "Decal 4 Color", "group": "Decal 4"  }
uniform vec3 _DecalColor4;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 4 Center X", "group": "Decal 4" }
uniform float _DecalCenterX4;
//: param custom { "default": 0.5, "min": 0.0, "max": 1.0, "label": "Decal 4 Center Y", "group": "Decal 4" }
uniform float _DecalCenterY4;
//: param custom { "default": 0.1, "min": 0.0, "max": 1.0, "label": "Decal 4 Scale", "group": "Decal 4" }
uniform float _DecalScale4;

//: param custom { "default": 0, "label": "Time", "min": 0.0, "max":1, "visible" : true }
uniform float Time;


vec2 ScaleAnimUV(vec2 uv, vec2 center, float scale, float rate)
{
    rate = rate * Time;
    scale = scale * 0.1;
    uv -= center;
    uv *= (sin(rate)) * scale + (scale + 1);
    uv += center;
    return uv;
}

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

    vec2 decalCenter1 = vec2(_DecalCenterX1, _DecalCenterY1);
    vec2 decalCenter2 = vec2(_DecalCenterX2, _DecalCenterY2);
    vec2 decalCenter3 = vec2(_DecalCenterX3, _DecalCenterY3);
    vec2 decalCenter4 = vec2(_DecalCenterX4, _DecalCenterY4);

    vec2 decalUV1 = ScaleAnimUV(inputs.tex_coord, decalCenter1, _DecalScale1, _DecalRate);
    vec2 decalUV2 = ScaleAnimUV(inputs.tex_coord, decalCenter2, _DecalScale2, _DecalRate);
    vec2 decalUV3 = ScaleAnimUV(inputs.tex_coord, decalCenter3, _DecalScale3, _DecalRate);
    vec2 decalUV4 = ScaleAnimUV(inputs.tex_coord, decalCenter4, _DecalScale4, _DecalRate);

    vec3 baseMap = getBaseColor(basecolor_tex, inputs.sparse_coord);
    float decalTex1 = (texture(_DecalTex1, decalUV1).rgb).r;
    float decalTex2 = (texture(_DecalTex2, decalUV2).rgb).r;
    float decalTex3 = (texture(_DecalTex3, decalUV3).rgb).r;
    float decalTex4 = (texture(_DecalTex4, decalUV4).rgb).r;

    //vec3 decalColor = mix()
    vec3 decalColor = mix(_BaseColor, _DecalColor1, decalTex1);
    decalColor = mix(decalColor, _DecalColor2, decalTex2);
    decalColor = mix(decalColor, _DecalColor3, decalTex3);
    decalColor = mix(decalColor, _DecalColor4, decalTex4);

    vec3 finalColor = decalColor * _BlackColor;
    finalColor = mix(finalColor, finalColor * (mainLightColor), 0.1);

    diffuseShadingOutput(finalColor);
    alphaOutput(getOpacity(opacity_tex, inputs.sparse_coord));
}