

#include "terminal_progress.h"

#include <stdio.h>
#include <unistd.h>

#define ANSI_ESC "\x1B"
#define ANSI_OSC ANSI_ESC "]"

#define ANSI_ST ANSI_ESC "\\"
#define ANSI_BELL "\x07"

#define OSC_PROGRESS_REPORT_BASE "9;4"

static void send_progress_1_impl(uint8_t st) {
  fprintf(stdout, ANSI_OSC OSC_PROGRESS_REPORT_BASE ";%d" ANSI_BELL, st);
  fflush(stdout);
}

static void send_progress_2_impl(uint8_t st, uint8_t pr) {
  fprintf(stdout, ANSI_OSC OSC_PROGRESS_REPORT_BASE ";%d;%d" ANSI_BELL, st, pr);
  fflush(stdout);
}

static void send_progress_opt_impl(uint8_t st, optional_uint8_t pr) {
  if (pr.has_value) {
    send_progress_2_impl(st, pr.value);
    return;
  }

  send_progress_1_impl(st);
}

void send_progress(ProgressReport report) {

  if (!isatty(STDOUT_FILENO)) {
    return;
  }

  switch (report.type) {
  case ProgressStateRemove: {
    send_progress_1_impl(report.type);
    break;
  }
  case ProgressStateSet: {
    send_progress_2_impl(report.type, report.data.set);
    break;
  }
  case ProgressStateError: {
    send_progress_opt_impl(report.type, report.data.error);
    break;
  }
  case ProgressStateIndeterminate: {
    send_progress_1_impl(report.type);
    break;
  }
  case ProgressStatePaused: {
    send_progress_opt_impl(report.type, report.data.paused);
    break;
  }
  default: {
    return;
  }
  }
}
