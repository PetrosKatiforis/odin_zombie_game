package engine 

// Animation utilities that can be used by any sort of project

AnimationFrame :: struct {
    // Frame time range in seconds relative to animation start
    start: f64,
    end: f64,

    on_start: proc(),
    update: proc(),
    on_end: proc(),
}

Animation :: struct {
    is_active: bool,
    total_seconds_running: f64,

    current_frame: int,

    // True if the current frame has run at least once. Note that some frames may have a delayed start
    has_frame_started: bool,

    frames: [dynamic]AnimationFrame,
}

run_animation_if_active :: proc (anim: ^Animation, delta_seconds: f64) {
    if !anim.is_active do return

    // Check if the animation has finished
    if anim.current_frame > (len(anim.frames) - 1) {
        anim.current_frame = 0
        anim.total_seconds_running = 0

        anim.is_active = false
        anim.has_frame_started = false 

        return
    }

    frame := &anim.frames[anim.current_frame]

    anim.total_seconds_running += delta_seconds

    if frame.start < anim.total_seconds_running && anim.total_seconds_running < frame.end {
        if !anim.has_frame_started {
            anim.has_frame_started = true

            // Call the frame's on_start function if it exists
            if frame.on_start != nil do frame.on_start()
        }

        frame.update()
    }

    if anim.total_seconds_running > frame.end {
        if frame.on_end != nil do frame.on_end()

        anim.current_frame += 1
        anim.has_frame_started = false
    }
}


