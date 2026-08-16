const std = @import("std");
pub const entries_per_page = 512;
pub const Error = error{ OutOfPages, UnknownFrame, ProviderReadFailure, ProviderWriteFailure, StillOwned };
pub fn PageOwner(comptime capacity: usize) type {
    return struct {
        const Self = @This();
        pub const Page = struct { frame: u64, entries: [entries_per_page]u64 };
        pages: [capacity]Page = undefined,
        used: [capacity]bool = [_]bool{false} ** capacity,
        next_frame: u64 = 0x1000,
        fail_reads: bool = false,
        fail_writes: bool = false,
        pub fn allocate(self: *Self) Error!u64 {
            for (0..capacity) |i| if (!self.used[i]) {
                self.used[i] = true;
                self.pages[i] = .{ .frame = self.next_frame, .entries = [_]u64{0} ** entries_per_page };
                self.next_frame += 4096;
                return self.pages[i].frame;
            };
            return error.OutOfPages;
        }
        pub fn release(self: *Self, frame: u64) Error!void {
            for (0..capacity) |i| if (self.used[i] and self.pages[i].frame == frame) {
                self.used[i] = false;
                return;
            };
            return error.UnknownFrame;
        }
        pub fn read(self: *Self, frame: u64, index: usize) Error!u64 {
            if (self.fail_reads) return error.ProviderReadFailure;
            for (0..capacity) |i| if (self.used[i] and self.pages[i].frame == frame) return self.pages[i].entries[index];
            return error.UnknownFrame;
        }
        pub fn write(self: *Self, frame: u64, index: usize, value: u64) Error!void {
            if (self.fail_writes) return error.ProviderWriteFailure;
            for (0..capacity) |i| if (self.used[i] and self.pages[i].frame == frame) {
                self.pages[i].entries[index] = value;
                return;
            };
            return error.UnknownFrame;
        }
        pub fn owns(self: *const Self, frame: u64) bool {
            for (0..capacity) |i| if (self.used[i] and self.pages[i].frame == frame) return true;
            return false;
        }
        pub fn count(self: *const Self) usize {
            var n: usize = 0;
            for (self.used) |u| {
                if (u) n += 1;
            }
            return n;
        }
        pub fn deinit(self: *Self) void {
            self.used = [_]bool{false} ** capacity;
        }
    };
}
test "allocation is explicit, zeroed, bounded and releasable" {
    var o = PageOwner(1){};
    const f = try o.allocate();
    try std.testing.expectEqual(@as(u64, 0), try o.read(f, 0));
    try std.testing.expectError(error.OutOfPages, o.allocate());
    try o.release(f);
    try std.testing.expectEqual(@as(usize, 0), o.count());
}
