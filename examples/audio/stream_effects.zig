const std = @import("std");
const raylib = @import("raylib");

// Required delay effect variables
var delayBuffer: []f32 = undefined;
var delayBufferSize: usize = undefined;
var delayReadIndex: usize = 2;
var delayWriteIndex: usize = 0;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    raylib.initWindow(screenWidth, screenHeight, "raylib.zig [audio] example - stream effects");
    defer raylib.closeWindow();

    raylib.initAudioDevice(); // Initialize audio device
    defer raylib.closeAudioDevice();

    const music: raylib.Music = raylib.loadMusicStream("resources/audio/country.mp3");
    defer raylib.unloadMusicStream(music);

    // Allocate buffer for the delay effect
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    delayBufferSize = 48000 * 2; // 1 second delay (device sampleRate*channels)
    delayBuffer = @as([]f32, try allocator.alloc(f32, delayBufferSize));
    defer allocator.free(delayBuffer);

    raylib.playMusicStream(music);

    var timePlayed: f32 = 0.0; // Time played normalized [0.0f..1.0f]
    var pause: bool = false; // Music playing paused

    var enableEffectLPF: bool = false; // Enable effect low-pass-filter
    var enableEffectDelay: bool = false; // Enable effect delay (1 second)

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

        // Add/Remove effect: lowpass filter
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_f)) {
            enableEffectLPF = !enableEffectLPF;
            if (enableEffectLPF) {
                raylib.attachAudioStreamProcessor(music.stream, AudioProcessEffectLPF);
            } else {
                raylib.detachAudioStreamProcessor(music.stream, AudioProcessEffectLPF);
            }
        }

        // Add/Remove effect: delay
        if (raylib.isKeyPressed(raylib.KeyboardKey.key_d)) {
            enableEffectDelay = !enableEffectDelay;
            if (enableEffectDelay) {
                raylib.attachAudioStreamProcessor(music.stream, AudioProcessEffectDelay);
            } else {
                raylib.detachAudioStreamProcessor(music.stream, AudioProcessEffectDelay);
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

        raylib.drawText("MUSIC SHOULD BE PLAYING!", 245, 150, 20, raylib.Color.light_gray);

        raylib.drawRectangle(200, 180, 400, 12, raylib.Color.light_gray);
        raylib.drawRectangle(200, 180, @as(i32, @intFromFloat(timePlayed * 400.0)), 12, raylib.Color.maroon);
        raylib.drawRectangleLines(200, 180, 400, 12, raylib.Color.gray);

        raylib.drawText("PRESS SPACE TO RESTART MUSIC", 215, 230, 20, raylib.Color.light_gray);
        raylib.drawText("PRESS P TO PAUSE/RESUME MUSIC", 208, 260, 20, raylib.Color.light_gray);

        var lpf_label: [*:0]const u8 = undefined;
        if (enableEffectLPF) {
            lpf_label = "ON";
        } else {
            lpf_label = "OFF";
        }

        var delay_label: [*:0]const u8 = undefined;
        if (enableEffectDelay) {
            delay_label = "ON";
        } else {
            delay_label = "OFF";
        }

        raylib.drawText(raylib.textFormat("PRESS F TO TOGGLE LPF EFFECT: %s", .{lpf_label}), 200, 320, 20, raylib.Color.gray);
        raylib.drawText(raylib.textFormat("PRESS D TO TOGGLE DELAY EFFECT: %s", .{delay_label}), 180, 350, 20, raylib.Color.gray);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }
}

//------------------------------------------------------------------------------------
// Module Functions Definition
//------------------------------------------------------------------------------------
// Audio effect: lowpass filter
fn AudioProcessEffectLPF(buffer: ?*anyopaque, frames: c_uint) callconv(.c) void {
    var low: [2]f32 = .{ 0.0, 0.0 };
    const cutoff: f32 = 70.0 / 44100.0; // 70 Hz lowpass filter
    const k: f32 = cutoff / (cutoff + 0.1591549431); // RC filter formula

    // Converts the buffer data before using it
    const samples = buffer orelse return;
    const samplesPtr = @as([*]f32, @ptrCast((@alignCast(samples))));

    var i: usize = 0;
    while (i < frames * 2) {
        const l = samplesPtr[i];
        const r = samplesPtr[i + 1];

        low[0] += k * (l - low[0]);
        low[1] += k * (r - low[1]);
        samplesPtr[i] = low[0];
        samplesPtr[i + 1] = low[1];

        i += 2;
    }
}

// Audio effect: delay
fn AudioProcessEffectDelay(buffer: ?*anyopaque, frames: c_uint) callconv(.c) void {
    // Converts the buffer data before using it
    const samples = buffer orelse return;
    const samplesPtr = @as([*]f32, @ptrCast((@alignCast(samples))));

    var i: usize = 0;
    while (i < frames * 2) {
        const leftDelay = delayBuffer[delayReadIndex]; // ERROR: Reading buffer -> WHY??? Maybe thread related???
        delayReadIndex += 1;

        const rightDelay = delayBuffer[delayReadIndex];
        delayReadIndex += 1;

        if (delayReadIndex == delayBufferSize) delayReadIndex = 0;

        samplesPtr[i] = 0.5 * samplesPtr[i] + 0.5 * leftDelay;
        samplesPtr[i + 1] = 0.5 * samplesPtr[i + 1] + 0.5 * rightDelay;

        delayBuffer[delayWriteIndex] = samplesPtr[i];
        delayWriteIndex += 1;

        delayBuffer[delayWriteIndex] = samplesPtr[i + 1];
        delayWriteIndex += 1;

        if (delayWriteIndex == delayBufferSize) {
            delayWriteIndex = 0;
        }

        i += 2;
    }
}
