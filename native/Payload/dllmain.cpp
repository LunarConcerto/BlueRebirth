#include "hooks.h"

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(module);
        HANDLE thread = CreateThread(nullptr, 0, [](LPVOID value) -> DWORD { InitializeHooks(static_cast<HMODULE>(value)); return 0; }, module, 0, nullptr);
        if (thread) CloseHandle(thread);
    }
    return TRUE;
}
