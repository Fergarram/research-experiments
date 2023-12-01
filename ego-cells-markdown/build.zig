const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;
const raylib = @import("raylib/lib.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{}); // Used for Raylib

    const exe = b.addExecutable("ego-cells-markdown", "main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(target); // Used for Raylib

    // OpenCL
    exe.addIncludePath("./opencl");
    exe.linkSystemLibrary("c");

    switch (builtin.os.tag) {
        .windows => {
            std.debug.print("Windows detected, adding default CUDA SDK x64 lib search path. Change this in build.zig if needed...\n", .{});
            exe.addLibPath("C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v10.1/lib/x64");
        },
        .macos => {
            std.debug.print("MacOS detected.\n", .{});
            exe.linkFramework("OpenCL");
        },
        else => {
            std.debug.print("Looking for OpenCL in system.\n", .{});
            exe.linkSystemLibrary("OpenCL");
        }
    }

    // Raylib
    const systemLib = b.option(
        bool,
        "system-raylib",
        "link to preinstalled raylib libraries"
    ) orelse false;
    raylib.link(exe, systemLib);
    raylib.addAsPackage("raylib", exe);
    raylib.math.addAsPackage("raylib-math", exe);

    exe.install(); // Used for both

    const runCmd = exe.run();
    runCmd.step.dependOn(b.getInstallStep()); // Used for OpenCL

    const runStep = b.step("run", "Run the app");
    runStep.dependOn(&runCmd.step);
}
