const raylib = @import("raylib");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    raylib.initWindow(screenWidth, screenHeight, "raylib.zig [audio] example - sound loading and playing");
    defer raylib.closeWindow(); // Close window and OpenGL context

    raylib.initAudioDevice(); // Initialize audio device
    defer raylib.closeAudioDevice(); // Close audio device (music streaming is automatically stopped)

    const fxWav = raylib.loadSound("resources/audio/sound.wav");
    defer raylib.unloadSound(fxWav);

    const fxOgg = raylib.loadSound("resources/audio/target.ogg");
    defer raylib.unloadSound(fxOgg);

    raylib.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!raylib.windowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_space)) raylib.playSound(fxWav); // Play WAV sound
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_enter)) raylib.playSound(fxOgg); // Play OGG sound
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();

        raylib.clearBackground(raylib.Color.ray_white);

        raylib.drawText("MUSIC SHOULD BE PLAYING!", 255, 150, 20, raylib.Color.light_gray);

        raylib.drawText("Press SPACE to PLAY the WAV sound!", 200, 180, 20, raylib.Color.light_gray);
        raylib.drawText("Press ENTER to PLAY the OGG sound!", 200, 220, 20, raylib.Color.light_gray);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }
}
