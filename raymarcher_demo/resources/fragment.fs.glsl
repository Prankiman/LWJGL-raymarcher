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

void main(){

    float exposure = 1;
    float gamma = 0.65;

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
    color = vec4(pow(toneMapped, vec3(1/gamma)),1);

}





