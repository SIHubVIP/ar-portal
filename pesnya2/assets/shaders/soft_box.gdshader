shader_type spatial;
// Предметы из коробок (Kit.box, 0.24): сетка со скруглёнными рёбрами (SoftMesh), тёплый обволакивающий
// свет (lambert_wrap) и холодный контровой блик — мультяшный объём без текстур.
// cut — вырез вокруг героя, как у домов района (IsoCamera.cut_material включает его).
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

#include "res://assets/shaders/soft_bevel.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness_value = 0.62;
uniform float rim = 0.32;
uniform bool cut = false;
instance uniform vec3 box_size = vec3(1.0);
global uniform vec2 hero_screen;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void vertex() {
	SOFT_BOX_VERTEX
}

void fragment() {
	if (cut) {
		vec2 d = (SCREEN_UV - hero_screen) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float inside = 1.0 - smoothstep(0.3 * 0.7, 0.3, length(d));
		if (bayer4(FRAGCOORD.xy) > mix(1.0, 0.12, inside)) {
			discard;
		}
	}
	// скругление уже в сетке (SoftMesh.box_mesh): здесь только объём цвета
	ALBEDO = albedo.rgb * soft_box_shade(sb_lpos, sb_scl, box_size, sb_lnorm.y);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.35;
	RIM = rim;
	RIM_TINT = 0.4;
}
