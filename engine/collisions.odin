package engine

import sdl "vendor:sdl2"

// Simple algorithm to check if a position is inside a 2d rectangle
is_inside :: proc (transform: ^sdl.Rect, x: i32, y: i32) -> bool {
    return (x >= transform.x && x <= transform.x + transform.w) && 
        (y >= transform.y && y <= transform.y + transform.h)
}
