shader_type canvas_item;

// This uniform is animated by the Tween in GDScript from 0.0 to 1.0
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Textures for creating the dissolve effect
uniform sampler2D noise_texture;

// --- Burn Effect Customization ---
uniform vec4 glow_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform float edge_width : hint_range(0.0, 0.5) = 0.06;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.2;
uniform float dissolve_softness : hint_range(0.0, 1.0) = 0.25;

void fragment() {
    // Get the original color and alpha from the logo's texture
    vec4 original_color = texture(TEXTURE, UV);

    // If the original pixel is mostly transparent, discard it immediately.
    // This is the key change to make the burn follow the logo's shape.
    if (original_color.a < 0.1) {
        discard;
    }

    // Get the noise value to determine the dissolve pattern
    float noise_value = texture(noise_texture, UV).r;

    // Determine the burn threshold, adding softness
    float burn_threshold = smoothstep(0.0, 1.0 - dissolve_softness, progress);

    // If the noise value is less than our progress, the pixel is "dissolved"
    if (noise_value < burn_threshold) {
        discard; // Discard the pixel to make it fully transparent
    }

    // --- Glow Effect ---
    // Calculate where the glowing edge should be
    float glow_threshold = burn_threshold + edge_width;
    
    // Check if the current pixel is within the glow band
    if (noise_value < glow_threshold) {
        // Calculate how deep into the glow band we are
        float glow_factor = 1.0 - smoothstep(burn_threshold, glow_threshold, noise_value);
        
        // Mix the original color with the glow color based on the factor and intensity
        vec3 final_rgb = mix(original_color.rgb, glow_color.rgb, glow_factor * glow_intensity);
        COLOR = vec4(final_rgb, original_color.a);
    } else {
        // If not dissolved and not glowing, just show the original color
        COLOR = original_color;
    }
}