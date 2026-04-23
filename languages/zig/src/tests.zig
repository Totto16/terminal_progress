const terminal_progress = @import("terminal_progress.zig");
const std = @import("std");
const builtin = @import("builtin");

const READ_END = 0;
const WRITE_END = 1;

const Pipe = struct {
    read: std.posix.fd_t,
    write: std.posix.fd_t,

    pub const PipeError = std.Io.Threaded.PipeError;

    fn pipeOldFn() PipeError![2]std.posix.fd_t {
        var fds: [2]std.posix.fd_t = undefined;
        switch (std.posix.errno(std.os.linux.pipe(&fds))) {
            .SUCCESS => return fds,
            .INVAL => unreachable, // Invalid parameters to pipe()
            .FAULT => unreachable, // Invalid fds pointer
            .NFILE => return error.SystemFdQuotaExceeded,
            .MFILE => return error.ProcessFdQuotaExceeded,
            else => |err| return std.posix.unexpectedErrno(err),
        }
    }

    pub fn get() PipeError!Pipe {
        const fds: [2]std.posix.fd_t = try Pipe.pipeOldFn();

        return Pipe{ .read = fds[READ_END], .write = fds[WRITE_END] };
    }
};

fn readAllStreaming(io: std.Io, file: std.Io.File, buffer: []u8) std.Io.File.ReadStreamingError!usize {
    var index: usize = 0;
    while (index != buffer.len) {
        const amt = file.readStreaming(io, &[_][]u8{buffer[index..]}) catch |err| {
            if (err == std.Io.File.ReadStreamingError.EndOfStream) {
                break;
            }

            return err;
        };
        if (amt == 0) break;
        index += amt;
    }
    return index;
}

test "ProgressWriter - no tty" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        // otherwise nothing is printed
        const isTty = try file.isTty(io);
        try std.testing.expect(!isTty);

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = false };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "",
            written,
        );
    }
}

test "writer - remove" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressState.remove);
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;0\x07",
            written,
        );
    }
}

test "writer - set" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .set = 74 });
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;1;74\x07",
            written,
        );
    }
}

test "writer - error - nothing" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .@"error" = null });
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;2\x07",
            written,
        );
    }
}

test "writer - error - percentage" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .@"error" = 34 });
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;2;34\x07",
            written,
        );
    }
}

test "writer - indeterminate" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;3\x07",
            written,
        );
    }
}

test "writer - paused - nothing" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .paused = null });
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;4\x07",
            written,
        );
    }
}

test "writer - paused - percentage" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    const io = std.testing.io;

    {
        const pipe = try Pipe.get();

        const read_file = std.Io.File{
            .handle = pipe.read,
            .flags = .{ .nonblocking = false },
        };
        defer read_file.close(io);

        const file = std.Io.File{
            .handle = pipe.write,
            .flags = .{ .nonblocking = false },
        };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(io, &pipe_buffer);
        {
            defer file.close(io);

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .paused = 58 });
        }

        var buf: [1024]u8 = undefined;
        const n = try readAllStreaming(io, read_file, &buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;4;58\x07",
            written,
        );
    }
}
