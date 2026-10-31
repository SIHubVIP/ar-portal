shader_type spatial;
// Кроны, кусты и замшелые камни (0.18, рисованный стиль, D-060). Цвет — из экземпляра MultiMesh.
// Свет обёрнут (lambert_wrap): теневая сторона кроны не проваливается в черноту, а уходит
// в бирюзу окружения. Сверху крона светлее и теплее, снизу темнее и холоднее — как мазок
// кисти на референсах; мягкие пятна шума ломают гладкую сферу на «листовые» мазки.

render_mode diffuse_lambert_wrap, specular_disabled;

uniform float top_light = 0.24;
uniform float under_dark = 0.38;
uniform float speckle = 0.16;
// 0.23: крона между камерой и героем редеет сеткой точек — герой и дорога под ней видны
global uniform vec2 hero_screen;
global uniform float hero_depth;

varying vec3 wnormal;
varying vec3 wpos;

void vertex() {
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float blobs(vec3 p) {
	// гладкие пятна без сетки: сумма синусов под разными углами
	return 0.5 + 0.25 * sin(p.x * 1.7 + sin(p.y * 1.3)) * sin(p.z * 1.9 + sin(p.x * 1.1)) + 0.25 * sin(p.y * 2.3 + p.z * 0.7);
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void fragment() {
	if (!IN_SHADOW_PASS && -VERTEX.z < hero_depth - 1.0) {
		vec2 d = (SCREEN_UV - hero_screen) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float inside = 1.0 - smoothstep(0.16, 0.3, length(d));
		if (bayer4(FRAGCOORD.xy) > mix(1.0, 0.3, inside)) {
			discard;
		}
	}
	float up = wnormal.y;
	vec3 col = COLOR.rgb;
	col *= mix(1.0 - under_dark, 1.0, smoothstep(-0.6, 0.2, up));
	col = mix(col, col * vec3(1.2, 1.16, 0.92) + vec3(0.03, 0.03, 0.0), smoothstep(0.35, 0.95, up) * top_light / 0.32);
	col *= 1.0 - speckle + speckle * 2.0 * blobs(wpos);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	// просвет листвы против солнца
	BACKLIGHT = col * 0.35;
}
