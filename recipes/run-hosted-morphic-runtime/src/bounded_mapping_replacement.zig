const std = @import("std");

/// Failure-atomic fixed replacement. The caller prepares backing and captures
/// prior leaves before entry; this helper owns topology commit and rollback.
pub fn replace(table: anytype, start: usize, length: usize, permissions: @TypeOf(table.*).PermissionsType, class: @TypeOf(table.*).BackingClassType, backing_start: usize, page_count: usize, context: anytype) !void {
    const snapshot = table.*;
    try table.replaceBackingRange(start, length, permissions, class, backing_start);
    var replaced: usize = 0;
    while (replaced < page_count) : (replaced += 1) {
        context.replacePage(replaced) catch |err| {
            context.restorePages(replaced + 1) catch unreachable;
            table.* = snapshot;
            return err;
        };
    }
}

test "mid replacement failure restores topology leaves bytes and cursor" {
    const mappings = @import("bounded_runtime_mappings.zig");
    const Table = mappings.BoundedRuntimeMappings(3, 4);
    var table: Table = .{};
    try table.reserve(0x1000, 8, .{ .read = true }, false, {}, struct {
        fn occupied(_: void, _: usize) bool {
            return false;
        }
    }.occupied);
    table.setLastBacking(.private_file, 5);
    const before = table;
    const cursor: usize = 9;
    const Context = struct {
        leaves: [2]u8 = .{ 0xaa, 0xbb },
        prior: [2]u8 = .{ 0xaa, 0xbb },
        fail_at: usize = 1,
        fn replacePage(self: *@This(), index: usize) !void {
            self.leaves[index] = 0;
            if (index == self.fail_at) return error.ForcedMapFailure;
            self.leaves[index] = 0x11;
        }
        fn restorePages(self: *@This(), count: usize) !void {
            @memcpy(self.leaves[0..count], self.prior[0..count]);
        }
    };
    var context: Context = .{};
    try std.testing.expectError(error.ForcedMapFailure, replace(&table, 0x1000, 8, Table.PermissionsType{ .read = true, .write = true }, .prepared, cursor, 2, &context));
    try std.testing.expectEqualDeep(before, table);
    try std.testing.expectEqualSlices(u8, &.{ 0xaa, 0xbb }, &context.leaves);
    try std.testing.expectEqual(@as(usize, 9), cursor);
}

test "unbacked PROT_NONE reservation can become backed RW without a prior leaf" {
    const mappings = @import("bounded_runtime_mappings.zig");
    const Table = mappings.BoundedRuntimeMappings(1, 4);
    var table: Table = .{};
    try table.reserve(0x2000, 4, .{}, false, {}, struct {
        fn occupied(_: void, _: usize) bool {
            return false;
        }
    }.occupied);
    const Context = struct {
        leaf: ?u8 = null,
        fn replacePage(self: *@This(), _: usize) !void {
            self.leaf = 0;
        }
        fn restorePages(self: *@This(), _: usize) !void {
            self.leaf = null;
        }
    };
    var context: Context = .{};
    try replace(&table, 0x2000, 4, Table.PermissionsType{ .read = true, .write = true }, .prepared, 3, 1, &context);
    try std.testing.expectEqual(@as(?u8, 0), context.leaf);
    try std.testing.expect(table.entries[0].permissions.write);
    try std.testing.expectEqual(mappings.BackingClass.prepared, table.entries[0].backing_class);
    try std.testing.expectEqual(@as(usize, 3), table.entries[0].backing_start);
}
