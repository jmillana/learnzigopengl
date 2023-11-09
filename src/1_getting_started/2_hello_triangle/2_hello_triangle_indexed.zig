const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const fs = std.fs;

const log = std.log.scoped(.Engine);

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("ERROR::GLFW::INITIALIZATION_FAILED: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Tutorial 2: Triangle", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 6,
    }) orelse {
        std.log.err("ERROR::GLFW::WINDOW::CREATION_FAILED: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    // SHADERS
    // Vertex shader: more details inside the file.
    const allocator = std.heap.page_allocator;
    const vertex_shader_file = try fs.cwd().openFile(
        "src/shaders/2_1_shader.vs",
        .{ .mode = .read_only },
    );
    defer vertex_shader_file.close();
    const vertex_shader_source = try allocator.alloc(u8, try vertex_shader_file.getEndPos());
    _ = try vertex_shader_file.read(vertex_shader_source);
    defer allocator.free(vertex_shader_source);
    var vertex_shader: gl.GLuint = gl.createShader(gl.VERTEX_SHADER);
    const vertex_shader_source_ptr: ?[*]const u8 = vertex_shader_source.ptr;
    gl.shaderSource(vertex_shader, 1, &vertex_shader_source_ptr, null);
    gl.compileShader(vertex_shader);
    var success: gl.GLint = 0;
    // Check the compilation status.
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        gl.getShaderInfoLog(vertex_shader, 512, &logSize, &logInfo);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{?s}", .{logInfo[0..i]});
        std.process.exit(1);
    } else {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        gl.getShaderInfoLog(vertex_shader, 512, &logSize, &logInfo);
        std.log.debug("DEBUG::SHADER::VERTEX::COMPILATION_SUCCESS\n{s}", .{logInfo[0..i]});
    }

    // Fragment shader
    const fragment_shader_file = try fs.cwd().openFile(
        "src/shaders/2_1_shader.fs",
        .{ .mode = .read_only },
    );
    defer fragment_shader_file.close();
    const fragment_shader_source = try allocator.alloc(u8, try fragment_shader_file.getEndPos());
    _ = try fragment_shader_file.read(fragment_shader_source);
    defer allocator.free(fragment_shader_source);
    var fragment_shader: gl.GLuint = gl.createShader(gl.FRAGMENT_SHADER);
    const fragment_shader_source_ptr: ?[*]const u8 = fragment_shader_source.ptr;
    gl.shaderSource(fragment_shader, 1, &fragment_shader_source_ptr, null);
    gl.compileShader(fragment_shader);
    // Check the compilation status
    gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}", .{logInfo[0..i]});
        std.process.exit(1);
    } else {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        std.log.debug("DEBUG::SHADER::FRAGMEN::COMPILATION_SUCCESS\n{s}", .{logInfo[0..i]});
    }

    var shaderProgram: gl.GLuint = gl.createProgram();
    gl.attachShader(shaderProgram, vertex_shader);
    gl.attachShader(shaderProgram, fragment_shader);
    var err = gl.getError();
    if (err != gl.NO_ERROR) {
        std.log.err("Failed to attach shaders: errno: {d}", .{err});
        std.process.exit(1);
    }
    gl.linkProgram(shaderProgram);
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        std.log.err("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}", .{logInfo[0..i]});
        std.process.exit(1);
    } else {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        std.log.debug("DEBUG::SHADER::PROGRAM::LINKING_SUCCESS\n{s}", .{logInfo[0..i]});
    }
    // After creating the program the shadres are no longer used
    gl.deleteShader(vertex_shader);
    gl.deleteShader(fragment_shader);
    err = gl.getError();
    if (err != gl.NO_ERROR) {
        std.log.err("ERROR::SHADER::DELETION_FAILED: errno: {d}", .{err});
        std.process.exit(1);
    }

    // Now lets describe a set of vertices
    // We pick the union of the vertices of both triangles
    const vertices = [_]gl.GLfloat{
        // Triangle 1
        0.5, 0.5, 0.0, // top right
        0.5, -0.5, 0.0, // bottom right
        // -0.5, 0.5, 0.0, // top left
        // Triangle 2
        // 0.5,  -0.5, 0.0, // bottom right
        -0.5, -0.5, 0.0, // bottom left
        -0.5, 0.5, 0.0, // top left
    };
    // Pich the indeces to build each triangle.
    const indices = [_]gl.GLuint{
        0, 1, 3, // fist triangle
        1, 2, 3, // second triangle
    };
    var VAO: gl.GLuint = undefined;
    var VBO: gl.GLuint = undefined;
    var EBO: gl.GLuint = undefined;
    gl.genVertexArrays(1, &VAO);
    defer gl.deleteBuffers(1, &VAO);
    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);
    gl.genBuffers(1, &EBO);
    defer gl.deleteBuffers(1, &EBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        vertices.len * @sizeOf(gl.GLfloat),
        &vertices,
        gl.STATIC_DRAW,
    );

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        @sizeOf(gl.GLuint) * indices.len,
        &indices,
        gl.STATIC_DRAW,
    );

    // Set the vertex attrs to pinters
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(gl.GLfloat), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    err = gl.getError();
    if (err != gl.NO_ERROR) {
        std.log.err("ERROR::VBO: errno: {d}", .{err});
        std.process.exit(1);
    }

    // Uncoment to draw in wireframe mode
    // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);
    while (!window.shouldClose()) {
        glfw.pollEvents();

        gl.clearColor(1, 0, 1, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shaderProgram);
        err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err("ERROR::SHADER::PROGRAM::USE_FAILED: errno: {d}", .{err});
        }
        gl.bindVertexArray(VAO);
        err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err("ERROR::VAO::BINDING_FAILED: errno: {d}", .{err});
        }
        // Call to the propper draw method
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);
        err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err("ERROR::DRAW::ARRAYS::FAILED_TO_DRAW: errno: {d}", .{err});
        }

        window.swapBuffers();
    }
}
