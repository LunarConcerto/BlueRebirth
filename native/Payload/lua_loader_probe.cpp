#include "lua_mod_loader.h"

#include <windows.h>

namespace {
DWORD WINAPI ProbeMain(void* value) {
    StartLuaModLoader(static_cast<HMODULE>(value));

    wchar_t eventName[96]{};
    wsprintfW(eventName, L"Local\\BlueOath.Inject.%lu", GetCurrentProcessId());
    HANDLE ready = OpenEventW(EVENT_MODIFY_STATE, FALSE, eventName);
    if (ready) {
        SetEvent(ready);
        CloseHandle(ready);
    }
    return 0;
}
}

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, void*) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(module);
        HANDLE thread = CreateThread(nullptr, 0, &ProbeMain, module, 0, nullptr);
        if (thread) CloseHandle(thread);
    }
    return TRUE;
}
