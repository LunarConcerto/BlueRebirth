#include "lua_mod_loader.h"

#include <bcrypt.h>
#include <atomic>
#include <cstring>
#include <cstdint>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>
#include <vector>

namespace {
using LuaState = void*;
using LuaKFunction = int(__cdecl*)(LuaState, int, intptr_t);
using LuaCFunction = int(__cdecl*)(LuaState);
using LuaPcallK = int(__cdecl*)(LuaState, int, int, int, intptr_t, LuaKFunction);
using LuaGetTop = int(__cdecl*)(LuaState);
using LuaSetTop = void(__cdecl*)(LuaState, int);
using LuaGetGlobal = int(__cdecl*)(LuaState, const char*);
using LuaSetGlobal = void(__cdecl*)(LuaState, const char*);
using LuaGetField = int(__cdecl*)(LuaState, int, const char*);
using LuaSetField = void(__cdecl*)(LuaState, int, const char*);
using LuaType = int(__cdecl*)(LuaState, int);
using LuaPushValue = void(__cdecl*)(LuaState, int);
using LuaPushBoolean = void(__cdecl*)(LuaState, int);
using LuaToBoolean = int(__cdecl*)(LuaState, int);
using LuaPushLString = const char*(__cdecl*)(LuaState, const char*, size_t);
using LuaPushCClosure = void(__cdecl*)(LuaState, LuaCFunction, int);
using LuaPushNil = void(__cdecl*)(LuaState);
using LuaToLString = const char*(__cdecl*)(LuaState, int, size_t*);
using LuaLoadBufferX = int(__cdecl*)(LuaState, const char*, size_t, const char*, const char*);

constexpr char SupportedJpXluaSha256[] =
    "1925AE34EF22F00680BA93A7CA60B5A566AF697AF31EDE6FB16CAC3A324AE4DF";
constexpr size_t LuaPcallStolenLength = 14;
constexpr int LuaTypeTable = 5;
constexpr int LuaTypeFunction = 6;
constexpr int LuaTypeNil = 0;
constexpr int LuaFirstUpvalueIndex = -1001001;

std::filesystem::path payloadDirectory;
std::filesystem::path logPath;
std::filesystem::path modsRoot;
std::filesystem::path bootstrapPath;
std::atomic<bool> installerStarted{false};
std::atomic<bool> bootstrapComplete{false};
std::atomic<bool> bootstrapRunning{false};
std::atomic<unsigned long long> nextBootstrapAttempt{0};

LuaPcallK originalLuaPcallK = nullptr;
LuaGetTop luaGetTop = nullptr;
LuaSetTop luaSetTop = nullptr;
LuaGetGlobal luaGetGlobal = nullptr;
LuaSetGlobal luaSetGlobal = nullptr;
LuaGetField showGirlGetField = nullptr;
LuaSetField showGirlSetField = nullptr;
LuaType luaType = nullptr;
LuaPushValue showGirlPushValue = nullptr;
LuaPushBoolean showGirlPushBoolean = nullptr;
LuaToBoolean showGirlToBoolean = nullptr;
LuaPushLString luaPushLString = nullptr;
LuaPushCClosure luaPushCClosure = nullptr;
LuaPushNil luaPushNil = nullptr;
LuaToLString luaToLString = nullptr;
LuaLoadBufferX luaLoadBufferX = nullptr;
void* luaPcallTrampoline = nullptr;
bool buildShipNewStatePatchApplied = false;
bool showGirlNewStatePatchApplied = false;
bool pendingBuildShipNewValid = false;
bool pendingBuildShipIsNew = false;

void Log(const std::string& message) noexcept {
    if (logPath.empty()) return;
    const auto line = "[LuaModLoader] " + message + "\r\n";
    HANDLE file = CreateFileW(logPath.c_str(), FILE_APPEND_DATA,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return;
    DWORD written = 0;
    WriteFile(file, line.data(), static_cast<DWORD>(line.size()), &written, nullptr);
    CloseHandle(file);
}

// BuildShipPage computes the correct per-card "new" state, including ships
// owned before the draw and duplicates seen earlier in the same ten-pull, but
// the shipped JP Lua bundle does not pass that boolean to ShowGirlPage. The
// latter then falls back to an older illustrate snapshot and asks the player
// to lock an already-owned ship. Keep this compatibility patch in the native
// xLua bridge so it works even when no external Mods directory is present.
int __cdecl BuildShipCheckShowMeetPatched(LuaState state) {
    if (!state || !luaGetTop || !showGirlPushValue || !showGirlToBoolean ||
        !luaSetTop || !originalLuaPcallK) {
        return 0;
    }

    const int argumentCount = luaGetTop(state);
    showGirlPushValue(state, LuaFirstUpvalueIndex);
    for (int i = 1; i <= argumentCount; ++i) showGirlPushValue(state, i);
    const int status = originalLuaPcallK(state, argumentCount, -1, 0, 0, nullptr);
    if (status != 0) {
        Log("BuildShipLogic.CheckShowMeet wrapper failed");
        luaSetTop(state, argumentCount);
        return 0;
    }

    const int resultCount = luaGetTop(state) - argumentCount;
    if (resultCount > 0) {
        pendingBuildShipIsNew = showGirlToBoolean(state, argumentCount + 1) != 0;
        pendingBuildShipNewValid = true;
    }
    return resultCount;
}

int __cdecl ShowGirlUpdatePagePatched(LuaState state) {
    if (!state || !luaGetTop || !luaSetTop || !showGirlGetField ||
        !showGirlSetField || !showGirlPushValue || !showGirlPushBoolean ||
        !originalLuaPcallK) {
        return 0;
    }

    const int argumentCount = luaGetTop(state);
    if (argumentCount < 1) return 0;

    showGirlGetField(state, 1, "param");
    if (luaType(state, -1) == LuaTypeTable) {
        const int paramIndex = luaGetTop(state);
        showGirlGetField(state, paramIndex, "buildNum");
        const bool hasBuildNum = luaType(state, -1) != LuaTypeNil;
        luaSetTop(state, paramIndex);
        showGirlGetField(state, paramIndex, "getWay");
        const bool hasGetWay = luaType(state, -1) != LuaTypeNil;
        luaSetTop(state, paramIndex);

        if (pendingBuildShipNewValid && hasBuildNum && !hasGetWay) {
            showGirlPushBoolean(state, pendingBuildShipIsNew ? 1 : 0);
            showGirlSetField(state, paramIndex, "bNew");
            pendingBuildShipNewValid = false;
        }
    }
    luaSetTop(state, argumentCount);

    showGirlPushValue(state, LuaFirstUpvalueIndex);
    for (int i = 1; i <= argumentCount; ++i) showGirlPushValue(state, i);
    const int status = originalLuaPcallK(state, argumentCount, -1, 0, 0, nullptr);
    if (status != 0) {
        Log("ShowGirlPage._UpdatePage wrapper failed");
        luaSetTop(state, argumentCount);
        return 0;
    }
    return luaGetTop(state) - argumentCount;
}

void TryPatchBuildShipNewState(LuaState state) {
    if (!state || (buildShipNewStatePatchApplied && showGirlNewStatePatchApplied) ||
        !luaGetTop || !luaSetTop || !luaGetGlobal || !showGirlGetField ||
        !showGirlSetField || !luaPushCClosure) {
        return;
    }

    const int top = luaGetTop(state);
    if (!buildShipNewStatePatchApplied) {
        luaGetGlobal(state, "Logic");
        if (luaType(state, -1) == LuaTypeTable) {
            showGirlGetField(state, -1, "buildShipLogic");
            if (luaType(state, -1) == LuaTypeTable) {
                showGirlGetField(state, -1, "CheckShowMeet");
                if (luaType(state, -1) == LuaTypeFunction) {
                    luaPushCClosure(state, &BuildShipCheckShowMeetPatched, 1);
                    showGirlSetField(state, -2, "CheckShowMeet");
                    buildShipNewStatePatchApplied = true;
                    Log("native BuildShipLogic new-state capture installed");
                }
            }
        }
        luaSetTop(state, top);
    }

    if (!showGirlNewStatePatchApplied) {
        luaGetGlobal(state, "ShowGirlPage");
        if (luaType(state, -1) == LuaTypeTable) {
            showGirlGetField(state, -1, "_UpdatePage");
            if (luaType(state, -1) == LuaTypeFunction) {
                luaPushCClosure(state, &ShowGirlUpdatePagePatched, 1);
                showGirlSetField(state, -2, "_UpdatePage");
                showGirlNewStatePatchApplied = true;
                Log("native ShowGirlPage new-state forwarding installed");
            }
        }
        luaSetTop(state, top);
    }
}

std::string WideToUtf8(const std::wstring& value) {
    if (value.empty()) return {};
    const int length = WideCharToMultiByte(CP_UTF8, 0, value.c_str(),
        static_cast<int>(value.size()), nullptr, 0, nullptr, nullptr);
    if (length <= 0) return {};
    std::string result(static_cast<size_t>(length), '\0');
    WideCharToMultiByte(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
        result.data(), length, nullptr, nullptr);
    return result;
}

bool Utf8ToWide(const std::string& value, std::wstring& result) {
    if (value.empty()) return false;
    const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        value.data(), static_cast<int>(value.size()), nullptr, 0);
    if (length <= 0) return false;
    result.assign(static_cast<size_t>(length), L'\0');
    return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
        static_cast<int>(value.size()), result.data(), length) == length;
}

std::string HashFileSha256(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) return {};

    BCRYPT_ALG_HANDLE algorithm = nullptr;
    BCRYPT_HASH_HANDLE hash = nullptr;
    DWORD objectLength = 0;
    DWORD digestLength = 0;
    DWORD bytes = 0;
    if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) != 0 ||
        BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH,
            reinterpret_cast<PUCHAR>(&objectLength), sizeof(objectLength), &bytes, 0) != 0 ||
        BCryptGetProperty(algorithm, BCRYPT_HASH_LENGTH,
            reinterpret_cast<PUCHAR>(&digestLength), sizeof(digestLength), &bytes, 0) != 0) {
        if (algorithm) BCryptCloseAlgorithmProvider(algorithm, 0);
        return {};
    }

    std::vector<UCHAR> object(objectLength);
    std::vector<UCHAR> digest(digestLength);
    std::vector<char> buffer(64 * 1024);
    if (BCryptCreateHash(algorithm, &hash, object.data(), objectLength, nullptr, 0, 0) != 0) {
        BCryptCloseAlgorithmProvider(algorithm, 0);
        return {};
    }

    bool ok = true;
    while (input) {
        input.read(buffer.data(), static_cast<std::streamsize>(buffer.size()));
        const auto count = input.gcount();
        if (count > 0 && BCryptHashData(hash, reinterpret_cast<PUCHAR>(buffer.data()),
            static_cast<ULONG>(count), 0) != 0) {
            ok = false;
            break;
        }
    }
    if (ok && BCryptFinishHash(hash, digest.data(), digestLength, 0) != 0) ok = false;
    BCryptDestroyHash(hash);
    BCryptCloseAlgorithmProvider(algorithm, 0);
    if (!ok) return {};

    std::ostringstream output;
    for (const auto value : digest)
        output << std::uppercase << std::hex << std::setw(2) << std::setfill('0')
               << static_cast<int>(value);
    return output.str();
}

bool ReadFile(const std::filesystem::path& path, std::string& content) {
    std::ifstream input(path, std::ios::binary);
    if (!input) return false;
    content.assign(std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>());
    return input.good() || input.eof();
}

std::filesystem::path FindModsRoot() {
    const auto configPath = payloadDirectory / L"bootstrap.ini";
    wchar_t configured[MAX_PATH]{};
    GetPrivateProfileStringW(L"mods", L"root", L"", configured, MAX_PATH, configPath.c_str());
    if (configured[0]) {
        auto path = std::filesystem::path(configured);
        if (path.is_relative()) path = payloadDirectory / path;
        std::error_code error;
        path = std::filesystem::absolute(path, error).lexically_normal();
        if (!error && std::filesystem::is_regular_file(path / L"bootstrap.lua", error)) return path;
        Log("configured mods root has no bootstrap.lua: " + WideToUtf8(path.wstring()));
    }

    const std::filesystem::path candidates[] = {
        payloadDirectory / L"Mods",
        payloadDirectory.parent_path() / L"Mods",
        payloadDirectory.parent_path().parent_path() / L"Mods",
    };
    for (const auto& candidate : candidates) {
        std::error_code error;
        const auto normalized = std::filesystem::absolute(candidate, error).lexically_normal();
        if (!error && std::filesystem::is_regular_file(normalized / L"bootstrap.lua", error))
            return normalized;
    }
    return {};
}

std::string LuaError(LuaState state) {
    if (!luaToLString) return "<lua error unavailable>";
    size_t length = 0;
    const char* value = luaToLString(state, -1, &length);
    if (!value || length == 0 || length > 64 * 1024) return "<lua error unreadable>";
    return std::string(value, length);
}

int __cdecl LogFromLua(LuaState state) {
    size_t length = 0;
    const char* value = luaToLString(state, 1, &length);
    if (value && length > 0 && length <= 64 * 1024)
        Log("lua: " + std::string(value, length));
    return 0;
}

int PushLoadError(LuaState state, const std::string& message) {
    luaSetTop(state, 0);
    luaPushNil(state);
    luaPushLString(state, message.data(), message.size());
    return 2;
}

int __cdecl LoadModFile(LuaState state) {
    size_t relativeLength = 0;
    const char* relativeValue = luaToLString(state, 1, &relativeLength);
    if (!relativeValue || relativeLength == 0 || relativeLength > 4096)
        return PushLoadError(state, "mod entry path must be a non-empty UTF-8 string");

    const std::string relativeUtf8(relativeValue, relativeLength);
    std::wstring relativeWide;
    if (!Utf8ToWide(relativeUtf8, relativeWide))
        return PushLoadError(state, "mod entry path is not valid UTF-8");

    const std::filesystem::path relative(relativeWide);
    if (relative.is_absolute() || relative.has_root_name() || relative.has_root_directory())
        return PushLoadError(state, "absolute mod entry paths are not allowed");
    for (const auto& component : relative) {
        if (component == L"..")
            return PushLoadError(state, "parent path segments are not allowed in mod entries");
    }

    const auto target = (modsRoot / relative).lexically_normal();
    std::string source;
    if (!ReadFile(target, source))
        return PushLoadError(state, "cannot read " + relativeUtf8);

    const auto chunkName = "@" + WideToUtf8(target.wstring());
    const int status = luaLoadBufferX(state, source.data(), source.size(), chunkName.c_str(), "t");
    if (status != 0) {
        const auto error = LuaError(state);
        return PushLoadError(state, error);
    }
    return 1;
}

bool LuaEnvironmentReady(LuaState state) {
    const int top = luaGetTop(state);
    luaGetGlobal(state, "package");
    const bool hasPackage = luaType(state, -1) == LuaTypeTable;
    luaSetTop(state, top);
    if (!hasPackage) return false;
    luaGetGlobal(state, "loadfile");
    const bool hasLoadFile = luaType(state, -1) == LuaTypeFunction;
    luaSetTop(state, top);
    return hasLoadFile;
}

void TryRunBootstrap(LuaState state) {
    if (bootstrapComplete.load(std::memory_order_acquire)) return;
    if (bootstrapPath.empty()) {
        bootstrapComplete.store(true, std::memory_order_release);
        return;
    }
    const auto now = GetTickCount64();
    if (now < nextBootstrapAttempt.load(std::memory_order_relaxed)) return;
    bool expected = false;
    if (!bootstrapRunning.compare_exchange_strong(expected, true)) return;

    if (!LuaEnvironmentReady(state)) {
        nextBootstrapAttempt.store(now + 1000, std::memory_order_relaxed);
        bootstrapRunning.store(false, std::memory_order_release);
        return;
    }

    std::string source;
    if (!ReadFile(bootstrapPath, source)) {
        Log("cannot read bootstrap: " + WideToUtf8(bootstrapPath.wstring()));
        nextBootstrapAttempt.store(now + 5000, std::memory_order_relaxed);
        bootstrapRunning.store(false, std::memory_order_release);
        return;
    }

    const int top = luaGetTop(state);
    const auto rootUtf8 = WideToUtf8(modsRoot.wstring());
    luaPushLString(state, rootUtf8.data(), rootUtf8.size());
    luaSetGlobal(state, "__BLUEOATH_MOD_ROOT");
    luaPushCClosure(state, &LoadModFile, 0);
    luaSetGlobal(state, "__blueoath_loadfile");
    luaPushCClosure(state, &LogFromLua, 0);
    luaSetGlobal(state, "__blueoath_log");

    const auto chunkName = "@" + WideToUtf8(bootstrapPath.wstring());
    int status = luaLoadBufferX(state, source.data(), source.size(), chunkName.c_str(), "t");
    if (status == 0)
        status = originalLuaPcallK(state, 0, 0, 0, 0, nullptr);
    if (status == 0) {
        bootstrapComplete.store(true, std::memory_order_release);
        Log("bootstrap executed successfully: " + WideToUtf8(bootstrapPath.wstring()));
    } else {
        Log("bootstrap failed: " + LuaError(state));
        nextBootstrapAttempt.store(now + 5000, std::memory_order_relaxed);
    }
    luaSetTop(state, top);
    bootstrapRunning.store(false, std::memory_order_release);
}

int __cdecl HookLuaPcallK(LuaState state, int argumentCount, int resultCount,
    int errorFunction, intptr_t context, LuaKFunction continuation) {
    const int status = originalLuaPcallK(state, argumentCount, resultCount,
        errorFunction, context, continuation);
    if (status != 0)
        Log("lua_pcallk status=" + std::to_string(status) + " error=" + LuaError(state));
    else {
        TryRunBootstrap(state);
        TryPatchBuildShipNewState(state);
    }
    return status;
}

template<typename T>
T Resolve(HMODULE module, const char* name) {
    return reinterpret_cast<T>(GetProcAddress(module, name));
}

bool ResolveLuaApi(HMODULE xlua) {
    luaGetTop = Resolve<LuaGetTop>(xlua, "lua_gettop");
    luaSetTop = Resolve<LuaSetTop>(xlua, "lua_settop");
    luaGetGlobal = Resolve<LuaGetGlobal>(xlua, "lua_getglobal");
    luaSetGlobal = Resolve<LuaSetGlobal>(xlua, "lua_setglobal");
    showGirlGetField = Resolve<LuaGetField>(xlua, "lua_getfield");
    showGirlSetField = Resolve<LuaSetField>(xlua, "lua_setfield");
    luaType = Resolve<LuaType>(xlua, "lua_type");
    showGirlPushValue = Resolve<LuaPushValue>(xlua, "lua_pushvalue");
    showGirlPushBoolean = Resolve<LuaPushBoolean>(xlua, "lua_pushboolean");
    showGirlToBoolean = Resolve<LuaToBoolean>(xlua, "lua_toboolean");
    luaPushLString = Resolve<LuaPushLString>(xlua, "lua_pushlstring");
    luaPushCClosure = Resolve<LuaPushCClosure>(xlua, "lua_pushcclosure");
    luaPushNil = Resolve<LuaPushNil>(xlua, "lua_pushnil");
    luaToLString = Resolve<LuaToLString>(xlua, "lua_tolstring");
    luaLoadBufferX = Resolve<LuaLoadBufferX>(xlua, "luaL_loadbufferx");
    return luaGetTop && luaSetTop && luaGetGlobal && luaSetGlobal &&
           showGirlGetField && showGirlSetField && luaType && showGirlPushValue &&
           showGirlPushBoolean && showGirlToBoolean && luaPushLString &&
           luaPushCClosure && luaPushNil && luaToLString && luaLoadBufferX;
}

bool InstallLuaPcallHook(HMODULE xlua) {
    const auto target = reinterpret_cast<unsigned char*>(GetProcAddress(xlua, "lua_pcallk"));
    if (!target || !ResolveLuaApi(xlua)) {
        Log("required xLua exports are missing");
        return false;
    }
    const unsigned char expectedPrologue[] = {0x55, 0x8B, 0xEC};
    if (memcmp(target, expectedPrologue, sizeof(expectedPrologue)) != 0) {
        Log("lua_pcallk prologue mismatch; hook refused");
        return false;
    }

    auto trampoline = static_cast<unsigned char*>(VirtualAlloc(nullptr,
        LuaPcallStolenLength + 5, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!trampoline) return false;
    memcpy(trampoline, target, LuaPcallStolenLength);
    trampoline[LuaPcallStolenLength] = 0xE9;
    const auto returnAddress = reinterpret_cast<uintptr_t>(target) + LuaPcallStolenLength;
    const auto returnRelative = static_cast<int32_t>(returnAddress -
        (reinterpret_cast<uintptr_t>(trampoline) + LuaPcallStolenLength + 5));
    memcpy(trampoline + LuaPcallStolenLength + 1, &returnRelative, sizeof(returnRelative));

    // Publish the callable trampoline before redirecting the live export. The
    // game may call lua_pcallk from another thread as soon as the first byte is
    // patched, so the hook must never observe a null original function.
    luaPcallTrampoline = trampoline;
    originalLuaPcallK = reinterpret_cast<LuaPcallK>(trampoline);

    DWORD oldProtection = 0;
    if (!VirtualProtect(target, LuaPcallStolenLength, PAGE_EXECUTE_READWRITE, &oldProtection)) {
        VirtualFree(trampoline, 0, MEM_RELEASE);
        return false;
    }
    const auto hookAddress = reinterpret_cast<uintptr_t>(&HookLuaPcallK);
    const auto hookRelative = static_cast<int32_t>(hookAddress -
        (reinterpret_cast<uintptr_t>(target) + 5));
    target[0] = 0xE9;
    memcpy(target + 1, &hookRelative, sizeof(hookRelative));
    for (size_t i = 5; i < LuaPcallStolenLength; ++i) target[i] = 0x90;
    VirtualProtect(target, LuaPcallStolenLength, oldProtection, &oldProtection);
    FlushInstructionCache(GetCurrentProcess(), target, LuaPcallStolenLength);

    return true;
}

DWORD InstallerThreadCore() {
    modsRoot = FindModsRoot();
    if (modsRoot.empty()) {
        Log("Mods/bootstrap.lua not found; continuing with built-in compatibility patches");
    } else {
        bootstrapPath = modsRoot / L"bootstrap.lua";
        Log("mods root: " + WideToUtf8(modsRoot.wstring()));
    }

    for (int attempt = 0; attempt < 6000; ++attempt) {
        const auto xlua = GetModuleHandleW(L"xlua.dll");
        if (!xlua) {
            Sleep(10);
            continue;
        }
        wchar_t path[MAX_PATH]{};
        if (!GetModuleFileNameW(xlua, path, MAX_PATH)) {
            Log("cannot resolve xlua.dll path");
            return 0;
        }
        const auto hash = HashFileSha256(path);
        if (hash != SupportedJpXluaSha256) {
            Log("unsupported xlua.dll SHA-256=" + hash + "; hook refused");
            return 0;
        }
        if (InstallLuaPcallHook(xlua))
            Log("lua_pcallk hook installed; waiting for Lua environment");
        else
            Log("lua_pcallk hook installation failed");
        return 0;
    }
    Log("xlua.dll did not load within 60 seconds");
    return 0;
}

DWORD WINAPI InstallerThread(void*) {
    try {
        return InstallerThreadCore();
    } catch (const std::exception& error) {
        Log(std::string("installer exception: ") + error.what());
    } catch (...) {
        Log("installer exception: unknown");
    }
    return 0;
}
}

void StartLuaModLoader(HMODULE payloadModule) {
    bool expected = false;
    if (!installerStarted.compare_exchange_strong(expected, true)) return;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(payloadModule, modulePath, MAX_PATH)) return;
    payloadDirectory = std::filesystem::path(modulePath).parent_path();
    logPath = payloadDirectory / L"BlueOath.Payload.log";
    Log("start requested");
    const auto thread = CreateThread(nullptr, 0, &InstallerThread, nullptr, 0, nullptr);
    if (thread) CloseHandle(thread);
    else Log("cannot create installer thread");
}
