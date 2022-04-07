#version 450 core

in vec2 texCoord;
uniform sampler2D tex;
uniform sampler2D tex2;

out vec4 color;

vec3 t;

const float offset_x = 1.0f / 1600.0f;  
const float offset_y = 1.0f / 1200.0f;  

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

    float exposure = 0.6;
    float gamma = 0.7;

    for(int i = 0; i < 9; i++)
        t += vec3(texture(tex, texCoord.st + offsets[i])) * kernel2[i]*0.0625;

    vec3 toneMapped = vec3(1)- exp(-t*exposure);
    color =vec4(pow(toneMapped, vec3(1/gamma)),1);

}





