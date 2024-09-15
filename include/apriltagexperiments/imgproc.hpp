#ifndef IMGPROC_HPP
#define IMGPROC_HPP

#include <apriltagexperiments/imgproc_export.hpp>

[[nodiscard]] IMGPROC_EXPORT int factorial(int) noexcept;

[[nodiscard]] constexpr int factorial_constexpr(int input) noexcept
{
  if (input == 0) { return 1; }

  return input * factorial_constexpr(input - 1);
}

#endif
