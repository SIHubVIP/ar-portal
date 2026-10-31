// Мягкая «мультяшная» коробка (0.24, D-067): скруглённые грани без лишней геометрии.
// Нормаль у ребра плавно наклоняется наружу — на гранях появляется светлый скат, как у
// настоящей фаски; низ слегка темнеет (контакт с землёй), бока — лёгкий градиент к верху.
// Работает по локальной позиции вершины: коробка BoxMesh (box_size — её размер) или
// единичный куб MultiMesh, растянутый матрицей экземпляра (box_size = 1).

// Варьинги пишутся только в самих vertex()/fragment() (функциям Godot это запрещает):
// в vertex() — SOFT_BOX_VERTEX, в fragment() — SOFT_BOX_ARGS при вызове soft_box_normal.

varying vec3 sb_lpos;
varying vec3 sb_lnorm;
varying vec3 sb_scl;

#define SOFT_BOX_VERTEX sb_lpos = VERTEX; sb_lnorm = NORMAL; sb_scl = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
#define SOFT_BOX_ARGS sb_lpos, sb_lnorm, sb_scl

// Возвращает нормаль в пространстве камеры; shade — множитель цвета (затенение низа и градиент).
vec3 soft_box_normal(vec3 lpos, vec3 lnorm, vec3 lscl, vec3 size, float radius, mat4 model, mat4 view, out float shade, out float edge) {
	vec3 scl = max(lscl, vec3(1e-4));
	vec3 p = lpos * scl;
	vec3 h = 0.5 * size * scl;
	vec3 an = abs(lnorm);
	float r = min(radius, 0.45 * min(h.x, min(h.y, h.z)));
	vec3 d = max(h - abs(p), vec3(0.0));
	vec3 w = 1.0 - smoothstep(vec3(0.0), vec3(max(r, 1e-3)), d);
	w *= w * (1.0 - step(0.5, an));    // только по осям, лежащим в плоскости грани
	vec3 ln = sign(lnorm) * step(0.5, an) + sign(p) * w * 0.85;
	edge = max(w.x, max(w.y, w.z));
	// нормаль локального пространства в мировое: обратно-транспонированная модельная
	vec3 wn = mat3(model) * (ln / (scl * scl));
	float hy = 2.0 * h.y;
	float y = p.y + h.y;                     // высота над низом коробки, м
	float ao = mix(0.7, 1.0, smoothstep(0.0, min(0.55, hy * 0.6), y));
	float grad = mix(0.9, 1.04, clamp(y / max(hy, 1e-3), 0.0, 1.0));
	shade = (an.y > 0.5) ? 1.0 : ao * grad;
	return normalize((view * vec4(wn, 0.0)).xyz);
}

// Только затенение (для сеток, где скругление уже в геометрии — SoftMesh): низ темнее, бока
// с градиентом к верху; ny — локальная нормаль по вертикали (верх не трогаем).
float soft_box_shade(vec3 lpos, vec3 lscl, vec3 size, float ny) {
	vec3 scl = max(lscl, vec3(1e-4));
	float hy = size.y * scl.y;
	float y = lpos.y * scl.y + 0.5 * hy;
	float ao = mix(0.7, 1.0, smoothstep(0.0, min(0.55, hy * 0.6), y));
	float grad = mix(0.9, 1.04, clamp(y / max(hy, 1e-3), 0.0, 1.0));
	return mix(ao * grad, 1.0, smoothstep(0.6, 0.95, ny));
}
