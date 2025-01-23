shader_type canvas_item;

uniform vec4 top_left : source_color;
uniform vec4 top_right : source_color;
uniform vec4 bottom_left : source_color;
uniform vec4 bottom_right : source_color;

uniform float speed = 0.1;
uniform float amplitude = 0.1;

void fragment() {
	float offset_x = sin(TIME * speed) * amplitude;
	float offset_y = cos(TIME * speed) * amplitude;

	vec4 dynamic_top_left = top_left + vec4(offset_x, offset_y, 0.0, 0.0);
	vec4 dynamic_top_right = top_right + vec4(-offset_x, offset_y, 0.0, 0.0);
	vec4 dynamic_bottom_left = bottom_left + vec4(offset_x, -offset_y, 0.0, 0.0);
	vec4 dynamic_bottom_right = bottom_right + vec4(-offset_x, -offset_y, 0.0, 0.0);

	vec4 top = mix(dynamic_top_left, dynamic_top_right, UV.x);
	vec4 bottom = mix(dynamic_bottom_left, dynamic_bottom_right, UV.x);

	COLOR = mix(top, bottom, UV.y);
}
