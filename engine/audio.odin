package engine

import "vendor:sdl2/mixer"

Audio :: struct {
    source_chunk: ^mixer.Chunk,
}

// Load sound effect from given file path
load_audio :: proc (path: cstring) -> Audio {
    return Audio{
        mixer.LoadWAV(path),
    }
}

play_audio :: proc (audio: ^Audio) {
    // Play the audio chunk without repeating it on an auto-recommended channel
    mixer.PlayChannel(-1, audio.source_chunk, 0)
}
