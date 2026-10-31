shader_type spatial;
// Человечек из npc_body.glb: зона — в красном канале цвета вершин (номер / 8), цвета зон —
// параметры материала. Один материал на облик, одна поверхность на кусок тела.

uniform vec3 skin : source_color = vec3(0.86, 0.7, 0.58);
uniform vec3 top : source_color = vec3(0.5, 0.2, 0.25);
uniform vec3 bottom : source_color = vec3(0.2, 0.22, 0.3);
uniform vec3 hair : source_color = vec3(0.2, 0.14, 0.1);
uniform vec3 shoes : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 mouth : source_color = vec3(0.55, 0.18, 0.18);
uniform float emission = 0.0;

void fragment() {
	int z = int(floor(COLOR.r * 8.0));
	vec3 c = skin;
	float rough = 0.8;
	if (z == 1) { c = top; }
	else if (z == 2) { c = bottom; }
	else if (z == 3) { c = hair; rough = 0.6; }
	else if (z == 4) { c = shoes; rough = 0.4; }
	else if (z == 5) { c = vec3(0.95); rough = 0.2; }
	else if (z == 6) { c = vec3(0.04, 0.03, 0.03); rough = 0.1; }
	else if (z == 7) { c = mouth; }
	ALBEDO = c;
	ROUGHNESS = rough;
	EMISSION = c * emission;
}
