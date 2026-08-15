const std = @import("std");

/// The compatibility-edge subset of Linux asm-generic `struct stat` needed by
/// already-open Morphic resources.  Callers retain ownership of the resource;
/// encoding is pure and therefore cannot change its shared file offset.
pub const Metadata = struct {
    inode: u64,
    mode: u32,
    size: u64,
};

pub fn encode(metadata: Metadata) [128]u8 {
    var stat: [128]u8 = .{0} ** 128;
    std.mem.writeInt(u64, stat[0..8], 1, .little); // st_dev
    std.mem.writeInt(u64, stat[8..16], metadata.inode, .little);
    std.mem.writeInt(u32, stat[16..20], metadata.mode, .little);
    std.mem.writeInt(u32, stat[20..24], 1, .little); // st_nlink
    std.mem.writeInt(u64, stat[48..56], metadata.size, .little);
    std.mem.writeInt(u32, stat[56..60], 4096, .little); // st_blksize
    std.mem.writeInt(u64, stat[64..72], (metadata.size + 511) / 512, .little);
    return stat;
}

pub fn copyOut(metadata: Metadata, destination: usize, copier: anytype) !void {
    const stat = encode(metadata);
    try copier(destination, &stat);
}

test "regular metadata is coherent and encoding does not carry an offset" {
    const stat = encode(.{ .inode = 17, .mode = 0o100755, .size = 513 });
    try std.testing.expectEqual(@as(u64, 1), std.mem.readInt(u64, stat[0..8], .little));
    try std.testing.expectEqual(@as(u64, 17), std.mem.readInt(u64, stat[8..16], .little));
    try std.testing.expectEqual(@as(u32, 0o100755), std.mem.readInt(u32, stat[16..20], .little));
    try std.testing.expectEqual(@as(u64, 513), std.mem.readInt(u64, stat[48..56], .little));
    try std.testing.expectEqual(@as(u64, 2), std.mem.readInt(u64, stat[64..72], .little));
}

test "copyout failure is explicit" {
    const Reject = struct {
        fn copy(_: usize, _: []const u8) error{InvalidUserMemory}!void {
            return error.InvalidUserMemory;
        }
    };
    try std.testing.expectError(error.InvalidUserMemory, copyOut(.{ .inode = 1, .mode = 0o010600, .size = 0 }, 0, Reject.copy));
}
