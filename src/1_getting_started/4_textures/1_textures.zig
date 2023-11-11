const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const fs = std.fs;
const Shader = @import("../../shader.zig").Shader;
const zstbi = @import("zstbi");

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
    // END: Tutorial 1 block
    const allocator = std.heap.page_allocator;
    const vertex_path = "src/shaders/1_4_1_shader.vs";
    const fragment_path = "src/shaders/1_4_1_shader.fs";

    const shader = try Shader.init(allocator, vertex_path, fragment_path);

    const vertices = [_]gl.GLfloat{
        // Position       // colors       // Colors
        0.5,  0.5,  0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0,
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
        -0.5, 0.5,  0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
    };

    const indices = [_]gl.GLuint{
        0, 1, 3,
        1, 2, 3,
    };

    // The Vertex Array Object
    // The VAO stores the vertex atribute calls, in order to change between
    // different vertex data and attrs configurations is as easy as binding
    // to a defferent VAO
    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;
    var EBO: c_uint = undefined;
    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);
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
        indices.len * @sizeOf(gl.GLfloat),
        &indices,
        gl.STATIC_DRAW,
    );

    // Position attribute
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(gl.GLfloat), null);
    gl.enableVertexAttribArray(0);

    // Color attibute
    gl.vertexAttribPointer(
        1,
        3,
        gl.FLOAT,
        gl.FALSE,
        8 * @sizeOf(gl.GLfloat),
        @ptrFromInt(3 * @sizeOf(gl.GLfloat)),
    );
    gl.enableVertexAttribArray(1);

    // Texture attribute
    gl.vertexAttribPointer(
        2,
        2,
        gl.FLOAT,
        gl.FALSE,
        8 * @sizeOf(gl.GLfloat),
        @ptrFromInt(6 * @sizeOf(gl.GLfloat)),
    );
    gl.enableVertexAttribArray(2);

    // Load texture
    var texture: c_uint = undefined;
    gl.genTextures(1, &texture);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    zstbi.init(allocator);
    defer zstbi.deinit();
    // Container texture
    const container_texture_info = zstbi.Image.info("textures/container.jpg");
    var container_texture = try zstbi.Image.loadFromFile(
        "textures/container.jpg",
        container_texture_info.num_components,
    );
    defer container_texture.deinit();
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGB,
        @intCast(container_texture.width),
        @intCast(container_texture.height),
        0,
        gl.RGB,
        gl.UNSIGNED_BYTE,
        container_texture.data.ptr,
    );

    shader.use();
    gl.uniform1i(gl.getUniformLocation(shader.id, "texture"), 0);
    // Wait for the user to close the window.
    // The main rendering loop remains the same, we will be adding the
    // rendering of the triangle in between
    while (!window.shouldClose()) {
        glfw.pollEvents();

        gl.clearColor(1, 0, 1, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // bind textures
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture);

        shader.use();

        gl.bindVertexArray(VAO);
        var err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err("ERROR::VAO::BINDING_FAILED: errno: {d}", .{err});
        }
        // Call to the propper draw method
        //gl.drawArrays(gl.TRIANGLES, 0, 3);
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);
        err = gl.getError();
        if (err != gl.NO_ERROR) {
            std.log.err("ERROR::DRAW::ARRAYS::FAILED_TO_DRAW: errno: {d}", .{err});
        }

        window.swapBuffers();
    }
}
