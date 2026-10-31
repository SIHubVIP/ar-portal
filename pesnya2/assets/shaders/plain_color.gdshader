shader_type spatial;
// Простые цветные детали без текстур (0.10): цвет — из вершин или экземпляра MultiMesh,
// альфа — «не свечение»: 1 — матовая краска, 0 — горит в полную силу (лампы, неон).
// Один материал на все такие детали — один вызов отрисовки на участок или вывеску.
// 0.11: детали домов вырезаются вместе с домом (cut — дом в коридоре камеры, depth_cut —
// всё, что ближе героя к камере, для MultiMesh мелких домов).

// 0.24: bevel_box — единичный куб MultiMesh становится мягкой коробкой (soft_bevel)
render_mode diffuse_lambert_wrap;
#include "res://assets/shaders/soft_bevel.gdshaderinc"
uniform bool bevel_box = false;
uniform float bevel = 0.07;
uniform float roughness_value = 0.75;
uniform float glow = 4.0;
uniform bool cut = false;
uniform bool depth_cut = false;
global uniform vec2 hero_screen;
global uniform float hero_depth;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

varying float pc_wy;

void vertex() {
	SOFT_BOX_VERTEX
	pc_wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (cut || depth_cut) {
		vec2 d = (SCREEN_UV - hero_screen) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float inside = 1.0 - smoothstep(0.3 * 0.7, 0.3, length(d));
		bool near = cut || -VERTEX.z < hero_depth - 0.8;
		if (near && bayer4(FRAGCOORD.xy) > mix(1.0, 0.12, inside)) {
			discard;
		}
	}
	// 0.24: контакт с землёй — низ любой детали мягко темнеет (машины, ящики, лавки)
	ALBEDO = COLOR.rgb * mix(0.72, 1.0, smoothstep(0.0, 0.55, pc_wy));
	RIM = 0.22;
	RIM_TINT = 0.4;
	if (bevel_box) {
		float shade;
		float edge;
		NORMAL = soft_box_normal(SOFT_BOX_ARGS, vec3(1.0), bevel, MODEL_MATRIX, VIEW_MATRIX, shade, edge);
		ALBEDO *= shade * (1.0 + 0.06 * edge);
	}
	ROUGHNESS = roughness_value;
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * glow;
}
