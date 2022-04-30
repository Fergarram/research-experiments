const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zig-opencl-test", "main.zig");
    exe.setBuildMode(mode);
    exe.addIncludeDir("./opencl");
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

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
