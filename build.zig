const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zzz", "src/main.zig");
    exe.addPackagePath("clap", "lib/clap/src/index.zig");
    exe.setBuildMode(mode);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
