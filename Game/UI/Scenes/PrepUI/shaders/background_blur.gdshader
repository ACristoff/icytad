// Declares this as a 2D shader to be used with CanvasItem nodes (sprites, UI elements, etc.)
shader_type canvas_item;

// Creates a uniform variable that accesses the current screen content
// hint_screen_texture: Special hint telling Godot this is the screen texture
// filter_linear_mipmap: Enables linear filtering and mipmapping for smoother sampling
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

// Creates a uniform float variable that controls the level of detail (mipmap level)
// hint_range(0.0, 5): Restricts the value between 0.0 and 5.0 in the inspector
// = 0.0: Sets the default value to 0.0 (highest detail)
uniform float lod: hint_range(0.0, 5) = 0.0;

// The fragment function runs for every pixel this shader affects
// This is the main processing function for pixel shaders
void fragment()
{
    // Samples a color from the screen texture at the current pixel's UV coordinates
    // SCREEN_UV: Built-in variable representing the current pixel's position on screen (0-1 range)
    // lod: The third parameter controls which mipmap level to sample from (higher = blurrier)
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
    
    // Sets the output color of this pixel to the sampled color
    // COLOR is a special output variable that determines the final pixel color
    COLOR = color;
}
