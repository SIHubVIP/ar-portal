shader_type spatial;
// Фасад дома района (0.11, макет «Рубин»): окна по сетке этажей в мировых координатах —
// белые рамы, подоконники, занавески, часть окон горит тёплым вечерним светом. Стена —
// кирпич (ряды и швы) или штукатурка (пятна, потёки, грязь у цоколя). Цвет стены — из
// вершин или экземпляра MultiMesh (use_color), иначе uniform wall. Текстуры не нужны.

uniform vec3 wall : source_color = vec3(0.55, 0.36, 0.3);
uniform bool use_color = false;
uniform bool use_custom = false;     // MultiMesh: цвет стены — данные экземпляра (детали не красятся)
uniform bool brick = false;
uniform bool shops = false;          // первый этаж — витрины (улица), иначе обычные окна
uniform float floor_h = 3.0;
uniform float bay_w = 2.6;
uniform float lit_share = 0.36;
uniform float plinth_h = 0.6;
// «house_cut»: дом между камерой и героем вырезается кругом (see_through.gdshader)
uniform bool cut = false;
// мелкие дома в MultiMesh: вырез только того, что ближе героя к камере, всегда включён
uniform bool depth_cut = false;
global uniform vec2 hero_screen;
global uniform float hero_depth;

varying vec3 wpos;
varying vec3 wnorm;
varying vec3 base;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	base = use_custom ? INSTANCE_CUSTOM.rgb : (use_color ? COLOR.rgb : wall);
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void fragment() {
	vec2 sd = (SCREEN_UV - hero_screen) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
	float inside = 1.0 - smoothstep(0.3 * 0.7, 0.3, length(sd));
	if (cut && bayer4(FRAGCOORD.xy) > mix(1.0, 0.12, inside)) {
		discard;
	}
	if (depth_cut && -VERTEX.z < hero_depth - 0.8 && bayer4(FRAGCOORD.xy) > mix(1.0, 0.12, inside)) {
		discard;
	}
	vec3 col = base;
	float rough = 0.9;
	if (abs(wnorm.y) < 0.5) {
		bool along_z = abs(wnorm.x) > 0.5;
		float u = along_z ? wpos.z : wpos.x;
		float facade = floor(along_z ? wpos.x : wpos.z);
		// стена: кирпич рядами 0.25 м со швами или штукатурка с пятнами
		if (brick) {
			float row = floor(wpos.y / 0.25);
			float bu = u / 0.5 + 0.5 * mod(row, 2.0);
			float seam = step(0.9, fract(wpos.y / 0.25)) + step(0.94, fract(bu));
			col *= 0.85 + 0.3 * hash(vec2(floor(bu), row));
			col = mix(col, vec3(0.62, 0.58, 0.52), clamp(seam, 0.0, 1.0) * 0.55);
		} else {
			float n = noise(vec2(u, wpos.y) * 0.35) * 0.6 + noise(vec2(u, wpos.y) * 1.7) * 0.4;
			col *= 0.82 + 0.3 * n;
			// потёки под карнизом и у водостоков
			col *= 1.0 - 0.18 * smoothstep(0.6, 1.0, noise(vec2(u * 3.0, wpos.y * 0.15)));
		}
		// грязь и цоколь
		col *= mix(0.62, 1.0, smoothstep(0.0, 1.2, wpos.y));
		if (wpos.y < plinth_h) {
			col = vec3(0.36, 0.34, 0.32) * (0.85 + 0.3 * noise(vec2(u, wpos.y) * 2.0));
		}
		vec2 cell = vec2(floor(u / bay_w), floor(wpos.y / floor_h));
		vec2 f = vec2(fract(u / bay_w), fract(wpos.y / floor_h));
		float h = hash(cell + vec2(facade * 0.37, facade * 1.13));
		bool ground = cell.y < 0.5;
		if (ground && shops) {
			// первый этаж у улицы: широкая витрина, у каждой пятой неон
			if (f.x > 0.08 && f.x < 0.92 && f.y > 0.12 && f.y < 0.8) {
				col = vec3(0.05, 0.06, 0.08);
				rough = 0.15;
				if (h < 0.35) {
					col = vec3(1.0, 0.8, 0.5) * 0.3;
					EMISSION = vec3(1.0, 0.78, 0.45) * 1.2;
				} else if (h < 0.45) {
					EMISSION = mix(vec3(1.0, 0.2, 0.6), vec3(0.2, 0.9, 1.0), step(0.4, h)) * 2.2;
				}
			}
		} else if (wpos.y > plinth_h + 0.4) {
			// окно: рама 6 см, подоконник, внутри — стекло, занавески или свет
			float x0 = 0.24, x1 = 0.76, y0 = 0.28, y1 = 0.8;
			if (f.x > x0 - 0.03 && f.x < x1 + 0.03 && f.y > y0 - 0.035 && f.y < y1 + 0.02) {
				col = vec3(0.86, 0.84, 0.8);
				rough = 0.6;
				if (f.y < y0 - 0.01) {
					col = vec3(0.55, 0.53, 0.5);       // подоконник
				}
				bool glass = f.x > x0 && f.x < x1 && f.y > y0 && f.y < y1 && abs(f.x - 0.5) > 0.012
						&& abs(f.y - 0.62) > 0.012;
				if (glass) {
					rough = 0.12;
					float lit = step(h, lit_share);
					float curtain = hash(cell * 2.3 + facade);
					vec3 inner = curtain < 0.5 ? vec3(1.0, 0.74, 0.42) : (curtain < 0.75 ? vec3(1.0, 0.55, 0.35)
							: vec3(0.95, 0.86, 0.62));
					// занавески по краям
					float drape = step(abs(f.x - 0.5), 0.17);
					if (lit > 0.5) {
						col = inner * mix(0.55, 0.3, drape);
						EMISSION = inner * mix(1.6, 0.9, drape) * (0.85 + 0.3 * curtain);
					} else {
						col = mix(vec3(0.1, 0.12, 0.15), vec3(0.26, 0.22, 0.2) * (0.7 + curtain), drape * 0.8);
						EMISSION = vec3(0.35, 0.4, 0.5) * 0.04;
					}
				}
			}
		}
	}
	ALBEDO = col;
	ROUGHNESS = rough;
}
