#version 330 core

in vec4 passColor;

uniform float xx;

out vec4 color;

vec3 pos = vec3(2+xx, 0.0, 2);//sphere position

vec3 c = vec3(0, 0.0, 2.2);//rect position

vec3 s = vec3(1,1,1);//rect size

// vec3 sc = ivec2(tex);

vec3 cam = vec3(0, 0, -5);

float xu = (gl_FragCoord.x/400-1)/0.75;
float yu = 1-(gl_FragCoord.y/300);

vec3 comp = vec3(xu, yu, -1);

vec3 dir = normalize(comp-cam);

vec3 light_position = vec3(1.0, 1.0, 3.0);

float rad = 0.5;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sphere_dist(vec3 p){
	float displacement = 0;//sin((5+xx) * p.x) * sin((5+xx) * p.y) * sin((5.0+xx) * p.z) * 0.25;
	return length(pos-p)-rad+displacement;
}

float rect_dist (vec3 p)
{
    float x = max
    (   p.x - c.x - s.x/2,
        c.x - p.x - s.x/2
    );
    float y = max
    (   p.y - c.y - s.y/2,
        c.y - p.y - s.y/2
    );
    
    float z = max
    (   p.z - c.z - s.z/2,
        c.z - p.z - s.z/2
    );
    float d = x;
    d = max(d,y);
    d = max(d,z);
    return d;
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

float dist(vec3 pos){
    return smin(rect_dist(pos), sphere_dist(pos), 0.4);
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
    const float MINIMUM_HIT_DISTANCE = 0.01;
    const float MAXIMUM_TRACE_DISTANCE = 1000.0;

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


            return vec4(1.3, 0.5, 0.3, 1)*diffuse_intensity;
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
	color = ray_march(cam, dir);
}

