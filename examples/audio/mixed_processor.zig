const raylib = @import("raylib");

const std = @import("std");

var exponent: f32 = 1.0;
var average_volume = std.mem.zeroes([400]f32);

pub fn main() void {
    const screenWidth = 800;
    const screenHeight = 450;

    raylib.initWindow(screenWidth, screenHeight, "raylib.zig [audio] example - processing mixed output");
    defer raylib.closeWindow();

    raylib.initAudioDevice();
    defer raylib.closeAudioDevice();

    raylib.attachAudioMixedProcessor(process_audio);
    defer raylib.detachAudioMixedProcessor(process_audio);

    const music = raylib.loadMusicStream("resources/audio/country.mp3");
    defer raylib.unloadMusicStream(music);
    raylib.playMusicStream(music);

    const sound = raylib.loadSound("resources/audio/coin.wav");
    defer raylib.unloadSound(sound);

    while (!raylib.windowShouldClose()) {
        // update
        raylib.updateMusicStream(music);

        if (raylib.isKeyPressed(raylib.KeyboardKey.key_left)) {
            exponent -= 0.05;
        }

        if (raylib.isKeyPressed(raylib.KeyboardKey.key_right)) {
            exponent += 0.05;
        }

        exponent = std.math.clamp(exponent, 0.5, 3.0);

        if (raylib.isKeyPressed(raylib.KeyboardKey.key_space)) {
            raylib.playSound(sound);
        }

        // draw
        raylib.beginDrawing();
        raylib.clearBackground(raylib.Color.ray_white);
        raylib.drawText("MUSIC SHOULD BE PLAYING!", 255, 150, 20, raylib.Color.light_gray);

        raylib.drawText(raylib.textFormat("EXPONENT = %.2f", .{exponent}), 215, 180, 20, raylib.Color.light_gray);

        raylib.drawRectangle(199, 199, 402, 34, raylib.Color.light_gray);
        for (0..399) |i| {
            raylib.drawLine(201 + @as(i32, @intCast(i)), 232 - @as(i32, @intFromFloat(average_volume[i] * 32)), 201 + @as(i32, @intCast(i)), 232, raylib.Color.maroon);
        }
        raylib.drawRectangleLines(199, 199, 402, 34, raylib.Color.gray);

        raylib.drawText("PRESS SPACE TO PLAY OTHER SOUND", 200, 250, 20, raylib.Color.light_gray);
        raylib.drawText("USE LEFT AND RIGHT ARROWS TO ALTER DISTORTION", 140, 280, 20, raylib.Color.light_gray);

        raylib.endDrawing();
    }
}

pub fn process_audio(buffer: ?*anyopaque, frames: c_uint) callconv(.c) void {
    if (buffer == null) return;

    // Samples are stored as `float` internally
    const samples = buffer orelse return;
    const samplesPtr = @as([*]f32, @ptrCast((@alignCast(samples))));

    var average: f32 = 0.0;

    for (0..frames) |frame| {
        const left = &samplesPtr[frame * 2];
        const right = &samplesPtr[frame * 2 + 1];

        left.* = std.math.pow(f32, @abs(left.*), exponent) * @as(f32, (if (left.* < 0.0) -1.0 else 1.0));
        right.* = std.math.pow(f32, @abs(right.*), exponent) * @as(f32, (if (right.* < 0.0) -1.0 else 1.0));

        average += @abs(left.*) / @as(f32, @floatFromInt(frames));
        average += @abs(right.*) / @as(f32, @floatFromInt(frames));
    }

    // Moving history to the left
    for (0..(average_volume.len - 1)) |i| {
        if (i < 399) average_volume[i] = average_volume[i + 1];
    }

    // Adding the last average value
    if (average_volume.len > 0) average_volume[399] = average;
}
