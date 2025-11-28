cmake_minimum_required(VERSION 3.10)
project(lamefft)

add_library(lamefft STATIC lamefft.cpp)

# Optionally, specify the include directory
target_include_directories(lamefft PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
