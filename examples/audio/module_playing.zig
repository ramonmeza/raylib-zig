const std = @import("std");
const raylib = @import("raylib");

const MAX_CIRCLES: i32 = 64;

const CircleWave = struct {
    position: raylib.Vector2,
    radius: f32,
    alpha: f32,
    speed: f32,
    color: raylib.Color,
};

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    raylib.setConfigFlags(raylib.ConfigFlags{ .msaa_4x_hint = true }); // NOTE: Try to enable MSAA 4X

    raylib.initWindow(screenWidth, screenHeight, "raylib [audio] example - module playing (streaming)");
    defer raylib.closeWindow(); // Close window and OpenGL context

    raylib.initAudioDevice(); // Initialize audio device
    defer raylib.closeAudioDevice(); // Close audio device (music streaming is automatically stopped)

    const colors: [14]raylib.Color = .{ raylib.Color.orange, raylib.Color.red, raylib.Color.gold, raylib.Color.lime, raylib.Color.blue, raylib.Color.violet, raylib.Color.brown, raylib.Color.light_gray, raylib.Color.pink, raylib.Color.yellow, raylib.Color.green, raylib.Color.sky_blue, raylib.Color.purple, raylib.Color.beige };

    // Creates some circles for visual effect
    var circles: [MAX_CIRCLES]CircleWave = std.mem.zeroes([MAX_CIRCLES]CircleWave);

    for (0..MAX_CIRCLES) |i| {
        circles[i].alpha = 0.0;
        circles[i].radius = @as(f32, @floatFromInt(raylib.getRandomValue(10, 40)));
        circles[i].position.x = @as(f32, @floatFromInt(raylib.getRandomValue(@as(i32, @intFromFloat(circles[i].radius)), @as(i32, @intFromFloat(screenWidth - circles[i].radius)))));
        circles[i].position.y = @as(f32, @floatFromInt(raylib.getRandomValue(@as(i32, @intFromFloat(circles[i].radius)), @as(i32, @intFromFloat(screenHeight - circles[i].radius)))));
        circles[i].speed = @as(f32, @floatFromInt(raylib.getRandomValue(1, 100))) / 2000.0;
        circles[i].color = colors[@as(usize, @intCast(raylib.getRandomValue(0, 13)))];
    }

    var music: raylib.Music = raylib.loadMusicStream("resources/audio/mini1111.xm");
    defer raylib.unloadMusicStream(music); // Unload music stream buffers from RAM
    music.looping = false;

    var pitch: f32 = 1.0;

    raylib.playMusicStream(music);

    var timePlayed: f32 = 0.0;
    var pause: bool = false;

    raylib.setTargetFPS(60); // Set our game to run at 60 frames-per-second
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
            pause = false;
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

        if (raylib.isKeyDown(raylib.KeyboardKey.key_down)) {
            pitch -= 0.01;
        } else if (raylib.isKeyDown(raylib.KeyboardKey.key_up)) {
            pitch += 0.01;
        }

        raylib.setMusicPitch(music, pitch);

        // Get timePlayed scaled to bar dimensions
        timePlayed = raylib.getMusicTimePlayed(music) / raylib.getMusicTimeLength(music) * (screenWidth - 40);

        // Color circles animation
        for (0..MAX_CIRCLES) |i| {
            circles[i].alpha += circles[i].speed;
            circles[i].radius += circles[i].speed * 10.0;

            if (circles[i].alpha > 1.0) circles[i].speed *= -1;

            if (circles[i].alpha <= 0.0) {
                circles[i].alpha = 0.0;
                circles[i].radius = @as(f32, @floatFromInt(raylib.getRandomValue(10, 40)));
                circles[i].position.x = @as(f32, @floatFromInt(raylib.getRandomValue(@as(i32, @intFromFloat(circles[i].radius)), @as(i32, @intFromFloat(screenWidth - circles[i].radius)))));
                circles[i].position.y = @as(f32, @floatFromInt(raylib.getRandomValue(@as(i32, @intFromFloat(circles[i].radius)), @as(i32, @intFromFloat(screenHeight - circles[i].radius)))));
                circles[i].color = colors[@as(usize, @intCast(raylib.getRandomValue(0, 13)))];
                circles[i].speed = @as(f32, @floatFromInt(raylib.getRandomValue(1, 100))) / 2000.0;
            }
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();

        raylib.clearBackground(raylib.Color.ray_white);

        for (0..MAX_CIRCLES) |i| {
            raylib.drawCircleV(circles[i].position, circles[i].radius, circles[i].color.fade(circles[i].alpha));
        }

        // Draw time bar
        raylib.drawRectangle(20, screenHeight - 20 - 12, screenWidth - 40, 12, raylib.Color.light_gray);
        raylib.drawRectangle(20, screenHeight - 20 - 12, @as(i32, @intFromFloat(timePlayed)), 12, raylib.Color.maroon);
        raylib.drawRectangleLines(20, screenHeight - 20 - 12, screenWidth - 40, 12, raylib.Color.gray);

        // Draw help instructions
        raylib.drawRectangle(20, 20, 425, 145, raylib.Color.white);
        raylib.drawRectangleLines(20, 20, 425, 145, raylib.Color.gray);
        raylib.drawText("PRESS SPACE TO RESTART MUSIC", 40, 40, 20, raylib.Color.black);
        raylib.drawText("PRESS P TO PAUSE/RESUME", 40, 70, 20, raylib.Color.black);
        raylib.drawText("PRESS UP/DOWN TO CHANGE SPEED", 40, 100, 20, raylib.Color.black);
        raylib.drawText(raylib.textFormat("SPEED: %f", .{pitch}), 40, 130, 20, raylib.Color.maroon);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }
}
