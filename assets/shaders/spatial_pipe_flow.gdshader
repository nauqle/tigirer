// spatial_pipe_flow.gdshader
// FloraLab 2.5D çiftlik: sulama borusu. Boru gövdesi koyu metal; içinden dünya X ekseni boyunca akan aydınlık su damlacıkları
// emisyonla gösterilir. `flow_speed` = 0 ise (hareketi azalt) damlacıklar durur.
shader_type spatial;
render_mode cull_back;

uniform vec3 water : source_color = vec3(0.30, 0.78, 1.0);
uniform float flow_speed = 0.32;
// Damlacık sıklığı (dünya birimi başına) ve parlaklıkları.
uniform float dots_per_unit = 1.6;
uniform float base_glow = 0.30;
uniform float dot_glow = 1.1;

// 0 = su dünya X ekseni boyunca akar (yatay boru), 1 = Y ekseni boyunca (dikey yükseltici).
uniform int axis = 0;

varying float along_axis;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	along_axis = axis == 0 ? world.x : -world.y;
}

void fragment() {
	float band = fract(along_axis * dots_per_unit - TIME * flow_speed);
	float dots = smoothstep(0.0, 0.10, band) * (1.0 - smoothstep(0.10, 0.28, band));
	ALBEDO = vec3(0.10, 0.20, 0.26);
	METALLIC = 0.55;
	ROUGHNESS = 0.32;
	EMISSION = water * (base_glow + dot_glow * dots);
}
