shader_type spatial;
// Здание между камерой и героем (D-046): в круге вокруг героя на экране стена вырезается
// сеткой Байера, по краю круга — плавно. Остаётся лёгкий «призрак» силуэта (ghost).
// Непрозрачный проход без сортировки: дешевле полупрозрачных копий в разы.
render_mode cull_back, depth_draw_opaque;

global uniform vec2 hero_screen;          // герой на экране, 0..1
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform bool triplanar = false;
uniform vec3 uv_scale = vec3(1.0);
uniform float roughness = 0.85;
uniform vec4 emission : source_color = vec4(0.0);
uniform float emission_energy = 0.0;
uniform float radius = 0.3;              // доля высоты экрана
uniform float ghost = 0.12;               // сколько пикселей стены остаётся внутри круга

varying vec3 wpos;
varying vec3 wnorm;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[i] + 0.5) / 16.0;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 d = (SCREEN_UV - hero_screen) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
	float inside = 1.0 - smoothstep(radius * 0.7, radius, length(d));
	float keep = mix(1.0, ghost, inside);
	if (bayer4(FRAGCOORD.xy) > keep) {
		discard;
	}
	vec4 c = albedo;
	if (use_tex) {
		if (triplanar) {
			vec3 w = pow(abs(wnorm), vec3(4.0));
			w /= (w.x + w.y + w.z);
			vec3 p = wpos * uv_scale;
			c *= texture(albedo_tex, p.zy) * w.x + texture(albedo_tex, p.xz) * w.y + texture(albedo_tex, p.xy) * w.z;
		} else {
			c *= texture(albedo_tex, UV * uv_scale.xy);
		}
	}
	ALBEDO = c.rgb;
	ROUGHNESS = roughness;
	EMISSION = emission.rgb * emission_energy;
}
