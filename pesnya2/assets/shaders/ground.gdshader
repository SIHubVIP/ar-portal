shader_type spatial;
// Земля района без повторов (0.16): текстура берётся дважды — по сетке и повёрнутой
// на 37° с другим масштабом — и смешивается по пятнам шума, поэтому клетка 4 × 4 м
// больше не читается рядами. Сверху крупные пятна светлее/темнее и цветные проплешины:
// на газоне — пожухлая трава и голая земля, на асфальте — заплатки и пыль.
// Проекция сверху в мировых координатах: швы не зависят от размера дороги.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 patch_color : source_color = vec4(1.0);
uniform float patch_amount = 0.0;
uniform float tile = 4.0;
uniform float macro = 0.26;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = wpos.xz / tile;
	vec2 uv2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * uv * 0.77 + vec2(0.37, 0.71);
	float blend = smoothstep(0.3, 0.7, vnoise(wpos.xz * 0.07));
	vec3 col = mix(texture(albedo_tex, uv).rgb, texture(albedo_tex, uv2).rgb, blend);
	float m = vnoise(wpos.xz * 0.013) * 0.6 + vnoise(wpos.xz * 0.09) * 0.4;
	col *= mix(1.0 - macro, 1.0 + macro, m);
	float p = smoothstep(0.55, 0.8, vnoise(wpos.xz * 0.035 + vec2(17.0, 5.0)));
	col = mix(col, col * patch_color.rgb, p * patch_amount);
	// вторая россыпь пятен — холоднее и темнее: тень от деревьев, сырость
	float q = smoothstep(0.6, 0.85, vnoise(wpos.xz * 0.05 + vec2(-31.0, 47.0)));
	col = mix(col, col * vec3(0.82, 0.9, 0.86), q * patch_amount * 0.6);
	ALBEDO = col * tint.rgb;
	NORMAL_MAP = mix(texture(normal_tex, uv).rgb, texture(normal_tex, uv2).rgb, blend);
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
