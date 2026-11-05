const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wmux_tui = b.addModule("wmux_tui", .{
        .root_source_file = b.path("../../../zig/src/cmux.zig"),
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
        .name = "cmux-resource-conformance-zig",
        .root_module = adapter,
    });
    b.installArtifact(executable);

    const adapter_tests = b.addTest(.{
        .name = "cmux-resource-conformance-zig-tests",
        .root_module = adapter,
    });
    const run_adapter_tests = b.addRunArtifact(adapter_tests);
    const test_step = b.step("test", "Run the Zig resource conformance adapter tests");
    test_step.dependOn(&run_adapter_tests.step);
}
