shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.6, 0.05, 0.1, 1.0);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float vignette = smoothstep(0.25, 0.85, length(centered));
	float alpha = vignette * intensity;
	COLOR = vec4(tint.rgb, alpha);
}
