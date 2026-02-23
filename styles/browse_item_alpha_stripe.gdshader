shader_type canvas_item;

uniform float row_height_px = 34.0;
uniform float viewport_height_px = 34.0;
uniform float scroll_offset_px = 0.0;
uniform float dark_row_alpha = 0.0;
uniform float light_row_alpha = 0.2;

void fragment() {
	float safe_row_height = max(row_height_px, 1.0);
	float content_y = (UV.y * viewport_height_px) + scroll_offset_px;
	float row_index = floor(content_y / safe_row_height);

	bool is_dark_row = mod(row_index, 2.0) < 1.0;

	float row_alpha = is_dark_row ? dark_row_alpha : light_row_alpha;
	COLOR.a *= row_alpha;
}
