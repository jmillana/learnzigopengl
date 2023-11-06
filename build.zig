const std = @import("std");
const print = std.debug.print;

const OPENGL_BINDINGS_PATH = "libs/gl4v6.zig";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // Tutorial selector
    const tutono: usize = b.option(usize, "n", "Select tutorial") orelse 1;

    if (tutono == 0 or tutono > tutorials.len) {
        print("unknown tutorial number: {}\n", .{tutono});
        std.os.exit(2);
    }

    const tuto = tutorials[tutono - 1];
    const tutorial_path = tuto.main_file;
    print("Running tutorial {d}: {s}", .{ tuto.number, tuto.name });

    const exe = b.addExecutable(.{
        .name = "learnzigopengl",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = tutorial_path },
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
    number: usize,
};

const tutorials = [_]Tutorial{
    .{
        .name = "Build a window",
        .main_file = "src/tutorial_1/window.zig",
        .number = 1,
    },
    .{
        .name = "Draw a triangle",
        .main_file = "src/tutorial_2/triangle.zig",
        .number = 2,
    },
};
