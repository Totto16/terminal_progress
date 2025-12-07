
#pragma once

#include <stdbool.h>
#include <stdint.h>

typedef enum {
  ProgressStateRemove = 0,
  ProgressStateSet = 1,
  ProgressStateError = 2,
  ProgressStateIndeterminate = 3,
  ProgressStatePaused = 4,
} ProgressState;

typedef struct {
  bool has_value;
  uint8_t value;
} optional_uint8_t;

typedef struct {
  ProgressState type;
  union {
    uint8_t set;
    optional_uint8_t error;
    optional_uint8_t paused;
  } data;
} ProgressReport;

void send_progress(ProgressReport report);
