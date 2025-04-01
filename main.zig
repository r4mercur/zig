const std = @import("std");
const SAVE_FILE_PATH = "C:/Users/bjarn/Projects/zig/data/passwords.json";

const Profile = struct {
    name: []const u8,
    password: []const u8,
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

fn addProfileToList(name: []const u8, password: []const u8) !void {
    const profile = Profile{
        .name = name,
        .password = password,
    };
    try profiles.append(profile);
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
        var new_profiles = std.ArrayList(Profile).init(profiles.allocator);
        defer new_profiles.deinit();

        for (profiles.items, 0..) |profile, i| {
            if (i != index) {
                try new_profiles.append(profile);
            }
        }

        profiles.clearAndFree();
        profiles = new_profiles;

        std.debug.print("Profile removed: {s}\n", .{name});
        return;
    }
    std.debug.print("Profile not found: {s}\n", .{name});
}

fn loadProfilesFromFile() !void {
    const file = std.fs.openFileAbsolute(SAVE_FILE_PATH, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("File not found\n", .{SAVE_FILE_PATH});
            return;
        } else {
            std.debug.print("Error opening file: {any}\n", .{err});
            return err;
        }
    };
    defer file.close();

    const contents = try file.reader().readAllAlloc(profiles.allocator, 1024 * 10);
    defer profiles.allocator.free(contents);

    // TODO: Handle JSON parsing errors
    var parsed = try std.json.Value.jsonParse();
    defer parsed.deinit();

    for (parsed.value.?) |profile| {
        try profiles.append(profile);
    }
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
        std.debug.print("Profile added: {s}, Password: {s}\n", .{ name, password });
    } else if (operation == Operation.Remove) {
        if (args.len < 3) {
            std.debug.print("Usage: remove <name>\n", .{});
            return;
        }

        const name = args[2];
        try removeProfileFromList(name);
    } else if (operation == Operation.List) {
        for (profiles.items) |profile| {
            std.debug.print("Profile: {s}, Password: {s}\n", .{ profile.name, profile.password });
        }
    } else {
        std.debug.print("Unknown operation: {s}\n", .{args[1]});
    }
}
