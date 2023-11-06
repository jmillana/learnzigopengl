# LearnZigOpenGL

This repository provides a comprehensive guide for porting the [LearnOpenGL](https://learnopengl.com/) tutorials to [Zig](https://ziglang.org/), using [zig-opengl](https://github.com/MasterQ32/zig-opengl) and [mach-glfw](https://github.com/hexops/mach-glfw).

## Objective

The primary aim of this project is to create a foundational resource for OpenGL development in the Zig programming language. Navigating the existing materials for setting up and running OpenGL projects in Zig can be daunting, which motivated me to start this learning journey. 
I hope that this repository will assist some of you in the future by providing a clear and detailed pathway to getting started on OpenGL with Zig.

## Getting Started

To ensure a smooth start with the tutorials, we must first establish our development environment by installing the necessary dependencies.

### Prerequisites

#### Zig
You should have Zig installed on your system. If not, follow the instructions here: [Installing Zig](https://ziglang.org/learn/getting-started/#installing-zig).

#### .NET
.NET is required for building the Zig bindings for OpenGL.
Download and install .NET from [Microsoft's .NET Download Page](https://dotnet.microsoft.com/en-us/download).

##### On Linux:
```bash
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x ./dotnet-install.sh
./dotnet-install.sh --version latest
```

### Obtain the OpenGL Bindings
The [zig-opengl](https://github.com/MasterQ32/zig-opengl) repository offers a method to generate Zig bindings for OpenGL. Customize the `GL_VERSION_X_Y` to correspond with the desired version. See the [zig-opengl README](https://github.com/MasterQ32/zig-opengl) for all available versions.
```bash
git clone --recursive https://github.com/MasterQ32/zig-opengl.git
cd zig-opengl
dotnet run OpenGL-Registry/xml/gl.xml gl4v6.zig GL_VERSION_4_6
```

### Clone This Tutorial Repository
```bash
git clone https://github.com/jmillana/learnzigopengl.git
```
Then, transfer the generated OpenGL bindings into the libs/ directory of this tutorial's repository.

If you opted for a different OpenGL version, you will need to update the build.zig file accordingly:

```zig
const std = @import("std");
const print = std.debug.print;

const OPENGL_BINDINGS_PATH = "libs/gl4v6.zig";

pub fn build(b: *std.Build) void {
  ...
```
# Tutorials
Each tutorial is encapsulated in its own directory located at src/tutorial_<tutorial_number>. You'll find a dedicated README within each tutorial's folder to guide you through its specifics.

## Running the Tutorials
To run a specific tutorial, use the command below, replacing <tutorial_number> with the number corresponding to the tutorial you wish to execute.
```
zig build run -Dn=<tutorial_number>  
```
To see a list of all available tutorials and instructions on how to run them, simply execute zig build without additional parameters. You will receive an output that provides usage details and lists the currently implemented tutorials:
```
zig build
> Usage:
> zig build run -Dn=<tutorial_number>
>
> Available tutorials: 1 - 2 
```

## List of Tutorials
- Tutorial 1: Setting up a Window
- Tutorial 2: Rendering a Triangle

# Contributions
This project is made entirely for fun as a way to get starged into computer grafics while deepend the knowledge about zig (at the time of writing this I'm preatty much a noob in both fields).

Whether you wish to enhance the documentation or add more tutorials, please feel free to fork this repository and open a PR.
