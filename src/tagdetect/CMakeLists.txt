add_executable(tagdetect main.cpp)

target_link_libraries(
  tagdetect
  PRIVATE apriltagexperiments::apriltagexperiments_options
          apriltagexperiments::apriltagexperiments_warnings)

target_link_system_libraries(
  tagdetect
  PRIVATE
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools)

target_include_directories(tagdetect PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")
