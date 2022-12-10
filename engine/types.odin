package engine

import "core:math"

Vector2 :: distinct [2]i32
Vector2f :: distinct [2]f64

vector2f_get_magnitude :: proc (vec: Vector2f) -> f64 {
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
}
