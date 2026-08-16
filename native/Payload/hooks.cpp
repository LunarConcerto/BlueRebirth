#include "hooks.h"
#include <ws2tcpip.h>
#include <wincrypt.h>
#include <bcrypt.h>
#include <psapi.h>
#include <intrin.h>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <vector>

namespace {

using GetAddrInfoFn = int (WSAAPI*)(PCSTR, PCSTR, const ADDRINFOA*, PADDRINFOA*);
using FreeAddrInfoFn = void (WSAAPI*)(PADDRINFOA);
using SendToFn = int (WSAAPI*)(SOCKET, const char*, int, int, const sockaddr*, int);
using WsaSendToFn = int (WSAAPI*)(SOCKET, LPWSABUF, DWORD, LPDWORD, DWORD,
    const sockaddr*, int, LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);
using RecvFromFn = int (WSAAPI*)(SOCKET, char*, int, int, sockaddr*, int*);
using CertOpenStoreFn = HCERTSTORE (WINAPI*)(LPCSTR, DWORD, HCRYPTPROV_LEGACY, DWORD, const void*);
using CertEnumCertificatesInStoreFn = PCCERT_CONTEXT (WINAPI*)(HCERTSTORE, PCCERT_CONTEXT);
using CertGetCertificateChainFn = BOOL (WINAPI*)(HCERTCHAINENGINE, PCCERT_CONTEXT, LPFILETIME, HCERTSTORE, PCERT_CHAIN_PARA, DWORD, LPVOID, PCCERT_CHAIN_CONTEXT*);
using CertVerifyCertificateChainPolicyFn = BOOL (WINAPI*)(LPCSTR, PCCERT_CHAIN_CONTEXT, PCERT_CHAIN_POLICY_PARA, PCERT_CHAIN_POLICY_STATUS);
using CurlEasySetOptFn = int (__cdecl*)(void*, int, ...);
using CurlEasyPerformFn = int (__cdecl*)(void*);
using CurlEasyGetInfoFn = int (__cdecl*)(void*, int, ...);
using GetProcAddressFn = FARPROC (WINAPI*)(HMODULE, LPCSTR);
using InitSdkFn = uintptr_t (__cdecl*)(const char*, void*);
using SdkCallbackFn = void (__stdcall*)(int, const char*);
using UniversalWebFn = int (__cdecl*)(const char*, const char*, const char*);
using UniversalWithBackFn = uintptr_t (__cdecl*)(const char*, const char*);

GetAddrInfoFn originalGetAddrInfo = nullptr;
FreeAddrInfoFn originalFreeAddrInfo = nullptr;
SendToFn originalSendTo = nullptr;
WsaSendToFn originalWsaSendTo = nullptr;
RecvFromFn originalRecvFrom = nullptr;
CertOpenStoreFn originalCertOpenStore = nullptr;
CertEnumCertificatesInStoreFn originalCertEnumCertificatesInStore = nullptr;
CertGetCertificateChainFn originalCertGetCertificateChain = nullptr;
CertVerifyCertificateChainPolicyFn originalCertVerifyCertificateChainPolicy = nullptr;
CurlEasyGetInfoFn curlEasyGetInfo = nullptr;
CurlEasySetOptFn sdkCurlEasySetOpt = nullptr;
CurlEasyPerformFn sdkCurlEasyPerform = nullptr;
CurlEasySetOptFn newSdkCurlEasySetOpt = nullptr;
CurlEasyPerformFn newSdkCurlEasyPerform = nullptr;

bool redirectEnabled = false;
unsigned short redirectPort = 0;
unsigned short httpRedirectPort = 0;
bool allowUntrusted = false;
bool unityTlsPatchApplied = false;
bool sdkTlsPatchProcessed = false;
bool newSdkTlsPatchProcessed = false;
GetProcAddressFn originalGetProcAddress = nullptr;
InitSdkFn originalInitSdk = nullptr;
SdkCallbackFn originalSdkCallback = nullptr;
UniversalWebFn originalCallUniversalWebFunction = nullptr;
UniversalWithBackFn originalCallUniversalFunctionWithBack = nullptr;

std::filesystem::path logPath;
std::filesystem::path trustCertificatePath;
std::vector<BYTE> trustCertificateBytes;
std::mutex logMutex;
std::set<std::string> loggedRedirects;

void Log(const std::string& message);
std::string DescribeCaller(void* address);

void Log(const std::string& message) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << message << '\n';
}

void LogRedirectOnce(const std::string& message) {
    std::lock_guard<std::mutex> guard(logMutex);
    if (!loggedRedirects.insert(message).second) return;
    std::ofstream output(logPath, std::ios::app);
    output << message << '\n';
}

std::string DescribeCaller(void* address) {
    HMODULE owner = nullptr;
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
            GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            reinterpret_cast<LPCWSTR>(address), &owner) || !owner) {
        return "unknown";
    }
    wchar_t path[MAX_PATH]{};
    GetModuleFileNameW(owner, path, MAX_PATH);
    const auto name = std::filesystem::path(path).filename().string();
    const auto rva = reinterpret_cast<uintptr_t>(address) - reinterpret_cast<uintptr_t>(owner);
    char rvaText[32]{};
    sprintf_s(rvaText, "0x%llX", static_cast<unsigned long long>(rva));
    return name + "+" + rvaText;
}

std::string HashFileSha256(const std::filesystem::path& path) {
    HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
        OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return {};
    BCRYPT_ALG_HANDLE algorithm = nullptr;
    BCRYPT_HASH_HANDLE hash = nullptr;
    DWORD objectLength = 0, hashLength = 0, bytes = 0;
    std::string result;
    if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) == 0 &&
        BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH, reinterpret_cast<PUCHAR>(&objectLength), sizeof(objectLength), &bytes, 0) == 0 &&
        BCryptGetProperty(algorithm, BCRYPT_HASH_LENGTH, reinterpret_cast<PUCHAR>(&hashLength), sizeof(hashLength), &bytes, 0) == 0) {
        std::vector<UCHAR> object(objectLength), digest(hashLength), buffer(64 * 1024);
        if (BCryptCreateHash(algorithm, &hash, object.data(), objectLength, nullptr, 0, 0) == 0) {
            bool ok = true;
            for (;;) {
                DWORD read = 0;
                if (!ReadFile(file, buffer.data(), static_cast<DWORD>(buffer.size()), &read, nullptr)) { ok = false; break; }
                if (!read) break;
                if (BCryptHashData(hash, buffer.data(), read, 0) != 0) { ok = false; break; }
            }
            if (ok && BCryptFinishHash(hash, digest.data(), hashLength, 0) == 0) {
                static constexpr char digits[] = "0123456789ABCDEF";
                result.reserve(hashLength * 2);
                for (auto value : digest) { result.push_back(digits[value >> 4]); result.push_back(digits[value & 0xF]); }
            }
            BCryptDestroyHash(hash);
        }
        BCryptCloseAlgorithmProvider(algorithm, 0);
    }
    CloseHandle(file);
    return result;
}

bool IsGameHost(const char* node) {
    if (!node) return false;
    const size_t len = strlen(node);
    if (len >= 13 && _stricmp(node + len - 13, ".zuiyouxi.com") == 0) return true;
    if (len >= 13 && _stricmp(node + len - 13, ".blueoath.com") == 0) return true;
    return _stricmp(node, "ifconfig.io") == 0 || _stricmp(node, "api.ipify.org") == 0 ||
        _stricmp(node, "ip.3322.net") == 0 || _stricmp(node, "ipinfo.io") == 0;
}

int WSAAPI HookGetAddrInfo(PCSTR node, PCSTR service, const ADDRINFOA* hints, PADDRINFOA* result) {
    if (!redirectEnabled || !node || _stricmp(node, "localhost") == 0)
        return originalGetAddrInfo(node, service, hints, result);
    if (!IsGameHost(node))
        return originalGetAddrInfo(node, service, hints, result);
    const auto selectedPort = httpRedirectPort ? httpRedirectPort : redirectPort;
    const std::string redirectedService = selectedPort ? std::to_string(selectedPort) : std::string();
    const auto targetService = selectedPort ? redirectedService.c_str() : service;
    const auto status = originalGetAddrInfo("127.0.0.1", targetService, hints, result);
    if (status != 0 || !result || !*result) {
        Log(std::string("getaddrinfo redirect failed host=") + node +
            " status=" + std::to_string(status));
        return status;
    }
    Log(std::string("getaddrinfo redirect host=") + node + " target=127.0.0.1" +
        " original_service=" + (service ? service : "") +
        " target_service=" + (targetService ? targetService : "") +
        " caller=" + DescribeCaller(_ReturnAddress()));
    return status;
}

void WSAAPI HookFreeAddrInfo(PADDRINFOA result) {
    originalFreeAddrInfo(result);
}

bool TryUseLocalPlainHttp(void* handle, CurlEasySetOptFn setOpt, std::string& originalUrl) {
    if (!curlEasyGetInfo) {
        if (const auto libcurl = GetModuleHandleW(L"libcurl.dll")) {
            curlEasyGetInfo = reinterpret_cast<CurlEasyGetInfoFn>(GetProcAddress(libcurl, "curl_easy_getinfo"));
        }
    }
    if (!curlEasyGetInfo) { LogRedirectOnce("libcurl downgrade refused: curl_easy_getinfo unresolved"); return false; }
    if (!httpRedirectPort) { LogRedirectOnce("libcurl downgrade refused: http_port is 0"); return false; }
    constexpr int curlInfoEffectiveUrl = 0x100001;
    constexpr int curlOptUrl = 10002;
    char* rawUrl = nullptr;
    const auto infoResult = curlEasyGetInfo(handle, curlInfoEffectiveUrl, &rawUrl);
    if (infoResult != 0 || !rawUrl) {
        LogRedirectOnce("libcurl downgrade refused: CURLINFO_EFFECTIVE_URL failed result=" +
            std::to_string(infoResult));
        return false;
    }
    originalUrl = rawUrl;
    static constexpr const char* localHosts[] = {
        "mapijpshipgirl.blueoath.com", "msdk.zuiyouxi.com", "haina.blueoath.com"
    };
    if (originalUrl.rfind("https://", 0) != 0) { LogRedirectOnce("libcurl downgrade refused: not https url=" + originalUrl); return false; }
    bool localHost = false;
    for (const auto host : localHosts) {
        if (originalUrl.compare(8, strlen(host), host) == 0) { localHost = true; break; }
    }
    if (!localHost) { LogRedirectOnce("libcurl downgrade refused: host not local url=" + originalUrl); return false; }
    const auto localUrl = std::string("http://") + originalUrl.substr(8);
    if (setOpt(handle, curlOptUrl, localUrl.c_str()) != 0) { LogRedirectOnce("libcurl downgrade refused: CURLOPT_URL set failed"); return false; }
    LogRedirectOnce("libcurl local HTTPS downgraded to loopback HTTP");
    return true;
}

int __cdecl HookSdkCurlEasyPerform(void* handle) {
    constexpr int curlOptSslVersion = 32;
    constexpr int curlOptSslVerifyPeer = 64;
    constexpr int curlOptSslVerifyHost = 81;
    constexpr long curlSslVersionTls12 = 6;
    sdkCurlEasySetOpt(handle, curlOptSslVersion, curlSslVersionTls12);
    sdkCurlEasySetOpt(handle, curlOptSslVerifyPeer, 0L);
    sdkCurlEasySetOpt(handle, curlOptSslVerifyHost, 0L);
    std::string originalUrl;
    const auto plainHttp = TryUseLocalPlainHttp(handle, sdkCurlEasySetOpt, originalUrl);
    LogRedirectOnce("sdk_ui curl_easy_perform hooked caller=" + DescribeCaller(_ReturnAddress()) +
        " url=" + originalUrl + " downgraded=" + (plainHttp ? "true" : "false"));
    const auto result = sdkCurlEasyPerform(handle);
    if (plainHttp) sdkCurlEasySetOpt(handle, 10002, originalUrl.c_str());
    return result;
}

int __cdecl HookNewSdkCurlEasyPerform(void* handle) {
    constexpr int curlOptSslVersion = 32;
    constexpr int curlOptSslVerifyPeer = 64;
    constexpr int curlOptSslVerifyHost = 81;
    constexpr long curlSslVersionTls12 = 6;
    newSdkCurlEasySetOpt(handle, curlOptSslVersion, curlSslVersionTls12);
    newSdkCurlEasySetOpt(handle, curlOptSslVerifyPeer, 0L);
    newSdkCurlEasySetOpt(handle, curlOptSslVerifyHost, 0L);
    std::string originalUrl;
    const auto plainHttp = TryUseLocalPlainHttp(handle, newSdkCurlEasySetOpt, originalUrl);
    LogRedirectOnce("new_sdk curl_easy_perform hooked caller=" + DescribeCaller(_ReturnAddress()) +
        " url=" + originalUrl + " downgraded=" + (plainHttp ? "true" : "false"));
    const auto result = newSdkCurlEasyPerform(handle);
    if (plainHttp) newSdkCurlEasySetOpt(handle, 10002, originalUrl.c_str());
    return result;
}

void TryPatchCurlCaller(const wchar_t* moduleName, const std::string& expectedHash,
    bool& processed, CurlEasySetOptFn& setOpt, CurlEasyPerformFn& perform,
    void* hook, const std::string& logName) {
    if (!redirectEnabled || !allowUntrusted || processed) return;
    auto sdk = GetModuleHandleW(moduleName);
    if (!sdk) return;
    processed = true;

    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(sdk, modulePath, MAX_PATH)) {
        Log(logName + " TLS patch refused: module path unavailable");
        return;
    }
    const auto hash = HashFileSha256(modulePath);
    if (hash != expectedHash) {
        Log(logName + " TLS patch refused: SHA-256 mismatch");
        return;
    }

    auto base = reinterpret_cast<unsigned char*>(sdk);
    auto dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return;
    auto nt = reinterpret_cast<IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) return;
    const auto directory = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!directory.VirtualAddress) return;

    IMAGE_THUNK_DATA* performSlot = nullptr;
    for (auto descriptor = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(base + directory.VirtualAddress);
         descriptor->Name; ++descriptor) {
        const char* library = reinterpret_cast<const char*>(base + descriptor->Name);
        if (_stricmp(library, "libcurl.dll") != 0) continue;
        auto names = descriptor->OriginalFirstThunk
            ? reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->OriginalFirstThunk)
            : reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
        auto slots = reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
        for (; names->u1.AddressOfData; ++names, ++slots) {
            if (IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal)) continue;
            auto import = reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(base + names->u1.AddressOfData);
            const auto name = reinterpret_cast<const char*>(import->Name);
            if (strcmp(name, "curl_easy_setopt") == 0) {
                setOpt = reinterpret_cast<CurlEasySetOptFn>(slots->u1.Function);
            } else if (strcmp(name, "curl_easy_perform") == 0) {
                perform = reinterpret_cast<CurlEasyPerformFn>(slots->u1.Function);
                performSlot = slots;
            }
        }
    }
    if (!setOpt || !perform || !performSlot) {
        Log(logName + " TLS patch refused: required libcurl imports missing");
        return;
    }

    DWORD oldProtect = 0;
    if (!VirtualProtect(&performSlot->u1.Function, sizeof(void*), PAGE_READWRITE, &oldProtect)) {
        Log(logName + " TLS patch refused: VirtualProtect failed");
        return;
    }
    performSlot->u1.Function = reinterpret_cast<ULONG_PTR>(hook);
    VirtualProtect(&performSlot->u1.Function, sizeof(void*), oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), &performSlot->u1.Function, sizeof(void*));
    Log(logName + " TLS patch applied: verified curl_easy_perform IAT");
}

void TryApplySdkTlsPatches() {
    TryPatchCurlCaller(L"sdk_ui_win32xx.dll",
        "06B23FA68AC436AEF9EF639EFAAD9FE34D879ADBCC175DEB3F7E12ABFD50F105",
        sdkTlsPatchProcessed, sdkCurlEasySetOpt, sdkCurlEasyPerform,
        reinterpret_cast<void*>(&HookSdkCurlEasyPerform), "sdk_ui_win32xx.dll");
    TryPatchCurlCaller(L"new_sdk.dll",
        "1CF7BF8C8B25C3C7F26F839AE8A4D32F1D3A4966ECCC826C8669C8AB5759DB0B",
        newSdkTlsPatchProcessed, newSdkCurlEasySetOpt, newSdkCurlEasyPerform,
        reinterpret_cast<void*>(&HookNewSdkCurlEasyPerform), "new_sdk.dll");
}

void __stdcall HookSdkCallback(int eventId, const char* payload) {
    std::string preview;
    if (payload) {
        for (int i = 0; i < 240 && payload[i]; ++i)
            preview.push_back(payload[i] >= 0x20 && payload[i] < 0x7f ? payload[i] : '.');
    } else {
        preview = "<null>";
    }
    Log("sdk callback event=" + std::to_string(eventId) + " payload=" + preview);
    if (originalSdkCallback) originalSdkCallback(eventId, payload);
}

uintptr_t __cdecl HookInitSdk(const char* options, void* callback) {
    originalSdkCallback = reinterpret_cast<SdkCallbackFn>(callback);
    Log("sdk initSDK called, callback captured");
    return originalInitSdk(options, reinterpret_cast<void*>(&HookSdkCallback));
}

std::string SafeStr(const char* s) {
    if (!s) return "<null>";
    std::string out;
    for (int i = 0; i < 256; ++i) {
        MEMORY_BASIC_INFORMATION m{};
        if (!VirtualQuery(s + i, &m, sizeof(m)) || m.State != MEM_COMMIT ||
            (m.Protect & (PAGE_NOACCESS | PAGE_GUARD)))
            return out.empty() ? "<unreadable>" : out;
        const unsigned char ch = static_cast<unsigned char>(s[i]);
        if (!ch) return out;
        out.push_back(ch >= 0x20 && ch < 0x7f ? static_cast<char>(ch) : '.');
    }
    return out;
}

int __cdecl HookCallUniversalWebFunction(const char* a, const char* b, const char* c) {
    Log("sdk callUniversalWebFunction a=" + SafeStr(a) +
        " b=" + SafeStr(b) +
        " c=" + SafeStr(c));
    const auto result = originalCallUniversalWebFunction(a, b, c);
    Log("sdk callUniversalWebFunction result=" + std::to_string(result));
    return result;
}

uintptr_t __cdecl HookCallUniversalFunctionWithBack(const char* functionName, const char* arguments) {
    Log("sdk callUniversalFunctionWithBack fn=" + SafeStr(functionName) +
        " args=" + SafeStr(arguments));
    const auto result = originalCallUniversalFunctionWithBack(functionName, arguments);
    Log("sdk callUniversalFunctionWithBack result=" + std::to_string(result));
    return result;
}

FARPROC WINAPI HookGetProcAddress(HMODULE module, LPCSTR name) {
    const auto procedure = originalGetProcAddress(module, name);
    if (name && reinterpret_cast<uintptr_t>(name) > 0xFFFF) {
        wchar_t path[MAX_PATH]{};
        const bool isNewSdk = GetModuleFileNameW(module, path, MAX_PATH) &&
            _wcsicmp(std::filesystem::path(path).filename().c_str(), L"new_sdk.dll") == 0;
        if (isNewSdk && strcmp(name, "initSDK") == 0) {
            originalInitSdk = reinterpret_cast<InitSdkFn>(procedure);
            Log("sdk callback observation: intercepted new_sdk initSDK");
            return reinterpret_cast<FARPROC>(&HookInitSdk);
        }
        if (isNewSdk && strcmp(name, "callUniversalWebFunction") == 0) {
            originalCallUniversalWebFunction = reinterpret_cast<UniversalWebFn>(procedure);
            Log("sdk callback observation: intercepted callUniversalWebFunction");
            return reinterpret_cast<FARPROC>(&HookCallUniversalWebFunction);
        }
        if (isNewSdk && strcmp(name, "callUniversalFunctionWithBack") == 0) {
            originalCallUniversalFunctionWithBack = reinterpret_cast<UniversalWithBackFn>(procedure);
            Log("sdk callback observation: intercepted callUniversalFunctionWithBack");
            return reinterpret_cast<FARPROC>(&HookCallUniversalFunctionWithBack);
        }
    }
    return procedure;
}

void* pageOpenStolen = nullptr;
bool pageOpenHookApplied = false;
void* boxContentStolen = nullptr;
bool boxContentHookApplied = false;

void LogIl2CppString(const char* label, void* str) {
    std::string name;
    if (str) {
        MEMORY_BASIC_INFORMATION mem{};
        if (!VirtualQuery(str, &mem, sizeof(mem)) || mem.State != MEM_COMMIT ||
            (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
            name = "<unreadable>";
        } else {
            const int length = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(str) + 8);
            if (length < 0 || length > 512) {
                name = "<bad-len:" + std::to_string(length) + ">";
            } else {
                const auto chars = reinterpret_cast<const wchar_t*>(reinterpret_cast<const char*>(str) + 12);
                for (int i = 0; i < length; ++i)
                    name.push_back(chars[i] >= 0x20 && chars[i] < 0x7f ? static_cast<char>(chars[i]) : '.');
            }
        }
    } else {
        name = "<null>";
    }
    Log(std::string(label) + ": " + name);
}

void LogPageOpen(void* str) { LogIl2CppString("page open", str); }
void LogBoxContent(void* str) { LogIl2CppString("box content", str); }

__declspec(naked) void PageOpenTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogPageOpen
        add esp, 4
        popad
        jmp dword ptr [pageOpenStolen]
    }
}

__declspec(naked) void BoxContentTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogBoxContent
        add esp, 4
        popad
        jmp dword ptr [boxContentStolen]
    }
}

bool InstallStrArgHook(uintptr_t rva, void* trampoline, void** stolenOut, size_t stolenLen, const char* name) {
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return false;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(ga, modulePath, MAX_PATH)) return false;
    if (HashFileSha256(modulePath) != "8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404") {
        Log(std::string(name) + " hook refused: SHA-256 mismatch");
        return false;
    }
    auto address = reinterpret_cast<unsigned char*>(ga) + rva;
    const unsigned char expected[] = { 0x55, 0x8B, 0xEC };
    if (memcmp(address, expected, sizeof(expected)) != 0) {
        char actual[16]{};
        for (int i = 0; i < 6; ++i) { char b[4]{}; sprintf_s(b, "%02X ", address[i]); strcat_s(actual, b); }
        Log(std::string(name) + " hook refused: prologue mismatch actual=" + actual);
        return false;
    }
    auto stolen = VirtualAlloc(nullptr, stolenLen + 7, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stolen) return false;
    auto s = reinterpret_cast<unsigned char*>(stolen);
    memcpy(s, address, stolenLen);
    int pos = static_cast<int>(stolenLen);
    auto backTarget = reinterpret_cast<uintptr_t>(address) + stolenLen;
    s[pos++] = 0xE9;
    int32_t backRel = static_cast<int32_t>(backTarget - (reinterpret_cast<uintptr_t>(stolen) + pos + 4));
    memcpy(s + pos, &backRel, 4);
    pos += 4;
    *stolenOut = stolen;
    const auto tramp = reinterpret_cast<uintptr_t>(trampoline);
    const auto rel = static_cast<int32_t>(tramp - (reinterpret_cast<uintptr_t>(address) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, stolenLen, PAGE_EXECUTE_READWRITE, &oldProtect)) return false;
    memcpy(address, jump, 5);
    for (size_t i = 5; i < stolenLen; ++i) address[i] = 0x90;
    VirtualProtect(address, stolenLen, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, stolenLen);
    Log(std::string(name) + " hook applied");
    return true;
}

void TryApplyPageOpenHook() {
    if (pageOpenHookApplied) return;
    pageOpenHookApplied = true;
    InstallStrArgHook(0x27FC90, &PageOpenTrampoline, &pageOpenStolen, 11, "page open");
}

void TryApplyBoxContentHook() {
    if (boxContentHookApplied) return;
    boxContentHookApplied = true;
    InstallStrArgHook(0x277580, &BoxContentTrampoline, &boxContentStolen, 10, "box content");
}

void TryApplyUnityTlsPatch() {
    if (!allowUntrusted || unityTlsPatchApplied) return;
    auto unity = GetModuleHandleW(L"UnityPlayer.dll");
    if (!unity) return;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(unity, modulePath, MAX_PATH)) return;
    const auto hash = HashFileSha256(modulePath);
    if (hash != "88C45E6394C4C42F6698319C9B85D29C1AB461F8EBD6284CA9EE931F2050D63D") {
        Log("UnityTLS trust patch refused: UnityPlayer SHA-256 mismatch");
        unityTlsPatchApplied = true;
        return;
    }
    constexpr uintptr_t patchRva = 0x8E1573;
    auto address = reinterpret_cast<unsigned char*>(unity) + patchRva;
    const unsigned char expected[] = {
        0x8B, 0x47, 0x34, 0x5F, 0x5E, 0x5D, 0xC3, 0xCC, 0xCC, 0xCC
    };
    if (memcmp(address, expected, sizeof(expected)) != 0) {
        Log("UnityTLS trust patch refused: RVA 0x8E1573 machine-code mismatch");
        unityTlsPatchApplied = true;
        return;
    }
    const unsigned char replacement[] = { 0x83, 0xE0, 0xF7, 0x5F, 0x5E, 0x5D, 0xC3 };
    DWORD oldProtect = 0;
    if (!VirtualProtect(address + 3, sizeof(replacement), PAGE_EXECUTE_READWRITE, &oldProtect)) {
        Log("UnityTLS trust patch refused: VirtualProtect failed");
        unityTlsPatchApplied = true;
        return;
    }
    memcpy(address + 3, replacement, sizeof(replacement));
    VirtualProtect(address + 3, sizeof(replacement), oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, sizeof(expected));
    unityTlsPatchApplied = true;
    Log("UnityTLS trust patch applied: UnityPlayer RVA 0x8E1573 masks NOT_TRUSTED only");
}

HCERTSTORE WINAPI HookCertOpenStore(LPCSTR provider, DWORD encoding, HCRYPTPROV_LEGACY cryptProvider,
    DWORD flags, const void* parameter) {
    const auto providerValue = reinterpret_cast<ULONG_PTR>(provider);
    const auto systemAnsi = providerValue == reinterpret_cast<ULONG_PTR>(CERT_STORE_PROV_SYSTEM_A);
    const auto systemWide = providerValue == reinterpret_cast<ULONG_PTR>(CERT_STORE_PROV_SYSTEM_W);
    const auto rootStore = parameter && ((systemAnsi && _stricmp(static_cast<const char*>(parameter), "ROOT") == 0) ||
        (systemWide && _wcsicmp(static_cast<const wchar_t*>(parameter), L"ROOT") == 0));
    auto store = originalCertOpenStore(provider, encoding, cryptProvider, flags, parameter);
    if (!redirectEnabled || !store || trustCertificatePath.empty() || !rootStore) {
        return store;
    }

    auto memory = originalCertOpenStore(CERT_STORE_PROV_MEMORY, 0, 0, 0, nullptr);
    if (!memory) return store;
    PCCERT_CONTEXT current = nullptr;
    while ((current = CertEnumCertificatesInStore(store, current)) != nullptr) {
        if (!CertAddCertificateContextToStore(memory, current, CERT_STORE_ADD_ALWAYS, nullptr)) {
            Log("failed to copy a ROOT certificate into process-local store");
            CertCloseStore(memory, 0);
            return store;
        }
    }
    HANDLE file = CreateFileW(trustCertificatePath.c_str(), GENERIC_READ, FILE_SHARE_READ,
        nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) {
        Log("trust certificate file could not be opened: " + trustCertificatePath.string());
        CertCloseStore(memory, 0);
        return store;
    }
    LARGE_INTEGER size{};
    std::vector<BYTE> bytes;
    if (GetFileSizeEx(file, &size) && size.QuadPart > 0 && size.QuadPart <= 4 * 1024 * 1024) {
        bytes.resize(static_cast<size_t>(size.QuadPart));
        DWORD read = 0;
        if (!ReadFile(file, bytes.data(), static_cast<DWORD>(bytes.size()), &read, nullptr) || read != bytes.size()) bytes.clear();
    }
    CloseHandle(file);
    auto context = bytes.empty() ? nullptr : CertCreateCertificateContext(X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, bytes.data(), static_cast<DWORD>(bytes.size()));
    if (!context || !CertAddCertificateContextToStore(memory, context, CERT_STORE_ADD_ALWAYS, nullptr)) {
        Log("trust certificate could not be added to process-local ROOT store");
        if (context) CertFreeCertificateContext(context);
        CertCloseStore(memory, 0);
        return store;
    }
    CertFreeCertificateContext(context);
    CertCloseStore(store, 0);
    Log("using process-local ROOT store with configured certificate");
    return memory;
}

PCCERT_CONTEXT WINAPI HookCertEnumCertificatesInStore(HCERTSTORE store, PCCERT_CONTEXT previous) {
    return originalCertEnumCertificatesInStore(store, previous);
}

BOOL WINAPI HookCertGetCertificateChain(HCERTCHAINENGINE engine, PCCERT_CONTEXT certificate,
    LPFILETIME time, HCERTSTORE additionalStore, PCERT_CHAIN_PARA parameters, DWORD flags,
    LPVOID reserved, PCCERT_CHAIN_CONTEXT* chain) {
    return originalCertGetCertificateChain(engine, certificate, time, additionalStore, parameters,
        flags, reserved, chain);
}

BOOL WINAPI HookCertVerifyCertificateChainPolicy(LPCSTR policyOid, PCCERT_CHAIN_CONTEXT chain,
    PCERT_CHAIN_POLICY_PARA policyParameters, PCERT_CHAIN_POLICY_STATUS policyStatus) {
    return originalCertVerifyCertificateChainPolicy(policyOid, chain, policyParameters, policyStatus);
}

std::string DescribeUdpTarget(const sockaddr* address) {
    if (!address || address->sa_family != AF_INET) return "non-ipv4";
    const auto addr = reinterpret_cast<const sockaddr_in*>(address);
    char ip[32]{};
    inet_ntop(AF_INET, &addr->sin_addr, ip, sizeof(ip));
    return std::string(ip) + ":" + std::to_string(ntohs(addr->sin_port));
}

void LogUdpPacket(const std::string& label, const sockaddr* address, const char* data,
    int length, void* returnAddress) {
    std::string preview;
    const auto previewLen = length > 0 ? std::min(length, 24) : 0;
    for (int i = 0; i < previewLen; ++i) {
        char buf[4]{};
        sprintf_s(buf, "%02X", static_cast<unsigned char>(data[i]));
        preview += buf;
        if (i + 1 < previewLen) preview += ' ';
    }
    Log(label + " target=" + DescribeUdpTarget(address) +
        " bytes=" + std::to_string(length) +
        " caller=" + DescribeCaller(returnAddress) +
        " hex=" + preview);
}

int WSAAPI HookSendTo(SOCKET socket, const char* buffer, int length, int flags,
    const sockaddr* address, int addressLength) {
    if (redirectEnabled) LogUdpPacket("udp sendto", address, buffer, length, _ReturnAddress());
    return originalSendTo(socket, buffer, length, flags, address, addressLength);
}

int WSAAPI HookWsaSendTo(SOCKET socket, LPWSABUF buffers, DWORD bufferCount, LPDWORD bytesSent,
    DWORD flags, const sockaddr* address, int addressLength,
    LPWSAOVERLAPPED overlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE completionRoutine) {
    if (redirectEnabled) {
        LogUdpPacket("udp WSASendTo", address,
            buffers && bufferCount ? buffers[0].buf : nullptr,
            buffers && bufferCount ? static_cast<int>(buffers[0].len) : 0, _ReturnAddress());
    }
    return originalWsaSendTo(socket, buffers, bufferCount, bytesSent, flags, address,
        addressLength, overlapped, completionRoutine);
}

int WSAAPI HookRecvFrom(SOCKET socket, char* buffer, int length, int flags,
    sockaddr* address, int* addressLength) {
    const auto result = originalRecvFrom(socket, buffer, length, flags, address, addressLength);
    if (redirectEnabled && result > 0) LogUdpPacket("udp recvfrom", address, buffer, result, _ReturnAddress());
    return result;
}

bool PatchModule(HMODULE module) {
    auto base = reinterpret_cast<unsigned char*>(module);
    auto dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    if (!base || dos->e_magic != IMAGE_DOS_SIGNATURE) return false;
    auto nt = reinterpret_cast<IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) return false;
    const auto directory = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!directory.VirtualAddress) return false;
    wchar_t modulePath[MAX_PATH]{};
    GetModuleFileNameW(module, modulePath, MAX_PATH);
    const bool gameAssembly = _wcsicmp(
        std::filesystem::path(modulePath).filename().c_str(), L"GameAssembly.dll") == 0;
    bool patched = false;
    for (auto descriptor = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(base + directory.VirtualAddress); descriptor->Name; ++descriptor) {
        const char* library = reinterpret_cast<const char*>(base + descriptor->Name);
        const bool winsock = _stricmp(library, "ws2_32.dll") == 0 || _stricmp(library, "wsock32.dll") == 0;
        const bool crypt32 = _stricmp(library, "crypt32.dll") == 0;
        const bool kernel32 = gameAssembly && _stricmp(library, "kernel32.dll") == 0;
        if (!winsock && !crypt32 && !kernel32) continue;
        auto names = descriptor->OriginalFirstThunk ? reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->OriginalFirstThunk) : reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
        auto slots = reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
        for (; names->u1.AddressOfData; ++names, ++slots) {
            void* replacement = nullptr;
            if (IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal)) {
            } else {
                auto import = reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(base + names->u1.AddressOfData);
                const auto name = reinterpret_cast<const char*>(import->Name);
                if (winsock && strcmp(name, "getaddrinfo") == 0) replacement = reinterpret_cast<void*>(&HookGetAddrInfo);
                if (winsock && strcmp(name, "freeaddrinfo") == 0) replacement = reinterpret_cast<void*>(&HookFreeAddrInfo);
                if (winsock && strcmp(name, "sendto") == 0) replacement = reinterpret_cast<void*>(&HookSendTo);
                if (winsock && strcmp(name, "WSASendTo") == 0) replacement = reinterpret_cast<void*>(&HookWsaSendTo);
                if (winsock && strcmp(name, "recvfrom") == 0) replacement = reinterpret_cast<void*>(&HookRecvFrom);
                if (crypt32 && strcmp(name, "CertOpenStore") == 0) replacement = reinterpret_cast<void*>(&HookCertOpenStore);
                if (crypt32 && strcmp(name, "CertEnumCertificatesInStore") == 0) replacement = reinterpret_cast<void*>(&HookCertEnumCertificatesInStore);
                if (crypt32 && strcmp(name, "CertGetCertificateChain") == 0) replacement = reinterpret_cast<void*>(&HookCertGetCertificateChain);
                if (crypt32 && strcmp(name, "CertVerifyCertificateChainPolicy") == 0) replacement = reinterpret_cast<void*>(&HookCertVerifyCertificateChainPolicy);
                if (kernel32 && strcmp(name, "GetProcAddress") == 0) replacement = reinterpret_cast<void*>(&HookGetProcAddress);
            }
            if (!replacement || reinterpret_cast<void*>(slots->u1.Function) == replacement) continue;
            DWORD old = 0;
            if (VirtualProtect(&slots->u1.Function, sizeof(void*), PAGE_READWRITE, &old)) {
                slots->u1.Function = reinterpret_cast<ULONG_PTR>(replacement);
                VirtualProtect(&slots->u1.Function, sizeof(void*), old, &old);
                FlushInstructionCache(GetCurrentProcess(), &slots->u1.Function, sizeof(void*));
                patched = true;
            }
        }
    }
    return patched;
}

}

void InitializeHooks(HMODULE module) {
    wchar_t modulePath[MAX_PATH]{};
    GetModuleFileNameW(module, modulePath, MAX_PATH);
    const auto directory = std::filesystem::path(modulePath).parent_path();
    logPath = directory / L"BlueOath.Payload.log";
    const auto config = (directory / L"bootstrap.ini").wstring();
    redirectEnabled = GetPrivateProfileIntW(L"redirect", L"enabled", 0, config.c_str()) != 0;
    redirectPort = static_cast<unsigned short>(GetPrivateProfileIntW(L"redirect", L"port", 0, config.c_str()));
    httpRedirectPort = static_cast<unsigned short>(GetPrivateProfileIntW(L"redirect", L"http_port", 0, config.c_str()));
    allowUntrusted = GetPrivateProfileIntW(L"trust", L"allow_untrusted", 0, config.c_str()) != 0;

    wchar_t trustPath[MAX_PATH]{};
    GetPrivateProfileStringW(L"trust", L"certificate", L"", trustPath, MAX_PATH, config.c_str());
    if (trustPath[0]) trustCertificatePath = std::filesystem::path(trustPath);
    if (!trustCertificatePath.empty()) {
        std::ifstream trustInput(trustCertificatePath, std::ios::binary);
        trustCertificateBytes.assign(std::istreambuf_iterator<char>(trustInput), std::istreambuf_iterator<char>());
    }

    if (const auto libcurl = GetModuleHandleW(L"libcurl.dll")) {
        curlEasyGetInfo = reinterpret_cast<CurlEasyGetInfoFn>(GetProcAddress(libcurl, "curl_easy_getinfo"));
    }

    auto ws2 = GetModuleHandleW(L"ws2_32.dll");
    if (!ws2) ws2 = LoadLibraryW(L"ws2_32.dll");
    originalGetAddrInfo = reinterpret_cast<GetAddrInfoFn>(GetProcAddress(ws2, "getaddrinfo"));
    originalFreeAddrInfo = reinterpret_cast<FreeAddrInfoFn>(GetProcAddress(ws2, "freeaddrinfo"));
    originalSendTo = reinterpret_cast<SendToFn>(GetProcAddress(ws2, "sendto"));
    originalWsaSendTo = reinterpret_cast<WsaSendToFn>(GetProcAddress(ws2, "WSASendTo"));
    originalRecvFrom = reinterpret_cast<RecvFromFn>(GetProcAddress(ws2, "recvfrom"));
    auto crypt32 = GetModuleHandleW(L"crypt32.dll");
    if (!crypt32) crypt32 = LoadLibraryW(L"crypt32.dll");
    originalCertOpenStore = reinterpret_cast<CertOpenStoreFn>(GetProcAddress(crypt32, "CertOpenStore"));
    originalCertEnumCertificatesInStore = reinterpret_cast<CertEnumCertificatesInStoreFn>(GetProcAddress(crypt32, "CertEnumCertificatesInStore"));
    originalCertGetCertificateChain = reinterpret_cast<CertGetCertificateChainFn>(GetProcAddress(crypt32, "CertGetCertificateChain"));
    originalCertVerifyCertificateChainPolicy = reinterpret_cast<CertVerifyCertificateChainPolicyFn>(GetProcAddress(crypt32, "CertVerifyCertificateChainPolicy"));
    auto kernel32 = GetModuleHandleW(L"kernel32.dll");
    originalGetProcAddress = reinterpret_cast<GetProcAddressFn>(GetProcAddress(kernel32, "GetProcAddress"));

    Log(std::string("payload initialized redirect=") + (redirectEnabled ? "true" : "false") +
        " port=" + std::to_string(redirectPort) +
        " http_port=" + std::to_string(httpRedirectPort) +
        " allow_untrusted=" + (allowUntrusted ? "true" : "false"));

    const auto eventName = L"Local\\BlueOath.Inject." + std::to_wstring(GetCurrentProcessId());
    HANDLE event = OpenEventW(EVENT_MODIFY_STATE, FALSE, eventName.c_str());
    if (event) { SetEvent(event); CloseHandle(event); }

    if (!redirectEnabled || !originalGetAddrInfo || !originalFreeAddrInfo || !originalCertOpenStore ||
        !originalCertEnumCertificatesInStore || !originalCertGetCertificateChain ||
        !originalCertVerifyCertificateChainPolicy) return;

    for (;;) {
        HMODULE modules[1024]{};
        DWORD bytes = 0;
        if (EnumProcessModules(GetCurrentProcess(), modules, sizeof(modules), &bytes)) {
            const auto count = std::min<DWORD>(bytes / sizeof(HMODULE), 1024);
            for (DWORD i = 0; i < count; ++i) PatchModule(modules[i]);
        }
        TryApplyUnityTlsPatch();
        TryApplySdkTlsPatches();
        TryApplyPageOpenHook();
        TryApplyBoxContentHook();
        Sleep(500);
    }
}
