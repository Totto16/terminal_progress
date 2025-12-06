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

test "ProgressWriter - no tty" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        // otherwise nothing is printed
        try std.testing.expect(!file.isTty());

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = false };
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

test "writer - remove" {
    if (comptime builtin.os.tag == .windows) {
        @compileError("Not supported on windows");
    }

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressState.remove);
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

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

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .set = 74 });
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

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

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .@"error" = null });
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

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

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .@"error" = 34 });
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

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

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressState.indeterminate);
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

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

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .paused = null });
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

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

    {
        const pipe = try Pipe.get();

        const read_file = std.fs.File{ .handle = pipe.read };
        defer read_file.close();

        const file = std.fs.File{ .handle = pipe.write };

        var pipe_buffer: [terminal_progress.buffer_length]u8 = undefined;

        const file_writer = file.writer(&pipe_buffer);
        {
            defer file.close();

            var writer = terminal_progress.ProgressWriter{ .writer = file_writer, .is_tty = true };
            try writer.setProgress(terminal_progress.ProgressReport{ .paused = 58 });
        }

        var buf: [1024]u8 = undefined;
        const n = try read_file.readAll(&buf);

        const written = buf[0..n];

        try std.testing.expectEqualStrings(
            "\x1b]9;4;4;58\x07",
            written,
        );
    }
}
