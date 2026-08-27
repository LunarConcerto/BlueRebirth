cmake_minimum_required(VERSION 3.15)
project(BlueOathNative LANGUAGES CXX)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "BlueOath native components must be built for x86")
endif()

# Debug hooks (full diagnostic instrumentation) vs product hooks (lean).
# debug-game.ps1 builds with -DebugHooks (default), release runs use product.
option(BLUEOATH_HOOKS_DEBUG "Build payload hooks with full diagnostic logging" OFF)
option(BLUEOATH_LUA_MODS "Include the experimental xLua mod loader in the main payload" ON)

add_executable(BlueOath.Injector Injector/main.cpp)
target_compile_features(BlueOath.Injector PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.Injector PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(BlueOath.Injector PRIVATE bcrypt)

add_library(BlueOath.Payload SHARED
  Payload/dllmain.cpp
  Payload/hooks.h
  $<$<BOOL:${BLUEOATH_LUA_MODS}>:Payload/lua_mod_loader.cpp>
  $<$<BOOL:${BLUEOATH_LUA_MODS}>:Payload/lua_mod_loader.h>
  $<$<BOOL:${BLUEOATH_HOOKS_DEBUG}>:Payload/hooks_debug.cpp>
  $<$<NOT:$<BOOL:${BLUEOATH_HOOKS_DEBUG}>>:Payload/hooks_product.cpp>)
target_compile_features(BlueOath.Payload PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.Payload PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX
  $<$<BOOL:${BLUEOATH_LUA_MODS}>:BLUEOATH_LUA_MODS>)
target_link_libraries(BlueOath.Payload PRIVATE ws2_32 psapi crypt32 bcrypt)
set_target_properties(BlueOath.Payload PROPERTIES OUTPUT_NAME "BlueOath.Payload")

# Minimal runtime probe used to validate the Lua loader independently from the
# much larger, version-sensitive network and gameplay hook set.
add_library(BlueOath.LuaLoaderProbe SHARED
  Payload/lua_loader_probe.cpp
  Payload/lua_mod_loader.cpp
  Payload/lua_mod_loader.h)
target_compile_features(BlueOath.LuaLoaderProbe PRIVATE cxx_std_17)
target_compile_definitions(BlueOath.LuaLoaderProbe PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(BlueOath.LuaLoaderProbe PRIVATE bcrypt)
set_target_properties(BlueOath.LuaLoaderProbe PROPERTIES OUTPUT_NAME "BlueOath.LuaLoaderProbe")
