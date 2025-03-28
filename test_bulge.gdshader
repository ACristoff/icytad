shader_type spatial;

uniform float wave_width : hint_range(0.0, 1.0) = 0.1;
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.2;
uniform float wave_speed : hint_range(0.0, 10.0) = 1.0;

void vertex() {
    // Wave position changes over time, now spanning the full range
    float wave_position = fract(TIME * wave_speed) * 2.0 - 1.0;
    
    // Calculate the distance from the wave center
    float distance_from_wave = abs(VERTEX.x - wave_position);
    
    // Create a smooth falloff for the bulge
    float wave_falloff = 1.0 - smoothstep(0.0, wave_width, distance_from_wave);
    
    // Calculate bulge displacement
    vec3 bulge_displacement = NORMAL * wave_amplitude * wave_falloff;
    
    // Apply displacement
    VERTEX += bulge_displacement;
}