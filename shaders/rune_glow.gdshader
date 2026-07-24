shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

uniform vec4 glow_color : source_color = vec4(0.55, 0.15, 0.85, 1.0);
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;
uniform float base_energy : hint_range(0.0, 4.0) = 1.2;

void fragment() {
	float pulse = 0.55 + 0.45 * sin(TIME * pulse_speed);
	float edge = 1.0 - smoothstep(0.35, 0.5, distance(UV, vec2(0.5)));
	ALBEDO = glow_color.rgb;
	ALPHA = edge * pulse * glow_color.a;
	EMISSION = glow_color.rgb * base_energy * pulse;
}
