package engine

import sdl "vendor:sdl2"
import "vendor:sdl2/image"
import "vendor:sdl2/ttf"

Sprite :: struct {
    texture: ^sdl.Texture,
    transform: sdl.Rect,

    // A position float vector needs to be defined for more precise movement which is not limited to just integers
    // For example, if an entity moves 1.5 pixels and then 1.5 pixels again, the final position should be 3 not 2
    position: Vector2f,
}

create_sprite :: proc (renderer: ^sdl.Renderer, path: cstring, scale: f64 = 1) -> Sprite {
    sprite := Sprite{
        texture = image.LoadTexture(renderer, path),
    }

    // Requesting the dimensions of the texture
    sdl.QueryTexture(sprite.texture, nil, nil, &sprite.transform.w, &sprite.transform.h)

    if scale != 1 {
        set_sprite_scale(&sprite, scale)
    }

    return sprite
}

set_sprite_scale :: proc (sprite: ^Sprite, scale: f64) {
    sprite.transform.h = i32(f64(sprite.transform.h) * scale)
    sprite.transform.w = i32(f64(sprite.transform.w) * scale)
}

// Updating sprite position
set_sprite_x :: proc (sprite: ^Sprite, new_position: f64) {
    sprite.position.x = new_position
    sprite.transform.x = i32(new_position)
}

set_sprite_y :: proc (sprite: ^Sprite, new_position: f64) {
    sprite.position.y = new_position
    sprite.transform.y = i32(new_position)
}

render_sprite :: proc (sprite: ^Sprite, renderer: ^sdl.Renderer) {
    sdl.RenderCopy(renderer, sprite.texture, nil, &sprite.transform)
}



// Text is basically a sprite too because it has a texture and it can be moved around
Text :: struct {
    using sprite: Sprite,
}

create_text :: proc (renderer: ^sdl.Renderer, font: ^ttf.Font, content: cstring, scale: f64 = 1) -> Text {
    surface := ttf.RenderText_Solid(font, content, sdl.Color{255, 255, 255, 255})

    defer sdl.FreeSurface(surface)
    
    text := Text{}
    text.texture = sdl.CreateTextureFromSurface(renderer, surface)

    // Finding the font's scale
    ttf.SizeText(font, content, &text.transform.w, &text.transform.h)

    text.transform.w = i32(f64(text.transform.w) * scale)
    text.transform.h = i32(f64(text.transform.h) * scale)

    return text
}

