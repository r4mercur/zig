const std = @import("std");
const profile = @import("profile.zig");
const Operation = @import("operation.zig").Operation;
const checkOperation = @import("operation.zig").checkOperation;

const SAVE_FILE_PATH = "YOUR_SAVE_FILE_PATH_HERE"; // Replace with your desired save file path

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var profile_manager = profile.ProfileManager.init(allocator, SAVE_FILE_PATH);
    defer profile_manager.deinit();

    try profile_manager.loadFromFile();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("No operation provided.\n", .{});
        return;
    }

    const operation = checkOperation(args[1]);

    switch (operation) {
        .Add => {
            if (args.len < 4) {
                std.debug.print("Usage: add <name> <password>\n", .{});
                return;
            }
            try profile_manager.addProfile(args[2], args[3]);
            try profile_manager.saveToFile();
            std.debug.print("Profile added: {s}\n", .{args[2]});
        },
        .Remove => {
            if (args.len < 3) {
                std.debug.print("Usage: remove <name>\n", .{});
                return;
            }
            try profile_manager.removeProfile(args[2]);
            try profile_manager.saveToFile();
        },
        .List => {
            profile_manager.listProfiles();
        },
        .Get => {
            if (args.len < 3) {
                std.debug.print("Usage: get <name>\n", .{});
                return;
            }
            if (profile_manager.getProfile(args[2])) |found_profile| {
                std.debug.print("Profile found: {s}, Password: {s}\n", .{ found_profile.name, found_profile.password });
            } else {
                std.debug.print("Profile not found: {s}\n", .{args[2]});
            }
        },
        .Update => {
            if (args.len < 4) {
                std.debug.print("Usage: update <name> <new_password>\n", .{});
                return;
            }

            if (try profile_manager.updateProfile(args[2], args[3])) {
                std.debug.print("Profile updated: {s}\n", .{args[2]});
            } else {
                std.debug.print("Profile not found: {s}\n", .{args[2]});
            }
        },
        .Unknown => {
            std.debug.print("Unknown operation: {s}\n", .{args[1]});
        },
    }
}
