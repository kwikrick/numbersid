#
# project: numbersid
#
cmake_minimum_required(VERSION 3.20)
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 11)
project(numbersid)

# include the fips main cmake file
get_filename_component(FIPS_ROOT_DIR "../fips" ABSOLUTE)
include("${FIPS_ROOT_DIR}/cmake/fips.cmake")

fips_setup()
fips_import_dcimgui_dcimgui()

# just suppress this pesky "missing field initializer warning" for now
if (FIPS_CLANG OR FIPS_GCC)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-missing-field-initializers")
endif()

fips_ide_group(source)
add_subdirectory(source)


fips_ide_group(lamefft)
add_subdirectory(lamefft)
