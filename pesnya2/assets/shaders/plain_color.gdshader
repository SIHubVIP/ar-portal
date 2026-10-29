shader_type spatial;
// Простые цветные детали без текстур (0.10): цвет — из вершин или экземпляра MultiMesh,
// альфа — «не свечение»: 1 — матовая краска, 0 — горит в полную силу (лампы, неон).
// Один материал на все такие детали — один вызов отрисовки на участок или вывеску.

uniform float roughness_value = 0.75;
uniform float glow = 4.0;

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = roughness_value;
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * glow;
}
