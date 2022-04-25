#version 450 core

layout (local_size_x = 8, local_size_y = 4, local_size_z = 1) in;

layout (rgba32f, binding = 0)  writeonly uniform image2D ftex;
layout (binding = 1)  uniform sampler2D skybox;
layout (binding = 2) uniform sampler2D normal_map;
layout (binding = 3) uniform sampler2D sphere_tex;
layout (binding = 4) uniform sampler2D displace;
layout (binding = 5) uniform sampler2D metal;
layout (binding = 6) uniform sampler2D roughness;

shared vec4[32] color_errors;

const float PI = 3.1415926535;

uniform float xx;

uniform float res;

uniform int fxaa;

uniform vec2 mouse_xy;

uniform vec3 orig;

int num_reflections = 1;

int width = 1600;

float inv_width = 0.000625;

uint globalInvocationIndex = gl_GlobalInvocationID.x+gl_GlobalInvocationID.y*width;

int height = 1000;

float inv_height = 0.001;

int samples = 1;

float inv_samples = 1.0;

float inverse_aspect = 0.625;

float aspect = 1.6;

vec2 cam_rot_xy= vec2(0.2*vec2(((mouse_xy.x+90.0)*0.0025-1.0), 2.0*((mouse_xy.y)*0.00333-1.0)));

vec4 color;

vec3 pos = vec3(2,0,2);//sphere position

float rad = 1.2;//sphere radius

vec3 cam = vec3(0, 0, -5);

ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);

//normalized pixel coordiantes
float xu = float(float(pixel_coords.x*2 - width)*inv_width*aspect);
float yu = float(1-(float(pixel_coords.y*2 - height)*inv_height));
// float xu = float(float(pixel_coords.x*2 - width)/width/inverse_aspect);
// float yu = float(1-(float(pixel_coords.y*2 - height)/height));


vec3 comp = vec3(xu, yu, -1);

vec3 lightColor[3] = vec3[3](vec3(1500), vec3(1000), vec3(800,250,50));

vec3 lightPosition[3] = vec3[3](vec3(-30,0, -8), vec3(-30,0,10), vec3(2,-3,2));

mat3 roty = mat3(vec3(cos(cam_rot_xy.x), 0, sin(cam_rot_xy.x)), vec3(0, 1, 0),  vec3(-sin(cam_rot_xy.x), 0, cos(cam_rot_xy.x)));
mat3 rotx = mat3(vec3(1, 0, 0), vec3(0, cos(-cam_rot_xy.y), -sin(-cam_rot_xy.y)),  vec3( 0, sin(-cam_rot_xy.y), cos(-cam_rot_xy.y)));

vec3 dir = vec3(normalize(comp-cam)*rotx*roty);

float rand(vec2 co){
    return float(fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453));
}

float sphere_dist(vec3 p){//distance function for spheres
	float displacement = float(0.0);//sin((3) * p.x) * sin((3) * p.y) * sin((3) * p.z) * 0.15;
	//p.x = (mod((pos.x-p.x),4)-2);
    return float(length(pos-p)-rad+displacement);//length(p)-rad+displacement;//
}


float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

float smax(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, -h) - k*h*(1.0-h);
}

float dist(vec3 pos){
    return smin(sphere_dist(pos), sphere_dist(pos-vec3(0.0,0.0,xx)), 2.0);//smin(rect_dist(pos), sphere_dist(pos), 2);//fractalSDF(pos);//
}

vec3 calculate_normal(vec3 p){
	vec3 smallstep = vec3(0.0001, 0.0, 0.0);

	float gx = dist(p+smallstep)-dist(p-smallstep);
	float gy = dist(p+smallstep.yxy)-dist(p-smallstep.yxy);
	float gz = dist(p+smallstep.yyx)-dist(p-smallstep.yyx);

	return normalize(vec3(gx,gy,gz));
}

mat3 TBN(vec3 n, vec3 px, vec3 py, vec3 pos ){

    //TBN: [tangent, bitangent, normal]

    vec3 t = normalize(px-pos);
    vec3 b = normalize(py-pos);

    return mat3(t, b, n);
}

float D_GGX (vec3 N, vec3 H, float roughness){
    float a2    = roughness * roughness;
    float NdotH = max (dot (N, H), 0.0);
    float d = max((NdotH * NdotH * (a2 - 1.0) + 1.0), 0.0000001);
    return a2 / (PI * d * d);
}

float G_GGX (float NdotV, float roughness){
    float k = roughness*0.5;
    return NdotV / max((NdotV * (1.0 - k) + k), 0.0000000000001);
}

float G_S (vec3 N, vec3 V, vec3 L, float roughness){
    return G_GGX (max (dot (N, L), 0.0), roughness) * 
          G_GGX (max (dot (N, V), 0.0), roughness);
}


vec3 fresnel_S(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 fresnel_rough(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0)  * pow(1.0 - cosTheta, 5.0);
}

//aproximate nearby intersection points for tangent and bitangent calculations
vec3[2] offsets(vec3 rdx, vec3 rdy, float t, vec3 ro )
{
    vec3 px = t*rdx+ro;
    vec3 py = t*rdy+ro;
    
    return vec3[2](px, py); 
}

vec4[3] ray_march(vec3 ro, vec3 rd, bool refl)
{
    //off is used so that the reflection direction doesn't intersect the object it bounced off from;
    float total_distance_traveled = 0.0;
    float MINIMUM_HIT_DISTANCE = 0.001;
    float MAXIMUM_TRACE_DISTANCE = 40.0;
    int num_steps = 0;

    vec3 kD;//used to determine how much specular light should be present

    vec3 kS;//used to determine how much diffise light should be present (1-kd)

    vec3 current_position;
    
    float distance_to_closest;

    vec3 normal;
    vec3 tan_normal;

    float offset = 0;

    float rough;

    vec3 rdx = vec3(normalize(vec3(xu+1*inv_width,yu-1*inv_height, -1)-cam)*rotx*roty);
    vec3 rdy = vec3(normalize(vec3(xu-1*inv_width,yu+1*inv_height, -1)-cam)*rotx*roty);

    vec3[2] offsetss = offsets(rdx, rdy, 0.01, ro);	

    if(refl){
        normal = calculate_normal(ro);

        rough = clamp(texture(roughness, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32)).r*3, 0.0f, 1.0f);

        tan_normal = (2*texture(normal_map, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32)).xyz)-1;

        normal = normalize(TBN(normal,offsetss[0],offsetss[1], ro)*tan_normal);

        rd = (rd-normal*2.0*dot(rd, normal));//reflecting the direction vector

        rdx = (rdx-normal*2.0*dot(rdx, normal));
        rdy = (rdy-normal*2.0*dot(rdy, normal));
        
        offset = 0.1;
    }

    float metalness;

    vec3 iSpecFac = vec3(1);

    vec4 skycolor;

    while(total_distance_traveled < MAXIMUM_TRACE_DISTANCE)
    {
        
        current_position = ro + (total_distance_traveled+offset) * rd;

        float ao = 1/(1+0.01*num_steps);//ambient occlusion

        vec3 temp_normal = calculate_normal(current_position);

        metalness = 0;//texture(metal,  vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).x;

        vec3 albedo = texture(sphere_tex, vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).rgb;
       
        float rough = clamp(texture(roughness, vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).r*3, 0.0f, 1.0f);

        vec3 F0 = vec3(0.04);
        F0 = mix(F0, albedo.rgb, metalness);

        float disp = texture(displace, vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).x;

        distance_to_closest = dist(current_position)-disp*0.08;

        vec3 Lo = vec3(0);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {      

            normal = calculate_normal(current_position);

            vec3[2] offsets = offsets(rdx, rdy, total_distance_traveled, ro);	

            tan_normal = (2*texture(normal_map, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32)).xyz)-1;

            normal = normalize(TBN(normal, offsets[0], offsets[1], current_position)*(tan_normal));

            vec3 N = normal;
            vec3 V = -rd;
           
           iSpecFac = fresnel_rough(max(dot(N, V), 0.0), F0, rough);

            for(int i = 0; i < 3; i++) 
            {
                vec3 L = normalize(lightPosition[i]-current_position);
                vec3 H = normalize(V + L); 

                float distant = length(lightPosition[i] - current_position);
                float attenuation = 1.0 / (distant * distant);
                vec3 radiance = lightColor[i] * attenuation;        

                //---------------------------------------------------
            
           
                //____________SPECULAR LIGHTING________________

                float NDF = D_GGX(N, H, rough);        
                float G  = G_S(N, V, L, rough);      
                vec3 F    = fresnel_S(max(dot(H, V), 0.0), F0); 
                kS = F;
            
                vec3 specular = NDF * F * G /(4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001);
                //_________________________________________________

                //_________________DIFFUSE LIGTHING___________________________
                //direct diffuse ligthing

                kD = 1.0 - kS;
                kD *= vec3(1) - metalness;

                float NdotL = max(dot(N, L), 0.0);                
                Lo += (kD * albedo / PI + specular) * radiance * NdotL; 
                //_____________________________________________________________________
            }

            //indirect diffuse ligthing____________
            vec3 indirectDiffuse = vec3(textureLod(skybox, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32), 12.0).rgb);

            vec3 idIntensity = (vec3(1) - iSpecFac); 

            indirectDiffuse *= idIntensity;

            //_____________________________________

            vec3 ambient = indirectDiffuse * albedo * ao;

            vec4 c = vec4(ambient+Lo, 1);

            return vec4[3] (c, vec4(current_position, 1), vec4(0,0,0,rough));

        }

        
        
        num_steps ++;
        total_distance_traveled += distance_to_closest;
        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
    }
    //return skycolor

    if (!refl)
        skycolor = vec4(textureLod(skybox, vec2(0.5+atan(rd.x, rd.z)*0.16, 0.5+asin(-rd.y)*0.32), 1.0));
    else
        skycolor = vec4(textureLod(skybox, vec2(0.5+atan(rd.x, rd.z)*0.16, 0.5+asin(-rd.y)*0.32), rough*14.0));
    return vec4[3](skycolor, vec4(0), vec4(0,0,0,rough));
}

void main() {   
        
    vec4 temp_color = vec4(0); 
    vec4 tot_color = vec4(0);
    if(mod(pixel_coords.x, res) == 0 || mod(pixel_coords.y, res) == 0){

        vec4[3] t = ray_march(orig+cam, dir, false);
        float rough = t[2].w;
        float gloss = rough*rough;

        for (int p = 0; p < samples; p++){//the more samples the less noisy glossy reflections will be
            dir = vec3(normalize(vec3(xu, yu, -1)-cam)*rotx*roty);
            vec4[3] temp = t;
            temp_color = temp[0];
            float reflectivity = 1.0-rough;
            for (int i = 0; i < num_reflections; i++){ 
                if(temp[1].w == 1.0){
                    // vec2 perturb = vec2(rand(vec2(p,dir.x))*gloss*2, rand(vec2(p, dir.y))*gloss*2);
                    //dir = normalize(dir+vec3(perturb,0));//perturb the reflected ray for glossy reflections
                    temp = ray_march(temp[1].xyz, dir, true);
                    temp_color = temp_color*(1.0-reflectivity)+temp[0]*reflectivity;

                }
            }

            tot_color += temp_color;
        }

    }
       
    color = tot_color*inv_samples;//tot_color/samples;

    imageStore(ftex, pixel_coords, clamp(color, 0.0f, 1.5f));

   
   
}

