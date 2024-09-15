include(GenerateExportHeader)


add_library(imgproc imgproc.cpp)



add_library(apriltagexperiments::imgproc ALIAS imgproc)

target_link_libraries(imgproc PRIVATE apriltagexperiments_options apriltagexperiments_warnings)

target_include_directories(imgproc ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                                                                  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)

target_compile_features(imgproc PUBLIC cxx_std_20)

set_target_properties(
  imgproc
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(imgproc EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/apriltagexperiments/imgproc_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(imgproc PUBLIC SAMPLE_LIBRARY_STATIC_DEFINE)
endif()
