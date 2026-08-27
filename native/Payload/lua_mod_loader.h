#pragma once
#include <windows.h>

// Starts a background installer for the xLua export hook. The bootstrap itself
// is always executed on the game's Lua thread, immediately after a normal
// lua_pcallk returns, never from this worker thread.
void StartLuaModLoader(HMODULE payloadModule);
