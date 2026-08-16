const std = @import("std");

/// Copies the live prefix required by a suspended parent. The caller owns both
/// bounded arrays, so child exec may reset or reuse the live pool afterward.
pub fn snapshot(live: anytype, saved: @TypeOf(live), cursor: usize) usize {
    std.debug.assert(cursor <= live.len and live.len == saved.len);
    @memcpy(saved[0..cursor], live[0..cursor]);
    return cursor;
}

/// Restores exactly the parent's allocated prefix and coherent next cursor.
pub fn restore(live: anytype, saved: @TypeOf(live), cursor: usize) usize {
    std.debug.assert(cursor <= live.len and live.len == saved.len);
    @memcpy(live[0..cursor], saved[0..cursor]);
    return cursor;
}

test "child reset and reuse cannot corrupt parent private mapping bytes" {
    var live = [_][4]u8{ .{ 1, 2, 3, 4 }, .{ 5, 6, 7, 8 }, .{ 0, 0, 0, 0 } };
    var saved: @TypeOf(live) = undefined;
    const parent_cursor = snapshot(&live, &saved, 2);

    live = .{ .{ 9, 9, 9, 9 }, .{ 8, 8, 8, 8 }, .{ 7, 7, 7, 7 } };
    var child_cursor: usize = 3;
    child_cursor = restore(&live, &saved, parent_cursor);

    try std.testing.expectEqual(@as(usize, 2), child_cursor);
    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3, 4 }, &live[0]);
    try std.testing.expectEqualSlices(u8, &.{ 5, 6, 7, 8 }, &live[1]);
}
