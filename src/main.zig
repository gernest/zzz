const std = @import("std");
const clap = @import("clap");
const mem = std.mem;
const io = std.io;
const json = std.json;
const path = std.os.path;
const Sha3_256 = std.crypto.Sha3_256;
const warn = std.debug.warn;
const Dir = std.os.Dir;
const Entry = std.os.Dir.Entry;
const base64 = std.base64.standard_encoder;

fn hashDir(allocator: *std.mem.Allocator, output_buf: *std.Buffer, full_path: []const u8) !void {
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
    var full_entry_buf = std.ArrayList(u8).init(allocator);
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

pub fn main() !void {
    const stdout_file = try std.io.getStdOut();
    var stdout_out_stream = stdout_file.outStream();
    const stdout = &stdout_out_stream.stream;

    var direct_allocator = std.heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    // First we specify what parameters our program can take.
    const params = comptime []clap.Param([]const u8){
        clap.Param([]const u8).option(
            "Base64 encoded hash of the directory",
            clap.Names.both("hash"),
        ),
        clap.Param([]const u8).flag(
            "Verifies the hash provided by --hash flag against the directory",
            clap.Names.both("verify"),
        ),
        clap.Param([]const u8).flag(
            "calculates and prints checksum of a directory",
            clap.Names.both("sum"),
        ),
        clap.Param([]const u8).positional("hash"),
        clap.Param([]const u8).positional("verify"),
    };

    // We then initialize an argument iterator. We will use the OsIterator as it nicely
    // wraps iterating over arguments the most efficient way on each os.
    var os_iter = clap.args.OsIterator.init(allocator);
    const iter = &os_iter.iter;
    defer os_iter.deinit();

    // Consume the exe arg.
    const exe = try iter.next();
    var buf = &try std.Buffer.init(allocator, "");
    defer buf.deinit();
    // Finally we can parse the arguments
    var args = try clap.ComptimeClap([]const u8, params).parse(allocator, clap.args.OsIterator.Error, iter);
    defer args.deinit();
    if (args.flag("--sum")) {
        const pos = args.positionals();
        if (pos.len != 1) {
            warn("missing dir path");
            return;
        }
        try hashDir(allocator, buf, pos[0]);
        warn("{}", buf.toSlice());
        return;
    }

    if (args.flag("--verify")) {
        const pos = args.positionals();
        if (pos.len != 1) {
            warn("missing dir path");
            return;
        }
        var h = args.option("--hash");
        if (h == null) {
            warn("missing --hash flag value");
            return;
        }
        try hashDir(allocator, buf, pos[0]);
        if (buf.eql(h.?)) {
            warn("pass");
        } else {
            warn("failed validation expected want {} got {}", h, buf.toSlice());
        }
        return;
    }
    return try clap.help(stdout, params);
}
