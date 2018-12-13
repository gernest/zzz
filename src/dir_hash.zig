const std = @import("std");
const mem = std.mem;
const io = std.io;
const json = std.json;
const path = std.os.path;
const Sha3_256 = std.crypto.Sha3_256;
const warn = std.debug.warn;
const Dir = std.os.Dir;
const Entry = std.os.Dir.Entry;
const base64 = std.base64.standard_encoder;

const String = std.ArrayList(u8);

pub fn hashDir(allocator: *std.mem.Allocator, output_buf: *std.Buffer, full_path: []const u8) !void {
    var buf = &try std.Buffer.init(allocator, "");
    defer buf.deinit();
    var stream = io.BufferOutStream.init(buf);
    try walkTree(allocator, &stream.stream, full_path);
    var h = Sha3_256.init();
    var out: [Sha3_256.digest_length]u8 = undefined;
    h.update(buf.toSlice());
    h.final(out[0..]);
    try output_buf.resize(std.base64.Base64Encoder.calcSize(out.len));
    base64.encode(output_buf.toSlice(), out[0..]);
}

fn walkTree(allocator: *std.mem.Allocator, stream: var, full_path: []const u8) anyerror!void {
    var dir = try Dir.open(allocator, full_path);
    defer dir.close();
    var full_entry_buf = String.init(allocator);
    defer full_entry_buf.deinit();
    var h = Sha3_256.init();
    var out: [Sha3_256.digest_length]u8 = undefined;

    while (try dir.next()) |entry| {
        try full_entry_buf.resize(full_path.len + entry.name.len + 1);
        const full_entry_path = full_entry_buf.toSlice();
        mem.copy(u8, full_entry_path, full_path);
        full_entry_path[full_path.len] = path.sep;
        mem.copy(u8, full_entry_path[full_path.len + 1 ..], entry.name);
        switch (entry.kind) {
            Entry.Kind.File => {
                const content = try io.readFileAlloc(allocator, full_entry_path);
                errdefer allocator.free(content);
                h.reset();
                h.update(content);
                h.final(out[0..]);
                try stream.print("{x} {s}\n", out, full_entry_path);
                allocator.free(content);
            },
            Entry.Kind.Directory => {
                try walkTree(allocator, stream, full_entry_path);
            },
            else => {},
        }
    }
}

test "list" {
    const path_src = "/Volumes/code/zig/zig-src/std/atomic";
    var allocator = std.debug.global_allocator;
    var buf = &try std.Buffer.init(allocator, "");
    defer buf.deinit();
    try hashDir(allocator, buf, path_src);

    warn("\nh1:{}", buf.toSlice());
}

const Hash = struct {
    name: []const u8,
    hash: []const u8,
};
