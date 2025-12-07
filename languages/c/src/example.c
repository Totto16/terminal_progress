#define _XOPEN_SOURCE 500
#include <unistd.h>

#include <stdio.h>
#include <terminal_progress.h>

static __useconds_t seconds_to_us(double seconds) {
  return (__useconds_t)(seconds * 1000000.0);
}

int main(void) {
  const size_t percentage = 100;

  send_progress((ProgressReport){.type = ProgressStateRemove});

  {
    const size_t steps = 50;
    fprintf(stderr, "Indeterminate progress bar for 2 seconds\n");

    for (size_t i = 0; i <= steps; ++i) {
      send_progress((ProgressReport){.type = ProgressStateIndeterminate});

      usleep(seconds_to_us(2.0 / ((double)steps)));
    }
  }

  send_progress((ProgressReport){.type = ProgressStateRemove});

  {
    fprintf(stderr, "Progress bar from 0%% to 100%% in 5 seconds\n");

    for (size_t i = 0; i <= percentage; ++i) {
      send_progress(
          (ProgressReport){.type = ProgressStateSet, .data = {.set = i}});

      usleep(seconds_to_us(5.0 / ((double)percentage)));
    }
  }

  send_progress((ProgressReport){.type = ProgressStateRemove});

  {
    const size_t steps = 50;
    fprintf(stderr, "Error progress bar for 2 seconds\n");

    for (size_t i = 0; i <= steps; ++i) {
      send_progress((ProgressReport){.type = ProgressStateError,
                                     .data = {.error = {.has_value = false}}});

      usleep(seconds_to_us(2.0 / ((double)steps)));
    }
  }

  send_progress((ProgressReport){.type = ProgressStateRemove});

  {
    fprintf(stderr, "Progress bar error from 0%% to 100%% in 5 seconds\n");

    for (size_t i = 0; i <= percentage; ++i) {
      send_progress(
          (ProgressReport){.type = ProgressStateError,
                           .data = {.error = {.has_value = true, .value = i}}});

      usleep(seconds_to_us(5.0 / ((double)percentage)));
    }
  }

  send_progress((ProgressReport){.type = ProgressStateRemove});

  {
    const size_t steps = 50;
    fprintf(stderr, "Paused progress bar for 2 seconds\n");

    for (size_t i = 0; i <= steps; ++i) {
      send_progress((ProgressReport){.type = ProgressStatePaused,
                                     .data = {.paused = {.has_value = false}}});

      usleep(seconds_to_us(2.0 / ((double)steps)));
    }
  }

  send_progress((ProgressReport){.type = ProgressStateRemove});

  {
    fprintf(stderr, "Progress bar paused from 0%% to 100%% in 5 seconds\n");

    for (size_t i = 0; i <= percentage; ++i) {
      send_progress((ProgressReport){
          .type = ProgressStatePaused,
          .data = {.paused = {.has_value = true, .value = i}}});

      usleep(seconds_to_us(5.0 / ((double)percentage)));
    }
  }

  send_progress((ProgressReport){.type = ProgressStateRemove});
}
