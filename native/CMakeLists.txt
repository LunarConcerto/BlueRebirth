cmake_minimum_required(VERSION 3.15)
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()
project(BlueOathNative LANGUAGES CXX)

# The JP client ships its own 2018-era MSVC runtime DLLs. A payload linked with
# the current dynamic runtime resolves MSVCP/VCRUNTIME imports to those older
# copies after injection and can crash before signalling the ready event.
# Keep the native tools self-contained so their C++ runtime always matches the
# compiler that produced them.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "BlueOath native components must be built for x86")
endif()

# Debug hooks (full diagnostic instrumentation) vs product hooks (lean).
# debug-game.ps1 builds with -DebugHooks (default), release runs use product.
option(BLUEOATH_HOOKS_DEBUG "Build payload hooks with full diagnostic logging" OFF)

add_executable(BlueOath.Injector Injector/main.cpp)
target_compile_features(BlueOath.Injector PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.Injector PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(BlueOath.Injector PRIVATE bcrypt)

add_library(BlueOath.Payload SHARED
  Payload/dllmain.cpp
  Payload/hooks.h
  $<$<BOOL:${BLUEOATH_HOOKS_DEBUG}>:Payload/hooks_debug.cpp>
  $<$<NOT:$<BOOL:${BLUEOATH_HOOKS_DEBUG}>>:Payload/hooks_product.cpp>)
target_compile_features(BlueOath.Payload PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.Payload PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(BlueOath.Payload PRIVATE ws2_32 psapi crypt32 bcrypt)
set_target_properties(BlueOath.Payload PROPERTIES OUTPUT_NAME "BlueOath.Payload")
