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
using SendFn = int (WSAAPI*)(SOCKET, const char*, int, int);
using RecvFn = int (WSAAPI*)(SOCKET, char*, int, int);
using SocketFn = SOCKET (WSAAPI*)(int, int, int);
using ConnectFn = int (WSAAPI*)(SOCKET, const sockaddr*, int);
using WsaSocketFn = SOCKET (WSAAPI*)(int, int, int, void*, unsigned int, DWORD);
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
SendFn originalSend = nullptr;
RecvFn originalRecv = nullptr;
SocketFn originalSocket = nullptr;
ConnectFn originalConnect = nullptr;
WsaSocketFn originalWsaSocket = nullptr;
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
uintptr_t ReadPtrSafe(uintptr_t addr);

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

bool simulationModeSet = false;

void DispatchLoginEvent() {
    static ULONGLONG lastDispatch = 0;
    const auto now = GetTickCount64();
    if (now - lastDispatch < 5000) return;
    lastDispatch = now;
    if (!originalSdkCallback) { Log("dispatchLogin: no sdk callback"); return; }
    // The SDK delivers every event (1/9/19/27/31/1007/...) through the initSDK callback
    // as a plain (int, const char*) UTF-8 pair; event 2 is login. Calling it directly
    // avoids the SDK's custom C++ string class (which differs from MSVC std::string and
    // corrupts the stack when crossed from the payload ABI).
    // SetLoginInfo (event 2) requires errornu == "0" (string), stores uid -> m_pid and
    // regPlosgn -> m_regPlosgn. Lua login reads result.uid and result.protocolStatus ("2"
    // marks the user treaty as accepted).
    const char* result =
        "{\"errornu\":\"0\",\"errordesc\":\"\",\"uid\":\"local-player\",\"pid\":\"local-player\","
        "\"regPlosgn\":\"google_windows_android_jpshipgirl\",\"token\":\"local-token\","
        "\"protocolStatus\":\"2\",\"newuser\":\"0\"}";
    originalSdkCallback(2, result);
    Log("dispatchLogin done event=2");
}

bool closeWebViewRequested = false;
ULONGLONG closeWebViewAt = 0;
bool closeScheduledOnce = false;

void HideCefWebView() {
    static ULONGLONG lastRun = 0;
    const auto now = GetTickCount64();
    if (now - lastRun < 1000) return;
    lastRun = now;
    // The QR login WebView is a native CEF window (libcef.dll) that stays on top with a
    // blank page. Enumerate this process's top-level windows and hide the CEF browser
    // window and its host dialog.
    EnumWindows([](HWND hwnd, LPARAM) -> BOOL {
        DWORD pid = 0;
        GetWindowThreadProcessId(hwnd, &pid);
        if (pid != GetCurrentProcessId()) return TRUE;
        if (!IsWindowVisible(hwnd)) return TRUE;
        char cls[256]{};
        char title[256]{};
        GetClassNameA(hwnd, cls, sizeof(cls));
        GetWindowTextA(hwnd, title, sizeof(title));
        const bool cef = strstr(cls, "Chrome_WidgetWin") != nullptr ||
            strstr(cls, "Chrome_") != nullptr;
        const bool blankDialog = strcmp(cls, "#32770") == 0 && title[0] == '\0';
        if (cef || blankDialog) {
            ShowWindow(hwnd, SW_HIDE);
            Log(std::string("hidden WebView window class=") + cls + " title=" + title);
        }
        return TRUE;
    }, 0);
}

void CloseSdkWebView() {
    auto newSdk = GetModuleHandleW(L"new_sdk.dll");
    if (newSdk) {
        const auto base = reinterpret_cast<uintptr_t>(newSdk);
        auto closeCustomWebView = reinterpret_cast<void(__cdecl*)()>(base + 0x3B9D0);
        closeCustomWebView();
        Log("closeCustomWebView called");
    }
    HideCefWebView();
}

bool sdkLoginHookApplied = false;

bool getUserExtraSeen = false;

void __cdecl HookSdkLogin() {
    Log("sdk login intercepted (new_sdk.login)");
    DispatchLoginEvent();
}

void TryApplySdkLoginHook() {
    if (sdkLoginHookApplied) return;
    auto newSdk = GetModuleHandleW(L"new_sdk.dll");
    if (!newSdk) return;
    sdkLoginHookApplied = true;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(newSdk, modulePath, MAX_PATH)) {
        Log("sdk login hook refused: module path unavailable");
        return;
    }
    if (HashFileSha256(modulePath) != "1CF7BF8C8B25C3C7F26F839AE8A4D32F1D3A4966ECCC826C8669C8AB5759DB0B") {
        Log("sdk login hook refused: SHA-256 mismatch");
        return;
    }
    // new_sdk.login export: mov eax, [0x1005ef54]; test eax,eax; jne ...; ... jmp 0x19060.
    // Replace the first instruction with a jump straight into HookSdkLogin so the SDK skips
    // the QR/token flow and dispatches a fabricated login result (event 2) instead.
    // NOTE: the "mov eax, moffs32" operand is a relocatable absolute address, so only the
    // 0xA1 opcode is stable in memory (the SHA-256 check above already pins the DLL version).
    constexpr uintptr_t loginRva = 0x3A850;
    auto address = reinterpret_cast<unsigned char*>(newSdk) + loginRva;
    if (address[0] != 0xA1) {
        char actual[32]{};
        for (int i = 0; i < 5; ++i) { char b[8]{}; sprintf_s(b, "%02X ", address[i]); strcat_s(actual, b); }
        Log(std::string("sdk login hook refused: opcode mismatch actual=") + actual);
        return;
    }
    const auto target = reinterpret_cast<uintptr_t>(&HookSdkLogin);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(address) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        Log("sdk login hook refused: VirtualProtect failed");
        return;
    }
    memcpy(address, jump, 5);
    VirtualProtect(address, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, 5);
    Log("sdk login hook applied: new_sdk.login -> HookSdkLogin");
}

bool loginMethodHookApplied = false;

void __cdecl HookLoginMethod() {
    Log("Login method intercepted (BabelTimeSDKManager.Login)");
    DispatchLoginEvent();
}

void TryApplyLoginMethodHook() {
    if (loginMethodHookApplied) return;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    loginMethodHookApplied = true;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(ga, modulePath, MAX_PATH)) return;
    if (HashFileSha256(modulePath) != "8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404") {
        Log("login method hook refused: SHA-256 mismatch");
        return;
    }
    // BabelTimeSDKManager.Login (static void) begins with a runtime cctor guard:
    //   cmp byte ptr [0x11d45edb], 0  ->  80 3D <disp32> 00
    // The disp32 is relocated at load, so verify only the 80 3D opcode prefix.
    constexpr uintptr_t loginMethodRva = 0x2D1870;
    auto address = reinterpret_cast<unsigned char*>(ga) + loginMethodRva;
    if (address[0] != 0x80 || address[1] != 0x3D) {
        Log("login method hook refused: opcode mismatch");
        return;
    }
    const auto target = reinterpret_cast<uintptr_t>(&HookLoginMethod);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(address) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    memcpy(address, jump, 5);
    VirtualProtect(address, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, 5);
    Log("login method hook applied: BabelTimeSDKManager.Login -> HookLoginMethod");
}

void TrySetSimulationMode() {
    if (simulationModeSet) return;
    auto newSdk = GetModuleHandleW(L"new_sdk.dll");
    if (!newSdk) return;
    const auto base = reinterpret_cast<uintptr_t>(newSdk);
    auto setSimulationInfo = reinterpret_cast<void(__cdecl*)(const char*)>(base + 0x3CE20);
    setSimulationInfo("{\"pl\":\"google_windows\",\"os\":\"android\",\"pid\":\"local-player\"}");
    const auto obj = *reinterpret_cast<uintptr_t*>(base + 0x5EF54);
    const auto isSimulation = obj ? *reinterpret_cast<unsigned char*>(obj + 0x128) : 0;
    Log("setSimulationInfo called obj=" + std::to_string(obj) +
        " isSimulation=" + std::to_string(static_cast<int>(isSimulation)));
    simulationModeSet = true;
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
    // Event 29 (kWebViewResUrlParms) is the SDK's WebView lifecycle. The first "open" is the
    // announcement/supernotice WebView; dispatch a fabricated login result (event 2) then and
    // schedule a single close so the blank CEF window does not stay on top. The close is
    // scheduled only once to avoid the SDK re-opening the WebView in a loop.
    if (eventId == 29 && payload && strstr(payload, "open") != nullptr) {
        DispatchLoginEvent();
        if (!closeScheduledOnce) {
            closeScheduledOnce = true;
            closeWebViewRequested = true;
            closeWebViewAt = GetTickCount64() + 500;
        }
    }
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
    if (b && strstr(b, "getuserextra") != nullptr) {
        getUserExtraSeen = true;
    }
    const auto result = originalCallUniversalWebFunction(a, b, c);
    Log("sdk callUniversalWebFunction result=" + std::to_string(result));
    return result;
}

uintptr_t __cdecl HookCallUniversalFunctionWithBack(const char* functionName, const char* arguments) {
    Log("sdk callUniversalFunctionWithBack fn=" + SafeStr(functionName) +
        " args=" + SafeStr(arguments));
    const auto result = originalCallUniversalFunctionWithBack(functionName, arguments);
    Log("sdk callUniversalFunctionWithBack result=" + std::to_string(result) +
        " str=" + SafeStr(reinterpret_cast<const char*>(result)));
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
        if (isNewSdk && strcmp(name, "login") == 0) {
            Log("sdk observation: GetProcAddress new_sdk login");
        }
        if (isNewSdk && strcmp(name, "getServerList") == 0) {
            Log("sdk observation: GetProcAddress new_sdk getServerList");
        }
    }
    return procedure;
}

void* pageOpenStolen = nullptr;
bool pageOpenHookApplied = false;
void* boxContentStolen = nullptr;
bool boxContentHookApplied = false;
void* openCustomWebViewStolen = nullptr;
bool openCustomWebViewHookApplied = false;
void* selectServiceStolen = nullptr;
bool selectServiceHookApplied = false;
void* netLogicConnectStolen = nullptr;
bool netLogicConnectHookApplied = false;
void* netSocketConnectStolen = nullptr;
bool netSocketConnectHookApplied = false;
void* netSocketReceivedPacketStolen = nullptr;
bool netSocketReceivedPacketHookApplied = false;
void* netSocketSendStolen = nullptr;
bool netSocketSendHookApplied = false;
void* stageGotoStolen = nullptr;
bool stageGotoHookApplied = false;
uintptr_t stageMgrInstance = 0;
bool forcedMainStage = false;
void* gameSceneChangeStolen = nullptr;
bool gameSceneChangeHookApplied = false;
void* debugLogStolen = nullptr;
bool debugLogHookApplied = false;
void* debugLogErrorStolen = nullptr;
bool debugLogErrorHookApplied = false;
void* debugLogWarningStolen = nullptr;
bool debugLogWarningHookApplied = false;
void* uiShipProxyLoadModelStolen = nullptr;
bool uiShipProxyLoadModelHookApplied = false;
void* uiShipProxyCtorStolen = nullptr;
bool uiShipProxyCtorHookApplied = false;
void* getJsonDataStolen = nullptr;
bool getJsonDataHookApplied = false;
void* getAllStolen = nullptr;
bool getAllHookApplied = false;
void* createPartStolen = nullptr;
bool createPartHookApplied = false;
void* playMusicStolen = nullptr;
bool playMusicHookApplied = false;
void* showTopPageStolen = nullptr;
bool showTopPageHookApplied = false;
void* setLuaButtonClickStolen = nullptr;
bool setLuaButtonClickHookApplied = false;
void* setOnClickLuaEventStolen = nullptr;
bool setOnClickLuaEventHookApplied = false;
void* getRedDotListStolen = nullptr;
bool getRedDotListHookApplied = false;
void* logExceptionStolen = nullptr;
bool logExceptionHookApplied = false;
void* logError2Stolen = nullptr;
bool logError2HookApplied = false;
void* logException2Stolen = nullptr;
bool logException2HookApplied = false;

void LogIl2CppString(const char* label, void* str) {
    std::string name;
    if (str) {
        MEMORY_BASIC_INFORMATION mem{};
        if (!VirtualQuery(str, &mem, sizeof(mem)) || mem.State != MEM_COMMIT ||
            (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
            name = "<unreadable>";
        } else {
            const int length = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(str) + 8);
            if (length < 0 || length > 8192) {
                name = "<bad-len:" + std::to_string(length) + ">";
            } else {
                const auto chars = reinterpret_cast<const wchar_t*>(reinterpret_cast<const char*>(str) + 12);
                for (int i = 0; i < length; ++i) {
                    const auto ch = chars[i];
                    if (ch >= 0x20 && ch < 0x7f) {
                        name.push_back(static_cast<char>(ch));
                    } else {
                        char hex[8]{};
                        sprintf_s(hex, "\\u%04X", static_cast<unsigned>(ch));
                        name += hex;
                    }
                }
            }
        }
    } else {
        name = "<null>";
    }
    Log(std::string(label) + ": " + name);
}

void LogPageOpen(void* str) { LogIl2CppString("page open", str); }
void LogBoxContent(void* str) { LogIl2CppString("box content", str); }

static std::string ReadIl2CppString(void* str) {
    if (!str) return "<null>";
    MEMORY_BASIC_INFORMATION mem{};
    if (!VirtualQuery(str, &mem, sizeof(mem)) || mem.State != MEM_COMMIT ||
        (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return "<unreadable>";
    const int length = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(str) + 8);
    if (length < 0 || length > 8192) return "<bad-len:" + std::to_string(length) + ">";
    std::string name;
    const auto chars = reinterpret_cast<const wchar_t*>(reinterpret_cast<const char*>(str) + 12);
    for (int i = 0; i < length; ++i) {
        const auto ch = chars[i];
        if (ch >= 0x20 && ch < 0x7f) name.push_back(static_cast<char>(ch));
        else { char hex[8]{}; sprintf_s(hex, "\\u%04X", static_cast<unsigned>(ch)); name += hex; }
    }
    return name;
}

void LogGetJsonData(void* self, void* tableName, void* key) {
    const auto t = ReadIl2CppString(tableName);
    if (t == "config_ship_main" || t == "config_ship_show" || t == "config_ship_model" ||
        t == "config_parameter" || t == "config_ship_info" || t == "config_fashion" ||
        t == "config_home_page" || t == "config_function_info" || t == "config_ui_config") {
        Log("GetJsonData table=" + t + " key=" + ReadIl2CppString(key));
    }
}

void LogGetAll(void* self, void* tableName) {
    const auto t = ReadIl2CppString(tableName);
    if (t == "config_ship_main" || t == "config_ship_show" || t == "config_ship_model" ||
        t == "config_parameter" || t == "config_ship_info" || t == "config_fashion" ||
        t == "config_home_page" || t == "config_function_info" || t == "config_ui_config") {
        Log("GetAll table=" + t);
    }
}

void LogCreatePart() {
    Log("CSUIHelper.CreatePart called");
}

void LogGetRedDotList(void* self) {
    Log("UILuaPage.GetRedDotList called self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}

void LogPlayMusic(void* self, void* musicId) {
    Log("SoundManager.PlayMusic " + ReadIl2CppString(musicId));
}

void LogShowTopPage(void* self, void* param) {
    Log("ShowTopPage called self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " param=" + std::to_string(reinterpret_cast<uintptr_t>(param)));
}

void LogSetLuaButtonClick(void* btn, void* func) {
    Log("SetLuaButtonClick called btn=" + std::to_string(reinterpret_cast<uintptr_t>(btn)) +
        " func=" + std::to_string(reinterpret_cast<uintptr_t>(func)));
}

void LogSetOnClickLuaEvent(void* obj_go, void* func) {
    Log("SetOnClickLuaEvent called go=" + std::to_string(reinterpret_cast<uintptr_t>(obj_go)) +
        " func=" + std::to_string(reinterpret_cast<uintptr_t>(func)));
}
void LogOpenCustomWebViewUrl(void* str) { LogIl2CppString("openCustomWebView url", str); }
void LogSelectServiceJson(void* str) { LogIl2CppString("SelectService json", str); }
void LogNetLogicConnectHost(void* str, int port) {
    LogIl2CppString("NetLogic.Connect host", str);
    Log("NetLogic.Connect port=" + std::to_string(port));
}
void LogNetSocketConnectHost(void* str) { LogIl2CppString("NetSocket.Connect host", str); }

void LogManagedByteArray(const char* label, void* arr) {
    if (!arr) { Log(std::string(label) + ": <null>"); return; }
    MEMORY_BASIC_INFORMATION mem{};
    if (!VirtualQuery(arr, &mem, sizeof(mem)) || mem.State != MEM_COMMIT ||
        (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
        Log(std::string(label) + ": <unreadable>");
        return;
    }
    const int length = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(arr) + 0xC);
    if (length < 0 || length > 4096) { Log(std::string(label) + ": <bad-len:" + std::to_string(length) + ">"); return; }
    const unsigned char* data = reinterpret_cast<const unsigned char*>(reinterpret_cast<const char*>(arr) + 0x10);
    std::string hex;
    const int preview = length < 64 ? length : 64;
    for (int i = 0; i < preview; ++i) {
        char tmp[4]{}; sprintf_s(tmp, "%02X", data[i]); hex += tmp;
    }
    Log(std::string(label) + " len=" + std::to_string(length) + " hex=" + hex);
}

void LogNetSocketSend(void* netSocket, void* msg) {
    if (netSocket) {
        const int currState = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(netSocket) + 0x8);
        Log("NetSocket.Send currState=" + std::to_string(currState));
    }
    LogManagedByteArray("NetSocket.Send msg", msg);
}

void LogStageGoto(void* self, int nextStateType) {
    Log("StageMgr.Goto nextStateType=" + std::to_string(nextStateType));
    if (nextStateType == 1) {
        stageMgrInstance = reinterpret_cast<uintptr_t>(self);
    }
}

void LogGameSceneChange(void* resPath) { LogIl2CppString("GameSceneManager.ChangeScene", resPath); }

void LogUIShipProxyLoadModel(void* self, void* tabParam) {
    Log("UIShipProxy.LoadModel called self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " tabParam=" + std::to_string(reinterpret_cast<uintptr_t>(tabParam)));
}

void LogUIShipProxyCtor(void* self) {
    Log("UIShipProxy.ctor called self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}

void LogDebugLog(void* msg) { LogIl2CppString("Unity.Log", msg); }
void LogDebugLogError(void* msg) { LogIl2CppString("Unity.LogError", msg); }
void LogDebugLogWarning(void* msg) { LogIl2CppString("Unity.LogWarning", msg); }

void LogLogException(void* exception) {
    if (!exception) {
        Log("Debug.LogException called exception=<null>");
        return;
    }
    const auto msg = ReadPtrSafe(reinterpret_cast<uintptr_t>(exception) + 0x8);
    Log("Debug.LogException called exception=" + std::to_string(reinterpret_cast<uintptr_t>(exception)) +
        " msg=" + ReadIl2CppString(reinterpret_cast<void*>(msg)));
}

void LogDebugLogError2(void* msg) { LogIl2CppString("Unity.LogError(2arg)", msg); }

void LogLogException2(void* exception) {
    if (!exception) {
        Log("Debug.LogException(2arg) called exception=<null>");
        return;
    }
    const auto msg = ReadPtrSafe(reinterpret_cast<uintptr_t>(exception) + 0x8);
    Log("Debug.LogException(2arg) called exception=" + std::to_string(reinterpret_cast<uintptr_t>(exception)) +
        " msg=" + ReadIl2CppString(reinterpret_cast<void*>(msg)));
}

typedef void(__cdecl* StageGotoFn)(void* self, int nextStateType, void* enterParam, int allowSameState);

void ForceMainStage() {
    if (!stageMgrInstance || forcedMainStage) return;
    forcedMainStage = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    const auto lastState = *reinterpret_cast<int*>(stageMgrInstance + 0x28);
    const auto nextState = *reinterpret_cast<int*>(stageMgrInstance + 0x2C);
    Log("ForceMainStage lastStateType=" + std::to_string(lastState) +
        " nextStateType=" + std::to_string(nextState));
    const auto fn = reinterpret_cast<StageGotoFn>(reinterpret_cast<uintptr_t>(ga) + 0x1ECD80);
    Log("forcing StageMgr.Goto(eStageMain=2)");
    fn(reinterpret_cast<void*>(stageMgrInstance), 2, nullptr, 0);
    const auto lastStateAfter = *reinterpret_cast<int*>(stageMgrInstance + 0x28);
    const auto nextStateAfter = *reinterpret_cast<int*>(stageMgrInstance + 0x2C);
    Log("ForceMainStage after lastStateType=" + std::to_string(lastStateAfter) +
        " nextStateType=" + std::to_string(nextStateAfter));
}

void LogNetSocketReceivedPacket(void* netSocket, int isPing, int offset, int length) {
    Log("NetSocket.ReceivedPacket isPing=" + std::to_string(isPing) +
        " offset=" + std::to_string(offset) +
        " length=" + std::to_string(length) +
        " this=" + std::to_string(reinterpret_cast<uintptr_t>(netSocket)));
    if (!netSocket) return;
    const auto recvBuf = ReadPtrSafe(reinterpret_cast<uintptr_t>(netSocket) + 0x14);
    if (!recvBuf) { Log("  recvBuf=0"); return; }
    const auto buf = ReadPtrSafe(recvBuf + 0x8);
    if (!buf) { Log("  m_Buffer=0 recvBuf=" + std::to_string(recvBuf)); return; }
    const unsigned char* data = reinterpret_cast<const unsigned char*>(buf + 0x10);
    std::string hex;
    const int preview = length < 64 ? length : 64;
    for (int i = 0; i < preview; ++i) {
        char tmp[4]{}; sprintf_s(tmp, "%02X", data[offset + i]); hex += tmp;
    }
    Log("  hex=" + hex);
}

uintptr_t ReadPtrSafe(uintptr_t addr) {
    MEMORY_BASIC_INFORMATION m{};
    if (!VirtualQuery(reinterpret_cast<void*>(addr), &m, sizeof(m)) ||
        m.State != MEM_COMMIT || (m.Protect & (PAGE_NOACCESS | PAGE_GUARD)))
        return 0;
    return *reinterpret_cast<uintptr_t*>(addr);
}

void LogReviewState(uintptr_t base) {
    // BabelTimeSDKManager static fields (TypeInfo at 0x1D2C454)
    const auto sdkTypeInfo = ReadPtrSafe(base + 0x1D2C454);
    const auto sdkStatic = sdkTypeInfo ? ReadPtrSafe(sdkTypeInfo + 0x5C) : 0;
    if (sdkStatic) {
        const auto hasResult = *reinterpret_cast<unsigned char*>(sdkStatic + 0x71);
        const auto appleReview = *reinterpret_cast<uint32_t*>(sdkStatic + 0x74);
        const auto androidReview = *reinterpret_cast<uint32_t*>(sdkStatic + 0x78);
        Log("review hasResult=" + std::to_string(hasResult) +
            " apple=" + std::to_string(appleReview) +
            " android=" + std::to_string(androidReview));
        Log("review screenW=" + std::to_string(*reinterpret_cast<uint32_t*>(sdkStatic + 0x44)) +
            " screenH=" + std::to_string(*reinterpret_cast<uint32_t*>(sdkStatic + 0x48)));
        LogIl2CppString("review deviceInfo", reinterpret_cast<void*>(ReadPtrSafe(sdkStatic + 0x50)));
    } else {
        Log("review sdkStatic=0 typeInfo=" + std::to_string(sdkTypeInfo));
    }
}

bool reviewSetDone = false;

void TrySetReview() {
    // The game's SetReview (event 19) only sets HasReceiveReviewResult, it never writes
    // AppleReview/AndroidReview (verified: set_AppleReview has zero callers). So
    // BabelTimeSDKManager.AppleReview stays REVIEW_NO_GOT(-1), which makes LoginLogic.CheckUpdate
    // take the CheckNetState/HasUpdate path and eventually pop "网络不可用". Force
    // AppleReview = IS_REVIEW(1) so CheckUpdate skips the update check and goes to getHash.
    // NOTE: the static .cctor resets these fields to -1 after the first write, so keep
    // re-asserting every loop rather than writing once.
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    const auto base = reinterpret_cast<uintptr_t>(ga);
    const auto sdkTypeInfo = ReadPtrSafe(base + 0x1D2C454);
    const auto sdkStatic = sdkTypeInfo ? ReadPtrSafe(sdkTypeInfo + 0x5C) : 0;
    if (!sdkStatic) return;
    *reinterpret_cast<uint32_t*>(sdkStatic + 0x74) = 1;
    *reinterpret_cast<uint32_t*>(sdkStatic + 0x78) = 0;
    if (!reviewSetDone) {
        reviewSetDone = true;
        Log("set review AppleReview=1 AndroidReview=0");
    }
}

void LogNetLogicState() {
    static ULONGLONG lastLog = 0;
    const auto now = GetTickCount64();
    if (now - lastLog < 5000) return;
    lastLog = now;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    const auto base = reinterpret_cast<uintptr_t>(ga);
    const auto netLogicClass = ReadPtrSafe(base + 0x1D30BC8);
    const auto staticFields = netLogicClass ? ReadPtrSafe(netLogicClass + 0x5C) : 0;
    const auto mono = staticFields ? ReadPtrSafe(staticFields + 0) : 0;
    const auto netService = mono ? ReadPtrSafe(mono + 0x14) : 0;
    const auto core = netService ? ReadPtrSafe(netService + 0x8) : 0;
    const auto socketObj = core ? ReadPtrSafe(core + 0x8) : 0;
    const auto conn = core ? ReadPtrSafe(core + 0xC) : 0;
    const auto sock = core ? ReadPtrSafe(core + 0x10) : 0;
    const auto sockField8 = socketObj ? ReadPtrSafe(socketObj + 0x8) : 0;
    const auto sockField10 = socketObj ? ReadPtrSafe(socketObj + 0x10) : 0;
    const auto sockField14 = socketObj ? ReadPtrSafe(socketObj + 0x14) : 0;
    const auto sockField20 = socketObj ? ReadPtrSafe(socketObj + 0x20) : 0;
    const auto sockField24 = socketObj ? ReadPtrSafe(socketObj + 0x24) : 0;
    Log("netlogic class=" + std::to_string(netLogicClass) +
        " mono=" + std::to_string(mono) +
        " netService=" + std::to_string(netService) +
        " core=" + std::to_string(core) +
        " socketObj=" + std::to_string(socketObj) +
        " currState=" + std::to_string(sockField8) +
        " socket=" + std::to_string(sockField10) +
        " recvBuf=" + std::to_string(sockField14) +
        " PacksLock=" + std::to_string(sockField20) +
        " Packets=" + std::to_string(sockField24) +
        " conn=" + std::to_string(conn) +
        " sock=" + std::to_string(sock));
}

void LogStrLiteral(const char* label, uintptr_t base, uintptr_t rva) {
    const auto ptr = ReadPtrSafe(base + rva);
    LogIl2CppString(label, reinterpret_cast<void*>(ptr));
    char buf[64]{};
    sprintf_s(buf, "%s raw=0x%X", label, ptr);
    Log(buf);
}

void LogHotPatchState() {
    static ULONGLONG lastLog = 0;
    const auto now = GetTickCount64();
    if (now - lastLog < 5000) return;
    lastLog = now;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    const auto base = reinterpret_cast<uintptr_t>(ga);
    const auto typeInfo = ReadPtrSafe(base + 0x1D2C61C);
    const auto staticFields = typeInfo ? ReadPtrSafe(typeInfo + 0x5C) : 0;
    const auto packageVersion = staticFields ? ReadPtrSafe(staticFields + 0x4) : 0;
    const auto patchVersion = staticFields ? ReadPtrSafe(staticFields + 0x8) : 0;
    const auto state = staticFields ? ReadPtrSafe(staticFields + 0xC) : 0;
    Log("hotpatch typeInfo=" + std::to_string(typeInfo) +
        " staticFields=" + std::to_string(staticFields) +
        " state=" + std::to_string(state));
    LogIl2CppString("hotpatch PackageVersion", reinterpret_cast<void*>(packageVersion));
    LogIl2CppString("hotpatch PatchVersion", reinterpret_cast<void*>(patchVersion));
    LogReviewState(base);
    if (staticFields) {
        const auto updateChecker = ReadPtrSafe(staticFields + 0x10);
        const auto hotPatchManager = ReadPtrSafe(staticFields + 0x1C);
        Log("hotpatch updateChecker=" + std::to_string(updateChecker) +
            " manager=" + std::to_string(hotPatchManager));
        if (updateChecker) {
            const auto ucPkg = ReadPtrSafe(updateChecker + 0xC);
            const auto ucPatch = ReadPtrSafe(updateChecker + 0x10);
            LogIl2CppString("hotpatch ucPkg", reinterpret_cast<void*>(ucPkg));
            LogIl2CppString("hotpatch ucPatch", reinterpret_cast<void*>(ucPatch));
        }
        if (hotPatchManager) {
            const auto curState = ReadPtrSafe(hotPatchManager + 0x8);
            Log("hotpatch curState=" + std::to_string(curState));
            if (curState) {
                const auto dlState = *reinterpret_cast<uint32_t*>(curState + 0x3C);
                const auto scState = *reinterpret_cast<uint32_t*>(curState + 0x24);
                Log("hotpatch dlState=" + std::to_string(dlState) +
                    " scState=" + std::to_string(scState));
                LogIl2CppString("hotpatch svVer", reinterpret_cast<void*>(ReadPtrSafe(curState + 0x10)));
                LogIl2CppString("hotpatch pkgUrl", reinterpret_cast<void*>(ReadPtrSafe(curState + 0x40)));
            }
        }
        LogStrLiteral("lit gvA", base, 0x1D3CBA4);
        LogStrLiteral("lit gvB", base, 0x1D3CBFC);
        LogStrLiteral("lit gvC", base, 0x1D3CC20);
        LogStrLiteral("lit gvD", base, 0x1D3CC5C);
        LogStrLiteral("lit gvDefField", base, 0x1D3CC88);
        LogStrLiteral("lit gvDefCmp", base, 0x1D3CC74);
        LogStrLiteral("lit gvDefErr", base, 0x1D3CCA8);
        LogStrLiteral("lit setreview0", base, 0x1D213C0);
        LogStrLiteral("lit setreview1", base, 0x1D38DDC);
        LogStrLiteral("lit hasupdate", base, 0x1D390AC);
        LogStrLiteral("lit applereview", base, 0x1D3CB80);
        LogStrLiteral("lit gvFieldC", base, 0x1D11358);
        LogStrLiteral("lit gvFieldB", base, 0x1D1133C);
        LogStrLiteral("lit errornu", base, 0x1D113B4);
        LogStrLiteral("lit gwCmp", base, 0x1D1135C);
        LogStrLiteral("lit gwF1", base, 0x1D20070);
        LogStrLiteral("lit gwF2", base, 0x1D124B0);
        LogStrLiteral("lit sliA", base, 0x1D3CADC);
        LogStrLiteral("lit sliB", base, 0x1D3CAE0);
        LogStrLiteral("lit sliC", base, 0x1D3CB08);
        LogStrLiteral("lit sliD", base, 0x1D3CB28);
    }
}

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

__declspec(naked) void OpenCustomWebViewTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogOpenCustomWebViewUrl
        add esp, 4
        popad
        jmp dword ptr [openCustomWebViewStolen]
    }
}

__declspec(naked) void SelectServiceTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogSelectServiceJson
        add esp, 4
        popad
        jmp dword ptr [selectServiceStolen]
    }
}

__declspec(naked) void NetLogicConnectTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        mov ecx, dword ptr [esp + 44]
        push ecx
        push eax
        call LogNetLogicConnectHost
        add esp, 8
        popad
        jmp dword ptr [netLogicConnectStolen]
    }
}

__declspec(naked) void NetSocketConnectTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogNetSocketConnectHost
        add esp, 4
        popad
        jmp dword ptr [netSocketConnectStolen]
    }
}

__declspec(naked) void NetSocketSendTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogNetSocketSend
        add esp, 8
        popad
        jmp dword ptr [netSocketSendStolen]
    }
}

__declspec(naked) void NetSocketReceivedPacketTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 44]
        mov ebx, dword ptr [esp + 48]
        push ebx
        push edx
        push ecx
        push eax
        call LogNetSocketReceivedPacket
        add esp, 16
        popad
        jmp dword ptr [netSocketReceivedPacketStolen]
    }
}

__declspec(naked) void StageGotoTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogStageGoto
        add esp, 8
        popad
        jmp dword ptr [stageGotoStolen]
    }
}

__declspec(naked) void GameSceneChangeTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogGameSceneChange
        add esp, 4
        popad
        jmp dword ptr [gameSceneChangeStolen]
    }
}

__declspec(naked) void UIShipProxyLoadModelTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogUIShipProxyLoadModel
        add esp, 8
        popad
        jmp dword ptr [uiShipProxyLoadModelStolen]
    }
}

__declspec(naked) void UIShipProxyCtorTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogUIShipProxyCtor
        add esp, 4
        popad
        jmp dword ptr [uiShipProxyCtorStolen]
    }
}

__declspec(naked) void GetJsonDataTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 44]
        push edx
        push ecx
        push eax
        call LogGetJsonData
        add esp, 12
        popad
        jmp dword ptr [getJsonDataStolen]
    }
}

__declspec(naked) void GetAllTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogGetAll
        add esp, 8
        popad
        jmp dword ptr [getAllStolen]
    }
}

__declspec(naked) void CreatePartTrampoline() {
    __asm {
        pushad
        call LogCreatePart
        popad
        jmp dword ptr [createPartStolen]
    }
}

__declspec(naked) void GetRedDotListTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogGetRedDotList
        add esp, 4
        popad
        jmp dword ptr [getRedDotListStolen]
    }
}

__declspec(naked) void PlayMusicTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogPlayMusic
        add esp, 8
        popad
        jmp dword ptr [playMusicStolen]
    }
}

__declspec(naked) void ShowTopPageTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogShowTopPage
        add esp, 8
        popad
        jmp dword ptr [showTopPageStolen]
    }
}

__declspec(naked) void SetLuaButtonClickTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        mov ecx, dword ptr [esp + 44]
        push ecx
        push eax
        call LogSetLuaButtonClick
        add esp, 8
        popad
        jmp dword ptr [setLuaButtonClickStolen]
    }
}

__declspec(naked) void SetOnClickLuaEventTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        mov ecx, dword ptr [esp + 44]
        push ecx
        push eax
        call LogSetOnClickLuaEvent
        add esp, 8
        popad
        jmp dword ptr [setOnClickLuaEventStolen]
    }
}

__declspec(naked) void DebugLogTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogDebugLog
        add esp, 4
        popad
        jmp dword ptr [debugLogStolen]
    }
}

__declspec(naked) void DebugLogErrorTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogDebugLogError
        add esp, 4
        popad
        jmp dword ptr [debugLogErrorStolen]
    }
}

__declspec(naked) void DebugLogWarningTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogDebugLogWarning
        add esp, 4
        popad
        jmp dword ptr [debugLogWarningStolen]
    }
}

__declspec(naked) void LogExceptionTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogLogException
        add esp, 4
        popad
        jmp dword ptr [logExceptionStolen]
    }
}

__declspec(naked) void LogError2Trampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogDebugLogError2
        add esp, 4
        popad
        jmp dword ptr [logError2Stolen]
    }
}

__declspec(naked) void LogException2Trampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]
        push eax
        call LogLogException2
        add esp, 4
        popad
        jmp dword ptr [logException2Stolen]
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

void TryApplyOpenCustomWebViewHook() {
    if (openCustomWebViewHookApplied) return;
    openCustomWebViewHookApplied = true;
    InstallStrArgHook(0x2D26C0, &OpenCustomWebViewTrampoline, &openCustomWebViewStolen, 10, "openCustomWebView");
}

void TryApplySelectServiceHook() {
    if (selectServiceHookApplied) return;
    selectServiceHookApplied = true;
    InstallStrArgHook(0x2D3780, &SelectServiceTrampoline, &selectServiceStolen, 10, "SelectService");
}

void TryApplyNetLogicConnectHook() {
    if (netLogicConnectHookApplied) return;
    netLogicConnectHookApplied = true;
    InstallStrArgHook(0x2A2770, &NetLogicConnectTrampoline, &netLogicConnectStolen, 10, "NetLogic.Connect");
}

void TryApplyNetSocketConnectHook() {
    if (netSocketConnectHookApplied) return;
    netSocketConnectHookApplied = true;
    InstallStrArgHook(0x2A4990, &NetSocketConnectTrampoline, &netSocketConnectStolen, 10, "NetSocket.Connect");
}

void TryApplyNetSocketSendHook() {
    if (netSocketSendHookApplied) return;
    netSocketSendHookApplied = true;
    InstallStrArgHook(0x2A5A00, &NetSocketSendTrampoline, &netSocketSendStolen, 10, "NetSocket.Send");
}

void TryApplyNetSocketReceivedPacketHook() {
    if (netSocketReceivedPacketHookApplied) return;
    netSocketReceivedPacketHookApplied = true;
    InstallStrArgHook(0x2A53C0, &NetSocketReceivedPacketTrampoline, &netSocketReceivedPacketStolen, 10, "NetSocket.ReceivedPacket");
}

void TryApplyStageGotoHook() {
    if (stageGotoHookApplied) return;
    stageGotoHookApplied = true;
    InstallStrArgHook(0x1ECD80, &StageGotoTrampoline, &stageGotoStolen, 11, "StageMgr.Goto");
}

void TryApplyGameSceneChangeHook() {
    if (gameSceneChangeHookApplied) return;
    gameSceneChangeHookApplied = true;
    InstallStrArgHook(0x5431C0, &GameSceneChangeTrampoline, &gameSceneChangeStolen, 11, "GameSceneManager.ChangeScene");
}

void TryApplyUIShipProxyLoadModelHook() {
    if (uiShipProxyLoadModelHookApplied) return;
    uiShipProxyLoadModelHookApplied = true;
    InstallStrArgHook(0x4F2CA0, &UIShipProxyLoadModelTrampoline, &uiShipProxyLoadModelStolen, 10, "UIShipProxy.LoadModel");
}

void TryApplyUIShipProxyCtorHook() {
    if (uiShipProxyCtorHookApplied) return;
    uiShipProxyCtorHookApplied = true;
    InstallStrArgHook(0x4F33D0, &UIShipProxyCtorTrampoline, &uiShipProxyCtorStolen, 10, "UIShipProxy.ctor");
}

void TryApplyGetJsonDataHook() {
    if (getJsonDataHookApplied) return;
    getJsonDataHookApplied = true;
    InstallStrArgHook(0x2E2C40, &GetJsonDataTrampoline, &getJsonDataStolen, 10, "SQLiteConfigManager.GetJsonData");
}

void TryApplyGetAllHook() {
    if (getAllHookApplied) return;
    getAllHookApplied = true;
    InstallStrArgHook(0x2E2740, &GetAllTrampoline, &getAllStolen, 10, "SQLiteConfigManager.GetAll");
}

void TryApplyCreatePartHook() {
    if (createPartHookApplied) return;
    createPartHookApplied = true;
    InstallStrArgHook(0x2A9E40, &CreatePartTrampoline, &createPartStolen, 10, "CSUIHelper.CreatePart");
}

void TryApplyGetRedDotListHook() {
    if (getRedDotListHookApplied) return;
    getRedDotListHookApplied = true;
    InstallStrArgHook(0x27A080, &GetRedDotListTrampoline, &getRedDotListStolen, 13, "UILuaPage.GetRedDotList");
}

void TryApplyPlayMusicHook() {
    if (playMusicHookApplied) return;
    playMusicHookApplied = true;
    InstallStrArgHook(0x3DE120, &PlayMusicTrampoline, &playMusicStolen, 10, "SoundManager.PlayMusic");
}

void TryApplyShowTopPageHook() {
    if (showTopPageHookApplied) return;
    showTopPageHookApplied = true;
    InstallStrArgHook(0x27CF40, &ShowTopPageTrampoline, &showTopPageStolen, 10, "ShowTopPage");
}

void TryApplySetLuaButtonClickHook() {
    if (setLuaButtonClickHookApplied) return;
    setLuaButtonClickHookApplied = true;
    InstallStrArgHook(0x274010, &SetLuaButtonClickTrampoline, &setLuaButtonClickStolen, 10, "SetLuaButtonClick");
}

void TryApplySetOnClickLuaEventHook() {
    if (setOnClickLuaEventHookApplied) return;
    setOnClickLuaEventHookApplied = true;
    InstallStrArgHook(0x274560, &SetOnClickLuaEventTrampoline, &setOnClickLuaEventStolen, 10, "SetOnClickLuaEvent");
}

void TryApplyDebugLogHook() {
    if (debugLogHookApplied) return;
    debugLogHookApplied = true;
    InstallStrArgHook(0xE51CF0, &DebugLogTrampoline, &debugLogStolen, 10, "Debug.Log");
}

void TryApplyDebugLogErrorHook() {
    if (debugLogErrorHookApplied) return;
    debugLogErrorHookApplied = true;
    InstallStrArgHook(0xE515F0, &DebugLogErrorTrampoline, &debugLogErrorStolen, 10, "Debug.LogError");
}

void TryApplyDebugLogWarningHook() {
    if (debugLogWarningHookApplied) return;
    debugLogWarningHookApplied = true;
    InstallStrArgHook(0xE51AE0, &DebugLogWarningTrampoline, &debugLogWarningStolen, 10, "Debug.LogWarning");
}

void TryApplyLogExceptionHook() {
    if (logExceptionHookApplied) return;
    logExceptionHookApplied = true;
    InstallStrArgHook(0xE516A0, &LogExceptionTrampoline, &logExceptionStolen, 10, "Debug.LogException");
}

void TryApplyLogError2Hook() {
    if (logError2HookApplied) return;
    logError2HookApplied = true;
    InstallStrArgHook(0xE51540, &LogError2Trampoline, &logError2Stolen, 10, "Debug.LogError(2arg)");
}

void TryApplyLogException2Hook() {
    if (logException2HookApplied) return;
    logException2HookApplied = true;
    InstallStrArgHook(0xE51750, &LogException2Trampoline, &logException2Stolen, 10, "Debug.LogException(2arg)");
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

bool onErrorPatchApplied = false;

void TryApplyOnErrorPatch() {
    if (onErrorPatchApplied) return;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(ga, modulePath, MAX_PATH)) return;
    if (HashFileSha256(modulePath) != "8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404") {
        Log("OnError patch refused: SHA-256 mismatch");
        onErrorPatchApplied = true;
        return;
    }
    // StateChecker.OnError(0x3DF200): "cmp eax,3 / jne <show-error>" -> nop the jne so
    // every SDK error type takes the RECHECK_PACKAGE_BACK branch (FinishCheck = no update).
    constexpr uintptr_t patchRva = 0x3DF22C;
    auto address = reinterpret_cast<unsigned char*>(ga) + patchRva;
    const unsigned char expected[] = { 0x75, 0x35 };
    if (memcmp(address, expected, sizeof(expected)) != 0) {
        char actual[16]{};
        for (int i = 0; i < 4; ++i) { char b[4]{}; sprintf_s(b, "%02X ", address[i]); strcat_s(actual, b); }
        Log(std::string("OnError patch refused: machine-code mismatch actual=") + actual);
        onErrorPatchApplied = true;
        return;
    }
    const unsigned char replacement[] = { 0x90, 0x90 };
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, sizeof(replacement), PAGE_EXECUTE_READWRITE, &oldProtect)) {
        Log("OnError patch refused: VirtualProtect failed");
        onErrorPatchApplied = true;
        return;
    }
    memcpy(address, replacement, sizeof(replacement));
    VirtualProtect(address, sizeof(replacement), oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, sizeof(replacement));
    onErrorPatchApplied = true;
    Log("OnError patch applied: StateChecker always FinishCheck (no update)");
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

int WSAAPI HookSend(SOCKET socket, const char* buffer, int length, int flags) {
    if (redirectEnabled) Log("udp? send bytes=" + std::to_string(length) + " caller=" + DescribeCaller(_ReturnAddress()));
    return originalSend(socket, buffer, length, flags);
}

int WSAAPI HookRecv(SOCKET socket, char* buffer, int length, int flags) {
    const auto result = originalRecv(socket, buffer, length, flags);
    if (redirectEnabled && result > 0) Log("udp? recv bytes=" + std::to_string(result) + " caller=" + DescribeCaller(_ReturnAddress()));
    return result;
}

SOCKET WSAAPI HookSocket(int af, int type, int protocol) {
    const auto result = originalSocket(af, type, protocol);
    if (redirectEnabled) Log("socket af=" + std::to_string(af) + " type=" + std::to_string(type) +
        " proto=" + std::to_string(protocol) + " result=" + std::to_string(static_cast<int>(result)) +
        " caller=" + DescribeCaller(_ReturnAddress()));
    return result;
}

int WSAAPI HookConnect(SOCKET socket, const sockaddr* address, int addressLength) {
    const auto result = originalConnect(socket, address, addressLength);
    if (redirectEnabled) Log("connect " + DescribeUdpTarget(address) + " result=" + std::to_string(result) +
        " caller=" + DescribeCaller(_ReturnAddress()));
    return result;
}

SOCKET WSAAPI HookWsaSocket(int af, int type, int protocol, void* info, unsigned int group, DWORD flags) {
    const auto result = originalWsaSocket(af, type, protocol, info, group, flags);
    if (redirectEnabled) Log("WSASocket af=" + std::to_string(af) + " type=" + std::to_string(type) +
        " proto=" + std::to_string(protocol) + " result=" + std::to_string(static_cast<int>(result)) +
        " caller=" + DescribeCaller(_ReturnAddress()));
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
                if (winsock && strcmp(name, "send") == 0) replacement = reinterpret_cast<void*>(&HookSend);
                if (winsock && strcmp(name, "recv") == 0) replacement = reinterpret_cast<void*>(&HookRecv);
                if (winsock && strcmp(name, "socket") == 0) replacement = reinterpret_cast<void*>(&HookSocket);
                if (winsock && strcmp(name, "connect") == 0) replacement = reinterpret_cast<void*>(&HookConnect);
                if (winsock && strcmp(name, "WSASocketW") == 0) replacement = reinterpret_cast<void*>(&HookWsaSocket);
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
    originalSend = reinterpret_cast<SendFn>(GetProcAddress(ws2, "send"));
    originalRecv = reinterpret_cast<RecvFn>(GetProcAddress(ws2, "recv"));
    originalSocket = reinterpret_cast<SocketFn>(GetProcAddress(ws2, "socket"));
    originalConnect = reinterpret_cast<ConnectFn>(GetProcAddress(ws2, "connect"));
    originalWsaSocket = reinterpret_cast<WsaSocketFn>(GetProcAddress(ws2, "WSASocketW"));
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
        TryApplyOpenCustomWebViewHook();
        TryApplySelectServiceHook();
        TryApplyNetLogicConnectHook();
        TryApplyNetSocketConnectHook();
        TryApplyNetSocketSendHook();
        TryApplyNetSocketReceivedPacketHook();
        TryApplyStageGotoHook();
        TryApplyGameSceneChangeHook();
        TryApplyUIShipProxyLoadModelHook();
        TryApplyUIShipProxyCtorHook();
        TryApplyGetJsonDataHook();
        TryApplyGetAllHook();
        TryApplyCreatePartHook();
        TryApplyGetRedDotListHook();
        TryApplyPlayMusicHook();
        TryApplyShowTopPageHook();
        TryApplySetLuaButtonClickHook();
        TryApplySetOnClickLuaEventHook();
        TryApplyDebugLogHook();
        TryApplyDebugLogErrorHook();
        TryApplyDebugLogWarningHook();
        TryApplyLogExceptionHook();
        TryApplyLogError2Hook();
        TryApplyLogException2Hook();
        TryApplySdkLoginHook();
        TryApplyLoginMethodHook();
        TrySetSimulationMode();
        TrySetReview();
        if (closeWebViewRequested && GetTickCount64() >= closeWebViewAt) {
            closeWebViewRequested = false;
            CloseSdkWebView();
        }
        HideCefWebView();
        LogHotPatchState();
        LogNetLogicState();
        if (getUserExtraSeen) {
            ForceMainStage();
        }
        Sleep(500);
    }
}
