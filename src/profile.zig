const std = @import("std");

pub const Profile = struct {
    name: []const u8,
    password: []const u8,

    pub fn deinit(self: Profile, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.password);
    }
};

pub const ProfileManager = struct {
    profiles: std.ArrayList(Profile),
    allocator: std.mem.Allocator,
    save_path: []const u8,

    pub fn init(allocator: std.mem.Allocator, save_path: []const u8) ProfileManager {
        return .{
            .profiles = std.ArrayList(Profile).init(allocator),
            .allocator = allocator,
            .save_path = save_path,
        };
    }

    pub fn deinit(self: *ProfileManager) void {
        self.freeProfileMemory();
        self.profiles.deinit();
    }

    pub fn loadFromFile(self: *ProfileManager) !void {
        const file = std.fs.openFileAbsolute(self.save_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                std.debug.print("File not found: {s}\n", .{self.save_path});
                return;
            }
            return err;
        };
        defer file.close();

        const contents = try file.reader().readAllAlloc(self.allocator, 1024 * 10);
        defer self.allocator.free(contents);

        var parsed = try std.json.parseFromSlice([]const Profile, self.allocator, contents, .{
            .allocate = .alloc_always,
            .duplicate_field_behavior = .use_first,
            .ignore_unknown_fields = true,
        });
        defer parsed.deinit();

        self.freeProfileMemory();

        for (parsed.value) |profile| {
            try self.addProfile(profile.name, profile.password);
        }
    }

    pub fn saveToFile(self: *ProfileManager) !void {
        var file = try std.fs.createFileAbsolute(self.save_path, .{});
        defer file.close();

        try std.json.stringify(self.profiles.items, .{}, file.writer());
    }

    pub fn addProfile(self: *ProfileManager, name: []const u8, password: []const u8) !void {
        const name_dup = try self.allocator.dupe(u8, name);
        const password_dup = try self.allocator.dupe(u8, password);

        const profile = Profile{
            .name = name_dup,
            .password = password_dup,
        };
        try self.profiles.append(profile);
    }

    pub fn removeProfile(self: *ProfileManager, name: []const u8) !void {
        var index_to_remove: ?usize = null;
        for (self.profiles.items, 0..) |profile, index| {
            if (std.mem.eql(u8, profile.name, name)) {
                index_to_remove = index;
                break;
            }
        }

        if (index_to_remove != null) {
            const index = index_to_remove.?;
            self.profiles.items[index].deinit(self.allocator);
            _ = self.profiles.orderedRemove(index);
            std.debug.print("Profile removed: {s}\n", .{name});
            return;
        }
        std.debug.print("Profile not found: {s}\n", .{name});
    }

    pub fn getProfile(self: *ProfileManager, name: []const u8) ?Profile {
        for (self.profiles.items) |profile| {
            if (std.mem.eql(u8, profile.name, name)) {
                return profile;
            }
        }
        return null;
    }

    pub fn listProfiles(self: *ProfileManager) void {
        for (self.profiles.items) |profile| {
            std.debug.print("Profile: {s}, Password: {s}\n", .{ profile.name, profile.password });
        }
    }

    fn freeProfileMemory(self: *ProfileManager) void {
        for (self.profiles.items) |*profile| {
            profile.deinit(self.allocator);
        }
        self.profiles.clearAndFree();
    }
};
