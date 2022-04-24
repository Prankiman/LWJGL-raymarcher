#version 450 core

layout (local_size_x = 8, local_size_y = 4, local_size_z = 1) in;


layout (rgba32f, binding = 0)  writeonly uniform image2D ftex;
layout ( binding = 1)  uniform sampler2D skybox;

// uniform float xx;

float xx = 2;

uniform int fxaa;

uniform vec2 mouse_xy;

uniform vec3 orig;


vec2 sphere_xy = 2*vec2(((mouse_xy.x+90)/400-1), 2*((mouse_xy.y)/300-1));

vec2 cam_rot_xy= sphere_xy*0.1;

vec4 color;

mat3 roty = mat3(vec3(cos(cam_rot_xy.x), 0, sin(cam_rot_xy.x)), vec3(0, 1, 0),  vec3(-sin(cam_rot_xy.x), 0, cos(cam_rot_xy.x)));
mat3 rotx = mat3(vec3(1, 0, 0), vec3(0, cos(-cam_rot_xy.y), -sin(-cam_rot_xy.y)),  vec3( 0, sin(-cam_rot_xy.y), cos(-cam_rot_xy.y)));

vec3 pos = vec3(2+xx,0,2);//vec3(sphere_xy, 2);//sphere position

float rad = 1.2;//sphere radius

vec3 c = vec3(0.0, -1.0, 2.2);//rect position

vec3 s = vec3(2,2,2);//rect size

vec3 cam = vec3(0, 0, -5);
// vec3 orig = vec3(0, 0, -7);


ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
//normalized pixel coordiantes
float xu = (float(pixel_coords.x*2 - 1600)/1600/0.75);
float yu = 1-(float(pixel_coords.y*2 - 1200)/1200);

vec3 comp = vec3(xu, yu, -1);

vec3 dir = normalize(comp-cam)*rotx*roty;

vec3 light_position = vec3(-10,20, 0.5);

float globe_lum = 5;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sphere_dist(vec3 p){//distance function for spheres
	float displacement = 0;//sin((3) * p.x) * sin((3) * p.y) * sin((3) * p.z) * 0.15;
	p.xz = (mod((pos.xz-p.xz),4)-2);
    // p.y = (mod((p.y),6)-3);
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
    return smin(rect_dist(pos), sphere_dist(pos), 2);//fractalSDF(pos);//
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

vec4 ray_march(vec3 ro, vec3 rd)
{
    float total_distance_traveled = 0;
    float MINIMUM_HIT_DISTANCE = 0.001;
    float MAXIMUM_TRACE_DISTANCE = 40;
    int num_steps = 0;

    vec3 current_position;
    
    float distance_to_closest;
    vec3 normall = calculate_normal(ro);
    
    while(total_distance_traveled < MAXIMUM_TRACE_DISTANCE)
    {

        current_position = ro + (total_distance_traveled+0.1) * rd;

        distance_to_closest = dist(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
                
            vec3 normal = calculate_normal(current_position);

            vec3 direction_to_light = normalize(current_position- light_position);


            float diffuse = 0.3+max(0,dot(normal, direction_to_light));//diffuse lighting


            vec3 refl_dir =  rd-normall*2*dot(rd, normall);

            vec3 spec = vec3(0);//specular lighting


            vec4 c = 
            //blending color according to the relative distance between objects
            (vec4(1,0.5,0, 1)*diffuse*rect_dist(current_position)/max((sphere_dist(current_position)+rect_dist(current_position))*10,10)+
            vec4(0,1,0, 1)*diffuse*sphere_dist(current_position)/max((sphere_dist(current_position)+rect_dist(current_position))*10,10))*globe_lum;
            
            // color = vec4(current_position+vec3(0.5,0.5,0.5),1)*(vec4(20)/num_steps);
            
            
            return c;
           
        
             //TOON SHADING
            //----------------------------------
            // if (diffuse > 0.75)
            //     diffuse = 0.75;
            // else if (diffuse > 0.5)
            //     diffuse = 0.5;
            // else if (diffuse > 0.35)
            //     diffuse = 0.35;
            // else if (diffuse > 0.15)
            //     diffuse = 0.15;
            // else
            //     diffuse = 0;
            //------------------------------------

            //SHADING BASED ON NORMALS
            //---------------------------
            // vec4 color = diffuse/2+vec4(normal.x/min(normal.z, 0.1), normal.y/min(normal.z, 0.1),  normal.z*normal.z/2,1)*diffuse;

        }

       
        num_steps ++;
        total_distance_traveled += distance_to_closest;
        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            
           break;
        }
    }

    //GLOW EFFECT
    //-------------------------
    // if(0.03*(num_steps)>= 1)
    //     return  vec4(0,1,1,1);
    // if(0.01*(num_steps)>= 0.1)
    //     return  vec4(0,1,1,1)*vec4(0.001)*(min(1000,num_steps));
    //----------------------------------------

    //return skycolor

	return (texture(skybox, vec2(0.5+atan(rd.x, rd.z)*0.159154943092, 0.5+asin(-rd.y)*0.318309886184)));
}


void main() {    
    
    vec4 color = ray_march(orig+cam, dir);
    
    imageStore(ftex, pixel_coords, color);
}