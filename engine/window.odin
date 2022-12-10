package engine

import sdl "vendor:sdl2"
import "vendor:sdl2/image"
import "vendor:sdl2/ttf"
import "vendor:sdl2/mixer"

// Basic data about the instanciated SDL window
Game :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,

    title: cstring,
    
    // Window dimensions
    width:  i32,
    height: i32,
}

centered :: sdl.WINDOWPOS_CENTERED

create_game :: proc (title: cstring, width, height: i32) -> Game {
    // Initializing sdl components
    sdl.Init({ .VIDEO, .AUDIO })
    image.Init({ .PNG })
    ttf.Init()
    
    // Initializing SDL_Mixer with standard frequency and sample chunk size
    mixer.OpenAudio(44100, mixer.DEFAULT_FORMAT, 2, 2048)

    // Creating instance with the constant arguments
    game := Game{title = title, width = width, height = height}

    game.window = sdl.CreateWindow(title, centered, centered, width, height, sdl.WINDOW_SHOWN)
    game.renderer = sdl.CreateRenderer(game.window, -1, sdl.RENDERER_ACCELERATED)

    return game
}

cleanup_game :: proc (game: ^Game) {
    // Just cleans up SDL components
    // For now, the engine is limited to just one window

    sdl.DestroyWindow(game.window)
    sdl.DestroyRenderer(game.renderer)

    image.Quit()
    ttf.Quit()
    mixer.Quit()
    sdl.Quit()
}

