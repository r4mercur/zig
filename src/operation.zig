const std = @import("std");
const Profile = @import("profile.zig");

pub const Operation = enum {
    Add,
    Remove,
    List,
    Get,
    Update,
    Unknown,
};

pub fn checkOperation(operation: []const u8) Operation {
    if (std.mem.eql(u8, operation, "add")) {
        return Operation.Add;
    } else if (std.mem.eql(u8, operation, "remove")) {
        return Operation.Remove;
    } else if (std.mem.eql(u8, operation, "list")) {
        return Operation.List;
    } else if (std.mem.eql(u8, operation, "get")) {
        return Operation.Get;
    } else if (std.mem.eql(u8, operation, "update")) {
        return Operation.Update;
    } else {
        return Operation.Unknown;
    }
}
