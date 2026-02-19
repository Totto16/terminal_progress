#define _XOPEN_SOURCE 500
#include <unistd.h>

#include <iostream>
#include <terminal_progress_cpp.hpp>

static __useconds_t seconds_to_us(double seconds) {
  return (__useconds_t)(seconds * 1000000.0);
}

int main() {
  const size_t percentage = 100;

  std::cout << ProgressReport::remove();

  {
    const size_t steps = 50;
    std::cerr << "Indeterminate progress bar for 2 seconds\n";
    // set the normal progress, so that color is used
    ProgressReport::set(10).send();

    for (size_t i = 0; i <= steps; ++i) {
      ProgressReport::indeterminate().send_to(std::cout);

      usleep(seconds_to_us(2.0 / ((double)steps)));
    }
  }

  send_progress_cpp(ProgressReport::remove());

  {
    std::cerr << "Progress bar from 0% to 100% in 5 seconds\n";

    for (size_t i = 0; i <= percentage; ++i) {
      send_progress_to_cpp(ProgressReport::set(i), std::cout);

      usleep(seconds_to_us(5.0 / ((double)percentage)));
    }
  }

  std::cout << ProgressReport::remove();

  {
    const size_t steps = 50;
    std::cerr << "Error progress bar for 2 seconds\n";

    for (size_t i = 0; i <= steps; ++i) {
      std::cout << ProgressReport::error();

      usleep(seconds_to_us(2.0 / ((double)steps)));
    }
  }

  std::cout << ProgressReport::remove();

  {
    std::cerr << "Progress bar error from 0% to 100% in 5 seconds\n";

    for (size_t i = 0; i <= percentage; ++i) {
      std::cout << ProgressReport::error(i);

      usleep(seconds_to_us(5.0 / ((double)percentage)));
    }
  }

  std::cout << ProgressReport::remove();

  {
    const size_t steps = 50;
    std::cerr << "Paused progress bar for 2 seconds\n";

    for (size_t i = 0; i <= steps; ++i) {
      std::cout << ProgressReport::paused();

      usleep(seconds_to_us(2.0 / ((double)steps)));
    }
  }

  std::cout << ProgressReport::remove();

  {
    std::cerr << "Progress bar paused from 0% to 100% in 5 seconds\n";

    for (size_t i = 0; i <= percentage; ++i) {
      std::cout << ProgressReport::paused(i);

      usleep(seconds_to_us(5.0 / ((double)percentage)));
    }
  }

  std::cout << ProgressReport::remove();
}
