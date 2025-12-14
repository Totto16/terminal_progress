

#include "terminal_progress_cpp.hpp"

#include <fstream>
#include <iostream>

#define ANSI_ESC "\x1B"
#define ANSI_OSC ANSI_ESC "]"

#define ANSI_ST ANSI_ESC "\\"
#define ANSI_BELL "\x07"

#define OSC_PROGRESS_REPORT_BASE "9;4"

static void send_progress_impl(std::ostream &os, uint8_t st,
                               std::optional<uint8_t> pr) {

  if (pr.has_value()) {
    os << ANSI_OSC OSC_PROGRESS_REPORT_BASE << ";" << st << ";" << pr.value()
    << ANSI_BELL;
    
  } else {
    os << ANSI_OSC OSC_PROGRESS_REPORT_BASE << ";" << st << ANSI_BELL;
  }

  std::flush(os);
}

static bool is_ostream_atty(std::ostream &os) {

  const auto fos = reinterpret_cast<std::ofstream *>(&os);

  if (fos == nullptr) {
    return false;
  }

#if __cplusplus >= 202600L && defined(__cpp_lib_fstream_native_handle)
  const auto fd = fos->native_handle();
  return isatty(fd);
#else
  return true;
#endif
}

void ProgressReport::send_to(std::ostream &os) const {

  if (!is_ostream_atty(os)) {
    return;
  }

  switch (this->m_type) {
  case ProgressStateRemove: {
    send_progress_impl(os, this->m_type, std::nullopt);
    break;
  }
  case ProgressStateSet: {
    send_progress_impl(os, this->m_type, this->m_data.set);
    break;
  }
  case ProgressStateError: {
    send_progress_impl(os, this->m_type, this->m_data.error);
    break;
  }
  case ProgressStateIndeterminate: {
    send_progress_impl(os, this->m_type, std::nullopt);
    break;
  }
  case ProgressStatePaused: {
    send_progress_impl(os, this->m_type, this->m_data.paused);
    break;
  }
  default: {
    return;
  }
  }
}

void ProgressReport::send() const { return this->send_to(std::cout); }

std::ostream &operator<<(std::ostream &os, ProgressReport report) {
  report.send_to(os);
  return os;
}

void send_progress_to_cpp(ProgressReport report, std::ostream &os) {
  return report.send_to(os);
}

void send_progress_cpp(ProgressReport report) { return report.send(); }

ProgressReport::ProgressReport(ProgressState state) : m_type{state}, m_data{} {}

ProgressReport::ProgressReport(ProgressState state, details::DataUnion data)
    : m_type{state}, m_data{data} {}

[[nodiscard]] ProgressReport ProgressReport::remove() {
  return ProgressReport{ProgressState::ProgressStateRemove};
}

[[nodiscard]] ProgressReport ProgressReport::set(std::uint8_t value) {
  return ProgressReport{ProgressState::ProgressStateSet,
                        details::DataUnion{.set = value}};
}

[[nodiscard]] ProgressReport ProgressReport::error() {
  return ProgressReport::error(std::nullopt);
}

[[nodiscard]] ProgressReport ProgressReport::error(uint8_t value) {
  return ProgressReport::error(std::optional<std::uint8_t>{value});
}

[[nodiscard]] ProgressReport
ProgressReport::error(std::optional<std::uint8_t> value) {
  return ProgressReport{ProgressState::ProgressStateError,
                        details::DataUnion{.error = value}};
}

[[nodiscard]] ProgressReport ProgressReport::indeterminate() {
  return ProgressReport{ProgressState::ProgressStateIndeterminate};
}

[[nodiscard]] ProgressReport ProgressReport::paused() {
  return ProgressReport::paused(std::nullopt);
}

[[nodiscard]] ProgressReport ProgressReport::paused(uint8_t value) {
  return ProgressReport::paused(std::optional<std::uint8_t>{value});
}

[[nodiscard]] ProgressReport
ProgressReport::paused(std::optional<std::uint8_t> value) {
  return ProgressReport{ProgressState::ProgressStatePaused,
                        details::DataUnion{.paused = value}};
}
