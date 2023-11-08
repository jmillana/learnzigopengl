#version 460 core
/* The shader files are written in GLSL (OpenGL Shading Language)
* The version 460 corresponds to the OpenGL version 4.6
*/
layout (location = 0) in vec3 aPos;
void main() {
    gl_Position= vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
