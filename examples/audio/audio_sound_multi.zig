const std = @import("std");
const raylib = @import("raylib");

const MAX_SOUNDS: i32 = 10;
var soundArray: [MAX_SOUNDS]raylib.Sound = std.mem.zeroes([MAX_SOUNDS]raylib.Sound);
var currentSound: usize = 0;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    raylib.initWindow(screenWidth, screenHeight, "raylib.zig [audio] example - playing sound multiple times");
    defer raylib.closeWindow(); // Close window and OpenGL context

    raylib.initAudioDevice(); // Initialize audio device
    defer raylib.closeAudioDevice(); // Close audio device

    // load the sound list
    soundArray[0] = raylib.loadSound("resources/audio/sound.wav"); // Load WAV audio file into the first slot as the 'source' sound. this sound owns the sample data
    defer raylib.unloadSound(soundArray[0]);
    for (1..MAX_SOUNDS) |i| {
        soundArray[i] = raylib.loadSoundAlias(soundArray[0]); // Load an alias of the sound into slots 1-9. These do not own the sound data, but can be played
    }
    currentSound = 0; // set the sound list to the start

    raylib.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!raylib.windowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_space)) {
            raylib.playSound(soundArray[currentSound]); // play the next open sound slot
            currentSound += 1; // increment the sound slot
            if (currentSound >= MAX_SOUNDS) { // if the sound slot is out of bounds, go back to 0
                currentSound = 0;
            }

            // Note: a better way would be to look at the list for the first sound that is not playing and use that slot
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();

        raylib.clearBackground(raylib.Color.ray_white);

        raylib.drawText("Press SPACE to PLAY a WAV sound!", 200, 180, 20, raylib.Color.light_gray);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    for (1..MAX_SOUNDS) |i| {
        raylib.unloadSoundAlias(soundArray[i]);
    }
}
