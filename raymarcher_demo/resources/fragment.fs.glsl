#version 450 core

in vec2 texCoord;
layout(binding = 0) uniform sampler2D tex;

uniform float res;//resolution variable

out vec4 color;

float ww = 1600.0f;
float hh = 1000.0f;

ivec2 pix_coord = ivec2(texCoord*vec2(ww, hh));

vec3 t;

float offset_x = 1.0f / ww;  
float offset_y = 1.0f / hh;  

vec2 offsets[9] = vec2[]
(
    vec2(-offset_x,  offset_y), vec2( 0.0f,    offset_y), vec2( offset_x,  offset_y),
    vec2(-offset_x,  0.0f),     vec2( 0.0f,    0.0f),     vec2( offset_x,  0.0f),
    vec2(-offset_x, -offset_y), vec2( 0.0f,   -offset_y), vec2( offset_x, -offset_y) 
);

float kernel[9] = float[]
(
    1, 1, 1,
    1, -8, 1,
    1, 1, 1
);
float kernel2[9] = float[]
(
   1, 2, 1,
   2, 4, 2,
   1, 2, 1
);

// float[4][4] dithering = float[][]
// (
//     float[](0, 8, 2, 10),
//     float[](12, 4, 14, 6),
//     float[](3, 11, 1, 9),
//     float[](15, 7, 13, 5)
// );
float dithering[8][8] = float[][](
    float[](0, 32, 8, 40, 2, 34, 10, 42),
    float[](48, 16, 56, 24, 50, 18, 58, 26),
    float[](12, 44, 4, 36, 14, 46, 6, 38),
    float[](60, 28, 52, 20, 62, 30, 54, 22),
    float[](3, 35, 11, 43, 1, 33, 9, 41),
    float[](51, 19, 59, 27, 49, 17, 57, 25),
    float[](15, 47, 7, 39, 13, 45, 5, 37),
    float[](63, 31, 55, 23, 61, 29, 53, 21)
);

void main(){

    float exposure = 1;
    float gamma = 0.75;

    vec2 off = pix_coord-mod(pix_coord, res);

    //swizzle suffixes: xyzw, stpq, rgba

    // if(res == 1){
    //     for(int i = 0; i < 9; i++)
    //         t += vec3(texture(tex, texCoord.st + offsets[i])) * kernel2[i]*0.0625;
    // }
    // else
    //      t = vec3(texture(tex, offsets[2]+off*offsets[2]));//sets the pixel color to that of the nearest calculated pixel

    t = vec3(texture(tex, offsets[2]+off*offsets[2]));
    
    vec3 toneMapped = vec3(1)- exp(-t*exposure);
    vec3 tc = pow(toneMapped, vec3(1/gamma));

    color = vec4(tc,1)*(0.015625*dithering[int(mod(pix_coord.s, 8))][int(mod(pix_coord.t, 8))]);


}





