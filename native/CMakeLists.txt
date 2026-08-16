cmake_minimum_required(VERSION 3.15)
project(BlueOathNative LANGUAGES CXX)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "BlueOath native components must be built for x86")
endif()

add_executable(BlueOath.Injector Injector/main.cpp)
target_compile_features(BlueOath.Injector PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.Injector PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(BlueOath.Injector PRIVATE bcrypt)

add_library(BlueOath.Payload SHARED Payload/dllmain.cpp Payload/hooks.cpp)
target_compile_features(BlueOath.Payload PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.Payload PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(BlueOath.Payload PRIVATE ws2_32 psapi crypt32 bcrypt)
set_target_properties(BlueOath.Payload PROPERTIES OUTPUT_NAME "BlueOath.Payload")
