shader_type spatial;
// Дом района ночью: окна по сетке этажей в мировых координатах, часть горит тёплым
// или холодным светом, на первом этаже — редкие неоновые витрины. Одна текстура не нужна.

uniform vec3 wall : source_color = vec3(0.55, 0.36, 0.3);
uniform float floor_h = 3.0;
uniform float bay_w = 2.6;
uniform float lit_share = 0.33;

varying vec3 wpos;
varying vec3 wnorm;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	ALBEDO = wall;
	ROUGHNESS = 0.85;
	if (abs(wnorm.y) < 0.5) {
		bool along_z = abs(wnorm.x) > 0.5;
		float u = along_z ? wpos.z : wpos.x;
		float facade = floor(along_z ? wpos.x : wpos.z);
		vec2 cell = vec2(floor(u / bay_w), floor(wpos.y / floor_h));
		vec2 f = vec2(fract(u / bay_w), fract(wpos.y / floor_h));
		float h = hash(cell + vec2(facade * 0.37, facade * 1.13));
		if (cell.y < 0.5) {
			// первый этаж: широкая витрина, у каждой пятой неон
			if (f.x > 0.08 && f.x < 0.92 && f.y > 0.12 && f.y < 0.8) {
				ALBEDO = vec3(0.05, 0.06, 0.08);
				ROUGHNESS = 0.15;
				if (h < 0.2) {
					vec3 neon = mix(vec3(1.0, 0.2, 0.6), vec3(0.2, 0.9, 1.0), step(0.1, h));
					EMISSION = neon * 2.2;
				}
			}
		} else if (f.x > 0.25 && f.x < 0.75 && f.y > 0.3 && f.y < 0.78) {
			ALBEDO = vec3(0.06, 0.07, 0.1);
			ROUGHNESS = 0.2;
			if (h < lit_share) {
				vec3 c = mix(vec3(1.0, 0.72, 0.38), vec3(0.62, 0.8, 1.0), step(0.8, hash(cell * 1.7 + facade)));
				ALBEDO = c * 0.25;
				EMISSION = c * 1.5;
			}
		}
	}
}
