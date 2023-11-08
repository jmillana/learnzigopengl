const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const gl = @import("gl");

pub const Shader = struct {
    id: gl.GLuint,

    pub fn init(
        allocator: Allocator,
        vertex_path: []const u8,
        fragment_path: []const u8,
    ) !Shader {
        std.debug.print("\n\ncwd: {any}\n\n", .{fs.cwd()});
        const v_shader_file = try fs.cwd().openFile(
            vertex_path,
            .{ .mode = .read_only },
        );
        defer v_shader_file.close();
        const f_shader_file = try fs.cwd().openFile(
            fragment_path,
            .{ .mode = .read_only },
        );
        defer f_shader_file.close();

        var vertex_shader_code = try allocator.alloc(u8, try v_shader_file.getEndPos());
        _ = try v_shader_file.read(vertex_shader_code);
        defer allocator.free(vertex_shader_code);

        var fragment_shader_code = try allocator.alloc(u8, try f_shader_file.getEndPos());
        defer allocator.free(fragment_shader_code);
        _ = try f_shader_file.read(fragment_shader_code);
        // Compile the shaders
        var success: gl.GLint = 0;
        // Vertex shader
        const vertex = gl.createShader(gl.VERTEX_SHADER);
        const vertex_code_ptr: ?[*]const u8 = vertex_shader_code.ptr;
        gl.shaderSource(vertex, 1, &vertex_code_ptr, null);
        gl.compileShader(vertex);
        checkCompileErrors(vertex, .VERTEX);
        gl.getShaderiv(vertex, gl.COMPILE_STATUS, &success);
        // Fragment code
        const fragment = gl.createShader(gl.FRAGMENT_SHADER);
        const fragment_code_ptr: ?[*]const u8 = fragment_shader_code.ptr;
        gl.shaderSource(fragment, 1, &fragment_code_ptr, null);
        gl.compileShader(fragment);
        gl.getShaderiv(fragment, gl.COMPILE_STATUS, &success);
        checkCompileErrors(fragment, .FRAGMENT);
        // Build the shader program
        const id = gl.createProgram();
        gl.attachShader(id, vertex);
        gl.attachShader(id, fragment);
        var err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err(
                "ERROR::SHADER::PROGRAM::ATTACH_FAILED\nErrno: {d}",
                .{err},
            );
        }
        gl.linkProgram(id);
        checkCompileErrors(id, .PROGRAM);
        // Delete the shaders
        gl.deleteShader(vertex);
        gl.deleteShader(fragment);
        return Shader{ .id = id };
    }

    pub fn use(self: Shader) void {
        gl.useProgram(self.id);
    }

    pub fn setBool(self: Shader, name: [:0]const u8, value: bool) void {
        gl.uniform1i(gl.getUniformLocation(self.id, name), value);
    }

    pub fn setInt(self: Shader, name: [:0]const u8, value: gl.GLint) void {
        gl.uniform1i(gl.getUniformLocation(self.id, name), value);
    }

    pub fn setFloat(self: Shader, name: [:0]const u8, value: gl.GFloat) void {
        gl.uniform1f(gl.getUniformLocation(self.id, name), value);
    }
};

fn checkCompileErrors(
    shader: gl.GLuint,
    shader_type: ShaderType,
) void {
    var success: gl.GLint = 0;
    var info_log: [1024]u8 = undefined;
    std.debug.print("Checking shader: {d} - {s}\n", .{ shader, shader_type.str() });
    switch (shader_type) {
        .PROGRAM => {
            gl.getProgramiv(shader, gl.COMPILE_STATUS, &success);
            if (success == 0) {
                gl.getShaderInfoLog(shader, 1024, null, &info_log);
                std.log.err(
                    "ERROR::SHADER::{s}::COMPILATION_FAILED\n{s}",
                    .{ shader_type.str(), info_log },
                );
            }
        },
        else => {
            gl.getProgramiv(shader, gl.LINK_STATUS, &success);
            if (success == 0) {
                gl.getShaderInfoLog(shader, 1024, null, &info_log);
                std.log.err(
                    "ERROR::SHADER::{s}::LINKING_FAILED\n{s}",
                    .{ shader_type.str(), info_log },
                );
            }
        },
    }
}

const ShaderType = enum {
    PROGRAM,
    VERTEX,
    FRAGMENT,

    const TypeToString = [@typeInfo(ShaderType).Enum.fields.len][]const u8{
        "PROGRAM",
        "VERTEX",
        "FRAGMENT",
    };

    pub fn str(self: ShaderType) []const u8 {
        return switch (self) {
            .PROGRAM => "PROGRAM",
            .VERTEX => "VERTEX",
            .FRAGMENT => "FRAGMENT",
        };
    }
};
