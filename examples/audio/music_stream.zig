const raylib = @import("raylib");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    raylib.initWindow(screenWidth, screenHeight, "raylib.zig [audio] example - music playing (streaming)");
    defer raylib.closeWindow(); // Close window and OpenGL context

    raylib.initAudioDevice(); // Initialize audio device
    defer raylib.closeAudioDevice(); // Close audio device (music streaming is automatically stopped)

    const music: raylib.Music = raylib.loadMusicStream("resources/audio/country.mp3");
    defer raylib.unloadMusicStream(music); // Unload music stream buffers from RAM
    raylib.playMusicStream(music);

    var timePlayed: f32 = 0.0; // Time played normalized [0.0f..1.0f]
    var pause: bool = false; // Music playing paused

    raylib.setTargetFPS(30); // Set our game to run at 30 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!raylib.windowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        raylib.updateMusicStream(music); // Update music buffer with new stream data

        // Restart music playing (stop and play)
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_space)) {
            raylib.stopMusicStream(music);
            raylib.playMusicStream(music);
        }

        // Pause/Resume music playing
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_p)) {
            pause = !pause;

            if (pause) {
                raylib.pauseMusicStream(music);
            } else {
                raylib.resumeMusicStream(music);
            }
        }

        // Get normalized time played for current music stream
        timePlayed = raylib.getMusicTimePlayed(music) / raylib.getMusicTimeLength(music);

        if (timePlayed > 1.0) {
            timePlayed = 1.0; // Make sure time played is no longer than music
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();

        raylib.clearBackground(raylib.Color.ray_white);

        raylib.drawText("MUSIC SHOULD BE PLAYING!", 255, 150, 20, raylib.Color.light_gray);

        raylib.drawRectangle(200, 200, 400, 12, raylib.Color.light_gray);
        raylib.drawRectangle(200, 200, @as(i32, @intFromFloat(timePlayed * 400.0)), 12, raylib.Color.maroon);
        raylib.drawRectangleLines(200, 200, 400, 12, raylib.Color.gray);

        raylib.drawText("PRESS SPACE TO RESTART MUSIC", 215, 250, 20, raylib.Color.light_gray);
        raylib.drawText("PRESS P TO PAUSE/RESUME MUSIC", 208, 280, 20, raylib.Color.light_gray);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }
}
