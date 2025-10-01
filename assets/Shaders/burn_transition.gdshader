shader_type canvas_item;
// Burn transition shader (fixed logic)
// progress: 0 = old scene fully visible, 1 = new scene fully revealed

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.06;
uniform float distortion_amount : hint_range(0.0, 10.0) = 2.0;
uniform float distortion_scale : hint_range(0.1, 8.0) = 3.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.2;
uniform float dissolve_softness : hint_range(0.0, 1.0) = 0.25;
uniform vec2 noise_scroll = vec2(0.2, 0.0);

uniform sampler2D noise_texture : repeat_enable;
uniform sampler2D prev_scene_texture; // captured old scene
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture; // new scene below

void fragment() {
    // Sample and animate noise
    vec2 burn_uv = UV + noise_scroll * progress;
    float n = texture(noise_texture, burn_uv).r;

    // Distort only old scene portion for heat effect
    vec2 distort_sample_uv = UV + (texture(noise_texture, UV * distortion_scale).rg - 0.5) * (distortion_amount * (1.0 - progress)) / 450.0;
    distort_sample_uv = clamp(distort_sample_uv, vec2(0.0), vec2(1.0));

    vec4 old_col = texture(prev_scene_texture, distort_sample_uv);
    vec4 new_col = texture(SCREEN_TEXTURE, SCREEN_UV);

    // Threshold for burn front: we invert so as progress increases more NEW scene is revealed
    // progress 0 => threshold 1.0 (nothing revealed yet)
    // progress 1 => threshold 0.0 (everything revealed)
    float threshold = 1.0 - progress;
    float softness = max(1e-4, dissolve_softness * 0.5);

    // Mask: 0 = old, 1 = new
    float mask = smoothstep(threshold - softness, threshold + softness, n);

    // Edge detection centered around threshold
    float edge = smoothstep(threshold - edge_width, threshold, n) - smoothstep(threshold, threshold + edge_width, n);

    // Blend old to new
    vec4 col = mix(old_col, new_col, mask);

    // Add glow (fades out as progress nears completion)
    col.rgb += glow_color.rgb * edge * glow_intensity * (1.0 - progress);

    // Subtle char / darkening just behind edge
    float char_band = smoothstep(threshold - edge_width * 0.6, threshold - edge_width * 0.15, n) * (1.0 - progress);
    col.rgb = mix(col.rgb * 0.85, col.rgb, 1.0 - char_band * 0.6);

    COLOR = col;
}
