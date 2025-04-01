const std = @import("std");
const SAVE_FILE_PATH = "YOUR_DIRECTORY";

pub const Profile = struct {
    name: []const u8,
    password: []const u8,

    pub fn deinit(self: Profile, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.password);
    }
};

var profiles: std.ArrayList(Profile) = undefined;

const Operation = enum {
    Add,
    Remove,
    List,
    Unknown,
};

fn checkOperation(arg: []const u8) Operation {
    if (std.mem.eql(u8, arg, "add")) return Operation.Add;
    if (std.mem.eql(u8, arg, "remove")) return Operation.Remove;
    if (std.mem.eql(u8, arg, "list")) return Operation.List;
    return Operation.Unknown;
}

fn removeProfileFromList(name: []const u8) !void {
    var index_to_remove: ?usize = null;
    for (profiles.items, 0..) |profile, index| {
        if (std.mem.eql(u8, profile.name, name)) {
            index_to_remove = index;
            break;
        }
    }

    if (index_to_remove != null) {
        const index = index_to_remove.?;
        profiles.items[index].deinit(profiles.allocator);
        _ = profiles.orderedRemove(index);
        std.debug.print("Profile removed: {s}\n", .{name});
        return;
    }
    std.debug.print("Profile not found: {s}\n", .{name});
}

fn loadProfilesFromFile() !void {
    const file = std.fs.openFileAbsolute(SAVE_FILE_PATH, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("File not found: {s}\n", .{SAVE_FILE_PATH});
            return;
        }
        return err;
    };
    defer file.close();

    const contents = try file.reader().readAllAlloc(profiles.allocator, 1024 * 10);
    defer profiles.allocator.free(contents);

    var parsed = try std.json.parseFromSlice([]const Profile, profiles.allocator, contents, .{
        .allocate = .alloc_always,
        .duplicate_field_behavior = .use_first,
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    for (profiles.items) |*profile| {
        profile.deinit(profiles.allocator);
    }
    profiles.clearAndFree();

    for (parsed.value) |profile| {
        const name_dup = try profiles.allocator.dupe(u8, profile.name);
        const password_dup = try profiles.allocator.dupe(u8, profile.password);
        try profiles.append(Profile{
            .name = name_dup,
            .password = password_dup,
        });
    }
}

fn addProfileToList(name: []const u8, password: []const u8) !void {
    const name_dup = try profiles.allocator.dupe(u8, name);
    const password_dup = try profiles.allocator.dupe(u8, password);

    const profile = Profile{
        .name = name_dup,
        .password = password_dup,
    };
    try profiles.append(profile);
}

fn saveProfilesToFile() !void {
    var file = try std.fs.createFileAbsolute(SAVE_FILE_PATH, .{});
    defer file.close();

    try std.json.stringify(profiles.items, .{}, file.writer());
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    profiles = std.ArrayList(Profile).init(allocator);
    defer profiles.deinit();

    try loadProfilesFromFile();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("No operation provided.\n", .{});
        return;
    }

    const operation = checkOperation(args[1]);

    if (operation == Operation.Add) {
        if (args.len < 4) {
            std.debug.print("Usage: add <name> <password>\n", .{});
            return;
        }

        const name = args[2];
        const password = args[3];
        try addProfileToList(name, password);
        try saveProfilesToFile();
        std.debug.print("Profile added: {s}, Password: {s}\n", .{ name, password });
    } else if (operation == Operation.Remove) {
        if (args.len < 3) {
            std.debug.print("Usage: remove <name>\n", .{});
            return;
        }

        const name = args[2];
        try removeProfileFromList(name);
        try saveProfilesToFile();
    } else if (operation == Operation.List) {
        for (profiles.items) |profile| {
            std.debug.print("Profile: {s}, Password: {s}\n", .{ profile.name, profile.password });
        }
    } else {
        std.debug.print("Unknown operation: {s}\n", .{args[1]});
    }
}
