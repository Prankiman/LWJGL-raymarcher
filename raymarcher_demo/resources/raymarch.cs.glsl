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

int num_reflections = 2;

uniform float xx;

uniform float res;

// float xx = 2;

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

vec3 rotateYP(vec3 v, float yaw, float pitch) {
    //needs to be in radians
    float yawRads = yaw;
    float pitchRads = pitch;

   vec3 rotateY, rotateX;
    
    // Rotate around the Y axis (pitch)
    rotateY.x = v.x;
    rotateY.y = (v.y*cos(pitchRads) + v.z*sin(pitchRads));
    rotateY.z = (-v.y*sin(pitchRads) + v.z*cos(pitchRads));
    
    //Rotate around X axis (yaw)
    rotateX.y = rotateY.y;
    rotateX.x = (rotateY.x*cos(yawRads) + rotateY.z*sin(yawRads));
    rotateX.z = (-rotateY.x*sin(yawRads) + rotateY.z*cos(yawRads));

    
    return rotateX;
}

vec3 pos = vec3(2,0,2);//sphere position

float rad = 1.2;//sphere radius

vec3 c = vec3(-2, 1, 1);//rect position

vec3 s = vec3(2,2,2);//rect size

vec3 cam = vec3(0, 0, -5);

// vec3 orig = vec3(0, 0, -7);


ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
//normalized pixel coordiantes
float xu = (float(pixel_coords.x*2 - width)/width/inverse_aspect);
float yu = 1-(float(pixel_coords.y*2 - height)/height);


vec3 comp = vec3(xu, yu, -1);

vec3 dir = normalize(comp-cam)*rotx*roty;

vec3 light_position = vec3(-5, -20, 0);

float sphere_dist(vec3 p){//distance function for spheres
	float displacement = 0;//sin((3) * p.x) * sin((3) * p.y) * sin((3) * p.z) * 0.15;
	p.x = (mod((pos.x-p.x),4)-2);
    return length(p)-rad+displacement;//length(pos-p)-rad+displacement;//
}

float fractalSDF(vec3 pos) {
	vec3 z = pos;
	float dr = 1;
	float r;
    float Power = 4, Iterations = 1000, Bailout = 200;
	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return 0.5*log(r)*r/dr;
}

float rect_dist(vec3 p)//distance function for cubeoids
{
    
    vec3 t = c;
    vec3 t2 = p;

    float x = max
    (   t2.x - t.x - s.x/2,
        t.x - t2.x - s.x/2
    );

    float y = max
    (   t2.y - t.y - s.y/2,
        t.y - t2.y - s.y/2
    );

    float z = max
    (   t2.z - t.z - s.z/2,
        t.z - t2.z - s.z/2
    );

    float d = x;
    d = max(d, y);
    d = max(d, z);
    return d;
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

float dist(vec3 pos){
    return smin(sphere_dist(pos), sphere_dist(pos-vec3(0,0,xx)), 2);//smin(rect_dist(pos), sphere_dist(pos), 2);//fractalSDF(pos);//
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

vec4[3] ray_march(vec3 ro, vec3 rd, bool refl, float off)
{
    //off is used so that the reflection direction doesn't intersect the object it bounced off from;
    float total_distance_traveled = 0;
    float MINIMUM_HIT_DISTANCE = 0.001;
    float MAXIMUM_TRACE_DISTANCE = 40;
    int num_steps = 0;

    float reflectivity;

    vec3 base_refl = vec3(0.04);

    float rough;

    vec3 kd;//used to determine how much specular light should be present

    vec3 ks;//used to determine how much diffise light should be present (1-kd)

    vec3 current_position;
    
    float distance_to_closest;

    vec3 normal = calculate_normal(ro);

    float metalness;

    normal *= 2*texture(normal_map, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32)).xyz-1;//applying normal map

    if(refl)        
       rd = rd-normal*2*dot(rd, normal);//reflecting the direction vector
    
    while(total_distance_traveled < MAXIMUM_TRACE_DISTANCE)
    {
        
        current_position = ro + (total_distance_traveled+off) * rd;

        vec3 temp_normal = calculate_normal(current_position);

        metalness = texture(metal,  vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).x;//used to determine specular lighting

        vec4 sphere_text = texture(sphere_tex, vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32));
       
        rough = texture(roughness, vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).x;

        float smoothness = max(0,1-rough);
        smoothness*=smoothness;

        float disp = texture(displace, vec2(0.5+atan(temp_normal.x, temp_normal.z)*0.16, 0.5+asin(-temp_normal.y)*0.32)).x;

        float fresnel_effect = 1-dot(rd, normal);//the surface should be more reflective if the viewing vector is perpendicular to the surfice normal and vice versa
        
        base_refl = mix(base_refl, sphere_text.rgb, metalness);//for pbr base reflectivity should be a mix between a base reflectivity and albedo color depending on the metalness
        
        distance_to_closest = dist(current_position)-disp*0.08;//displace sphere based on displacement map

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            normal = calculate_normal(current_position);

            normal *= 2*texture(normal_map, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32)).xyz-1;

            fresnel_effect = 1-dot(rd, normal);

            reflectivity = min(max(fresnel_effect*smoothness, 0),1);

            vec3 direction_to_light = normalize(light_position-current_position);

            vec3 half_v  = normalize(direction_to_light+rd);
            //---------------------------------------------------
           
            //____________SPECULAR LIGHTING________________
            ks =  (base_refl+(1-base_refl)*pow(1-dot(rd, half_v),5));
            float shine_dampening = 5;
            
            
            vec3 spec = metalness*ks*vec3(pow(max(dot(-rd, direction_to_light), 0), shine_dampening));//don't need to reflect rd further since it's been reflected alreadt

            //_________________________________________________

            //_________________DIFFUSE LIGTHING___________________________
            //direct diffuse ligthing

            kd = 1-ks;
            kd *= 1-metalness;

            vec4 diffuse = vec4(sphere_text.rgb*kd/3.141, 1);//diffuse lighting

            vec4 indirect_diffuse = sphere_text*textureLod(skybox, vec2(0.5+atan(normal.x, normal.z)*0.16, 0.5+asin(-normal.y)*0.32), 10);
            //_____________________________________________________________________

            vec4 c = (indirect_diffuse+vec4(max(0,dot(normal, direction_to_light)))
            *(vec4(spec,1)+diffuse))/(max(1.0f,0.01f*num_steps));//devide over number of steps for ambient occlusion

            //blending color according to the relative distance between the sphere/s and the cuboid
            // (sphere_text*indirect_diffuse*diffuse*rect_dist(current_position)/max((sphere_dist(current_position)+rect_dist(current_position)),1)+
            // vec4(0,1,0, 1)*diffuse*sphere_dist(current_position)/max((sphere_dist(current_position)+rect_dist(current_position)),1));

            return vec4[3](vec4(c.xyz, 1 ), vec4(current_position, 1), vec4(0,0,0, reflectivity));
           

        }

        
        
        num_steps ++;
        total_distance_traveled += distance_to_closest;
        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            reflectivity = min(max(fresnel_effect*smoothness, 0),1);
            break;
        }
    }

    //return skycolor
    vec4 temp;
    if(!refl){
        temp = textureLod(skybox, vec2(0.5+atan(rd.x, rd.z)*0.16, 0.5+asin(-rd.y)*0.32), 1);
         return vec4[3](temp, vec4(0), vec4(0,0,0,reflectivity));
    }
    else 
        temp = textureLod(skybox, vec2(0.5+atan(rd.x, rd.z)*0.16, 0.5+asin(-rd.y)*0.32), 1/min(1,reflectivity));//change mipmap level depending on reflectivity
    return vec4[3](temp, vec4(0), vec4(0,0,0,reflectivity));
}


void main() {   
    vec4 temp_color = vec4(0); 

    if(mod(pixel_coords.x, res) == 0 || mod(pixel_coords.y, res) == 0){
        vec4[3] temp = ray_march(orig+cam, dir, false, 0);
        temp_color = temp[0];
        float reflectivity = temp[2].w;
        for (int i = 0; i < num_reflections; i++){ 
            if(temp[1].w == 1){
                reflectivity*=temp[2].w;
                //blend reflected color and color based on reflecticity
                temp = ray_march(temp[1].xyz, dir, true, i);
                temp_color = temp_color*(1-reflectivity)+(temp[0]*reflectivity);
                
            }
        }
    }
    color = temp_color;
    
    imageStore(ftex, pixel_coords, color);
}

