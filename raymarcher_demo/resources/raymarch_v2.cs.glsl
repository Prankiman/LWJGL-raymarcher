#version 450 core

layout (local_size_x = 8, local_size_y = 4, local_size_z = 1) in;

precision lowp float;
precision lowp int;
precision lowp sampler2D;

layout (rgba32f, binding = 0)  writeonly uniform image2D ftex;
layout (binding = 1)  uniform sampler2D skybox;
layout (binding = 2) uniform sampler2D normal_map;
layout (binding = 3) uniform sampler2D sphere_tex;
layout (binding = 4) uniform sampler2D displace;
layout (binding = 5) uniform sampler2D metal;
layout (binding = 6) uniform sampler2D roughness;

const float PI = 3.14159265358979f;

uniform float xx;

uniform float res;

uniform int fxaa;

uniform vec2 mouse_xy;

uniform vec3 orig;

int width = 1600;

int height = 1000;

float inverse_aspect = 0.625;

vec2 cam_rot_xy= 0.2*vec2(((mouse_xy.x+90)/400-1), 2*((mouse_xy.y)/300-1));

vec4 color;

mat3 roty = mat3(vec3(cos(cam_rot_xy.x), 0, sin(cam_rot_xy.x)), vec3(0, 1, 0),  vec3(-sin(cam_rot_xy.x), 0, cos(cam_rot_xy.x)));
mat3 rotx = mat3(vec3(1, 0, 0), vec3(0, cos(-cam_rot_xy.y), -sin(-cam_rot_xy.y)),  vec3( 0, sin(-cam_rot_xy.y), cos(-cam_rot_xy.y)));

vec3 pos = vec3(2,0,2);//sphere position

float rad = 2;//sphere radius

vec3 cam = vec3(0, 0, -5);

// vec3 orig = vec3(0, 0, -7);


ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
//normalized pixel coordiantes
float xu = (float(pixel_coords.x*2 - width)/width/inverse_aspect);
float yu = 1-(float(pixel_coords.y*2 - height)/height);


vec3 comp = vec3(xu, yu, -1);

vec3 dir = normalize(comp-cam)*rotx*roty;

vec3 lightColor[3] = vec3[3](vec3(2500), vec3(2000), vec3(800,700,500));

vec3 lightPosition[3] = vec3[3](vec3(-30,0, -8), vec3(-30,0,10), vec3(2,-30,2));

float sphere_dist(vec3 p){//distance function for spheres
	float displacement = 0;//sin((3) * p.x) * sin((3) * p.y) * sin((3) * p.z) * 0.15;
	//p.x = (mod((pos.x-p.x),4)-2);
    return length(pos-p)-rad+displacement;//length(p)-rad+displacement;//
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

float dist(vec3 pos){
    return sphere_dist(pos);//smin(sphere_dist(pos), sphere_dist(pos-vec3(0,0,xx)), 2);//smin(rect_dist(pos), sphere_dist(pos), 2);//fractalSDF(pos);//
}

vec3 calculate_normal(vec3 p){
	vec3 smallx = vec3(0.001, 0.0, 0.0);
	vec3 smally = vec3(0.0, 0.001, 0.0);
	vec3 smallz = vec3(0.0, 0.0, 0.001);

	float gx = dist(p+smallx)-dist(p-smallx);
	float gy = dist(p+smally)-dist(p-smally);
	float gz = dist(p+smallz)-dist(p-smallz);

	return normalize(vec3(gx,gy,gz));
}

float D_GGX (vec3 N, vec3 H, float roughness){
    float a2    = roughness * roughness;
    float NdotH = max (dot (N, H), 0.0);
    float d = max((NdotH * NdotH * (a2 - 1.0) + 1.0), 0.0000001);
    return a2 / (PI * d * d);
}

float G_GGX (float NdotV, float roughness){
    float k = roughness/2;
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

vec4 ray_march(vec3 ro, vec3 rd)
{
    //off is used so that the reflection direction doesn't intersect the object it bounced off from;
    float total_distance_traveled = 0;
    float MINIMUM_HIT_DISTANCE = 0.001;
    float MAXIMUM_TRACE_DISTANCE = 40;
    int num_steps = 0;

    float reflectivity;

    float rough;

    vec3 kD;//used to determine how much specular light should be present

    vec3 kS;//used to determine how much diffise light should be present (1-kd)

    vec3 current_position;
    
    float distance_to_closest;

    vec3 normal = calculate_normal(ro);

    float metalness;
    
    while(total_distance_traveled < MAXIMUM_TRACE_DISTANCE)
    {
        
        current_position = ro + (total_distance_traveled) * rd;

        metalness =  1;

        rough = 0.6;

        vec3 albedo = vec3(0.5,0.5,1);

        float ao = 1/(1+0.01*num_steps);//ambient occlusion

        vec3 F0 = vec3(0.04);
        F0 = mix(F0, albedo.rgb, metalness);

        distance_to_closest = dist(current_position);

        vec3 Lo = vec3(0);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {

            normal = calculate_normal(current_position);
            vec3 N = normal;
            vec3 V = -rd;
           

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

                kD = 1 - kS;
                kD *= vec3(1) - metalness;

                float NdotL = max(dot(N, L), 0.0);                
                Lo += (kD * albedo / PI + specular) * radiance * NdotL; 
                //_____________________________________________________________________
            }

            //indirect diffuse ligthing____________
            vec3 indirectDiffuse = textureLod(skybox, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32), 12).rgb;

            vec3 idIntensity = (vec3(1) - fresnel_rough(max(dot(N, V), 0.0), F0, rough)); 

            indirectDiffuse*= idIntensity;
            
            //_____________________________________

            vec3 ambient = indirectDiffuse * albedo * ao;

            vec4 c = vec4(ambient+Lo, 1);

            return c;

        }

        
        
        num_steps ++;
        total_distance_traveled += distance_to_closest;
        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
    }
    //return skycolor
    
    vec4 skycolor = textureLod(skybox, vec2(0.5+atan(rd.x, rd.z)*0.16, 0.5+asin(-rd.y)*0.32), 1);
    return skycolor;
}


void main() {   
    vec4 temp_color = vec4(0); 

    if(mod(pixel_coords.x, res) == 0 || mod(pixel_coords.y, res) == 0){
        temp_color = ray_march(orig+cam, dir);
    }
       
    color = temp_color;
    imageStore(ftex, pixel_coords, color);
   
}

