cmake_minimum_required(VERSION 3.27.6)
set(FETCHCONTENT_QUIET OFF)

project(hfc-bench VERSION "0.0.1")

include(FetchContent)


if(BENCH_BOOST_VERSION STREQUAL "1.85")
  set(boost_git_tag "ab7968a0bbcf574a7859240d1d8443f58ed6f6cf")
elseif(BENCH_BOOST_VERSION STREQUAL "1.84")
  set(boost_git_tag "ad09f667e61e18f5c31590941e748ac38e5a81bf")
endif()

FetchContent_Declare(
  Boost
  GIT_REPOSITORY https://github.com/boostorg/boost
  GIT_TAG        "${boost_git_tag}"
)

if(BENCH_HFC)

  FetchContent_Populate(hfc
    GIT_REPOSITORY https://github.com/tipi-build/hfc.git
    GIT_TAG main
    SOURCE_DIR "${PROJECT_SOURCE_DIR}/thirdparty/cache/hfc/src"
    SUBBUILD_DIR "${PROJECT_SOURCE_DIR}/thirdparty/cache/hfc/subbuild"
    BINARY_DIR "${PROJECT_SOURCE_DIR}/thirdparty/cache/hfc/bin"
  )
  FetchContent_GetProperties(hfc)
  list(APPEND CMAKE_MODULE_PATH "${hfc_SOURCE_DIR}/cmake")

  include(HermeticFetchContent)
  # 
  if(BENCH_HFC_LOCAL_SOURCE_CACHE)
    HermeticFetchContent_SetSouceCacheDir("${BENCH_HFC_LOCAL_SOURCE_CACHE}")
  endif()


  if(BENCH_HFC_LOCAL_INSTALL_CACHE)
    HermeticFetchContent_SetBaseDir("${BENCH_HFC_LOCAL_INSTALL_CACHE}")
  endif()  

  FetchContent_MakeHermetic(
    Boost
    HERMETIC_TOOLCHAIN_EXTENSION
    [=[
      set(BOOST_BUILD_TEST OFF CACHE BOOL "" FORCE)
      set(BOOST_ENABLE_PYTHON OFF CACHE BOOL "" FORCE)
    ]=]
  )

  HermeticFetchContent_MakeAvailableAtBuildTime(Boost)

else()

  set(BOOST_BUILD_TEST OFF CACHE BOOL "" FORCE)
  set(BOOST_ENABLE_PYTHON OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(Boost)

endif()



add_executable(hfc_test_app "hfc_test_app.cpp")
target_link_libraries(hfc_test_app Boost::system Boost::filesystem
Boost::uuid
Boost::included_unit_test_framework)