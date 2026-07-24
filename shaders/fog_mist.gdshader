shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled;

uniform vec4 mist_color : source_color = vec4(0.55, 0.6, 0.75, 1.0);
uniform float speed : hint_range(0.0, 1.0) = 0.05;
uniform float density : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV * 3.0 + vec2(TIME * speed, TIME * speed * 0.4);
	float n = noise(uv) * 0.6 + noise(uv * 2.1 + 5.0) * 0.4;
	float edge = smoothstep(0.0, 0.4, UV.y) * smoothstep(1.0, 0.6, UV.y);
	ALBEDO = mist_color.rgb;
	ALPHA = n * density * edge;
}
