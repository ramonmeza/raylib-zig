const std = @import("std");
const raylib = @import("raylib");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: i32 = 800;
    const screenHeight: i32 = 450;

    raylib.initWindow(screenWidth, screenHeight, "raylib.zig [models] example - heightmap loading and drawing");
    defer raylib.closeWindow(); // Close window and OpenGL context

    // Define our custom camera to look into our 3d world
    var camera: raylib.Camera = .{
        .position = .{ .x = 18.0, .y = 21.0, .z = 18.0 }, // Camera position
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 }, // Camera looking at point
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, // Camera up vector (rotation towards target)
        .fovy = 45.0, // Camera field-of-view Y
        .projection = raylib.CameraProjection.camera_perspective, // Camera projection type
    };

    const image = raylib.loadImage("resources/models/heightmap.png"); // Load heightmap image (RAM)

    const texture = raylib.loadTextureFromImage(image); // Convert image to texture (VRAM)
    defer raylib.unloadTexture(texture); // Unload texture

    std.debug.print("genMeshHightmap not working, causing segmentation fault", .{});
    const mesh = raylib.genMeshHeightmap(image, .{ .x = 16, .y = 8, .z = 16 }); // Generate heightmap mesh (RAM and VRAM)
    defer raylib.unloadMesh(mesh); // Unload mesh

    var model = raylib.loadModelFromMesh(mesh); // Load model from generated mesh
    defer raylib.unloadModel(model); // Unload model

    model.materials[0].maps[@as(usize, @intFromEnum(raylib.MATERIAL_MAP_DIFFUSE))].texture = texture; // Set map diffuse texture

    const mapPosition: raylib.Vector3 = .{ .x = -8.0, .y = 0.0, .z = -8.0 }; // Define model position

    raylib.unloadImage(image); // Unload heightmap image from RAM, already uploaded to VRAM

    raylib.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    std.debug.print("\n\n\t\tgotem\n\n", .{});

    // Main game loop
    while (!raylib.windowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        raylib.updateCamera(&camera, raylib.CameraMode.camera_orbital);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();

        raylib.clearBackground(raylib.Color.ray_white);

        raylib.beginMode3D(camera);
        raylib.drawModel(model, mapPosition, 1.0, raylib.Color.red);
        raylib.drawGrid(20, 1.0);
        raylib.endMode3D();

        raylib.drawTexture(texture, screenWidth - texture.width - 20, 20, raylib.Color.white);
        raylib.drawRectangleLines(screenWidth - texture.width - 20, 20, texture.width, texture.height, raylib.Color.green);

        raylib.drawFPS(10, 10);

        raylib.endDrawing();
        //----------------------------------------------------------------------------------
    }
}
