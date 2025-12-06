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
    const result = try std.posix.fcntl(file.handle, std.os.linux.F.SETFL, std.os.linux.IN.NONBLOCK);
    if (result != 0) {
        const errno = std.c._errno();
        std.debug.panic("fcntl returned errno: {d}\n", .{errno.*});
        return error.Errno;
    }
}

const CInterop = @cImport({
    @cInclude("asm/termbits.h");
    @cInclude("asm/termios.h");
});

fn setTTyFile(file: std.fs.File) !void {
    const winsize: CInterop.winsize = .{ .ws_row = 1, .ws_col = 1, .ws_xpixel = 1, .ws_ypixel = 1 };

    const result = std.os.linux.ioctl(file.handle, CInterop.TIOCSWINSZ, @intFromPtr(&winsize));
    if (result != 0) {
        const errno = std.c._errno();
        std.debug.panic("ioctl returned errno: {d}\n", .{errno.*});
        return error.Errno;
    }
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
            var writer = terminal_progress.ProgressWriter{ .writer = file_writer };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const n = blk: {
            const n = read_file.readAll(&buf) catch |err| {
                if (err == error.WouldBlock) {
                    break :blk 0;
                }
                return err;
            };
            break :blk n;
        };

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "",
            written,
        );
    }
}

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
        try setTTyFile(read_file);

        // otherwise nothing is printed
        try std.testing.expect(file.isTty());

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            var writer = terminal_progress.ProgressWriter{ .writer = file_writer };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "",
            written,
        );
    }
}
