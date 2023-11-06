const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

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
    // This block is the same as Tutorial 1
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
    // END: Tutorial 1 block

    // Time for triangles.
    const vertices = [9]gl.GLfloat{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // The Vertex Array Object
    // The VAO stores the vertex atribute calls, in order to change between
    // different vertex data and attrs configurations is as easy as binding
    // to a defferent VAO
    var VAO: gl.GLuint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);
    // The Vertex Buffer Object
    // The VBO object manages the GPU memory that will be used to allocate
    // the vertices. This will be handy when we want to send large batches of
    // data at once to the GPU.
    var VBO: gl.GLuint = undefined;
    gl.genBuffers(1, &VBO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    // The bufferData function copies user-defined data into the boulnd buffer.
    // With the STATIC_DRAW flag indicate that the data will be set only once
    gl.bufferData(
        gl.ARRAY_BUFFER,
        vertices.len * @sizeOf(gl.GLfloat),
        &vertices,
        gl.STATIC_DRAW,
    );
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(gl.GLfloat), null);
    gl.enableVertexAttribArray(0);

    var err = gl.getError();
    if (err != gl.NO_ERROR) {
        std.log.err("ERROR::VBO: errno: {d}", .{err});
        std.process.exit(1);
    }

    // Vertex shader: more details inside the file.
    const vertexShaderSource: [:0]const u8 = @embedFile("triangle.vs");
    var vertexShader: gl.GLuint = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, 1, &[_][*c]const u8{vertexShaderSource.ptr}, null);
    gl.compileShader(vertexShader);
    var success: gl.GLint = 0;
    // Check the compilation status.
    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &logInfo);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{?s}", .{logInfo[0..i]});
        std.process.exit(1);
    } else {
        var logInfo: [512]u8 = undefined;
        var logSize: gl.GLint = 0;
        var i: usize = @intCast(logSize);
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &logInfo);
        std.log.debug("DEBUG::SHADER::VERTEX::LINKING_SUCCESS\n{s}", .{logInfo[0..i]});
    }

    // Fragment shader
    const fragmentShaderSource: [:0]const u8 = @embedFile("triangle.fs");
    var fragmentShader: gl.GLuint = gl.createShader(gl.FRAGMENT_SHADER);

    gl.shaderSource(fragmentShader, 1, &[_][*c]const u8{fragmentShaderSource.ptr}, null);
    gl.compileShader(fragmentShader);
    // Check the compilation status
    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
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
        std.log.debug("DEBUG::SHADER::FRAGMEN::LINKING_SUCCESS\n{s}", .{logInfo[0..i]});
    }

    // Shader Program
    // The final linked version of multiple shaders combined. To use the combenid
    // shaders we have to link them to the shader program object and then activate
    // it when rendering oblects.
    //
    // When linking the shaders, it links the outputs of each shader to the inputs
    // of the next shader. Also it will link errors if the outputs and inputs
    // do not match
    var shaderProgram: gl.GLuint = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    err = gl.getError();
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
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    err = gl.getError();
    if (err != gl.NO_ERROR) {
        std.log.err("ERROR::SHADER::DELETION_FAILED: errno: {d}", .{err});
        std.process.exit(1);
    }

    // Wait for the user to close the window.
    // The main rendering loop remains the same, we will be adding the
    // rendering of the triangle in between
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
        gl.drawArrays(gl.TRIANGLES, 0, 3);
        err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err("ERROR::DRAW::ARRAYS::FAILED_TO_DRAW: errno: {d}", .{err});
        }

        window.swapBuffers();
    }
}
