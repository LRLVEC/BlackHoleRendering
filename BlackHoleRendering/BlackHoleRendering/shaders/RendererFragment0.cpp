#version 450 core
#define Pi 3.14159265359
#define R_s 1
#define um 0.6664
#define alpha_ratio 0.999
#define u_ratio_1 0.9999
#define Num 64
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
layout(binding = 1)uniform sampler2D texSmpCase1;
layout(binding = 2)uniform sampler2D texSmpCase2;
layout(binding = 3)uniform sampler1D texSmpCase2Edge;
out vec4 o_color;

vec2 map(vec2 p)
{
	return p * vec2(float(Num - 1) / Num) + vec2(1.0 / (2 * Num));
}

vec3 escapeDirectionColor(vec3 v0)
{
	float rr0 = length(r0);
	if (rr0 < 1)return vec3(0);

	float c = dot(r0, v0) / rr0;
	if (c > 0.999999)
		return texture(cubeSmp, v0).xyz;
	else if (c < -0.999999)
		return vec3(0);

	float u0 = 1 / rr0;
	float s2 = 1 - c * c;
	float e2 = (1 - u0) / (s2 * rr0 * rr0);
	float deltaPhi;
	if (e2 * 6.75 > 1)
	{
		if (c < 0)
			return vec3(0);
		//return vec3(1, 0, 0);
		float alpha = atan(sqrt(s2) * inversesqrt(1 - u0) / abs(c));
		float alpha_c = atan(inversesqrt(rr0 * rr0 / 6.25 + u0 - 1));
		float v = alpha / (alpha_c * alpha_ratio);

		//if (v > 63 / 64)
			//deltaPhi = texture(texSmpCase1, vec2(v, u0 / u_ratio_1)).x;
		//return vec3(abs(deltaPhi - acos(c)));
		deltaPhi = texture(texSmpCase1, map(vec2(v, u0 / u_ratio_1))).x;
		//deltaPhi = acos(c);
	}
	else
	{
		if (rr0 < 1.5)
			return vec3(0);
		//return vec3(1, 1, 0);
		float ua = (1 + 2 * sin(asin(13.5 * e2 - 1) / 3)) / 3;
		float phi0 = texture(texSmpCase2Edge, ua / um).x;
		float phi1 = texture(texSmpCase2, map(vec2(u0 / ua, ua / um ))).x;
		if (c > 0)
			deltaPhi = phi0 - phi1;
		else
			deltaPhi = phi0 + phi1;
		//return vec3(abs(deltaPhi-acos(c)));
		//deltaPhi = acos(c);
	}

	vec3 n = cross(r0, v0);
	vec3 y = normalize(cross(n, r0));
	vec3 x = r0 / rr0;
	return texture(cubeSmp, x * cos(deltaPhi) + y * sin(deltaPhi)).xyz;
	//return texture(cubeSmp, v0).xyz;
}

void main()
{
	vec3 n = normalize(trans * vec3(2 * gl_FragCoord.xy - size, z0));
	o_color = vec4(escapeDirectionColor(n), 1);

	//vec2 pos = gl_FragCoord.xy / vec2(size);
	//o_color = vec4(texture(texSmpCase2, map(pos)).x / (2.5 * Pi));
}
