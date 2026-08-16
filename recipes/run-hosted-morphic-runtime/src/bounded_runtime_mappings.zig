const std = @import("std");

pub const Permissions = packed struct {
    read: bool = false,
    write: bool = false,
    execute: bool = false,
};

pub const BackingClass = enum { none, prepared, private_file };

pub const Mapping = struct {
    start: usize,
    end: usize,
    permissions: Permissions,
    backing_class: BackingClass = .none,
    backing_start: usize = 0,
};

/// Allocation-free runtime address-range ownership. Linux flags and errno are
/// intentionally absent: personalities translate into this neutral boundary.
pub fn BoundedRuntimeMappings(comptime capacity: usize, comptime page_size: usize) type {
    if (capacity == 0 or page_size == 0 or page_size & (page_size - 1) != 0)
        @compileError("mapping capacity and power-of-two page size are required");

    return struct {
        const Self = @This();
        pub const PermissionsType = Permissions;
        pub const BackingClassType = BackingClass;
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

        /// Linux mmap byte lengths cover every touched page. Return the
        /// checked page-aligned ownership length for that ABI boundary.
        pub fn roundedLength(length: usize) Error!usize {
            if (length == 0) return error.InvalidRange;
            const with_tail = std.math.add(usize, length, page_size - 1) catch return error.InvalidRange;
            return with_tail & ~(page_size - 1);
        }

        /// A reservation with no access permissions intentionally owns virtual
        /// address space without consuming or installing data-page backing.
        pub fn hasBacking(mapping: Mapping) bool {
            return mapping.backing_class != .none;
        }

        pub fn isAccessible(mapping: Mapping) bool {
            return mapping.permissions.read or mapping.permissions.write or mapping.permissions.execute;
        }

        pub fn setLastBacking(self: *Self, class: BackingClass, start: usize) void {
            std.debug.assert(self.count != 0);
            self.entries[self.count - 1].backing_class = class;
            self.entries[self.count - 1].backing_start = start;
        }

        pub fn containsRange(self: *const Self, start: usize, length: usize) bool {
            const end = std.math.add(usize, start, length) catch return false;
            for (self.entries[0..self.count]) |entry|
                if (entry.start <= start and end <= entry.end) return true;
            return false;
        }

        pub fn mappingAt(self: *const Self, address: usize) ?Mapping {
            for (self.entries[0..self.count]) |entry|
                if (entry.start <= address and address < entry.end) return entry;
            return null;
        }

        pub fn protectRange(self: *Self, start: usize, length: usize, permissions: Permissions) Error!void {
            const current = self.mappingAt(start) orelse return error.InvalidRange;
            const end = std.math.add(usize, start, length) catch return error.InvalidRange;
            if (length == 0 or start & (page_size - 1) != 0 or length & (page_size - 1) != 0 or end > current.end) return error.InvalidRange;
            if (permissions.write and permissions.execute) return error.WriteExecute;
            var extra: usize = 0;
            if (current.start < start) extra += 1;
            if (end < current.end) extra += 1;
            if (self.count + extra > capacity) return error.CapacityExceeded;
            const index = for (self.entries[0..self.count], 0..) |entry, i| {
                if (entry.start == current.start) break i;
            } else unreachable;
            var replacement: [capacity]Mapping = undefined;
            var out: usize = 0;
            for (self.entries[0..self.count], 0..) |entry, i| {
                if (i != index) {
                    replacement[out] = entry;
                    out += 1;
                    continue;
                }
                if (entry.start < start) {
                    replacement[out] = entry;
                    replacement[out].end = start;
                    out += 1;
                }
                replacement[out] = entry;
                replacement[out].start = start;
                replacement[out].end = end;
                replacement[out].permissions = permissions;
                replacement[out].backing_start += (start - entry.start) / page_size;
                out += 1;
                if (end < entry.end) {
                    replacement[out] = entry;
                    replacement[out].start = end;
                    replacement[out].backing_start += (end - entry.start) / page_size;
                    out += 1;
                }
            }
            self.entries = replacement;
            self.count = out;
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
                        replacement[replacement_count] = entry;
                        replacement[replacement_count].end = start;
                        replacement_count += 1;
                    }
                    if (end < entry.end) {
                        if (replacement_count == capacity) return error.CapacityExceeded;
                        replacement[replacement_count] = entry;
                        replacement[replacement_count].start = end;
                        if (entry.backing_class != .none)
                            replacement[replacement_count].backing_start += (end - entry.start) / page_size;
                        replacement_count += 1;
                    }
                }
            }
            self.entries = replacement;
            self.count = replacement_count;
        }

        /// Reclassifies a contained subrange after a fixed replacement. The
        /// complete replacement table is prepared before mutation.
        pub fn replaceBackingRange(self: *Self, start: usize, length: usize, permissions: Permissions, class: BackingClass, backing_start: usize) Error!void {
            if (!self.containsRange(start, length) or permissions.write and permissions.execute) return error.InvalidRange;
            const end = start + length;
            var replacement: [capacity]Mapping = undefined;
            var replacement_count: usize = 0;
            for (self.entries[0..self.count]) |entry| {
                if (end <= entry.start or entry.end <= start) {
                    if (replacement_count == capacity) return error.CapacityExceeded;
                    replacement[replacement_count] = entry;
                    replacement_count += 1;
                    continue;
                }
                if (entry.start < start) {
                    if (replacement_count == capacity) return error.CapacityExceeded;
                    replacement[replacement_count] = entry;
                    replacement[replacement_count].end = start;
                    replacement_count += 1;
                }
                if (replacement_count == capacity) return error.CapacityExceeded;
                replacement[replacement_count] = .{ .start = start, .end = end, .permissions = permissions, .backing_class = class, .backing_start = backing_start };
                replacement_count += 1;
                if (end < entry.end) {
                    if (replacement_count == capacity) return error.CapacityExceeded;
                    replacement[replacement_count] = entry;
                    replacement[replacement_count].start = end;
                    if (entry.backing_class != .none)
                        replacement[replacement_count].backing_start += (end - entry.start) / page_size;
                    replacement_count += 1;
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

test "Linux byte lengths round to complete bounded pages" {
    const Table = BoundedRuntimeMappings(1, 4096);
    try std.testing.expectEqual(@as(usize, 4096), try Table.roundedLength(1));
    try std.testing.expectEqual(@as(usize, 0x28000), try Table.roundedLength(0x2711c));
    try std.testing.expectError(error.InvalidRange, Table.roundedLength(0));
    try std.testing.expectError(error.InvalidRange, Table.roundedLength(std.math.maxInt(usize)));
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

test "backing identity is independent from current accessibility" {
    const Table = BoundedRuntimeMappings(2, 4096);
    try std.testing.expect(!Table.hasBacking(.{ .start = 0x1000, .end = 0x2000, .permissions = .{} }));
    try std.testing.expect(Table.hasBacking(.{ .start = 0x2000, .end = 0x3000, .permissions = .{}, .backing_class = .prepared }));
}

test "backed mapping retains identity while protection is disabled and restored" {
    const Table = BoundedRuntimeMappings(1, 4096);
    var table: Table = .{};
    try table.reserve(0x1000, 4096, .{ .read = true, .write = true }, false, {}, neverOccupied);
    table.setLastBacking(.prepared, 13);
    try table.protectRange(0x1000, 4096, .{});
    try std.testing.expect(Table.hasBacking(table.entries[0]));
    try std.testing.expect(!Table.isAccessible(table.entries[0]));
    try std.testing.expectEqual(@as(usize, 13), table.entries[0].backing_start);
    try table.protectRange(0x1000, 4096, .{ .read = true });
    try std.testing.expect(Table.isAccessible(table.entries[0]));
    try std.testing.expectEqual(@as(usize, 13), table.entries[0].backing_start);
}

test "snapshot preserves backing identity and split cursor offsets" {
    const Table = BoundedRuntimeMappings(3, 4096);
    var parent: Table = .{};
    try parent.reserve(0x4000, 0x3000, .{ .read = true }, false, {}, neverOccupied);
    parent.setLastBacking(.private_file, 7);
    const snapshot = parent;

    parent = .{}; // child exec/reset may freely reuse its process-local table.
    try parent.reserve(0x9000, 0x1000, .{ .read = true, .write = true }, false, {}, neverOccupied);
    parent.setLastBacking(.prepared, 2);
    parent = snapshot;
    try parent.releaseRange(0x5000, 0x1000);

    try std.testing.expectEqual(BackingClass.private_file, parent.entries[0].backing_class);
    try std.testing.expectEqual(@as(usize, 7), parent.entries[0].backing_start);
    try std.testing.expectEqual(BackingClass.private_file, parent.entries[1].backing_class);
    try std.testing.expectEqual(@as(usize, 9), parent.entries[1].backing_start);
}

test "fixed replacement records private backing atomically" {
    const Table = BoundedRuntimeMappings(3, 4096);
    var table: Table = .{};
    try table.reserve(0x4000, 0x3000, .{}, false, {}, neverOccupied);
    try table.replaceBackingRange(0x5000, 0x1000, .{ .read = true, .execute = true }, .private_file, 11);
    try std.testing.expectEqual(@as(usize, 3), table.count);
    try std.testing.expectEqual(BackingClass.private_file, table.entries[1].backing_class);
    try std.testing.expectEqual(@as(usize, 11), table.entries[1].backing_start);
    try std.testing.expect(table.entries[1].permissions.execute);
}

test "protection split retains backing offsets" {
    const Table = BoundedRuntimeMappings(3, 4096);
    var table: Table = .{};
    try table.reserve(0x4000, 0x3000, .{ .read = true, .write = true }, false, {}, neverOccupied);
    table.setLastBacking(.prepared, 4);
    try table.protectRange(0x5000, 0x1000, .{ .read = true });
    try std.testing.expectEqual(@as(usize, 3), table.count);
    try std.testing.expectEqual(@as(usize, 5), table.entries[1].backing_start);
    try std.testing.expect(!table.entries[1].permissions.write);
    try std.testing.expectEqual(@as(usize, 6), table.entries[2].backing_start);
}

test "bounded apk-sized topology admits the thirty-third mapping" {
    const Table = BoundedRuntimeMappings(64, 4096);
    var table: Table = .{};
    for (0..33) |index|
        try table.reserve(0x1000 + index * 0x2000, 0x1000, .{ .read = true }, false, {}, neverOccupied);
    try std.testing.expectEqual(@as(usize, 33), table.count);
    try std.testing.expect(table.containsRange(0x41000, 0x1000));
}
