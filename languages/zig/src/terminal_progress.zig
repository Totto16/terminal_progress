const std = @import("std");

pub const buffer_length: comptime_int = 4096;

const ansi_esc = "\x1B";
const ansi_osc = ansi_esc ++ "]";

const ansi_st = ansi_esc ++ "\\";
const ansi_bell = "\x07";

const osc_progress_report_base = "9;4";

// see docs at: https://conemu.github.io/en/AnsiEscapeCodes.html#ConEmu_specific_OSC
// Set progress state. When st is 0: remove progress. When st is 1: set progress value to pr (number, 0-100). When st is 2: set error state in progress taskbar, pr is optional. When st is 3: set indeterminate state. When st is 4: set paused state, pr is optional.

pub const ProgressState = enum(u8) {
    remove = 0,
    set = 1,
    @"error" = 2,
    indeterminate = 3,
    paused = 4,
};

pub const ProgressReport = union(ProgressState) { remove, set: u8, @"error": ?u8, indeterminate, paused: ?u8 };

pub const ProgressWriter = struct {
    writer: std.fs.File.Writer,

    pub fn create(buffer: []u8) ProgressWriter {
        const writer = std.fs.File.stdout().writer(buffer);

        return .{ .writer = writer };
    }

    fn sendProgressOSC(self: *ProgressWriter, st: u8, pr: ?u8) !void {
        if (!self.writer.file.isTty()) {
            return;
        }

        // Note. These codes may ends with ‘ESC\’ (two symbols - ESC and BackSlash) or ‘BELL’ (symbol with code \x07, same as ‘^a’ in *nix). For simplifying, endings in the following table marked as ‘ST’.

        // OSC 9 ; 4 ; st ; pr ST
        if (pr) |pr_val| {
            try self.writer.interface.print(ansi_osc ++ osc_progress_report_base ++ ";{d};{d}" ++ ansi_bell, .{ st, pr_val });
        } else {
            try self.writer.interface.print(ansi_osc ++ osc_progress_report_base ++ ";{d}" ++ ansi_bell, .{st});
        }

        try self.writer.interface.flush();
    }

    pub fn setProgress(self: *ProgressWriter, report: ProgressReport) !void {
        switch (report) {
            .remove, .indeterminate => {
                try self.sendProgressOSC(@intFromEnum(report), null);
            },
            .set => |value| {
                try self.sendProgressOSC(@intFromEnum(report), value);
            },
            .paused, .@"error" => |value| {
                try self.sendProgressOSC(@intFromEnum(report), value);
            },
        }
    }
};

pub const ProgressManager = struct {
    total_items: ?u32,
    processed_items: u32,
    writer: ProgressWriter,

    pub fn init(buffer: []u8, total_items: ?u32) ProgressManager {
        const writer = ProgressWriter.create(buffer);
        if (total_items == 0) {
            return ProgressManager{ .total_items = null, .processed_items = 0, .writer = writer };
        }

        return ProgressManager{ .total_items = total_items, .processed_items = 0, .writer = writer };
    }

    pub fn start(self: *ProgressManager) !void {
        if (self.total_items) |_| {
            try self.writer.setProgress(ProgressReport{ .set = 0 });
        } else {
            try self.writer.setProgress(.indeterminate);
        }
    }

    pub fn set_error(self: *ProgressManager) !void {
        const err_f = self.current_progress();

        const err: ?u8 = if (err_f) |e| @as(u8, @intCast(@as(u64, @intFromFloat(e)))) else null;

        try self.writer.setProgress(ProgressReport{ .@"error" = err });
    }

    pub fn end(self: *ProgressManager) !void {
        try self.writer.setProgress(.remove);
    }

    fn current_progress(self: *const ProgressManager) ?f64 {
        if (self.total_items) |total| {
            const current_progress_f64: f64 = @as(f64, @floatFromInt(self.processed_items)) / @as(f64, @floatFromInt(total)) * 100.0;
            return @max(0.0, current_progress_f64);
        }
        return null;
    }

    pub fn set_progress_in_sub_node(self: *ProgressManager, sub_progress: f64) !void {
        const progress = self.current_progress();
        if (progress) |p| {
            try self.set_progress_impl(p + sub_progress);
        }
    }

    fn set_progress_impl(self: *ProgressManager, progress: ?f64) !void {
        if (progress) |p| {
            if (p < 0.0 or p > 100.0) {
                return error.InvalidProgress;
            }
            try self.writer.setProgress(ProgressReport{ .set = @intFromFloat(p) });
        } else {
            try self.writer.setProgress(.indeterminate);
        }
    }

    pub fn sub_manager(self: *ProgressManager) ProgressSubManager {
        const start_percent: ?f64 = self.current_progress();
        var total_available_progress: ?f64 = null;

        if (start_percent) |start_p| {
            if (self.total_items) |total| {
                std.debug.assert(total > self.processed_items);
                const end_progress: f64 = @as(f64, @floatFromInt(self.processed_items + 1)) / @as(f64, @floatFromInt(total)) * 100.0;
                const end_percent: f64 = @min(100.0, end_progress);

                const total_available_progress_f: f64 = (end_percent - start_p);
                std.debug.assert(total_available_progress_f >= 0.0 and total_available_progress_f <= 100.0);
                total_available_progress = total_available_progress_f;
            }
        }

        return ProgressSubManager{ .top_instance = self, .total_available_progress = total_available_progress };
    }

    pub fn finishOne(self: *ProgressManager) !void {
        if (self.total_items) |total| {
            std.debug.assert(total > self.processed_items);
        }

        self.processed_items += 1;

        const progress = self.current_progress();
        try self.set_progress_impl(progress);
    }
};

pub const ProgressSubManager = struct {
    top_instance: *ProgressManager,
    total_available_progress: ?f64,
    ended: bool = false,

    pub fn end(self: *ProgressSubManager) !void {
        if (self.ended) {
            return;
        }
        self.ended = true;

        try self.top_instance.finishOne();
    }

    pub fn start(self: *ProgressSubManager, total_items: u32) ProgressNode {
        return ProgressNode{ .instance = self, .total_items = total_items, .processed_items = 0 };
    }

    pub fn update(self: *ProgressSubManager, progress: ?f64) !void {
        if (progress) |p| {
            if (p < 0.0 or p > 100.0) {
                return error.InvalidProgress;
            }

            if (self.total_available_progress) |total_avail_progress| {
                const sub_progress: f64 = total_avail_progress * p / 100.0;

                try self.top_instance.set_progress_in_sub_node(sub_progress);
            }
        }
    }
};

pub const ProgressNode = struct {
    instance: *ProgressSubManager,
    total_items: u32,
    processed_items: u32,

    fn current_progress(self: *const ProgressNode) ?f64 {
        if (self.total_items == 0) {
            return null;
        }

        const current_progress_f64: f64 = @as(f64, @floatFromInt(self.processed_items)) / @as(f64, @floatFromInt(self.total_items)) * 100.0;

        return @max(0.0, current_progress_f64);
    }

    pub fn addItems(self: *ProgressNode, amount: u32) !void {
        self.total_items += amount;

        const current_progress_f64 = self.current_progress();
        try self.instance.update(current_progress_f64);
    }

    pub fn completeOne(self: *ProgressNode) !void {
        std.debug.assert(self.total_items > self.processed_items);
        self.processed_items += 1;

        const current_progress_f64 = self.current_progress();
        try self.instance.update(current_progress_f64);
    }
};
