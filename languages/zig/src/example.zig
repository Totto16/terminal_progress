const terminal_progress = @import("terminal_progress.zig");
const std = @import("std");

fn seconds_to_ns(seconds: f64) std.Io.Duration {
    return std.Io.Duration.fromNanoseconds(@intFromFloat(seconds * 1_000_000_000));
}

fn sleepOld(io: std.Io, amount: std.Io.Duration) void {
    const clock = std.Io.Clock.real;

    io.sleep(amount, clock) catch @panic("cancelled sleep");
}

pub fn main(init: std.process.Init) !void {
    const percentage = 100;

    const io = init.io;

    var buffer: [terminal_progress.buffer_length]u8 = undefined;
    var writer = terminal_progress.ProgressWriter.create(io, &buffer);

    try writer.setProgress(.remove);

    {
        const steps = 50;
        std.debug.print("Indeterminate progress bar for 2 seconds\n", .{});

        // set the normal progress, so that color is used
        try writer.setProgress(.{ .set = 10 });

        for (0..steps + 1) |_| {
            try writer.setProgress(.indeterminate);

            sleepOld(io, seconds_to_ns(2.0 / @as(f64, @floatFromInt(steps))));
        }
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Progress bar from 0% to 100% in 5 seconds\n", .{});

        for (0..percentage + 1) |i| {
            try writer.setProgress(.{ .set = @intCast(i) });
            sleepOld(io, seconds_to_ns(5.0 / @as(f64, @floatFromInt(percentage))));
        }
    }

    try writer.setProgress(.remove);

    {
        const steps = 50;
        std.debug.print("Error progress bar for 2 seconds\n", .{});

        for (0..steps + 1) |_| {
            try writer.setProgress(.{ .@"error" = null });

            sleepOld(io, seconds_to_ns(2.0 / @as(f64, @floatFromInt(steps))));
        }
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Progress bar error from 0% to 100% in 5 seconds\n", .{});

        for (0..percentage + 1) |i| {
            try writer.setProgress(.{ .@"error" = @intCast(i) });
            sleepOld(io, seconds_to_ns(5.0 / @as(f64, @floatFromInt(percentage))));
        }
    }

    try writer.setProgress(.remove);

    {
        const steps = 50;
        std.debug.print("Paused progress bar for 2 seconds\n", .{});

        for (0..steps + 1) |_| {
            try writer.setProgress(.{ .paused = null });

            sleepOld(io, seconds_to_ns(2.0 / @as(f64, @floatFromInt(steps))));
        }
    }

    try writer.setProgress(.remove);

    {
        std.debug.print("Progress bar paused from 0% to 100% in 5 seconds\n", .{});

        for (0..percentage + 1) |i| {
            try writer.setProgress(.{ .paused = @intCast(i) });
            sleepOld(io, seconds_to_ns(5.0 / @as(f64, @floatFromInt(percentage))));
        }
    }

    try writer.setProgress(.remove);
}
