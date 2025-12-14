
#pragma once

#include <cstdint>
#include <optional>
#include <ostream>

typedef enum {
  ProgressStateRemove = 0,
  ProgressStateSet = 1,
  ProgressStateError = 2,
  ProgressStateIndeterminate = 3,
  ProgressStatePaused = 4,
} ProgressState;

using optional_uint8_t = std::optional<std::uint8_t>;

namespace details {
using DataUnion = union {
  std::uint8_t set;
  optional_uint8_t error;
  optional_uint8_t paused;
};
}; // namespace details

struct ProgressReport {
private:
  ProgressState m_type;
  details::DataUnion m_data;

  ProgressReport(ProgressState state);

  ProgressReport(ProgressState state, details::DataUnion data);

public:
  [[nodiscard]] static ProgressReport remove();

  [[nodiscard]] static ProgressReport set(std::uint8_t value);

  [[nodiscard]] static ProgressReport error();

  [[nodiscard]] static ProgressReport error(uint8_t value);

  [[nodiscard]] static ProgressReport error(std::optional<std::uint8_t> value);

  [[nodiscard]] static ProgressReport indeterminate();

  [[nodiscard]] static ProgressReport paused();

  [[nodiscard]] static ProgressReport paused(uint8_t value);

  [[nodiscard]] static ProgressReport paused(std::optional<std::uint8_t> value);

  void send_to(std::ostream &os) const;

  void send() const;

  friend std::ostream &operator<<(std::ostream &os, ProgressReport report);
};

void send_progress_to_cpp(ProgressReport report, std::ostream &os);

void send_progress_cpp(ProgressReport report);
