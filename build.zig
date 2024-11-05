// raylib-zig (c) Nikolas Wipper 2020-2024

const std = @import("std");
const this = @This();
const rl = @import("raylib");

pub const emcc = @import("emcc.zig");

pub const Options = struct {
    raudio: bool = true,
    rmodels: bool = true,
    rshapes: bool = true,
    rtext: bool = true,
    rtextures: bool = true,
    platform: PlatformBackend = .glfw,
    shared: bool = false,
    linux_display_backend: LinuxDisplayBackend = .X11,
    opengl_version: OpenglVersion = .auto,
};

pub const OpenglVersion = enum {
    auto,
    gl_1_1,
    gl_2_1,
    gl_3_3,
    gl_4_3,
    gles_2,
    gles_3,
};

pub const LinuxDisplayBackend = enum {
    X11,
    Wayland,
};

pub const PlatformBackend = enum {
    glfw,
    rgfw,
    sdl,
    drm,
};

const Program = struct {
    name: []const u8,
    path: []const u8,
    desc: []const u8,
};

fn link(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    options: Options,
) void {
    const lib = getRaylib(b, target, optimize, options);

    const target_os = exe.rootModuleTarget().os.tag;
    switch (target_os) {
        .windows => {
            exe.linkSystemLibrary("winmm");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");
        },
        .macos => {
            exe.linkFramework("OpenGL");
            exe.linkFramework("Cocoa");
            exe.linkFramework("IOKit");
            exe.linkFramework("CoreAudio");
            exe.linkFramework("CoreVideo");
        },
        .freebsd, .openbsd, .netbsd, .dragonfly => {
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("Xrandr");
            exe.linkSystemLibrary("Xinerama");
            exe.linkSystemLibrary("Xi");
            exe.linkSystemLibrary("Xxf86vm");
            exe.linkSystemLibrary("Xcursor");
        },
        .emscripten, .wasi => {
            // When using emscripten, the libries don't need to be linked
            // because emscripten is going to do that later.
        },
        else => { // Linux and possibly others.
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");
        },
    }

    exe.linkLibrary(lib);
}

var _raylib_lib_cache: ?*std.Build.Step.Compile = null;
fn getRaylib(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, options: Options) *std.Build.Step.Compile {
    if (_raylib_lib_cache) |lib| return lib else {
        const raylib = b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
            .raudio = options.raudio,
            .rmodels = options.rmodels,
            .rshapes = options.rshapes,
            .rtext = options.rtext,
            .rtextures = options.rtextures,
            .platform = options.platform,
            .shared = options.shared,
            .linux_display_backend = options.linux_display_backend,
            .opengl_version = options.opengl_version,
        });

        const lib = raylib.artifact("raylib");

        const raygui_dep = b.dependency("raygui", .{
            .target = target,
            .optimize = optimize,
        });

        var gen_step = b.addWriteFiles();
        lib.step.dependOn(&gen_step.step);

        const raygui_c_path = gen_step.add("raygui.c", "#define RAYGUI_IMPLEMENTATION\n#include \"raygui.h\"\n");
        lib.addCSourceFile(.{
            .file = raygui_c_path,
            .flags = &[_][]const u8{
                "-std=gnu99",
                "-D_GNU_SOURCE",
                "-DGL_SILENCE_DEPRECATION=199309L",
                "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/3674
            },
        });
        lib.addIncludePath(raylib.path("src"));
        lib.addIncludePath(raygui_dep.path("src"));

        lib.installHeader(raygui_dep.path("src/raygui.h"), "raygui.h");

        b.installArtifact(lib);
        _raylib_lib_cache = lib;
        return lib;
    }
}

fn getModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Module {
    if (b.modules.contains("raylib")) {
        return b.modules.get("raylib").?;
    }
    return b.addModule("raylib", .{
        .root_source_file = b.path("lib/raylib.zig"),
        .target = target,
        .optimize = optimize,
    });
}

const gui = struct {
    fn getModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Module {
        const raylib = this.getModule(b, target, optimize);
        return b.addModule("raygui", .{
            .root_source_file = b.path("lib/raygui.zig"),
            .imports = &.{.{ .name = "raylib-zig", .module = raylib }},
            .target = target,
            .optimize = optimize,
        });
    }
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const defaults = Options{};
    const options = Options{
        .platform = b.option(PlatformBackend, "platform", "Compile raylib in native mode (no X11)") orelse defaults.platform,
        .raudio = b.option(bool, "raudio", "Compile with audio support") orelse defaults.raudio,
        .rmodels = b.option(bool, "rmodels", "Compile with models support") orelse defaults.rmodels,
        .rtext = b.option(bool, "rtext", "Compile with text support") orelse defaults.rtext,
        .rtextures = b.option(bool, "rtextures", "Compile with textures support") orelse defaults.rtextures,
        .rshapes = b.option(bool, "rshapes", "Compile with shapes support") orelse defaults.rshapes,
        .shared = b.option(bool, "shared", "Compile as shared library") orelse defaults.shared,
        .linux_display_backend = b.option(LinuxDisplayBackend, "linux_display_backend", "Linux display backend to use") orelse defaults.linux_display_backend,
        .opengl_version = b.option(OpenglVersion, "opengl_version", "OpenGL version to use") orelse defaults.opengl_version,
    };

    const examples = [_]Program{
        // [audio]
        .{
            .name = "audio_mixed_processor",
            .path = "examples/audio/audio_mixed_processor.zig",
            .desc = "Mixed audio processing",
        },
        .{
            .name = "audio_module_playing",
            .path = "examples/audio/audio_module_playing.zig",
            .desc = "Module playing (streaming)",
        },
        .{
            .name = "audio_music_stream",
            .path = "examples/audio/audio_music_stream.zig",
            .desc = "Music playing (streaming)",
        },
        .{
            .name = "audio_raw_stream",
            .path = "examples/audio/audio_raw_stream.zig",
            .desc = "Plays a sine wave",
        },
        .{
            .name = "audio_sound_loading",
            .path = "examples/audio/audio_sound_loading.zig",
            .desc = "Sound loading and playing",
        },
        .{
            .name = "audio_sound_multi",
            .path = "examples/audio/audio_sound_multi.zig",
            .desc = "Playing sound multiple times",
        },
        .{
            .name = "audio_stream_effects",
            .path = "examples/audio/audio_stream_effects.zig",
            .desc = "Music stream processing effects",
        },

        // [core]
        .{
            .name = "core_2d_camera",
            .path = "examples/core/core_2d_camera.zig",
            .desc = "Shows the functionality of a 2D camera",
        },
        .{
            .name = "core_2d_camera_mouse_zoom",
            .path = "examples/core/core_2d_camera_mouse_zoom.zig",
            .desc = "Shows mouse zoom demo",
        },
        // @todo: core_2d_camera_platformer
        // @todo: core_2d_camera_split_screen
        .{
            .name = "core_3d_camera_first_person",
            .path = "examples/core/core_3d_camera_first_person.zig",
            .desc = "Simple first person demo",
        },
        .{
            .name = "core_3d_camera_free",
            .path = "examples/core/core_3d_camera_free.zig",
            .desc = "Shows basic 3d camera initialization",
        },
        // @todo: core_3d_camera_mode
        // @todo: core_3d_camera_split_screen
        .{
            .name = "core_3d_picking",
            .path = "examples/core/core_3d_picking.zig",
            .desc = "Shows picking in 3d mode",
        },
        // @todo: core_automation_events
        .{
            .name = "core_basic_screen_manager",
            .path = "examples/core/core_basic_screen_manager.zig",
            .desc = "Illustrates simple screen manager based on a state machine",
        },
        .{
            .name = "core_basic_window",
            .path = "examples/core/core_basic_window.zig",
            .desc = "Creates a basic window with text",
        },
        // @todo: core_frame_control
        // @todo: core_custom_logging
        // @todo: core_drop_files
        // @todo: core_input_gamepad
        // @todo: core_input_gamepad_info
        // @todo: core_input_gestures
        .{
            .name = "core_input_keys",
            .path = "examples/core/core_input_keys.zig",
            .desc = "Simple keyboard input",
        },
        .{
            .name = "core_input_mouse",
            .path = "examples/core/core_input_mouse.zig",
            .desc = "Simple mouse input",
        },
        .{
            .name = "core_input_mouse_wheel",
            .path = "examples/core/core_input_mouse_wheel.zig",
            .desc = "Mouse wheel input",
        },
        .{
            .name = "core_input_multitouch",
            .path = "examples/core/core_input_multitouch.zig",
            .desc = "Multitouch input",
        },
        // @todo: core_loading_thread
        // @todo: core_random_sequence
        // @todo: core_random_values
        // @todo: core_scissor_test
        // @todo: core_smooth_pixelperfect
        // @todo: core_storage_values
        // @todo: core_vr_simulator
        .{
            .name = "core_window_flags",
            .path = "examples/core/core_window_flags.zig",
            .desc = "Demonstrates various flags used during and after window creation",
        },
        // @todo: core_window_letterbox
        // @todo: core_window_should_close
        // @todo: core_world_screen

        // [models]
        // @todo: models_animation
        // @todo: models_billboard
        // @todo: models_box_collisions
        // @todo: models_cubicmap
        // @todo: models_draw_cube_texture
        // @todo: models_first_person_maze
        // @todo: models_geometry_shapes
        // @todo: models_gpu_skinning
        .{
            .name = "models_heightmap",
            .path = "examples/models/models_heightmap.zig",
            .desc = "Heightmap loading and drawing",
        },
        // @todo: models_loading
        // @todo: models_loading_gltf
        // @todo: models_loading_m3d
        // @todo: models_loading_vox
        // @todo: models_mesh_generation
        // @todo: models_mesh_picking
        // @todo: models_orthographic_projection
        // @todo: models_rlgl_solar_system
        // @todo: models_skybox
        // @todo: models_waving_cubes
        // @todo: models_yaw_pitch_roll

        // [other]
        // @todo: other_easings_testbed
        // @todo: other_embedded_files_loading
        // @todo: other_rlgl_compute_shaders
        // @todo: other_rlgl_standalone

        // [shaders]
        // @todo: texture_basic_lighting
        // @todo: texture_custom_uniform
        // @todo: texture_deferred_render
        // @todo: texture_eratosthenes
        // @todo: texture_fog
        // @todo: texture_hot_reloading
        // @todo: texture_hybrid_render
        // @todo: texture_julia_set
        // @todo: texture_mesh_instancing
        // @todo: texture_model_shader
        // @todo: texture_multi_sample2d
        // @todo: texture_palette_switch
        // @todo: texture_postprocessing
        // @todo: texture_raymarching
        // @todo: texture_shadowmap
        // @todo: texture_shape_textures
        // @todo: texture_simple_mask
        // @todo: texture_spotlight
        // @todo: texture_texture_drawing
        .{
            .name = "texture_outline",
            .path = "examples/shaders/texture_outline.zig",
            .desc = "Uses a shader to create an outline around a sprite",
        },
        // @todo: texture_texture_tiling
        // @todo: texture_texture_waves
        // @todo: texture_write_depth

        // [shapes]
        // @todo: shapes_basic_shapes
        // @todo: shapes_bouncing_ball
        // @todo: shapes_collision_area
        // @todo: shapes_colors_palette
        // @todo: shapes_draw_circle_sector
        // @todo: shapes_draw_rectangle_rounded
        // @todo: shapes_draw_ring
        // @todo: shapes_easing_ball_anim
        // @todo: shapes_easing_box_anim
        // @todo: shapes_easing_rectangle_array
        // @todo: shapes_following_eyes
        // @todo: shapes_lines_bezier
        .{
            .name = "logo_raylib",
            .path = "examples/shapes/shapes_logo_raylib.zig",
            .desc = "Renders the raylib-zig logo",
        },
        // @todo: shapes_logo_raylib_anim
        // @todo: shapes_rectangle_advanced
        // @todo: shapes_rectangle_scaling
        // @todo: shapes_splines_drawing
        // @todo: shapes_top-down_lights

        // [text]
        // @todo: text_codepoints_loading
        // @todo: text_draw_3d
        // @todo: text_font_filters
        // @todo: text_font_loading
        // @todo: text_font_sdf
        // @todo: text_font_spritefont
        .{
            .name = "text_format_text",
            .path = "examples/text/text_format_text.zig",
            .desc = "Renders variables as text",
        },
        // @todo: text_input_box
        // @todo: text_raylib_fonts
        // @todo: text_rectangle_bounds
        // @todo: text_unicode
        // @todo: text_writing_anim

        // [textures]
        .{
            .name = "textures_background_scrolling",
            .path = "examples/textures/textures_background_scrolling.zig",
            .desc = "Background scrolling & parallax demo",
        },
        // @todo: textures_blend_modes
        // @todo: textures_bunnymark
        // @todo: textures_draw_tiled
        // @todo: textures_fog_of_war
        // @todo: textures_gif_player
        // @todo: textures_image_drawing
        // @todo: textures_image_generation
        // @todo: textures_image_loading
        // @todo: textures_image_processing
        // @todo: textures_image_text
        // @todo: textures_logo_raylib
        // @todo: textures_mouse_painting
        // @todo: textures_npatch_drawing
        // @todo: textures_particles_blending
        // @todo: textures_polygon
        // @todo: textures_raw_data
        .{
            .name = "sprite_anim",
            .path = "examples/textures/textures_sprite_anim.zig",
            .desc = "Animate a sprite",
        },
        // @todo: textures_sprite_button
        // @todo: textures_sprite_explosion
        // @todo: textures_srcrec_dstrec
        // @todo: textures_textured_curve
        // @todo: textures_to_image
    };

    const raylib = this.getModule(b, target, optimize);
    const raygui = this.gui.getModule(b, target, optimize);

    const raylib_test = b.addTest(.{
        .root_source_file = b.path("lib/raylib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const raygui_test = b.addTest(.{
        .root_source_file = b.path("lib/raygui.zig"),
        .target = target,
        .optimize = optimize,
    });
    raygui_test.root_module.addImport("raylib-zig", raylib);

    const test_step = b.step("test", "Check for library compilation errors");
    test_step.dependOn(&raylib_test.step);
    test_step.dependOn(&raygui_test.step);

    const examples_step = b.step("examples", "Builds all the examples");

    for (examples) |ex| {
        if (target.query.os_tag == .emscripten) {
            const exe_lib = emcc.compileForEmscripten(b, ex.name, ex.path, target, optimize);
            exe_lib.root_module.addImport("raylib", raylib);
            exe_lib.root_module.addImport("raygui", raygui);
            const raylib_lib = getRaylib(b, target, optimize, options);

            // Note that raylib itself isn't actually added to the exe_lib
            // output file, so it also needs to be linked with emscripten.
            exe_lib.linkLibrary(raylib_lib);
            const link_step = try emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, raylib_lib });
            link_step.addArg("--embed-file");
            link_step.addArg("resources/");

            const run_step = try emcc.emscriptenRunStep(b);
            run_step.step.dependOn(&link_step.step);
            const run_option = b.step(ex.name, ex.desc);

            run_option.dependOn(&run_step.step);
            examples_step.dependOn(&exe_lib.step);
        } else {
            const exe = b.addExecutable(.{
                .name = ex.name,
                .root_source_file = b.path(ex.path),
                .optimize = optimize,
                .target = target,
            });
            this.link(b, exe, target, optimize, options);
            exe.root_module.addImport("raylib", raylib);
            exe.root_module.addImport("raygui", raygui);

            const run_cmd = b.addRunArtifact(exe);
            const run_step = b.step(ex.name, ex.desc);

            run_step.dependOn(&run_cmd.step);
            examples_step.dependOn(&exe.step);
        }
    }
}
