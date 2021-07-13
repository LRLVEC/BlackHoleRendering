#version 450 core
layout(location = 0)in vec2 position;
layout(std140, binding = 0)uniform Size
{
	uvec2 size;
};
void main()
{
	gl_Position = vec4(position, 0, 1);
}
