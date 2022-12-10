package engine

import "core:math/rand"

// Returns a random integer in [min, max]
random_range :: proc(min, max: i32) -> i32 {
    return rand.int31_max(max - min) + min + 1
}

random_bool :: proc () -> bool {
    return rand.int31_max(2) == 0
}
