const std = @import("std");
const print = std.debug.print;

const OPENGL_BINDINGS_PATH = "libs/gl4v6.zig";
const zstbi = @import("libs/zstbi/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // Tutorial selector
    const tutono: ?usize = b.option(usize, "n", "Select tutorial");

    var tutorial_path: ?[]const u8 = null;
    if (tutono) |n| {
        if (n < 1 or n > tutorials.len) {
            print("Unknown tutorial number: {}\n", .{n});
            print("Available tutorials: 1 - {d}\n", .{tutorials.len});
            std.os.exit(2);
        }
        const tuto = tutorials[n - 1];
        tutorial_path = tuto.main_file;
        print("Selected Tutorial {d}: {s}\n", .{ n, tuto.name });
    } else {
        const msg =
            \\Usage:
            \\zig build run -Dn=<tutorial_number>
        ;
        print("{s}\n\nAvailable tutorials: 1 - {d}\n", .{ msg, tutorials.len });
        std.os.exit(2);
    }

    if (tutorial_path == null) {
        print("Unable to locate the tutorial", .{});
    }

    const exe = b.addExecutable(.{
        .name = "learnzigopengl",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = tutorial_path orelse unreachable },
        .main_mod_path = .{ .path = "src/" },
        .target = target,
        .optimize = optimize,
    });

    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = exe.target,
        .optimize = exe.optimize,
    });
    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));
    @import("mach_glfw").link(glfw_dep.builder, exe);

    // Add OpenGL
    exe.addModule("gl", b.createModule(.{
        .source_file = .{ .path = OPENGL_BINDINGS_PATH },
    }));

    const zstbi_pkg = zstbi.package(b, target, optimize, .{});
    zstbi_pkg.link(exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

const Tutorial = struct {
    name: []const u8,
    main_file: []const u8,
};

const tutorials = [_]Tutorial{
    .{
        .name = "Build a window",
        .main_file = "src/1_getting_started/1_hello_window/hello_window.zig",
    },
    .{
        .name = "Draw a triangle",
        .main_file = "src/1_getting_started/2_hello_triangle/1_hello_triangle.zig",
    },
    .{
        .name = "Draw 2 triangles",
        .main_file = "src/1_getting_started/2_hello_triangle/2_hello_triangle_indexed.zig",
    },
    .{
        .name = "Shaders with Uniform",
        .main_file = "src/1_getting_started/3_shaders/1_uniform.zig",
    },
    .{
        .name = "Shaders with Uniform",
        .main_file = "src/1_getting_started/3_shaders/2_shaders_interpolation.zig",
    },
    .{
        .name = "Custom shader builder",
        .main_file = "src/1_getting_started/3_shaders/3_shaders_class.zig",
    },
    .{
        .name = "Textures",
        .main_file = "src/1_getting_started/4_textures/1_textures.zig",
    },
    .{
        .name = "Textures mix",
        .main_file = "src/1_getting_started/4_textures/2_mix_textures.zig",
    },
};
