const terminal_progress = @import("terminal_progress.zig");
const std = @import("std");
const builtin = @import("builtin");

const READ_END = 0;
const WRITE_END = 1;

const Pipe = struct {
    read: std.posix.fd_t,
    write: std.posix.fd_t,

    pub fn get() std.posix.PipeError!Pipe {
        const fds: [2]std.posix.fd_t = try std.posix.pipe();

        return Pipe{ .read = fds[READ_END], .write = fds[WRITE_END] };
    }
};

fn setNonBlockFile(file: std.fs.File) !void {
    const flags = try std.posix.fcntl(file.handle, std.os.linux.F.GETFL, 0);

    const result = try std.posix.fcntl(file.handle, std.os.linux.F.SETFL, flags | std.os.linux.IN.NONBLOCK);
    if (result != 0) {
        const errno = std.c._errno();
        std.debug.panic("fcntl returned errno: {d}\n", .{errno.*});
        return error.Errno;
    }
}

fn readAvailFromNonBlock(fd: std.posix.fd_t, buf: []u8) ![]u8 {
    const n: usize = blk: {
        const n = std.posix.read(fd, buf) catch |err| {
            switch (err) {
                // No data available right now
                error.WouldBlock => {
                    break :blk 0;
                },
                else => return err,
            }
        };
        break :blk n;
    };

    return buf[0..n];
}
test "ProgressWriter - no tty" {
    if (builtin.os.tag != .linux) {
        @compileError("Only work on linux");
    }

    {
        const pipe = try Pipe.get();
        defer std.posix.close(pipe.read);
        defer std.posix.close(pipe.write);

        const read_file = std.fs.File{ .handle = pipe.read };
        try setNonBlockFile(read_file);
        const file = std.fs.File{ .handle = pipe.write };

        // otherwise nothing is printed
        try std.testing.expect(!file.isTty());

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = false };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const written = try readAvailFromNonBlock(pipe.read, &buf);

        try std.testing.expectEqualStrings(
            "",
            written,
        );
    }
}

// const progress_remove = "\x1b]9;4;0\x07";
// const @"progress_normal {d}" = "\x1b]9;4;1;{d}\x07";
// const @"progress_error {d}" = "\x1b]9;4;2;{d}\x07";
// const progress_pulsing_error = "\x1b]9;4;2\x07";
// const progress_normal_100 = "\x1b]9;4;1;100\x07";
// const progress_error_100 = "\x1b]9;4;2;100\x07";

test "writer - indeterminate" {
    if (builtin.os.tag != .linux) {
        @compileError("Only work on linux");
    }

    {
        const pipe = try Pipe.get();
        defer std.posix.close(pipe.read);
        defer std.posix.close(pipe.write);

        const read_file = std.fs.File{ .handle = pipe.read };
        try setNonBlockFile(read_file);
        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const written = try readAvailFromNonBlock(pipe.read, &buf);

        std.debug.print("here: '{any}'\n", .{written});

        try std.testing.expectEqualStrings(
            "\x1b]9;4;3\x07",
            written,
        );
    }
}
