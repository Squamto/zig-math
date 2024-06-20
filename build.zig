const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options: std.Build.StaticLibraryOptions = .{
        .name = "math",
        .root_source_file = b.path("src/math.zig"),
        .target = target,
        .optimize = optimize,
    };

    const lib = b.addStaticLibrary(options);
    b.installArtifact(lib);

    const module = b.addModule("math", .{
        .root_source_file = b.path("src/math.zig"),
    });
    _ = module; // autofix

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/math.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const doc_compile = b.addStaticLibrary(options);

    const docs = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = doc_compile.getEmittedDocs(),
    });

    const doc_step = b.step("doc", "Install documentation");
    doc_step.dependOn(&docs.step);
}
