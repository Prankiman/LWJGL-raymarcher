#version 330 core

in vec4 passColor;

uniform float xx;

uniform vec2 mouse_xy;

uniform vec3 orig;

vec2 sphere_xy = 2*vec2(((mouse_xy.x+orig.x*200)/400-1), 2*((mouse_xy.y+orig.y*150)/300-1));

vec2 cam_rot_xy= sphere_xy*0.2;

out vec4 color;

mat3 roty = mat3(vec3(cos(cam_rot_xy.x), 0, sin(cam_rot_xy.x)), vec3(0, 1, 0),  vec3(-sin(cam_rot_xy.x), 0, cos(cam_rot_xy.x)));
mat3 rotx = mat3(vec3(1, 0, 0), vec3(0, cos(cam_rot_xy.y*-1), -sin(cam_rot_xy.y*-1)),  vec3( 0, sin(cam_rot_xy.y*-1), cos(cam_rot_xy.y*-1)));

vec3 pos = vec3(2+xx,0,2);//vec3(sphere_xy, 2);//sphere position

float rad = 0.35;//sphere radius

vec3 c = vec3(0.0, 0.0, 2.2);//rect position

vec3 s = vec3(1,1,1);//rect size


vec3 cam = vec3(0, 0, -5);
// vec3 orig = vec3(0, 0, -7);

//normalized pixel coordiantes
float xu = (gl_FragCoord.x/400-1)/0.75;
float yu = 1-(gl_FragCoord.y/300);

vec3 comp = vec3(xu, yu, -1);

vec3 dir = normalize(comp-cam)*rotx*roty;

vec3 light_position = vec3(0, 6, 6.0);

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sphere_dist(vec3 p){//distance function for spheres
	float displacement = 0;//sin((5) * p.x) * sin((5) * p.y) * sin((5.0) * p.z) * 0.25;
	return length(pos-p)-rad+displacement;
}

float fractalSDF(vec3 pos) {
	vec3 z = pos*rotx*roty;
	float dr = 20;
	float r;
    float Power = 4, Iterations = 2000, Bailout = 200;
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
    
    vec3 t = c*roty;
    vec3 t2 = p*roty;

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
    return smin(rect_dist(pos), sphere_dist(pos), 0.9);//fractalSDF(pos);
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
    const float MINIMUM_HIT_DISTANCE = 0.0001;
    const float MAXIMUM_TRACE_DISTANCE = 1000;

    while(total_distance_traveled < MAXIMUM_TRACE_DISTANCE)
    {
        vec3 current_position = ro + total_distance_traveled * rd;

        float distance_to_closest = dist(current_position);

        if (distance_to_closest <= MINIMUM_HIT_DISTANCE) 
        {
            
            vec3 normal = calculate_normal(current_position);
            vec3 direction_to_light = normalize(current_position - light_position);

            float diffuse_intensity = max(0.06, dot(normal, direction_to_light));


            //TOON SHADING

            //----------------------------------
            // if (diffuse_intensity > 0.75)
            //     diffuse_intensity = 0.75;
            // else if (diffuse_intensity > 0.5)
            //     diffuse_intensity = 0.5;
            // else if (diffuse_intensity > 0.35)
            //     diffuse_intensity = 0.35;
            // else if (diffuse_intensity > 0.15)
            //     diffuse_intensity = 0.15;
            // else
            //     diffuse_intensity = 0;
            //------------------------------------

            // vec4 color = (vec4(2,2,0, 1)*diffuse_intensity*rect_dist(current_position)/max(sphere_dist(current_position)+rect_dist(current_position),0.001)+//blending according to the relative distance between objects
            //     vec4(0.9, 1, 1.2, 1)*diffuse_intensity*sphere_dist(current_position)/max(rect_dist(current_position)+sphere_dist(current_position),0.001));

            vec4 color = diffuse_intensity/2+vec4(normal.x/min(normal.z, 0.1), normal.y/min(normal.z, 0.1),  normal.z*normal.z/2,1)*diffuse_intensity;
            return color;
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
           break;
        }
        total_distance_traveled += distance_to_closest;
    }
	return vec4(0);
}


void main() {
	color = ray_march(orig, dir);
}

