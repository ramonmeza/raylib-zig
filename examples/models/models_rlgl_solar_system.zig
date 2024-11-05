const raylib = @import("raylib");
const rlgl = raylib.gl;

const std = @import("std");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    const sunRadius: f32 = 4.0;
    const earthRadius: f32 = 0.6;
    const earthOrbitRadius: f32 = 8.0;
    const moonRadius: f32 = 0.16;
    const moonOrbitRadius: f32 = 1.5;

    raylib.initWindow(screenWidth, screenHeight, "raylib [models] example - rlgl module usage with push/pop matrix transformations");
    defer raylib.closeWindow();

    // Define the camera to look into our 3d world
    var camera: raylib.Camera = .{
        .position = .{
            .x = 16.0,
            .y = 16.0,
            .z = 16.0,
        }, // Camera position
        .target = .{
            .x = 0.0,
            .y = 0.0,
            .z = 0.0,
        }, // Camera looking at point
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, // Camera up vector (rotation towards target)
        .fovy = 45.0, // Camera field-of-view Y
        .projection = raylib.CameraProjection.camera_perspective, // Camera projection type
    };

    const rotationSpeed: f32 = 0.2; // General system rotation speed
    var earthRotation: f32 = 0.0; // Rotation of earth around itself (days) in degrees
    var earthOrbitRotation: f32 = 0.0; // Rotation of earth around the Sun (years) in degrees
    var moonRotation: f32 = 0.0; // Rotation of moon around itself
    var moonOrbitRotation: f32 = 0.0; // Rotation of moon around earth in degrees

    raylib.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!raylib.windowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        raylib.updateCamera(&camera, raylib.CameraMode.camera_orbital);

        earthRotation += (5.0 * rotationSpeed);
        earthOrbitRotation += (365.0 / 360.0 * (5.0 * rotationSpeed) * rotationSpeed);
        moonRotation += (2.0 * rotationSpeed);
        moonOrbitRotation += (8.0 * rotationSpeed);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();

        raylib.clearBackground(raylib.Color.ray_white);

        raylib.beginMode3D(camera);

        rlgl.rlPushMatrix();
        rlgl.rlScalef(sunRadius, sunRadius, sunRadius); // Scale Sun
        DrawSphereBasic(raylib.Color.gold); // Draw the Sun
        rlgl.rlPopMatrix();

        rlgl.rlPushMatrix();
        rlgl.rlRotatef(earthOrbitRotation, 0.0, 1.0, 0.0); // Rotation for Earth orbit around Sun
        rlgl.rlTranslatef(earthOrbitRadius, 0.0, 0.0); // Translation for Earth orbit

        rlgl.rlPushMatrix();
        rlgl.rlRotatef(earthRotation, 0.25, 1.0, 0.0); // Rotation for Earth itself
        rlgl.rlScalef(earthRadius, earthRadius, earthRadius); // Scale Earth

        DrawSphereBasic(raylib.Color.blue); // Draw the Earth
        rlgl.rlPopMatrix();

        rlgl.rlRotatef(moonOrbitRotation, 0.0, 1.0, 0.0); // Rotation for Moon orbit around Earth
        rlgl.rlTranslatef(moonOrbitRadius, 0.0, 0.0); // Translation for Moon orbit
        rlgl.rlRotatef(moonRotation, 0.0, 1.0, 0.0); // Rotation for Moon itself
        rlgl.rlScalef(moonRadius, moonRadius, moonRadius); // Scale Moon

        DrawSphereBasic(raylib.Color.light_gray); // Draw the Moon
        rlgl.rlPopMatrix();

        // Some reference elements (not affected by previous matrix transformations)
        raylib.drawCircle3D(.{ .x = 0.0, .y = 0.0, .z = 0.0 }, earthOrbitRadius, .{ .x = 1.0, .y = 0.0, .z = 0.0 }, 90.0, raylib.Color.red.fade(0.5));
        raylib.drawGrid(20, 1.0);

        raylib.endMode3D();

        raylib.drawText("EARTH ORBITING AROUND THE SUN!", 400, 10, 20, raylib.Color.maroon);
        raylib.drawFPS(10, 10);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }
}

//--------------------------------------------------------------------------------------------
// Module Functions Definitions (local)
//--------------------------------------------------------------------------------------------

// Draw sphere without any matrix transformation
// NOTE: Sphere is drawn in world position ( 0, 0, 0 ) with radius 1.0f
fn DrawSphereBasic(color: raylib.Color) void {
    const DEG2RAD: f32 = std.math.pi / 180.0;

    const rings: i32 = 16;
    const slices: i32 = 16;

    // Make sure there is enough space in the internal render batch
    // buffer to store all required vertex, batch is reseted if required
    _ = rlgl.rlCheckRenderBatchLimit((rings + 2) * slices * 6);

    rlgl.rlBegin(rlgl.rl_triangles);
    rlgl.rlColor4ub(color.r, color.g, color.b, color.a);

    for (0..(rings + 2)) |i| {
        const i_cast = @as(f32, @floatFromInt(i));
        for (0..slices) |j| {
            const j_cast = @as(f32, @floatFromInt(j));

            rlgl.rlVertex3f(std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * i_cast)) * std.math.sin(DEG2RAD * (j_cast * 360 / slices)), std.math.sin(DEG2RAD * (270 + (180 / (rings + 1)) * i_cast)), std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * i_cast)) * std.math.cos(DEG2RAD * (j_cast * 360 / slices)));
            rlgl.rlVertex3f(std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))) * std.math.sin(DEG2RAD * ((j_cast + 1) * 360 / slices)), std.math.sin(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))), std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))) * std.math.cos(DEG2RAD * ((j_cast + 1) * 360 / slices)));
            rlgl.rlVertex3f(std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))) * std.math.sin(DEG2RAD * (j_cast * 360 / slices)), std.math.sin(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))), std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))) * std.math.cos(DEG2RAD * (j_cast * 360 / slices)));

            rlgl.rlVertex3f(std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * i_cast)) * std.math.sin(DEG2RAD * (j_cast * 360 / slices)), std.math.sin(DEG2RAD * (270 + (180 / (rings + 1)) * i_cast)), std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * i_cast)) * std.math.cos(DEG2RAD * (j_cast * 360 / slices)));
            rlgl.rlVertex3f(std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast))) * std.math.sin(DEG2RAD * ((j_cast + 1) * 360 / slices)), std.math.sin(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast))), std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast))) * std.math.cos(DEG2RAD * ((j_cast + 1) * 360 / slices)));
            rlgl.rlVertex3f(std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))) * std.math.sin(DEG2RAD * ((j_cast + 1) * 360 / slices)), std.math.sin(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))), std.math.cos(DEG2RAD * (270 + (180 / (rings + 1)) * (i_cast + 1))) * std.math.cos(DEG2RAD * ((j_cast + 1) * 360 / slices)));
        }
    }
    rlgl.rlEnd();
}
