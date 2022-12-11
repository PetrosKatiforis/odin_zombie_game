package main

import "core:fmt"
import "core:strings"

import sdl "vendor:sdl2"
import "vendor:sdl2/image"
import "vendor:sdl2/ttf"

import "engine"

// Fixing the frame rate to 60 frames per second
FRAMES_PER_SECOND  :: 60
FRAME_DELAY        :: 1000 / FRAMES_PER_SECOND

GRASS_SPRITES :: 15 
WAVE_DELAY_MS :: 6000

Context :: struct {
    game: engine.Game,
    delta: f64,
    font: ^ttf.Font,

    is_paused: bool,
    lose_animation: engine.Animation,
    lose_text: engine.Text,
    overlay_alpha: u8,
    overlay_rect: sdl.Rect,

    current_wave: u32,
    spawn_timer: u32,
    // These values will change depending on the wave's difficulty
    zombie_speed: f64,
    total_wave_zombies: u32,
    zombies_to_spawn: u32,
    current_spawn_delay: u32,

    wave_counter: engine.Text,

    base_zombie_sprite: engine.Sprite,
    zombie_positions: [dynamic]engine.Vector2f,

    brain: engine.Sprite,
    brain_collision: sdl.Rect,
    gun_target: engine.Sprite,
    grass_sprite: engine.Sprite,
    grass_rects: [GRASS_SPRITES]sdl.Rect,

    lose_sfx: engine.Audio,
    spawn_sfx: engine.Audio,
    gun_sfx: engine.Audio,
    victory_sfx: engine.Audio,
}

// Global context instance
ctx := Context{}

create_animations :: proc () {
    // Simple fade-in fade-out with some text and audio when it gets black
    ctx.lose_animation.frames = {
        engine.AnimationFrame{
            start = 0,
            end = 1,

            on_start = proc () {
                ctx.is_paused = true
                ctx.overlay_alpha = 0
            },

            update = proc () {
                new_alpha := u32(ctx.overlay_alpha) + 5

                ctx.overlay_alpha = u8(min(255, new_alpha))
            },
        },

        engine.AnimationFrame{
            start = 2,
            end = 4,

            on_start = proc () {
                engine.play_audio(&ctx.lose_sfx)
            },

            update = proc () {
                // Rendering the lose text
                engine.render_sprite(&ctx.lose_text, ctx.game.renderer)                
            },
        },

        engine.AnimationFrame{
            start = 5,
            end = 6,

            on_start = proc () {
                // Destroy all zombies
                clear(&ctx.zombie_positions)

                ctx.current_wave = 0
                update_wave_text()
                update_wave_to_defaults()

                // Regerate the grass for variation 
                generate_grass()
            },

            update = proc () {
                new_alpha := i32(ctx.overlay_alpha) - 5

                ctx.overlay_alpha = u8(max(0, new_alpha))
            },

            on_end = proc () {
                // Making the game playable again
                ctx.is_paused = false
           },
        },
    }
}

// Update wave text based on current wave
update_wave_text :: proc () {
    ctx.wave_counter = engine.create_text(ctx.game.renderer, ctx.font, strings.clone_to_cstring(fmt.tprintf("Wave %v", ctx.current_wave)))

    engine.set_sprite_x(&ctx.wave_counter, f64(ctx.game.width - ctx.wave_counter.transform.w) / 2)
    engine.set_sprite_y(&ctx.wave_counter, 10)
}

initialize_context :: proc () {
    // This will automatically initialize all SDL components
    ctx.game = engine.create_game(title = "Zombolord - Made with Odin and SDL2", width = 480, height = 760)
    ctx.font = ttf.OpenFont("res/fonts/typewritter.ttf", 28)

    ctx.is_paused = false
    ctx.overlay_rect = sdl.Rect{0, 0, ctx.game.width, ctx.game.height}

    ctx.lose_text = engine.create_text(ctx.game.renderer, ctx.font, "The Zombies Have Won.")
    
    // Placing the text at the center of the screen
    engine.set_sprite_x(&ctx.lose_text, f64(ctx.game.width - ctx.lose_text.transform.w) / 2)
    engine.set_sprite_y(&ctx.lose_text, f64(ctx.game.height - ctx.lose_text.transform.h) / 2)
    
    ctx.brain = engine.create_sprite(ctx.game.renderer, "res/textures/brain.png", 2)
    engine.set_sprite_x(&ctx.brain, f64(ctx.game.width - ctx.brain.transform.w) / 2)
    engine.set_sprite_y(&ctx.brain, f64(ctx.game.height - ctx.brain.transform.h) / 2)
    
    // Hard-coded brain collision shape
    ctx.brain_collision = sdl.Rect{ctx.brain.transform.x + 5, ctx.brain.transform.y + 10, ctx.brain.transform.w - 5, ctx.brain.transform.h - 35}

    ctx.base_zombie_sprite = engine.create_sprite(ctx.game.renderer, "res/textures/zombie.png", 2)
    ctx.gun_target = engine.create_sprite(ctx.game.renderer, "res/textures/gun.png", 2)
    ctx.grass_sprite = engine.create_sprite(ctx.game.renderer, "res/textures/grass.png", 2)

    // Audio
    ctx.lose_sfx = engine.load_audio("res/audio/lose.wav")
    ctx.spawn_sfx = engine.load_audio("res/audio/spawn.wav")
    ctx.gun_sfx = engine.load_audio("res/audio/gun.wav")
    ctx.victory_sfx = engine.load_audio("res/audio/victory.wav")

    create_animations()
    update_wave_text()
    update_wave_to_defaults()
    generate_grass()
}

update_wave_to_defaults :: proc () {
    // Zombie speed in pixels per second
    ctx.zombie_speed = 80 

    ctx.total_wave_zombies = 10
    ctx.zombies_to_spawn = ctx.total_wave_zombies 
    ctx.current_spawn_delay = 1000
}

spawn_zombie :: proc () {
    engine.play_audio(&ctx.spawn_sfx)

    append(&ctx.zombie_positions, engine.Vector2f{
        // Spawning the zombie at one of the two screen edges based on randomness
        f64(engine.random_bool() ? -ctx.base_zombie_sprite.transform.w : ctx.game.width),

        f64(engine.random_bool() ? engine.random_range(0, i32(ctx.game.height / 4)) : engine.random_range(i32(ctx.game.height / 4 * 3), ctx.game.height)),
    })
}

generate_grass :: proc () {
    // Spawning the grass instances to make the map more beautiful than just one color
    for i in 0..<GRASS_SPRITES {
        ctx.grass_rects[i] = sdl.Rect{
            engine.random_range(20, ctx.game.width), engine.random_range(20, ctx.game.height), 
            ctx.grass_sprite.transform.w, ctx.grass_sprite.transform.h,
        }
    }
}

main :: proc () {
    // Initializing game and context
    initialize_context()
    defer engine.cleanup_game(&ctx.game)

    event: sdl.Event
    last_time: u32 = sdl.GetTicks()

    // Hiding the cursor
    sdl.ShowCursor(sdl.DISABLE)

    game_loop: for {
        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT: break game_loop

                case .MOUSEMOTION:
                    // Making the gun target follow the mouse
                    engine.set_sprite_x(&ctx.gun_target, f64(event.motion.x) - f64(ctx.gun_target.transform.w) / 2)
                    engine.set_sprite_y(&ctx.gun_target, f64(event.motion.y) - f64(ctx.gun_target.transform.h) / 2)

                case .MOUSEBUTTONDOWN:
                    if event.button.button == sdl.BUTTON_LEFT && !ctx.is_paused {
                        engine.play_audio(&ctx.gun_sfx)

                        // Check if a zombie has been hit
                        for pos, i in &ctx.zombie_positions {
                            zombie_rect := sdl.Rect{i32(pos.x), i32(pos.y), ctx.base_zombie_sprite.transform.w, ctx.base_zombie_sprite.transform.h}

                            // If the player has clicked on a zombie, kill it
                            if engine.is_inside(&zombie_rect, event.button.x, event.button.y) {
                                unordered_remove(&ctx.zombie_positions, i)

                                // Check if the wave has ended
                                if len(ctx.zombie_positions) == 0 && ctx.zombies_to_spawn == 0 {
                                    engine.play_audio(&ctx.victory_sfx)

                                    ctx.zombie_speed = min(280, ctx.zombie_speed + 30)
                                    ctx.total_wave_zombies += 4
                                    ctx.zombies_to_spawn = ctx.total_wave_zombies

                                    // Add a small delay between waves so the player can mentally prepare
                                    ctx.spawn_timer = 0
                                    ctx.current_spawn_delay = WAVE_DELAY_MS

                                    ctx.current_wave += 1
                                    update_wave_text()
                                }

                                break
                            }
                        }
                    }
            }
        }

        // Calculating delta time in seconds
        current_time := sdl.GetTicks()

        delta_ms := current_time - last_time
        ctx.delta = f64(delta_ms) / 1000.0

        last_time = current_time

        if !ctx.is_paused {
            // Using delta time as milliseconds for spawning
            ctx.spawn_timer += delta_ms

            // Zombie spawning
            if ctx.spawn_timer >= ctx.current_spawn_delay && ctx.zombies_to_spawn > 0 {
                spawn_zombie()

                ctx.zombies_to_spawn -= 1
                ctx.spawn_timer = 0

                // Randomly picking next zombie spawn time based on wave difficulty
                ctx.current_spawn_delay = u32(engine.random_range(i32(max(500, 1000 - ctx.current_wave * 100)), i32(max(1000, 2500 - ctx.current_wave * 200))))
            }
        }

        sdl.SetRenderDrawColor(ctx.game.renderer, 39, 48, 40, 255)
        sdl.RenderClear(ctx.game.renderer)

        for grass_rect in &ctx.grass_rects {
            sdl.RenderCopy(ctx.game.renderer, ctx.grass_sprite.texture, nil, &grass_rect)
        }

        engine.render_sprite(&ctx.brain, ctx.game.renderer)

        // Update and draw zombies
        for pos in &ctx.zombie_positions {
            if !ctx.is_paused {
                // Using vector subtraction to get vector from zombie to brain, normalizing it and applying the speed
                direction := ctx.brain.position - pos
                normalized := direction / engine.vector2f_get_magnitude(direction)

                pos += normalized * ctx.zombie_speed * ctx.delta
            }

            zombie_rect := sdl.Rect{i32(pos.x), i32(pos.y), ctx.base_zombie_sprite.transform.w, ctx.base_zombie_sprite.transform.h}

            // Check if any zombie has reached the brain
            if !ctx.is_paused && sdl.HasIntersection(&zombie_rect, &ctx.brain_collision) {
                // End the game and play the lose screen
                ctx.is_paused = true
                ctx.lose_animation.is_active = true
            }

            sdl.RenderCopy(ctx.game.renderer, ctx.base_zombie_sprite.texture, nil, &zombie_rect) 
        }

        // UI rendering
        engine.render_sprite(&ctx.wave_counter, ctx.game.renderer)
        engine.render_sprite(&ctx.gun_target, ctx.game.renderer)

        // Rendering the black overlay
        sdl.SetRenderDrawBlendMode(ctx.game.renderer, sdl.BlendMode.BLEND)
        sdl.SetRenderDrawColor(ctx.game.renderer, 0, 0, 0, ctx.overlay_alpha)
        sdl.RenderFillRect(ctx.game.renderer, &ctx.overlay_rect)

        // The animation has to play and draw after the overlay, because it tries to render text on top of it
        engine.run_animation_if_active(&ctx.lose_animation, ctx.delta)

        sdl.RenderPresent(ctx.game.renderer)
        sdl.Delay(FRAME_DELAY)
    }
}

