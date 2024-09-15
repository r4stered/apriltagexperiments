include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(apriltagexperiments_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(apriltagexperiments_setup_options)
  option(apriltagexperiments_ENABLE_HARDENING "Enable hardening" ON)
  option(apriltagexperiments_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    apriltagexperiments_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    apriltagexperiments_ENABLE_HARDENING
    OFF)

  apriltagexperiments_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR apriltagexperiments_PACKAGING_MAINTAINER_MODE)
    option(apriltagexperiments_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(apriltagexperiments_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(apriltagexperiments_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(apriltagexperiments_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(apriltagexperiments_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(apriltagexperiments_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(apriltagexperiments_ENABLE_PCH "Enable precompiled headers" OFF)
    option(apriltagexperiments_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(apriltagexperiments_ENABLE_IPO "Enable IPO/LTO" ON)
    option(apriltagexperiments_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(apriltagexperiments_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(apriltagexperiments_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(apriltagexperiments_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(apriltagexperiments_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(apriltagexperiments_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(apriltagexperiments_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(apriltagexperiments_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(apriltagexperiments_ENABLE_PCH "Enable precompiled headers" OFF)
    option(apriltagexperiments_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      apriltagexperiments_ENABLE_IPO
      apriltagexperiments_WARNINGS_AS_ERRORS
      apriltagexperiments_ENABLE_USER_LINKER
      apriltagexperiments_ENABLE_SANITIZER_ADDRESS
      apriltagexperiments_ENABLE_SANITIZER_LEAK
      apriltagexperiments_ENABLE_SANITIZER_UNDEFINED
      apriltagexperiments_ENABLE_SANITIZER_THREAD
      apriltagexperiments_ENABLE_SANITIZER_MEMORY
      apriltagexperiments_ENABLE_UNITY_BUILD
      apriltagexperiments_ENABLE_CLANG_TIDY
      apriltagexperiments_ENABLE_CPPCHECK
      apriltagexperiments_ENABLE_COVERAGE
      apriltagexperiments_ENABLE_PCH
      apriltagexperiments_ENABLE_CACHE)
  endif()

  apriltagexperiments_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (apriltagexperiments_ENABLE_SANITIZER_ADDRESS OR apriltagexperiments_ENABLE_SANITIZER_THREAD OR apriltagexperiments_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(apriltagexperiments_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(apriltagexperiments_global_options)
  if(apriltagexperiments_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    apriltagexperiments_enable_ipo()
  endif()

  apriltagexperiments_supports_sanitizers()

  if(apriltagexperiments_ENABLE_HARDENING AND apriltagexperiments_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR apriltagexperiments_ENABLE_SANITIZER_UNDEFINED
       OR apriltagexperiments_ENABLE_SANITIZER_ADDRESS
       OR apriltagexperiments_ENABLE_SANITIZER_THREAD
       OR apriltagexperiments_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${apriltagexperiments_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${apriltagexperiments_ENABLE_SANITIZER_UNDEFINED}")
    apriltagexperiments_enable_hardening(apriltagexperiments_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(apriltagexperiments_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(apriltagexperiments_warnings INTERFACE)
  add_library(apriltagexperiments_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  apriltagexperiments_set_project_warnings(
    apriltagexperiments_warnings
    ${apriltagexperiments_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(apriltagexperiments_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    apriltagexperiments_configure_linker(apriltagexperiments_options)
  endif()

  include(cmake/Sanitizers.cmake)
  apriltagexperiments_enable_sanitizers(
    apriltagexperiments_options
    ${apriltagexperiments_ENABLE_SANITIZER_ADDRESS}
    ${apriltagexperiments_ENABLE_SANITIZER_LEAK}
    ${apriltagexperiments_ENABLE_SANITIZER_UNDEFINED}
    ${apriltagexperiments_ENABLE_SANITIZER_THREAD}
    ${apriltagexperiments_ENABLE_SANITIZER_MEMORY})

  set_target_properties(apriltagexperiments_options PROPERTIES UNITY_BUILD ${apriltagexperiments_ENABLE_UNITY_BUILD})

  if(apriltagexperiments_ENABLE_PCH)
    target_precompile_headers(
      apriltagexperiments_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(apriltagexperiments_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    apriltagexperiments_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(apriltagexperiments_ENABLE_CLANG_TIDY)
    apriltagexperiments_enable_clang_tidy(apriltagexperiments_options ${apriltagexperiments_WARNINGS_AS_ERRORS})
  endif()

  if(apriltagexperiments_ENABLE_CPPCHECK)
    apriltagexperiments_enable_cppcheck(${apriltagexperiments_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(apriltagexperiments_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    apriltagexperiments_enable_coverage(apriltagexperiments_options)
  endif()

  if(apriltagexperiments_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(apriltagexperiments_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(apriltagexperiments_ENABLE_HARDENING AND NOT apriltagexperiments_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR apriltagexperiments_ENABLE_SANITIZER_UNDEFINED
       OR apriltagexperiments_ENABLE_SANITIZER_ADDRESS
       OR apriltagexperiments_ENABLE_SANITIZER_THREAD
       OR apriltagexperiments_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    apriltagexperiments_enable_hardening(apriltagexperiments_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
