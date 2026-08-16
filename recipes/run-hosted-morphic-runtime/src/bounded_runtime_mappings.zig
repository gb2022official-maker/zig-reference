const std = @import("std");

pub const Permissions = packed struct {
    read: bool = false,
    write: bool = false,
    execute: bool = false,
};

pub const Mapping = struct {
    start: usize,
    end: usize,
    permissions: Permissions,
};

/// Allocation-free runtime address-range ownership. Linux flags and errno are
/// intentionally absent: personalities translate into this neutral boundary.
pub fn BoundedRuntimeMappings(comptime capacity: usize, comptime page_size: usize) type {
    if (capacity == 0 or page_size == 0 or page_size & (page_size - 1) != 0)
        @compileError("mapping capacity and power-of-two page size are required");

    return struct {
        const Self = @This();
        pub const Error = error{ InvalidRange, Collision, CapacityExceeded, WriteExecute };

        entries: [capacity]Mapping = undefined,
        count: usize = 0,

        /// Converts a non-empty, page-multiple byte length to a checked count.
        /// Keeping this operation here lets personalities pass only a neutral
        /// page count to their bounded backing allocator.
        pub fn pageCount(length: usize) Error!usize {
            if (length == 0 or length & (page_size - 1) != 0) return error.InvalidRange;
            return length / page_size;
        }

        /// A reservation with no access permissions intentionally owns virtual
        /// address space without consuming or installing data-page backing.
        pub fn hasBacking(mapping: Mapping) bool {
            return mapping.permissions.read or mapping.permissions.write or mapping.permissions.execute;
        }

        pub fn containsRange(self: *const Self, start: usize, length: usize) bool {
            const end = std.math.add(usize, start, length) catch return false;
            for (self.entries[0..self.count]) |entry|
                if (entry.start <= start and end <= entry.end) return true;
            return false;
        }

        pub fn releaseRange(self: *Self, start: usize, length: usize) Error!void {
            if (length == 0 or start & (page_size - 1) != 0 or length & (page_size - 1) != 0) return error.InvalidRange;
            const end = std.math.add(usize, start, length) catch return error.InvalidRange;
            var replacement: [capacity]Mapping = undefined;
            var replacement_count: usize = 0;
            for (self.entries[0..self.count]) |entry| {
                if (end <= entry.start or entry.end <= start) {
                    if (replacement_count == capacity) return error.CapacityExceeded;
                    replacement[replacement_count] = entry;
                    replacement_count += 1;
                } else {
                    if (entry.start < start) {
                        if (replacement_count == capacity) return error.CapacityExceeded;
                        replacement[replacement_count] = .{ .start = entry.start, .end = start, .permissions = entry.permissions };
                        replacement_count += 1;
                    }
                    if (end < entry.end) {
                        if (replacement_count == capacity) return error.CapacityExceeded;
                        replacement[replacement_count] = .{ .start = end, .end = entry.end, .permissions = entry.permissions };
                        replacement_count += 1;
                    }
                }
            }
            self.entries = replacement;
            self.count = replacement_count;
        }

        /// Reserves an aligned half-open range. `pageOccupied` lets the caller
        /// include executable, stack, brk, and page-table truth without copying
        /// those mappings into this table. Failure never changes the table.
        pub fn reserve(
            self: *Self,
            start: usize,
            length: usize,
            permissions: Permissions,
            replace_occupied: bool,
            context: anytype,
            pageOccupied: fn (@TypeOf(context), usize) bool,
        ) Error!void {
            if (length == 0 or start & (page_size - 1) != 0 or length & (page_size - 1) != 0)
                return error.InvalidRange;
            const end = std.math.add(usize, start, length) catch return error.InvalidRange;
            if (end <= start) return error.InvalidRange;
            if (permissions.write and permissions.execute) return error.WriteExecute;
            if (self.count == capacity) return error.CapacityExceeded;

            for (self.entries[0..self.count]) |entry|
                if (start < entry.end and entry.start < end) return error.Collision;
            var page = start;
            while (page < end) : (page += page_size)
                if (!replace_occupied and pageOccupied(context, page)) return error.Collision;

            self.entries[self.count] = .{ .start = start, .end = end, .permissions = permissions };
            self.count += 1;
        }

        /// Cancels only the reservation most recently made by the caller.
        /// This deliberately narrow rollback primitive makes a reserve/map
        /// transaction failure-atomic without permitting arbitrary removal.
        pub fn cancelLast(self: *Self, start: usize, length: usize) void {
            std.debug.assert(self.count != 0);
            const end = std.math.add(usize, start, length) catch unreachable;
            const last = self.entries[self.count - 1];
            std.debug.assert(last.start == start and last.end == end);
            self.count -= 1;
        }
    };
}

fn neverOccupied(_: void, _: usize) bool {
    return false;
}

test "bounded reservations validate range collision capacity and W+X atomically" {
    const Table = BoundedRuntimeMappings(2, 4096);
    var table: Table = .{};
    try table.reserve(0x2000, 4096, .{}, false, {}, neverOccupied);
    try std.testing.expectError(error.Collision, table.reserve(0x2000, 4096, .{}, false, {}, neverOccupied));
    try std.testing.expectError(error.InvalidRange, table.reserve(0x3001, 4096, .{}, false, {}, neverOccupied));
    try std.testing.expectError(error.InvalidRange, table.reserve(0x3000, 0, .{}, false, {}, neverOccupied));
    try std.testing.expectError(error.InvalidRange, table.reserve(std.math.maxInt(usize) & ~@as(usize, 4095), 8192, .{}, false, {}, neverOccupied));
    try std.testing.expectError(error.WriteExecute, table.reserve(0x3000, 4096, .{ .write = true, .execute = true }, false, {}, neverOccupied));
    try std.testing.expectEqual(@as(usize, 1), table.count);
    try table.reserve(0x3000, 4096, .{ .read = true, .write = true }, false, {}, neverOccupied);
    try std.testing.expectError(error.CapacityExceeded, table.reserve(0x4000, 4096, .{}, false, {}, neverOccupied));
    try std.testing.expectEqual(@as(usize, 2), table.count);
}

test "external occupied pages reject a reservation without mutation" {
    const occupied = struct {
        fn check(_: void, page: usize) bool {
            return page == 0x5000;
        }
    }.check;
    const Table = BoundedRuntimeMappings(1, 4096);
    var table: Table = .{};
    try std.testing.expectError(error.Collision, table.reserve(0x4000, 8192, .{}, false, {}, occupied));
    try std.testing.expectEqual(@as(usize, 0), table.count);
    try table.reserve(0x4000, 8192, .{}, true, {}, occupied);
    try std.testing.expectEqual(@as(usize, 1), table.count);
}

test "range containment is checked without mutation" {
    const Table = BoundedRuntimeMappings(1, 4096);
    var table: Table = .{};
    try table.reserve(0x4000, 0x4000, .{ .read = true }, false, {}, neverOccupied);
    try std.testing.expect(table.containsRange(0x5000, 0x2000));
    try std.testing.expect(!table.containsRange(0x3000, 0x2000));
    try std.testing.expect(!table.containsRange(0x7000, 0x2000));
    try std.testing.expectEqual(@as(usize, 1), table.count);
}

test "release range splits ownership atomically" {
    const Table = BoundedRuntimeMappings(3, 4096);
    var table: Table = .{};
    try table.reserve(0x4000, 0x4000, .{ .read = true }, false, {}, neverOccupied);
    try table.releaseRange(0x5000, 0x2000);
    try std.testing.expectEqual(@as(usize, 2), table.count);
    try std.testing.expect(table.containsRange(0x4000, 0x1000));
    try std.testing.expect(table.containsRange(0x7000, 0x1000));
    try std.testing.expect(!table.containsRange(0x5000, 0x1000));
}

test "multi-page reservation is contiguous and rollback restores capacity" {
    const Table = BoundedRuntimeMappings(1, 4096);
    var table: Table = .{};
    try std.testing.expectEqual(@as(usize, 2), try Table.pageCount(8192));
    try std.testing.expectError(error.InvalidRange, Table.pageCount(0));
    try std.testing.expectError(error.InvalidRange, Table.pageCount(4097));

    try table.reserve(0x6000, 8192, .{ .read = true, .write = true }, false, {}, neverOccupied);
    try std.testing.expectEqual(@as(usize, 0x6000), table.entries[0].start);
    try std.testing.expectEqual(@as(usize, 0x8000), table.entries[0].end);
    table.cancelLast(0x6000, 8192);
    try std.testing.expectEqual(@as(usize, 0), table.count);
    try table.reserve(0x9000, 4096, .{}, false, {}, neverOccupied);
}

test "collision on the second page rejects the whole range" {
    const occupied = struct {
        fn check(_: void, page: usize) bool {
            return page == 0x7000;
        }
    }.check;
    const Table = BoundedRuntimeMappings(1, 4096);
    var table: Table = .{};
    try std.testing.expectError(error.Collision, table.reserve(0x6000, 8192, .{}, false, {}, occupied));
    try std.testing.expectEqual(@as(usize, 0), table.count);
}

test "no-access reservations remain unbacked while accessible mappings require backing" {
    const Table = BoundedRuntimeMappings(2, 4096);
    try std.testing.expect(!Table.hasBacking(.{ .start = 0x1000, .end = 0x2000, .permissions = .{} }));
    try std.testing.expect(Table.hasBacking(.{ .start = 0x2000, .end = 0x3000, .permissions = .{ .read = true } }));
}
