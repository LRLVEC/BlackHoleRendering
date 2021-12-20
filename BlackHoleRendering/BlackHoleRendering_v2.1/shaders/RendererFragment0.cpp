#version 450 core
#define Pi 3.14159265359
#define R_s 1
#define um 0.6664
#define alpha_ratio 0.999
#define u_ratio 0.9999
#define Num 256
#define offset (1.0 / (2 * Num))

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
layout(binding = 0)uniform samplerCube cubeSmp;
layout(binding = 1)uniform sampler2D texUnified;
layout(binding = 2)uniform sampler2D texSmpCase2;
layout(binding = 3)uniform sampler1D texPsim;
//layout(binding = 3)uniform sampler1D psim;
in vec4 gl_FragCoord;
out vec4 o_color;

float map(float p)
{
	return p * float(Num - 1) / Num + 1.0 / (2 * Num);
}
vec2 map(vec2 p)
{
	return p * vec2(float(Num - 1) / Num) + vec2(1.0 / (2 * Num));
}

float psi2(float x)
{
	float t = 0.0000166777;
	t = fma(t, x, -0.0000499505);
	t = fma(t, x, 0.0000596807);
	t = fma(t, x, -0.0000412057);
	t = fma(t, x, 1);
	return t;
}

float rand(vec2 a)
{
	return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 escapeDirectionColor(vec3 v0)
{
	float rr0 = length(r0);
	if (rr0 * u_ratio < 1)return vec3(0);

	float c = dot(r0, v0) / rr0;
	if (c > 0.999999)
		return texture(cubeSmp, v0).xyz;
	else if (c < -0.999999)
		return vec3(0);

	float u0 = 1 / rr0;

	float u0r = u0 / u_ratio;
	float x = 2 * acos(u0) / Pi;
	float xr = 2 * acos(u0r) / Pi;
	float psim = texture(texPsim, map(x)).x;
	float psi = acos(c);
	float psi2u = psi2(u0);
	if (psi > psi2u * psim)return vec3(0);
	float y = atanh(psi / psim) / atanh(psi2u);
	float deltaPhi = texture(texUnified, map(vec2(y, xr))).x;


	vec3 n = cross(r0, v0);
	vec3 y0 = normalize(cross(n, r0));
	vec3 x0 = r0 / rr0;
	return texture(cubeSmp, x0 * cos(deltaPhi) + y0 * sin(deltaPhi)).xyz;
}

void main()
{
	int c0 = 0;
	vec3 color = vec3(0);
	vec2 deltaXY;
	deltaXY.y = gl_FragCoord.y - 0.375;
	for (; c0 < 4; ++c0)
	{
		deltaXY.x = gl_FragCoord.x - 0.375;
		int c1 = 0;
		for (; c1 < 4; ++c1)
		{
			vec3 n = normalize(trans * vec3(2 * deltaXY - size, z0));
			color += escapeDirectionColor(n);
			deltaXY.x += 0.25;
		}
		deltaXY.y += 0.25;
	}

	o_color = vec4(color * (2.0 / 16), 1);

	//vec3 n = normalize(trans * vec3(2 * gl_FragCoord.xy - size, z0));
	//o_color = vec4(escapeDirectionColor(n), 1);

	//vec2 pos = (gl_FragCoord.xy - vec2(0.5)) / vec2(size);
	//o_color = vec4(1*texture(texUnified, vec2(0.00, 0.8)).x);
}
