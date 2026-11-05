const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wmux_tui = b.addModule("wmux_tui", .{
        .root_source_file = b.path("../../../../zig/src/cmux.zig"),
        .target = target,
        .optimize = optimize,
    });
    const adapter = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
    });
    adapter.addImport("wmux_tui", wmux_tui);

    const executable = b.addExecutable(.{
        .name = "cmux-conformance-zig",
        .root_module = adapter,
    });
    b.installArtifact(executable);
}
