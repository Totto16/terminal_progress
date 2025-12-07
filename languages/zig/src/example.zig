const terminal_progress = @import("terminal_progress.zig");
const std = @import("std");

fn seconds_to_us(seconds: f64) u64 {
    return @intFromFloat(seconds * 1_000_000_000);
}

pub fn main() !void {
    var buffer: [terminal_progress.buffer_length]u8 = undefined;

    var writer = terminal_progress.ProgressWriter.create(&buffer);

    {
        std.debug.print("Indeterminate progress bar for 2 seconds\n", .{});
        try writer.setProgress(.indeterminate);

        std.Thread.sleep(seconds_to_us(2.0));
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Progress bar from 0% to 100% in 5 seconds\n", .{});

        for (0..101) |i| {
            try writer.setProgress(.{ .set = @intCast(i) });
            std.Thread.sleep(seconds_to_us(5.0 / 100.0));
        }
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Error progress bar for 2 seconds\n", .{});
        try writer.setProgress(.{ .@"error" = null });

        std.Thread.sleep(seconds_to_us(2.0));
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Progress bar error from 0% to 100% in 5 seconds\n", .{});

        for (0..101) |i| {
            try writer.setProgress(.{ .@"error" = @intCast(i) });
            std.Thread.sleep(seconds_to_us(5.0 / 100.0));
        }
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Paused progress bar for 2 seconds\n", .{});
        try writer.setProgress(.{ .paused = null });

        std.Thread.sleep(seconds_to_us(2.0));
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Progress bar paused from 0% to 100% in 5 seconds\n", .{});

        for (0..101) |i| {
            try writer.setProgress(.{ .paused = @intCast(i) });
            std.Thread.sleep(seconds_to_us(5.0 / 100.0));
        }
    }

    try writer.setProgress(.remove);
}
