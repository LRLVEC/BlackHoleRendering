#version 450 core
#define Pi 3.14159265359

layout(std140, binding = 0)uniform Size
{
	uvec2 size;
};
layout(std140, row_major, binding = 1)uniform Trans
{
	mat3 trans;
	vec3 r0;
	float z0;
	float times;
};
layout(binding = 2)uniform samplerCube cubeSmp;

out vec4 o_color;

void main()
{
	vec3 n = normalize(trans * vec3(2 * gl_FragCoord.xy - size, z0));
	o_color = vec4(texture(cubeSmp, n).xyz, 1);
}
