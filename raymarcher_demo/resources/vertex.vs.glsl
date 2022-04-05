#version 450 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texture;
// layout (location = 1) in vec4 color;


out vec2 texCoord;
// out vec4 passColor;

void main() {
	gl_Position = vec4(position, 1);
	texCoord = texture;
	// passColor = color;
}