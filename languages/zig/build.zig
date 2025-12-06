const std = @import("std");
const builtin = @import("builtin");
const CompileStep = std.Build.Step.Compile;

const required_zig_version = std.SemanticVersion.parse("0.15.0") catch unreachable;

// taken and modified from: https://github.com/SpexGuy/Zig-AoC-Template/
pub fn build(b: *std.Build) !void {
    if (comptime builtin.zig_version.order(required_zig_version) == .lt) {
        std.debug.print("Warning: Your version of Zig too old. You will need to download a newer build\n", .{});
        std.os.exit(1);
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("terminal_progress", .{
        .root_source_file = b.path("src/terminal_progress.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (builtin.os.tag == .linux) {
        const main_tests = b.addTest(.{ .root_module = b.addModule("terminal_progress_tests", .{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }) });

        main_tests.root_module.addImport("terminal_progress", module);
        main_tests.linkLibC();

        const run_main_tests = b.addRunArtifact(main_tests);

        const test_step = b.step("test", "Run library tests");
        test_step.dependOn(&run_main_tests.step);
    }
}
