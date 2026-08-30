#include "hooks.h"
#ifdef BLUEOATH_LUA_MODS
#include "lua_mod_loader.h"
#endif
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
struct CurlSlist {
    char* data;
    struct CurlSlist* next;
};
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
bool captureBugly = false;
unsigned short capturePort = 9887;
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
std::string SafeStr(const char* s);

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

bool IsBuglyReportUrl(const std::string& url) {
    // Only hijack crash-report uploads; the SDK's normal login/analytics calls must keep
    // reaching the local backend so the game can actually reach the battle (where the crash
    // happens) instead of stalling at login.
    if (url.find("bugly") != std::string::npos) return true;
    if (url.find("report") != std::string::npos) return true;
    if (url.find("upload") != std::string::npos) return true;
    if (url.find("crash") != std::string::npos) return true;
    if (url.find(".qq.com") != std::string::npos) return true;
    if (url.find("uop") != std::string::npos) return true;
    return false;
}

std::string UrlEncode(const std::string& value) {
    static constexpr char digits[] = "0123456789ABCDEF";
    std::string out;
    for (unsigned char ch : value) {
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') ||
            ch == '-' || ch == '_' || ch == '.' || ch == '~') {
            out.push_back(static_cast<char>(ch));
        } else {
            out += '%';
            out += digits[ch >> 4];
            out += digits[ch & 0xF];
        }
    }
    return out;
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
    std::string captureUrl;
    if (captureBugly && capturePort) {
        if (originalUrl.empty()) {
            char* rawUrl = nullptr;
            if (curlEasyGetInfo && curlEasyGetInfo(handle, 0x100001, &rawUrl) == 0 && rawUrl)
                originalUrl = rawUrl;
        }
        if (IsBuglyReportUrl(originalUrl)) {
            captureUrl = std::string("http://127.0.0.1:") + std::to_string(capturePort) +
                "/bugly-capture?url=" + UrlEncode(originalUrl);
            newSdkCurlEasySetOpt(handle, 10002, captureUrl.c_str());
        }
    }
    LogRedirectOnce("new_sdk curl_easy_perform hooked caller=" + DescribeCaller(_ReturnAddress()) +
        " url=" + originalUrl + " downgraded=" + (plainHttp ? "true" : "false") +
        " capture=" + (captureUrl.empty() ? "false" : "true"));
    const auto result = newSdkCurlEasyPerform(handle);
    if (!captureUrl.empty()) newSdkCurlEasySetOpt(handle, 10002, originalUrl.c_str());
    else if (plainHttp) newSdkCurlEasySetOpt(handle, 10002, originalUrl.c_str());
    return result;
}

using CurlEasySetOptVarFn = int (__cdecl*)(void*, int, ...);
CurlEasySetOptVarFn originalNewSdkCurlSetopt = nullptr;
bool newSdkCurlSetoptPatched = false;

int __cdecl HookNewSdkCurlSetopt(void* handle, int option, ...) {
    void* param = nullptr;
    va_list args;
    va_start(args, option);
    param = va_arg(args, void*);
    va_end(args);
    if (option == 10002 && param) {
        Log("new_sdk curl URL: " + SafeStr(reinterpret_cast<const char*>(param)));
    } else if (option == 10015 && param) {
        Log("new_sdk curl POSTFIELDS: " + SafeStr(reinterpret_cast<const char*>(param)));
    } else if (option == 10023 && param) {
        // CURLOPT_HTTPHEADER: curl_slist chain, log a couple of entries
        auto node = reinterpret_cast<const struct CurlSlist*>(param);
        for (int i = 0; i < 12 && node; ++i, node = node->next) {
            if (node->data) Log("new_sdk curl HEADER: " + SafeStr(node->data));
        }
    }
    if (originalNewSdkCurlSetopt)
        return originalNewSdkCurlSetopt(handle, option, param);
    return -1;
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

bool PatchModuleImportSlot(const wchar_t* moduleName, const char* dllName, const char* functionName,
    void* hook, void** originalOut, const std::string& logName) {
    auto module = GetModuleHandleW(moduleName);
    if (!module) return false;
    auto base = reinterpret_cast<unsigned char*>(module);
    auto dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return false;
    auto nt = reinterpret_cast<IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) return false;
    const auto directory = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!directory.VirtualAddress) return false;
    for (auto descriptor = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(base + directory.VirtualAddress);
         descriptor->Name; ++descriptor) {
        const char* library = reinterpret_cast<const char*>(base + descriptor->Name);
        if (_stricmp(library, dllName) != 0) continue;
        auto names = descriptor->OriginalFirstThunk
            ? reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->OriginalFirstThunk)
            : reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
        auto slots = reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
        for (; names->u1.AddressOfData; ++names, ++slots) {
            if (IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal)) continue;
            auto import = reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(base + names->u1.AddressOfData);
            if (strcmp(reinterpret_cast<const char*>(import->Name), functionName) != 0) continue;
            if (originalOut) *originalOut = reinterpret_cast<void*>(slots->u1.Function);
            DWORD oldProtect = 0;
            if (!VirtualProtect(&slots->u1.Function, sizeof(void*), PAGE_READWRITE, &oldProtect)) {
                Log(logName + " IAT patch refused: VirtualProtect failed");
                return false;
            }
            slots->u1.Function = reinterpret_cast<ULONG_PTR>(hook);
            VirtualProtect(&slots->u1.Function, sizeof(void*), oldProtect, &oldProtect);
            FlushInstructionCache(GetCurrentProcess(), &slots->u1.Function, sizeof(void*));
            Log(logName + " IAT patch applied: " + functionName);
            return true;
        }
    }
    Log(logName + " IAT patch refused: import not found (" + functionName + ")");
    return false;
}

std::string WideToString(const wchar_t* text, int maxChars = 160) {
    if (!text) return "<null>";
    std::string out;
    for (int i = 0; i < maxChars; ++i) {
        MEMORY_BASIC_INFORMATION m{};
        const auto addr = reinterpret_cast<unsigned char*>(const_cast<wchar_t*>(text)) + i * 2;
        if (!VirtualQuery(addr, &m, sizeof(m)) || m.State != MEM_COMMIT ||
            (m.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
            out += "<badptr>";
            return out;
        }
        if (m.Protect & PAGE_READONLY || m.Protect & PAGE_READWRITE || m.Protect & PAGE_EXECUTE_READ ||
            m.Protect & PAGE_EXECUTE_READWRITE || m.Protect & PAGE_WRITECOPY ||
            m.Protect & PAGE_EXECUTE_WRITECOPY) {
            wchar_t ch = text[i];
            if (!ch) return out;
            char buf[8]{};
            WideCharToMultiByte(CP_UTF8, 0, &ch, 1, buf, sizeof(buf), nullptr, nullptr);
            for (char c : buf) if (c) out.push_back(c);
        } else {
            out += "<noperm>";
            return out;
        }
    }
    return out;
}

using VsnwprintfSFn = int (__cdecl*)(unsigned __int64, void*, size_t, size_t, const wchar_t*, void*, void*);
VsnwprintfSFn originalNewSdkVsnwprintfS = nullptr;
bool newSdkVsnwprintfSPatched = false;

int __cdecl HookNewSdkVsnwprintfS(unsigned __int64 options, void* buffer, size_t bufferCount,
    size_t maxCount, const wchar_t* format, void* locale, void* argList) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk vsnwprintf_s caller=" << DescribeCaller(_ReturnAddress())
        << " buf=" << std::hex << reinterpret_cast<uintptr_t>(buffer) << std::dec
        << " count=" << bufferCount << " max=" << maxCount
        << " fmt=\"" << WideToString(format) << "\"" << '\n';
    output.flush();
    return originalNewSdkVsnwprintfS(options, buffer, bufferCount, maxCount, format, locale, argList);
}

using VswprintfSFn = int (__cdecl*)(unsigned __int64, void*, size_t, const wchar_t*, void*, void*);
VswprintfSFn originalNewSdkVswprintfS = nullptr;
bool newSdkVswprintfSPatched = false;

int __cdecl HookNewSdkVswprintfS(unsigned __int64 options, void* buffer, size_t bufferCount,
    const wchar_t* format, void* locale, void* argList) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk vswprintf_s caller=" << DescribeCaller(_ReturnAddress())
        << " buf=" << std::hex << reinterpret_cast<uintptr_t>(buffer) << std::dec
        << " count=" << bufferCount
        << " fmt=\"" << WideToString(format) << "\"" << '\n';
    output.flush();
    if (originalNewSdkVswprintfS)
        return originalNewSdkVswprintfS(options, buffer, bufferCount, format, locale, argList);
    return -1;
}

bool newSdkReportFormatPatched = false;

void TryPatchNewSdkReportFormat() {
    if (newSdkReportFormatPatched || !captureBugly) return;
    auto newSdk = GetModuleHandleW(L"new_sdk.dll");
    if (!newSdk) return;
    newSdkReportFormatPatched = true;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(newSdk, modulePath, MAX_PATH)) return;
    if (HashFileSha256(modulePath) != "1CF7BF8C8B25C3C7F26F839AE8A4D32F1D3A4966ECCC826C8669C8AB5759DB0B") {
        Log("new_sdk report-format patch refused: SHA-256 mismatch");
        return;
    }
    // RVA 0x537D0 is the literal format string "%" (a lone trailing '%' is an invalid
    // format specifier under the modern UCRT and fail-fasts via _invalid_parameter_noinfo,
    // even though the old MSVC CRT new_sdk was built against printed it literally).
    // Replace the single '%' byte with NUL so the format becomes the empty string and
    // _vsnwprintf_s succeeds, letting the bugly crash-report flow continue to the upload.
    auto address = reinterpret_cast<unsigned char*>(newSdk) + 0x537D0;
    if (*address != '%') {
        Log("new_sdk report-format patch refused: unexpected byte " + std::to_string(*address));
        return;
    }
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, 1, PAGE_READWRITE, &oldProtect)) return;
    *address = 0;
    VirtualProtect(address, 1, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, 1);
    Log("new_sdk report-format patched: trailing-%% format neutralized");
}

using ExitFn = void (__cdecl*)(int);
ExitFn originalNewSdkExit = nullptr;
bool newSdkExitPatched = false;

void __cdecl HookNewSdkExit(int code) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk exit(" << code << ") intercepted caller=" << DescribeCaller(_ReturnAddress()) << '\n';
    output.flush();
    if (originalNewSdkExit) originalNewSdkExit(code);
}

void* newSdkReportCtorStolen = nullptr;
bool newSdkReportCtorHookApplied = false;

void LogNewSdkReportCtor(void* a1, void* a2, void* a3, void* a4, void* a5) {
    const auto p1 = reinterpret_cast<uintptr_t>(a1);
    const auto p2 = reinterpret_cast<uintptr_t>(a2);
    const auto p3 = reinterpret_cast<uintptr_t>(a3);
    const auto p4 = reinterpret_cast<uintptr_t>(a4);
    const auto p5 = reinterpret_cast<uintptr_t>(a5);
    std::string s1 = SafeStr(reinterpret_cast<const char*>(a1));
    std::string s2 = SafeStr(reinterpret_cast<const char*>(a2));
    std::string s3 = SafeStr(reinterpret_cast<const char*>(a3));
    std::string s4 = SafeStr(reinterpret_cast<const char*>(a4));
    std::string s5 = SafeStr(reinterpret_cast<const char*>(a5));
    if (s1 == "<null>") s1 = SafeStr(reinterpret_cast<const char*>(a1) + 4);
    if (s2 == "<null>") s2 = SafeStr(reinterpret_cast<const char*>(a2) + 4);
    if (s4 == "<null>") s4 = SafeStr(reinterpret_cast<const char*>(a4) + 4);
    if (s5 == "<null>") s5 = SafeStr(reinterpret_cast<const char*>(a5) + 4);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk report(a1=0x" << std::hex << p1 << std::dec << "[" << s1 << "]"
        << " a2=0x" << std::hex << p2 << std::dec << "[" << s2 << "]"
        << " a3=0x" << std::hex << p3 << std::dec << "[" << s3 << "]"
        << " a4=0x" << std::hex << p4 << std::dec << "[" << s4 << "]"
        << " a5=0x" << std::hex << p5 << std::dec << "[" << s5 << "])" << '\n';
    output.flush();
}

__declspec(naked) void NewSdkReportCtorTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 52]   // arg5
        push eax
        mov ecx, dword ptr [esp + 52]   // arg4
        push ecx
        mov edx, dword ptr [esp + 52]   // arg3
        push edx
        mov eax, dword ptr [esp + 52]   // arg2
        push eax
        mov ecx, dword ptr [esp + 52]   // arg1
        push ecx
        call LogNewSdkReportCtor
        add esp, 20
        popad
        jmp dword ptr [newSdkReportCtorStolen]
    }
}

bool InstallNewSdkRvaHook(uintptr_t rva, void* trampoline, void** stolenOut, size_t stolenLen, const char* name) {
    auto sdk = GetModuleHandleW(L"new_sdk.dll");
    if (!sdk) return false;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(sdk, modulePath, MAX_PATH)) return false;
    if (HashFileSha256(modulePath) != "1CF7BF8C8B25C3C7F26F839AE8A4D32F1D3A4966ECCC826C8669C8AB5759DB0B") {
        Log(std::string(name) + " hook refused: SHA-256 mismatch");
        return false;
    }
    auto address = reinterpret_cast<unsigned char*>(sdk) + rva;
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

void TryApplyNewSdkReportCtorHook() {
    if (newSdkReportCtorHookApplied) return;
    newSdkReportCtorHookApplied = true;
    auto sdk = GetModuleHandleW(L"new_sdk.dll");
    if (!sdk) return;
    // Bugly's crash finalizer 0x468FF ends by terminating the process. Making its ENTRY a
    // bare `ret` turns the whole finalizer into a no-op (no report, no exit), so when bugly's
    // crash-handler races the battle init, the game survives instead of being killed.
    auto address = reinterpret_cast<unsigned char*>(sdk) + 0x468FF;
    if (*address != 0x55) {
        Log("new_sdk finalizer patch refused: unexpected byte " + std::to_string(*address));
        return;
    }
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, 1, PAGE_READWRITE, &oldProtect)) return;
    *address = 0xC3;
    VirtualProtect(address, 1, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, 1);
    Log("new_sdk finalizer patched to ret (no-op)");
}

void* WINAPI HookNewSdkSetUnhandledExceptionFilter(void* handler) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk SetUnhandledExceptionFilter suppressed (handler=0x"
        << std::hex << reinterpret_cast<uintptr_t>(handler) << std::dec << ")" << '\n';
    output.flush();
    return nullptr;
}

using AddVectoredExceptionHandlerFn = void* (WINAPI*)(unsigned long, void*);
AddVectoredExceptionHandlerFn originalNewSdkAddVeh = nullptr;
bool newSdkSetUefPatched = false;
bool newSdkAddVehPatched = false;

void* WINAPI HookNewSdkAddVectoredExceptionHandler(unsigned long first, void* handler) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk AddVectoredExceptionHandler suppressed (first=" << first
        << " handler=0x" << std::hex << reinterpret_cast<uintptr_t>(handler) << std::dec << ")" << '\n';
    output.flush();
    return nullptr;
}

using InvalidParameterHandlerFn = void (__cdecl*)(const wchar_t*, const wchar_t*, const wchar_t*, unsigned, uintptr_t);
using SetInvalidParameterHandlerFn = InvalidParameterHandlerFn (__cdecl*)(InvalidParameterHandlerFn);
SetInvalidParameterHandlerFn originalSetInvalidParameterHandler = nullptr;
bool newSdkInvalidParamPatched = false;
void* newSdkRegisteredInvalidHandler = nullptr;

void __cdecl NoopInvalidParameterHandler(const wchar_t*, const wchar_t*, const wchar_t*, unsigned, uintptr_t) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "invalid_parameter suppressed by no-op handler" << '\n';
    output.flush();
}

InvalidParameterHandlerFn __cdecl HookSetInvalidParameterHandler(InvalidParameterHandlerFn handler) {
    newSdkRegisteredInvalidHandler = reinterpret_cast<void*>(handler);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "new_sdk set_invalid_parameter_handler intercepted (handler="
        << std::hex << reinterpret_cast<uintptr_t>(handler) << std::dec
        << ") -> registering no-op instead" << '\n';
    output.flush();
    if (originalSetInvalidParameterHandler)
        return originalSetInvalidParameterHandler(reinterpret_cast<InvalidParameterHandlerFn>(&NoopInvalidParameterHandler));
    return nullptr;
}

void TryApplyNewSdkReportHooks() {
    if (newSdkVswprintfSPatched && newSdkInvalidParamPatched && newSdkVsnwprintfSPatched &&
        newSdkCurlSetoptPatched && newSdkExitPatched) return;
    if (!GetModuleHandleW(L"new_sdk.dll")) return;
    if (!newSdkExitPatched) {
        newSdkExitPatched = PatchModuleImportSlot(L"new_sdk.dll", "api-ms-win-crt-runtime-l1-1-0.dll",
            "exit", reinterpret_cast<void*>(&HookNewSdkExit),
            reinterpret_cast<void**>(&originalNewSdkExit), "new_sdk exit");
    }
    if (!newSdkCurlSetoptPatched) {
        newSdkCurlSetoptPatched = PatchModuleImportSlot(L"new_sdk.dll", "libcurl.dll",
            "curl_easy_setopt", reinterpret_cast<void*>(&HookNewSdkCurlSetopt),
            reinterpret_cast<void**>(&originalNewSdkCurlSetopt), "new_sdk curl setopt");
    }
    if (!newSdkVswprintfSPatched) {
        newSdkVswprintfSPatched = PatchModuleImportSlot(L"new_sdk.dll",
            "api-ms-win-crt-stdio-l1-1-0.dll", "__stdio_common_vswprintf_s",
            reinterpret_cast<void*>(&HookNewSdkVswprintfS),
            reinterpret_cast<void**>(&originalNewSdkVswprintfS), "new_sdk vswprintf_s");
    }
    if (!newSdkVsnwprintfSPatched) {
        newSdkVsnwprintfSPatched = PatchModuleImportSlot(L"new_sdk.dll",
            "api-ms-win-crt-stdio-l1-1-0.dll", "__stdio_common_vsnwprintf_s",
            reinterpret_cast<void*>(&HookNewSdkVsnwprintfS),
            reinterpret_cast<void**>(&originalNewSdkVsnwprintfS), "new_sdk vsnwprintf_s");
    }
    if (!newSdkInvalidParamPatched) {
        newSdkInvalidParamPatched = PatchModuleImportSlot(L"new_sdk.dll",
            "api-ms-win-crt-runtime-l1-1-0.dll", "_set_invalid_parameter_handler",
            reinterpret_cast<void*>(&HookSetInvalidParameterHandler),
            reinterpret_cast<void**>(&originalSetInvalidParameterHandler), "new_sdk invalid-param");
    }
    TryPatchNewSdkReportFormat();
    TryApplyNewSdkReportCtorHook();
    if (!newSdkSetUefPatched) {
        newSdkSetUefPatched = PatchModuleImportSlot(L"new_sdk.dll", "KERNEL32.dll",
            "SetUnhandledExceptionFilter", reinterpret_cast<void*>(&HookNewSdkSetUnhandledExceptionFilter),
            nullptr, "new_sdk SetUnhandledExceptionFilter");
    }
    if (!newSdkAddVehPatched) {
        newSdkAddVehPatched = PatchModuleImportSlot(L"new_sdk.dll", "KERNEL32.dll",
            "AddVectoredExceptionHandler", reinterpret_cast<void*>(&HookNewSdkAddVectoredExceptionHandler),
            reinterpret_cast<void**>(&originalNewSdkAddVeh), "new_sdk AddVectoredExceptionHandler");
    }
}

bool simulationModeSet = false;

bool loginFallbackStarted = false;
const ULONGLONG loginFallbackStart = GetTickCount64() + 30000;
const ULONGLONG loginFallbackDelay = 30000;

bool IsGameNetworkConnected() {
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return false;
    const auto base = reinterpret_cast<uintptr_t>(ga);
    const auto netLogicClass = ReadPtrSafe(base + 0x1D30BC8);
    const auto staticFields = netLogicClass ? ReadPtrSafe(netLogicClass + 0x5C) : 0;
    const auto mono = staticFields ? ReadPtrSafe(staticFields + 0) : 0;
    const auto netService = mono ? ReadPtrSafe(mono + 0x14) : 0;
    const auto core = netService ? ReadPtrSafe(netService + 0x8) : 0;
    const auto socketObj = core ? ReadPtrSafe(core + 0x8) : 0;
    const auto sockField8 = socketObj ? ReadPtrSafe(socketObj + 0x8) : 0;
    return sockField8 == 2;
}

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
int closeWebViewAttemptCount = 0;
constexpr int MaxLoginWebViewCloseAttempts = 3;
bool loginWebViewSuppressionEnabled = true;

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
uint64_t getUserExtraSeenAt = 0;

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
    // schedule a bounded number of closes so a follow-up SDK WebView cannot leave the
    // client stuck at the title screen. The bound still prevents an SDK reopen loop.
    if (loginWebViewSuppressionEnabled && eventId == 29 && payload &&
        strstr(payload, "open") != nullptr) {
        DispatchLoginEvent();
        if (!closeWebViewRequested && closeWebViewAttemptCount < MaxLoginWebViewCloseAttempts) {
            ++closeWebViewAttemptCount;
            closeWebViewRequested = true;
            closeWebViewAt = GetTickCount64() + 500;
            Log("scheduled login WebView close attempt=" +
                std::to_string(closeWebViewAttemptCount));
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
        getUserExtraSeenAt = GetTickCount64();
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
// ---- ��������StageMgr.Goto ����¼ʵ����ForceMainStage �����������ٴ�ӡϸ�� ----
bool InstallStrArgHook(uintptr_t rva, void* trampoline, void** stolenOut, size_t stolenLen, const char* name);

void* stageGotoStolen = nullptr;
bool stageGotoHookApplied = false;
uintptr_t stageMgrInstance = 0;
bool forcedMainStage = false;

uintptr_t ReadPtrSafe(uintptr_t addr) {
    MEMORY_BASIC_INFORMATION m{};
    if (!VirtualQuery(reinterpret_cast<void*>(addr), &m, sizeof(m)) ||
        m.State != MEM_COMMIT || (m.Protect & (PAGE_NOACCESS | PAGE_GUARD)))
        return 0;
    return *reinterpret_cast<uintptr_t*>(addr);
}

static std::string ReadIl2CppString(void* str) {
    if (!str) return "<null>";
    MEMORY_BASIC_INFORMATION mem{};
    if (!VirtualQuery(str, &mem, sizeof(mem)) || mem.State != MEM_COMMIT ||
        (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return "<unreadable>";
    const int length = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(str) + 8);
    if (length < 0 || length > 8192) return "<bad-len:" + std::to_string(length) + ">";
    const auto charsAddr = reinterpret_cast<uintptr_t>(str) + 12;
    const auto regionEnd = reinterpret_cast<uintptr_t>(mem.BaseAddress) + mem.RegionSize;
    std::string name;
    const auto chars = reinterpret_cast<const wchar_t*>(charsAddr);
    for (int i = 0; i < length; ++i) {
        if (charsAddr + static_cast<size_t>(i) * 2 + 2 > regionEnd) break;
        const auto ch = chars[i];
        if (ch >= 0x20 && ch < 0x7f) name.push_back(static_cast<char>(ch));
        else { char hex[8]{}; sprintf_s(hex, "\\u%04X", static_cast<unsigned>(ch)); name += hex; }
    }
    return name;
}

std::string ReadAsciiCStr(uintptr_t addr) {
    if (!addr) return "<null>";
    MEMORY_BASIC_INFORMATION mem{};
    if (!VirtualQuery(reinterpret_cast<void*>(addr), &mem, sizeof(mem)) ||
        mem.State != MEM_COMMIT || (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return "<unreadable>";
    const auto regionEnd = reinterpret_cast<uintptr_t>(mem.BaseAddress) + mem.RegionSize;
    char buf[160]{};
    for (int i = 0; i < 159; i++) {
        if (addr + static_cast<size_t>(i) + 1 > regionEnd) break;
        const unsigned char c = *reinterpret_cast<unsigned char*>(addr + i);
        if (c == 0) break;
        buf[i] = (c >= 0x20 && c < 0x7f) ? static_cast<char>(c) : '?';
    }
    return buf;
}

std::string ReadWideCStr(uintptr_t addr) {
    if (!addr) return {};
    MEMORY_BASIC_INFORMATION mem{};
    if (!VirtualQuery(reinterpret_cast<void*>(addr), &mem, sizeof(mem)) ||
        mem.State != MEM_COMMIT || (mem.Protect & (PAGE_NOACCESS | PAGE_GUARD))) return {};
    wchar_t buf[200]{};
    for (int i = 0; i < 199; i++) {
        const wchar_t c = *reinterpret_cast<const wchar_t*>(addr + i * 2);
        if (c == 0) break;
        buf[i] = (c >= 0x20 && c < 0x7f) ? c : L'?';
    }
    char out[400]{};
    WideCharToMultiByte(CP_UTF8, 0, buf, -1, out, sizeof(out), nullptr, nullptr);
    return out;
}

static volatile bool gBattleStarted = false;

// ---- ͨ���ַ�����ȡ��������������ջ��ԭ�ã� ----

void LogStageGoto(void* self, int nextStateType, void* enterParam) {
    if (nextStateType == 1) stageMgrInstance = reinterpret_cast<uintptr_t>(self);
}

__declspec(naked) void StageGotoTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 44]
        push edx
        push ecx
        push eax
        call LogStageGoto
        add esp, 12
        popad
        jmp dword ptr [stageGotoStolen]
    }
}

void TryApplyStageGotoHook() {
    if (stageGotoHookApplied) return;
    stageGotoHookApplied = true;
    InstallStrArgHook(0x1ECD80, &StageGotoTrampoline, &stageGotoStolen, 11, "StageMgr.Goto");
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

bool reviewSetDone = false;
void TrySetReview() {
    // The game's SetReview (event 19) only sets HasReceiveReviewResult, it never writes
    // AppleReview/AndroidReview (verified: set_AppleReview has zero callers). So
    // BabelTimeSDKManager.AppleReview stays REVIEW_NO_GOT(-1), which makes LoginLogic.CheckUpdate
    // take the CheckNetState/HasUpdate path and eventually pop "网络不可�?. Force
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
template <typename Fn>
bool InstallReturnHook(uintptr_t rva, void* hookFn, Fn* originalOut, size_t stolenLen, const char* name);
using DamageFacReadFn = double (__cdecl*)(void*);
DamageFacReadFn originalDamageFacRead = nullptr;
bool damageFacReadHookApplied = false;
double __cdecl HookDamageFacRead(void* obj) {
    return 1.0;
}
void TryApplyDamageFacHook() {
    if (damageFacReadHookApplied) return;
    damageFacReadHookApplied = true;
    // prologue: 55 8B EC 8B 45 0C = push ebp(1) mov ebp,esp(2) mov eax,[ebp+0xc](3) = 6
    InstallReturnHook(0x52F5A0, &HookDamageFacRead, &originalDamageFacRead, 6, "DamageFacRead");
}

// ---------------------------------------------------------------------------
// MISSING-ENEMIES NRE fix: PVEStartData ctor at 0x58F304 reads
//   mov eax, [eax+0x14]   ; EnemyFleet.attachedFleets
//   test eax, eax; je NRE
// EnemyFleet.ConverPB (0x577150) only initializes +0x10 (ships), leaving
// +0x14 (attachedFleets) null. With an empty copy_attacheds (normal for most
// story stages) attachedFleets stays null -> NullReferenceException -> battle
// load hangs. Fix: on null, jump to the "skip attached" path 0x58F3DC instead
// of the NRE raise.
// ---------------------------------------------------------------------------
bool attachedFleetsFixApplied = false;

void TryApplyAttachedFleetsFix() {
    if (attachedFleetsFixApplied) return;
    attachedFleetsFixApplied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    const auto base = reinterpret_cast<uintptr_t>(ga);
    // 0x58F306: `0F 84 52 06 00 00` (je NRE at 0x58F95E). Rewrite to `E9 <rel to 0x58F3DC>` + nop.
    auto address = reinterpret_cast<unsigned char*>(base + 0x58F306);
    if (address[0] != 0x0F || address[1] != 0x84) {
        char act[16]{};
        for (int i = 0; i < 6; ++i) { char b[4]{}; sprintf_s(b, "%02X ", address[i]); strcat_s(act, b); }
        Log(std::string("attachedFleets fix refused: opcode mismatch actual=") + act);
        return;
    }
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, 6, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    address[0] = 0xE9;
    *reinterpret_cast<int32_t*>(address + 1) = static_cast<int32_t>(
        (base + 0x58F3DC) - (base + 0x58F306 + 5));
    address[5] = 0x90;
    VirtualProtect(address, 6, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, 6);
    Log("attachedFleets null NRE fix applied @0x58F306");
}

// xLua Lua 5.3 bridge used to patch ShowGirlPage after its Lua chunk loads.
// The shipped Lua bundles are compiled assets, so changing the decompiled
// reference source alone would not affect the running client.
typedef void* LuaStateRaw;
typedef int(__cdecl* lua_getglobal_t)(LuaStateRaw, const char*);
typedef int(__cdecl* lua_getfield_t)(LuaStateRaw, int, const char*);
typedef void(__cdecl* lua_setfield_t)(LuaStateRaw, int, const char*);
typedef void(__cdecl* lua_settop_t)(LuaStateRaw, int);
typedef int(__cdecl* lua_type_t)(LuaStateRaw, int);
typedef int(__cdecl* lua_gettop_t)(LuaStateRaw);
typedef void(__cdecl* lua_pushvalue_t)(LuaStateRaw, int);
typedef void(__cdecl* lua_pushcclosure_t)(LuaStateRaw, int(__cdecl*)(LuaStateRaw), int);
typedef void(__cdecl* lua_pushboolean_t)(LuaStateRaw, int);
typedef int(__cdecl* lua_toboolean_t)(LuaStateRaw, int);
typedef int(__cdecl* lua_pcallk_t)(LuaStateRaw, int, int, int, intptr_t, void*);

constexpr int LuaTypeNil = 0;
constexpr int LuaTypeTable = 5;
constexpr int LuaTypeFunction = 6;
constexpr int LuaFirstUpvalueIndex = -1001001;

void* luaPcallKStolen = nullptr;
bool luaPcallKHookApplied = false;
bool showGirlLockPatchApplied = false;
bool showGirlNewStatePatchApplied = false;
bool buildShipNewStatePatchApplied = false;
bool pendingBuildShipNewValid = false;
bool pendingBuildShipIsNew = false;
int luaPcallKResult = 0;
uintptr_t luaPcallKLState = 0;
lua_getglobal_t showGirlGetGlobal = nullptr;
lua_getfield_t showGirlGetField = nullptr;
lua_setfield_t showGirlSetField = nullptr;
lua_settop_t showGirlSetTop = nullptr;
lua_type_t showGirlType = nullptr;
lua_gettop_t showGirlGetTop = nullptr;
lua_pushvalue_t showGirlPushValue = nullptr;
lua_pushcclosure_t showGirlPushCClosure = nullptr;
lua_pushboolean_t showGirlPushBoolean = nullptr;
lua_toboolean_t showGirlToBoolean = nullptr;
lua_pcallk_t showGirlOriginalPcallK = nullptr;

static int ShowGirlOnClickBackPatched(LuaStateRaw L) {
    if (!L || !showGirlGetField || !showGirlSetTop || !showGirlType ||
        !showGirlGetTop || !showGirlPushValue || !showGirlToBoolean ||
        !showGirlOriginalPcallK) {
        return 0;
    }

    const int argumentCount = showGirlGetTop(L);
    if (argumentCount < 1) return 0;

    showGirlGetField(L, 1, "heroId");
    const bool hasHero = showGirlType(L, -1) != LuaTypeNil;
    showGirlSetTop(L, argumentCount);
    showGirlGetField(L, 1, "bNew");
    const bool isNew = showGirlToBoolean(L, -1) != 0;
    showGirlSetTop(L, argumentCount);

    if (hasHero && !isNew) {
        showGirlGetField(L, 1, "_ClickClose");
        if (showGirlType(L, -1) == LuaTypeFunction) {
            showGirlPushValue(L, 1);
            const int status = showGirlOriginalPcallK(L, 1, 0, 0, 0, nullptr);
            if (status != 0) {
                Log("ShowGirlPage _ClickClose failed status=" + std::to_string(status));
                showGirlSetTop(L, argumentCount);
            }
            return 0;
        }
        showGirlSetTop(L, argumentCount);
    }

    showGirlPushValue(L, LuaFirstUpvalueIndex);
    for (int i = 1; i <= argumentCount; ++i) showGirlPushValue(L, i);
    const int status = showGirlOriginalPcallK(L, argumentCount, 0, 0, 0, nullptr);
    if (status != 0) {
        Log("ShowGirlPage original OnClickBack failed status=" + std::to_string(status));
        showGirlSetTop(L, argumentCount);
    }
    return 0;
}

static int BuildShipCheckShowMeetPatched(LuaStateRaw L) {
    if (!L || !showGirlGetTop || !showGirlPushValue || !showGirlToBoolean ||
        !showGirlSetTop || !showGirlOriginalPcallK) {
        return 0;
    }
    const int argumentCount = showGirlGetTop(L);
    showGirlPushValue(L, LuaFirstUpvalueIndex);
    for (int i = 1; i <= argumentCount; ++i) showGirlPushValue(L, i);
    const int status = showGirlOriginalPcallK(L, argumentCount, -1, 0, 0, nullptr);
    if (status != 0) {
        Log("BuildShipLogic CheckShowMeet failed status=" + std::to_string(status));
        showGirlSetTop(L, argumentCount);
        return 0;
    }
    const int resultCount = showGirlGetTop(L) - argumentCount;
    if (resultCount > 0) {
        pendingBuildShipIsNew = showGirlToBoolean(L, argumentCount + 1) != 0;
        pendingBuildShipNewValid = true;
    }
    return resultCount;
}

static int ShowGirlUpdatePagePatched(LuaStateRaw L) {
    if (!L || !showGirlGetField || !showGirlSetField || !showGirlSetTop ||
        !showGirlType || !showGirlGetTop || !showGirlPushValue ||
        !showGirlPushBoolean || !showGirlOriginalPcallK) {
        return 0;
    }
    const int argumentCount = showGirlGetTop(L);
    if (argumentCount < 1) return 0;

    bool isBuildResultPage = false;
    showGirlGetField(L, 1, "param");
    if (showGirlType(L, -1) == LuaTypeTable) {
        const int paramIndex = showGirlGetTop(L);
        showGirlGetField(L, paramIndex, "buildNum");
        const bool hasBuildNum = showGirlType(L, -1) != LuaTypeNil;
        showGirlSetTop(L, paramIndex);
        showGirlGetField(L, paramIndex, "getWay");
        const bool hasGetWay = showGirlType(L, -1) != LuaTypeNil;
        isBuildResultPage = hasBuildNum && !hasGetWay;
    }
    showGirlSetTop(L, argumentCount);

    const bool useBuildNewState = pendingBuildShipNewValid && isBuildResultPage;
    const bool isNew = pendingBuildShipIsNew;
    if (useBuildNewState) pendingBuildShipNewValid = false;
    showGirlPushBoolean(L, useBuildNewState ? 1 : 0);
    showGirlSetField(L, 1, "__blueOathBuildNewValid");
    if (useBuildNewState) {
        showGirlPushBoolean(L, isNew ? 1 : 0);
        showGirlSetField(L, 1, "__blueOathBuildIsNew");
    }

    showGirlPushValue(L, LuaFirstUpvalueIndex);
    for (int i = 1; i <= argumentCount; ++i) showGirlPushValue(L, i);
    const int status = showGirlOriginalPcallK(L, argumentCount, -1, 0, 0, nullptr);
    if (status != 0) {
        Log("ShowGirlPage _UpdatePage failed status=" + std::to_string(status));
        showGirlSetTop(L, argumentCount);
        return 0;
    }
    const int resultCount = showGirlGetTop(L) - argumentCount;
    if (useBuildNewState) {
        showGirlPushBoolean(L, isNew ? 1 : 0);
        showGirlSetField(L, 1, "bNew");
    }
    return resultCount;
}

static int ShowGirlSetGirlImagePatched(LuaStateRaw L) {
    if (!L || !showGirlGetField || !showGirlSetField || !showGirlSetTop ||
        !showGirlGetTop || !showGirlPushValue || !showGirlPushBoolean ||
        !showGirlToBoolean || !showGirlOriginalPcallK) {
        return 0;
    }
    const int argumentCount = showGirlGetTop(L);
    if (argumentCount < 1) return 0;
    showGirlGetField(L, 1, "__blueOathBuildNewValid");
    const bool useBuildNewState = showGirlToBoolean(L, -1) != 0;
    showGirlSetTop(L, argumentCount);
    if (useBuildNewState) {
        showGirlGetField(L, 1, "__blueOathBuildIsNew");
        const bool isNew = showGirlToBoolean(L, -1) != 0;
        showGirlSetTop(L, argumentCount);
        showGirlPushBoolean(L, isNew ? 1 : 0);
        showGirlSetField(L, 1, "bNew");
    }
    showGirlPushValue(L, LuaFirstUpvalueIndex);
    for (int i = 1; i <= argumentCount; ++i) showGirlPushValue(L, i);
    const int status = showGirlOriginalPcallK(L, argumentCount, -1, 0, 0, nullptr);
    if (status != 0) {
        Log("ShowGirlPage _SetGirlImage failed status=" + std::to_string(status));
        showGirlSetTop(L, argumentCount);
        return 0;
    }
    return showGirlGetTop(L) - argumentCount;
}

void TryPatchShowGirlLockPrompt(LuaStateRaw L) {
    if (!L || (showGirlLockPatchApplied && showGirlNewStatePatchApplied &&
        buildShipNewStatePatchApplied)) return;
    const auto xlua = GetModuleHandleW(L"xlua.dll");
    if (!xlua) return;

    const auto resolve = [&](const char* name) {
        return reinterpret_cast<void*>(GetProcAddress(xlua, name));
    };
    showGirlGetGlobal = reinterpret_cast<lua_getglobal_t>(resolve("lua_getglobal"));
    showGirlGetField = reinterpret_cast<lua_getfield_t>(resolve("lua_getfield"));
    showGirlSetField = reinterpret_cast<lua_setfield_t>(resolve("lua_setfield"));
    showGirlSetTop = reinterpret_cast<lua_settop_t>(resolve("lua_settop"));
    showGirlType = reinterpret_cast<lua_type_t>(resolve("lua_type"));
    showGirlGetTop = reinterpret_cast<lua_gettop_t>(resolve("lua_gettop"));
    showGirlPushValue = reinterpret_cast<lua_pushvalue_t>(resolve("lua_pushvalue"));
    showGirlPushCClosure = reinterpret_cast<lua_pushcclosure_t>(resolve("lua_pushcclosure"));
    showGirlPushBoolean = reinterpret_cast<lua_pushboolean_t>(resolve("lua_pushboolean"));
    showGirlToBoolean = reinterpret_cast<lua_toboolean_t>(resolve("lua_toboolean"));
    showGirlOriginalPcallK = reinterpret_cast<lua_pcallk_t>(luaPcallKStolen);
    if (!showGirlGetGlobal || !showGirlGetField || !showGirlSetField || !showGirlSetTop ||
        !showGirlType || !showGirlGetTop || !showGirlPushValue || !showGirlPushCClosure ||
        !showGirlPushBoolean || !showGirlToBoolean || !showGirlOriginalPcallK) {
        return;
    }

    const int top = showGirlGetTop(L);
    if (!buildShipNewStatePatchApplied) {
        showGirlGetGlobal(L, "Logic");
        if (showGirlType(L, -1) == LuaTypeTable) {
            showGirlGetField(L, -1, "buildShipLogic");
            if (showGirlType(L, -1) != LuaTypeNil) {
                showGirlGetField(L, -1, "CheckShowMeet");
                if (showGirlType(L, -1) == LuaTypeFunction) {
                    showGirlPushCClosure(L, &BuildShipCheckShowMeetPatched, 1);
                    showGirlSetField(L, -2, "CheckShowMeet");
                    buildShipNewStatePatchApplied = true;
                    Log("BuildShipLogic New-state forwarding patch applied");
                }
            }
        }
        showGirlSetTop(L, top);
    }

    if (!showGirlLockPatchApplied || !showGirlNewStatePatchApplied) {
        showGirlGetGlobal(L, "ShowGirlPage");
        if (showGirlType(L, -1) != LuaTypeTable) {
            showGirlSetTop(L, top);
            return;
        }
        if (!showGirlLockPatchApplied) {
            showGirlGetField(L, -1, "OnClickBack");
            if (showGirlType(L, -1) == LuaTypeFunction) {
                showGirlPushCClosure(L, &ShowGirlOnClickBackPatched, 1);
                showGirlSetField(L, -2, "OnClickBack");
                showGirlLockPatchApplied = true;
                Log("ShowGirlPage lock prompt patch applied (New ships only)");
            } else {
                showGirlSetTop(L, showGirlGetTop(L) - 1);
            }
        }
        if (!showGirlNewStatePatchApplied) {
            showGirlGetField(L, -1, "_UpdatePage");
            if (showGirlType(L, -1) == LuaTypeFunction) {
                showGirlPushCClosure(L, &ShowGirlUpdatePagePatched, 1);
                showGirlSetField(L, -2, "_UpdatePage");
                showGirlGetField(L, -1, "_SetGirlImage");
                if (showGirlType(L, -1) == LuaTypeFunction) {
                    showGirlPushCClosure(L, &ShowGirlSetGirlImagePatched, 1);
                    showGirlSetField(L, -2, "_SetGirlImage");
                    showGirlNewStatePatchApplied = true;
                    Log("ShowGirlPage duplicate-New patch applied");
                } else {
                    showGirlSetTop(L, showGirlGetTop(L) - 1);
                }
            } else {
                showGirlSetTop(L, showGirlGetTop(L) - 1);
            }
        }
        showGirlSetTop(L, top);
    }
}

// POST-CALL hook on xlua.dll lua_pcallk. A successful protected call may have
// just loaded ShowGirlPage, so probe for it without changing Lua stack state.
__declspec(naked) void LuaPcallKTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov dword ptr [luaPcallKLState], eax
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 44]
        mov ebx, dword ptr [esp + 48]
        mov esi, dword ptr [esp + 52]
        mov edi, dword ptr [esp + 56]
        push edi
        push esi
        push ebx
        push edx
        push ecx
        push eax
        call dword ptr [luaPcallKStolen]
        add esp, 24
        mov dword ptr [luaPcallKResult], eax
        test eax, eax
        jne done
        push dword ptr [luaPcallKLState]
        call TryPatchShowGirlLockPrompt
        add esp, 4
    done:
        popad
        mov eax, dword ptr [luaPcallKResult]
        ret
    }
}

bool InstallXluaExportHook(const char* exportName, void* trampoline, void** stolenOut,
    size_t stolenLen, const char* name) {
    auto xlua = GetModuleHandleW(L"xlua.dll");
    if (!xlua) return false;
    const auto proc = GetProcAddress(xlua, exportName);
    if (!proc) return false;
    auto address = reinterpret_cast<unsigned char*>(proc);
    const unsigned char expected[] = { 0x55, 0x8B, 0xEC };
    if (memcmp(address, expected, sizeof(expected)) != 0) {
        char actual[16]{};
        for (int i = 0; i < 6; ++i) {
            char byte[4]{};
            sprintf_s(byte, "%02X ", address[i]);
            strcat_s(actual, byte);
        }
        Log(std::string(name) + " hook refused: prologue mismatch actual=" + actual);
        return false;
    }
    auto stolen = VirtualAlloc(nullptr, stolenLen + 7, MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE);
    if (!stolen) return false;
    auto bytes = reinterpret_cast<unsigned char*>(stolen);
    memcpy(bytes, address, stolenLen);
    int position = static_cast<int>(stolenLen);
    const auto backTarget = reinterpret_cast<uintptr_t>(address) + stolenLen;
    bytes[position++] = 0xE9;
    const int32_t backRelative = static_cast<int32_t>(
        backTarget - (reinterpret_cast<uintptr_t>(stolen) + position + 4));
    memcpy(bytes + position, &backRelative, 4);
    *stolenOut = stolen;

    const auto target = reinterpret_cast<uintptr_t>(trampoline);
    const int32_t relative = static_cast<int32_t>(
        target - (reinterpret_cast<uintptr_t>(address) + 5));
    unsigned char jump[5]{ 0xE9 };
    memcpy(jump + 1, &relative, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, stolenLen, PAGE_EXECUTE_READWRITE, &oldProtect)) return false;
    memcpy(address, jump, 5);
    for (size_t i = 5; i < stolenLen; ++i) address[i] = 0x90;
    VirtualProtect(address, stolenLen, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, stolenLen);
    Log(std::string(name) + " hook applied");
    return true;
}

void TryApplyLuaPcallKHook() {
    if (luaPcallKHookApplied) return;
    if (InstallXluaExportHook("lua_pcallk", &LuaPcallKTrampoline, &luaPcallKStolen,
        14, "lua_pcallk")) {
        luaPcallKHookApplied = true;
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

template <typename Fn>
bool InstallReturnHook(uintptr_t rva, void* hookFn, Fn* originalOut, size_t stolenLen, const char* name) {
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
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, stolenLen + 16, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return false;
    memcpy(tramp, address, stolenLen);
    const auto backRel = static_cast<int32_t>((reinterpret_cast<uintptr_t>(address) + stolenLen) -
        (reinterpret_cast<uintptr_t>(tramp) + stolenLen + 5));
    tramp[stolenLen] = 0xE9;
    memcpy(tramp + stolenLen + 1, &backRel, 4);
    *originalOut = reinterpret_cast<Fn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(hookFn);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(address) + 5));
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
bool mainGunDamageFacPatched = false;

void TryApplyMainGunDamageFacPatch() {
    if (mainGunDamageFacPatched) return;
    mainGunDamageFacPatched = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    wchar_t modulePath[MAX_PATH]{};
    if (!GetModuleFileNameW(ga, modulePath, MAX_PATH)) return;
    if (HashFileSha256(modulePath) != "8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404") {
        Log("main-gun damageFac patch refused: SHA-256 mismatch");
        return;
    }
    struct Slot { uintptr_t rva; unsigned char expect[5]; };
    const Slot slots[] = {
        { 0x52044A, { 0xF2, 0x0F, 0x59, 0x45, 0xF4 } },
        { 0x521910, { 0xF2, 0x0F, 0x59, 0x4D, 0xDC } },
        { 0x5222F1, { 0xF2, 0x0F, 0x59, 0x45, 0xA0 } },
        { 0x52314B, { 0xF2, 0x0F, 0x59, 0x45, 0xF0 } },
        { 0x5232F0, { 0xF2, 0x0F, 0x59, 0x45, 0xF8 } },
        { 0x523C03, { 0xF2, 0x0F, 0x59, 0x45, 0xC0 } },
        // 空袭 __BomberAttack 0x51D590�?x51DA87 mulsd xmm0,[ebp-0x60]（字�?F2 0F 59 45 A0）也�?
        // actSkillInfo.damageFac(=0)�?x51DA11 fstp [ebp-0x60] �?0x1052f5a0
        // �?[skill+0x64]+0x28（damageFac）覆盖，DA87 相乘把最终伤害清零�?
        { 0x51DA87, { 0xF2, 0x0F, 0x59, 0x45, 0xA0 } },
        // 空袭战斗机路径（0x51E500 区域函数）：0x51E6D7 同样�?damageFac 乘法�?
        { 0x51E6D7, { 0xF2, 0x0F, 0x59, 0x45, 0xA0 } },
        // ���� EPU_ViceGun.ExecuteAtom 0x523FD0: 0x52430C mulsd xmm1,[eax+0x28] (eax=[edi+0x64]=actSkillInfo, +0x28=damageFac)
        { 0x52430C, { 0xF2, 0x0F, 0x59, 0x48, 0x28 } },
    };
    for (const auto& s : slots) {
        auto address = reinterpret_cast<unsigned char*>(ga) + s.rva;
        if (memcmp(address, s.expect, 5) != 0) {
            char actual[16]{};
            for (int i = 0; i < 5; ++i) { char b[4]{}; sprintf_s(b, "%02X ", address[i]); strcat_s(actual, b); }
            Log(std::string("main-gun damageFac patch refused @0x") + std::to_string(s.rva) +
                " actual=" + actual);
            continue;
        }
        DWORD oldProtect = 0;
        if (!VirtualProtect(address, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) continue;
        memset(address, 0x90, 5);
        VirtualProtect(address, 5, oldProtect, &oldProtect);
        FlushInstructionCache(GetCurrentProcess(), address, 5);
        Log("main-gun damageFac patch applied @0x" + std::to_string(s.rva));
    }
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

// Registered in InitializeHooks. Logs native crashes (access violations, illegal
// instructions) with the exception code, faulting address and module+rva so the
// bundle-unload crash can be located without a debugger. Always EXCEPTION_CONTINUE_SEARCH
// so we never swallow the exception; also writes to the crash log without the mutex to
// avoid deadlock if the crash happened while the logging mutex was held.
LONG WINAPI CrashVectoredHandler(EXCEPTION_POINTERS* info) {
    static volatile LONG counts[64] = {};
    if (!info || !info->ExceptionRecord) return EXCEPTION_CONTINUE_SEARCH;
    const auto rec = info->ExceptionRecord;
    const auto code = rec->ExceptionCode;
    // Benign first-chance exceptions that fire constantly and are handled by the app
    // (OutputDebugString/debugger print, breakpoints, single-step, VEH/SEH notify).
    if (code == 0x406D1388 || code == 0x40010006 || code == 0x40010007 ||
        code == 0x80000003 || code == 0x80000004 || code == 0x40000001)
        return EXCEPTION_CONTINUE_SEARCH;

    const bool isCrash = code == 0xC0000005 || code == 0xC000001D || code == 0xC0000094 ||
        code == 0xC00000FD || code == 0xC000000D || code == 0xC0000409 ||
        code == 0xC0000374 || code == 0xC0000096 || code == 0xC0000026 ||
        code == 0xC0000008 || code == 0xC0000006 || code == 0xE06D7363;
    // Once the battle has started (data built), log EVERY exception reaching the VEH so a
    // non-standard crash code (e.g. one bugly fabricates or a watchdog raise) is visible.
    const bool afterBattle = gBattleStarted;
    if (!isCrash && !afterBattle) return EXCEPTION_CONTINUE_SEARCH;

    // A C++ exception (0xE06D7363) is normally caught by a runtime SEH frame (first chance,
    // flags=1 NONCONTINUABLE). Only an ESCAPED one (second chance, flags includes UNWINDING
    // 0x2, or a later pass) is a real crash. Count handled ones separately so login noise
    // never suppresses an unhandled throw at the crash point.
    const bool unhandledCxx = (code == 0xE06D7363) && ((rec->ExceptionFlags & 0x2) != 0);

    const auto bucket = (static_cast<unsigned>(code) >> 4) & 63;
    const auto n = InterlockedIncrement(&counts[bucket]);
    if (n > 8 && !unhandledCxx && !afterBattle) return EXCEPTION_CONTINUE_SEARCH;
    if (n > 64) return EXCEPTION_CONTINUE_SEARCH;
    if (unhandledCxx && n > 32) return EXCEPTION_CONTINUE_SEARCH;

    char buf[512]{};
    auto m = 0;
    m += sprintf_s(buf + m, sizeof(buf) - m, "CRASH#%ld code=0x%08X addr=0x%p flags=%u",
        n, static_cast<unsigned>(code), rec->ExceptionAddress, static_cast<unsigned>(rec->ExceptionFlags));
    if (rec->NumberParameters > 0) {
        m += sprintf_s(buf + m, sizeof(buf) - m, " params=");
        for (DWORD i = 0; i < rec->NumberParameters && i < 2; ++i)
            m += sprintf_s(buf + m, sizeof(buf) - m, "%s0x%p", i ? "," : "", reinterpret_cast<void*>(rec->ExceptionInformation[i]));
    }
    if (info->ContextRecord)
        m += sprintf_s(buf + m, sizeof(buf) - m, " eip=0x%lX eax=0x%lX ebx=0x%lX ecx=0x%lX edx=0x%lX esi=0x%lX edi=0x%lX ebp=0x%lX esp=0x%lX",
            info->ContextRecord->Eip, info->ContextRecord->Eax, info->ContextRecord->Ebx,
            info->ContextRecord->Ecx, info->ContextRecord->Edx, info->ContextRecord->Esi,
            info->ContextRecord->Edi, info->ContextRecord->Ebp, info->ContextRecord->Esp);
    m += sprintf_s(buf + m, sizeof(buf) - m, " caller=%s", DescribeCaller(rec->ExceptionAddress).c_str());
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    // A C++/managed exception (0xE06D7363, the IL2CPP dispatch for e.g. NullReferenceException)
    // is normally caught by the game's own SEH before it escapes. Walk the throw site stack so
    // the exact managed method (e.g. the MissionNode null-ref during battle init) is visible.
    if ((code == 0xE06D7363 || code == 0xC0000005 || code == 0x4001000A) && info->ContextRecord &&
        (code == 0xE06D7363 ? (rec->NumberParameters >= 2 && (afterBattle || unhandledCxx)) : true)) {
        const auto esp = info->ContextRecord->Esp;
        std::string trace = " throwEip=" + DescribeCaller(reinterpret_cast<void*>(info->ContextRecord->Eip));
        if (code == 0xE06D7363) {
            const auto exceptObj = static_cast<uintptr_t>(rec->ExceptionInformation[1]);
            if (exceptObj) {
                const auto klass = ReadPtrSafe(exceptObj);
                const auto className = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0x8)) : "";
                const auto nameSpace = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0xC)) : "";
                if (!className.empty()) trace += " type=" + nameSpace + "." + className;
                const auto msgPtr = ReadPtrSafe(exceptObj + 0x8);
                if (msgPtr) trace += " msg=" + ReadIl2CppString(reinterpret_cast<void*>(msgPtr));
            }
        }
        auto found = 0;
        for (DWORD off = 0; off < 0x2000 && found < 48; off += 4) {
            const auto addr = ReadPtrSafe(esp + off);
            const auto desc = DescribeCaller(reinterpret_cast<void*>(addr));
            if (desc.find("unknown") == std::string::npos) {
                trace += " " + desc;
                found++;
            }
        }
        Log("CXXSTACK" + trace);
    }
    // Stack overflow: walk the stack upward from esp, logging any dword that resolves into
    // a module as a return address. This reveals the recursive call chain.
    if (code == 0xC00000FD && info->ContextRecord) {
        const auto esp = info->ContextRecord->Esp;
        std::string trace;
        auto found = 0;
        for (DWORD off = 0; off < 0x4000 && found < 40; off += 4) {
            const auto addr = ReadPtrSafe(esp + off);
            const auto desc = DescribeCaller(reinterpret_cast<void*>(addr));
            if (desc.find("unknown") == std::string::npos) {
                trace += " " + desc;
                found++;
            }
        }
        Log("STACKTRACE esp=0x" + std::to_string(esp) + trace);
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

// Inline hook for dbghelp!MiniDumpWriteDump. The bugly/bt_dump crash reporter calls this
// with the REAL MINIDUMP_EXCEPTION_INFORMATION (genuine EXCEPTION_POINTERS), even though
// the minidump it writes has a synthetic context. Capturing the parameter here gives us the
// true faulting address / thread / registers for the bundle-unload crash.
using MiniDumpWriteDumpFn = BOOL(WINAPI*)(HANDLE, DWORD, HANDLE, DWORD,
    const void*, const void*, const void*);
MiniDumpWriteDumpFn originalMiniDumpWriteDump = nullptr;

struct MiniDumpExceptionInfo32 {
    DWORD ThreadId;
    void* ExceptionPointers;
    BOOL ClientPointers;
};

BOOL WINAPI HookMiniDumpWriteDump(HANDLE hProcess, DWORD processId, HANDLE hFile, DWORD dumpType,
    const void* exceptionParam, const void* userStreamParam, const void* callbackParam) {
    if (exceptionParam) {
        const auto info = static_cast<const MiniDumpExceptionInfo32*>(exceptionParam);
        const auto ep = reinterpret_cast<EXCEPTION_POINTERS*>(info->ExceptionPointers);
        char buf[1024]{};
        auto m = 0;
        m += sprintf_s(buf + m, sizeof(buf) - m, "MINIDUMP thread=%lu", info->ThreadId);
        if (ep && ep->ExceptionRecord) {
            const auto er = ep->ExceptionRecord;
            m += sprintf_s(buf + m, sizeof(buf) - m, " code=0x%08X addr=0x%p flags=%u params=%lu",
                static_cast<unsigned>(er->ExceptionCode), er->ExceptionAddress,
                static_cast<unsigned>(er->ExceptionFlags),
                static_cast<unsigned long>(er->NumberParameters));
            // _invalid_parameter passes wchar_t* (expression, function, file) as the first
            // three ExceptionInformation args - read them in-process as wide strings.
            for (DWORD i = 0; i < er->NumberParameters && i < 4; ++i) {
                const auto p = er->ExceptionInformation[i];
                m += sprintf_s(buf + m, sizeof(buf) - m, " p%lu=0x%p", i, reinterpret_cast<void*>(p));
                if (p && (p >> 16) != 0) {
                    const auto ws = ReadWideCStr(p);
                    if (!ws.empty())
                        m += sprintf_s(buf + m, sizeof(buf) - m, "(\"%s\")", ws.c_str());
                }
            }
            m += sprintf_s(buf + m, sizeof(buf) - m, " caller=%s", DescribeCaller(er->ExceptionAddress).c_str());
        }
        if (ep && ep->ContextRecord)
            m += sprintf_s(buf + m, sizeof(buf) - m, " eip=0x%lX eax=0x%lX ebx=0x%lX ecx=0x%lX edx=0x%lX esi=0x%lX edi=0x%lX ebp=0x%lX esp=0x%lX",
                ep->ContextRecord->Eip, ep->ContextRecord->Eax, ep->ContextRecord->Ebx,
                ep->ContextRecord->Ecx, ep->ContextRecord->Edx, ep->ContextRecord->Esi,
                ep->ContextRecord->Edi, ep->ContextRecord->Ebp, ep->ContextRecord->Esp);
        std::ofstream output(logPath, std::ios::app);
        output << buf << '\n';
        output.flush();
        // Walk the real stack from the captured context (esp/ebp) to expose the call chain.
        if (ep && ep->ContextRecord && ep->ContextRecord->Esp) {
            const auto esp = ep->ContextRecord->Esp;
            std::string trace;
            auto found = 0;
            for (DWORD off = 0; off < 0x4000 && found < 40; off += 4) {
                const auto addr = ReadPtrSafe(esp + off);
                const auto desc = DescribeCaller(reinterpret_cast<void*>(addr));
                if (desc.find("unknown") == std::string::npos) {
                    trace += " " + desc;
                    found++;
                }
            }
            if (!trace.empty()) {
                std::ofstream o2(logPath, std::ios::app);
                o2 << "MINIDUMP_STACK esp=0x" << std::hex << esp << std::dec << trace << '\n';
                o2.flush();
            }
        }
    }
    if (!originalMiniDumpWriteDump) return FALSE;
    return originalMiniDumpWriteDump(hProcess, processId, hFile, dumpType,
        exceptionParam, userStreamParam, callbackParam);
}

void TryApplyMiniDumpWriteDumpHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto dbghelp = GetModuleHandleW(L"dbghelp.dll");
    if (!dbghelp) dbghelp = LoadLibraryW(L"dbghelp.dll");
    if (!dbghelp) return;
    auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(dbghelp, "MiniDumpWriteDump"));
    if (!fn) return;
    // Build a trampoline that replays the stolen 5 bytes then jumps back to fn+5,
    // so originalMiniDumpWriteDump calls the REAL function (not the hooked entry).
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 5);                                  // stolen prologue
    const auto backRel = static_cast<int32_t>(
        (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
    tramp[5] = 0xE9;                                       // jmp back to fn+5
    memcpy(tramp + 6, &backRel, 4);
    originalMiniDumpWriteDump = reinterpret_cast<MiniDumpWriteDumpFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookMiniDumpWriteDump);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        originalMiniDumpWriteDump = nullptr;
        return;
    }
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log("MiniDumpWriteDump hook applied");
}

// CRT _invalid_parameter / _invalid_parameter_noinfo: the source of STATUS_INVALID_PARAMETER
// (0xC000000D) raised during the bundle-unload crash. Hook these exports in the CRT dll to
// capture the exact expression/function/file and the caller that passed a bad argument.
using InvalidParameterFn = void(__cdecl*)(const wchar_t*, const wchar_t*, const wchar_t*, unsigned, uintptr_t);
using InvalidParameterNoInfoFn = void(__cdecl*)(const wchar_t*, const wchar_t*, const wchar_t*, unsigned, uintptr_t);
InvalidParameterFn originalInvalidParameter = nullptr;
InvalidParameterNoInfoFn originalInvalidParameterNoInfo = nullptr;

void LogInvalidParameter(const wchar_t* expression, const wchar_t* function, const wchar_t* file, unsigned line) {
    char buf[1024]{};
    auto m = 0;
    auto wcopy = [](char* dst, size_t cap, const wchar_t* src) {
        if (!src) { dst[0] = 0; return; }
        WideCharToMultiByte(CP_UTF8, 0, src, -1, dst, static_cast<int>(cap), nullptr, nullptr);
    };
    m += sprintf_s(buf + m, sizeof(buf) - m, "INVALID_PARAM line=%u caller=%s", line, DescribeCaller(_ReturnAddress()).c_str());
    char e[256]{}, f[256]{}, fl[256]{};
    wcopy(e, sizeof(e), expression);
    wcopy(f, sizeof(f), function);
    wcopy(fl, sizeof(fl), file);
    m += sprintf_s(buf + m, sizeof(buf) - m, " expr=%s func=%s file=%s", e, f, fl);
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
}

void __cdecl HookInvalidParameter(const wchar_t* expression, const wchar_t* function, const wchar_t* file,
    unsigned line, uintptr_t reserved) {
    LogInvalidParameter(expression, function, file, line);
    if (originalInvalidParameter)
        originalInvalidParameter(expression, function, file, line, reserved);
}

void __cdecl HookInvalidParameterNoInfo(const wchar_t* expression, const wchar_t* function, const wchar_t* file,
    unsigned line, uintptr_t reserved) {
    LogInvalidParameter(expression, function, file, line);
    if (originalInvalidParameterNoInfo)
        originalInvalidParameterNoInfo(expression, function, file, line, reserved);
}

bool InstallCrtExportHook(HMODULE crt, const char* name, void* replacement, void** originalOut) {
    auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(crt, name));
    if (!fn) return false;
    // msvcr100 exports have a recognizable prologue; install a 5-byte jmp.
    const auto target = reinterpret_cast<uintptr_t>(replacement);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) return false;
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log(std::string("CRT hook applied: ") + name);
    return true;
}

void TryApplyInvalidParameterHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    // Hook BOTH CRT copies' _invalid_parameter_noinfo (the crash uses the SYSTEM ucrtbase
    // internal path). Do NOT return after the first success - hook every loaded copy.
    std::vector<HMODULE> crts;
    auto sys = GetModuleHandleW(L"ucrtbase.dll");
    if (sys) crts.push_back(sys);
    auto msvcr = GetModuleHandleW(L"msvcr100.dll");
    if (msvcr) crts.push_back(msvcr);
    for (auto crt : crts) {
        InstallCrtExportHook(crt, "_invalid_parameter",
            reinterpret_cast<void*>(&HookInvalidParameter),
            reinterpret_cast<void**>(&originalInvalidParameter));
        InstallCrtExportHook(crt, "_invalid_parameter_noinfo",
            reinterpret_cast<void*>(&HookInvalidParameterNoInfo),
            reinterpret_cast<void**>(&originalInvalidParameterNoInfo));
    }
    Log("InvalidParameterHooks configured");
}

// Hook RaiseException in kernelbase to log the actual STATUS_INVALID_PARAMETER raise with
// its argument pointers (CRT passes expression/function/file pointers as ExceptionInformation)
// and the caller that triggered it. This bypasses the fabrications of the bugly reporter.
using RaiseExceptionFn = void(WINAPI*)(DWORD, DWORD, DWORD, const ULONG_PTR*);
RaiseExceptionFn originalRaiseException = nullptr;

void WINAPI HookRaiseException(DWORD dwExceptionCode, DWORD dwExceptionFlags,
    DWORD nNumberOfArguments, const ULONG_PTR* lpArguments) {
    if (dwExceptionCode == 0xC000000D || dwExceptionCode == 0xC0000005 ||
        dwExceptionCode == 0xE06D7363 || dwExceptionCode == 0xC00000FD) {
        char buf[512]{};
        auto m = 0;
        m += sprintf_s(buf + m, sizeof(buf) - m, "RAISE code=0x%08X flags=0x%X nargs=%lu caller=%s",
            static_cast<unsigned>(dwExceptionCode), static_cast<unsigned>(dwExceptionFlags),
            static_cast<unsigned long>(nNumberOfArguments),
            DescribeCaller(_ReturnAddress()).c_str());
        for (DWORD i = 0; i < nNumberOfArguments && i < 4; ++i) {
            m += sprintf_s(buf + m, sizeof(buf) - m, " a%lu=0x%p", i,
                reinterpret_cast<void*>(lpArguments ? lpArguments[i] : 0));
            if (lpArguments && lpArguments[i] && (lpArguments[i] >> 16) != 0) {
                const auto s = ReadAsciiCStr(lpArguments[i]);
                if (s.find("<") == std::string::npos)
                    m += sprintf_s(buf + m, sizeof(buf) - m, "(\"%s\")", s.c_str());
            }
        }
        std::ofstream output(logPath, std::ios::app);
        output << buf << '\n';
        output.flush();
    }
    if (originalRaiseException)
        originalRaiseException(dwExceptionCode, dwExceptionFlags, nNumberOfArguments, lpArguments);
}

void TryApplyRaiseExceptionHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto kernelbase = GetModuleHandleW(L"KERNELBASE.dll");
    if (!kernelbase) kernelbase = LoadLibraryW(L"KERNELBASE.dll");
    if (!kernelbase) return;
    auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(kernelbase, "RaiseException"));
    if (!fn) return;
    // Trampoline replaying stolen 5 bytes then jumping back to fn+5.
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 5);
    const auto backRel = static_cast<int32_t>(
        (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
    tramp[5] = 0xE9;
    memcpy(tramp + 6, &backRel, 4);
    originalRaiseException = reinterpret_cast<RaiseExceptionFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookRaiseException);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        originalRaiseException = nullptr;
        VirtualFree(tramp, 0, MEM_RELEASE);
        return;
    }
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log("RaiseException hook applied");
}

// UnhandledExceptionFilter receives the REAL EXCEPTION_POINTERS when an exception escapes
// every handler. This is where bugly decides to dump - capture the true faulting address.
using UnhandledFilterFn = LONG(WINAPI*)(EXCEPTION_POINTERS*);
UnhandledFilterFn originalUnhandledExceptionFilter = nullptr;

LONG WINAPI HookUnhandledExceptionFilter(EXCEPTION_POINTERS* info) {
    char buf[512]{};
    auto m = 0;
    if (info && info->ExceptionRecord) {
        const auto rec = info->ExceptionRecord;
        m += sprintf_s(buf + m, sizeof(buf) - m, "UNHANDLED code=0x%08X addr=0x%p flags=%u nargs=%lu caller=%s",
            static_cast<unsigned>(rec->ExceptionCode), rec->ExceptionAddress,
            static_cast<unsigned>(rec->ExceptionFlags),
            static_cast<unsigned long>(rec->NumberParameters),
            DescribeCaller(rec->ExceptionAddress).c_str());
        for (DWORD i = 0; i < rec->NumberParameters && i < 3; ++i) {
            m += sprintf_s(buf + m, sizeof(buf) - m, " a%lu=0x%p", i,
                reinterpret_cast<void*>(rec->ExceptionInformation[i]));
            if (rec->ExceptionInformation[i] && (rec->ExceptionInformation[i] >> 16) != 0) {
                const auto s = ReadAsciiCStr(rec->ExceptionInformation[i]);
                if (s.find("<") == std::string::npos)
                    m += sprintf_s(buf + m, sizeof(buf) - m, "(\"%s\")", s.c_str());
            }
        }
    }
    if (info && info->ContextRecord)
        m += sprintf_s(buf + m, sizeof(buf) - m, " eip=0x%lX eax=0x%lX ebx=0x%lX ecx=0x%lX edx=0x%lX esi=0x%lX edi=0x%lX ebp=0x%lX esp=0x%lX",
            info->ContextRecord->Eip, info->ContextRecord->Eax, info->ContextRecord->Ebx,
            info->ContextRecord->Ecx, info->ContextRecord->Edx, info->ContextRecord->Esi,
            info->ContextRecord->Edi, info->ContextRecord->Ebp, info->ContextRecord->Esp);
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    if (originalUnhandledExceptionFilter) return originalUnhandledExceptionFilter(info);
    return EXCEPTION_CONTINUE_SEARCH;
}

void TryApplyUnhandledExceptionFilterHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto kernelbase = GetModuleHandleW(L"KERNELBASE.dll");
    if (!kernelbase) kernelbase = LoadLibraryW(L"KERNELBASE.dll");
    if (!kernelbase) return;
    auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(kernelbase, "UnhandledExceptionFilter"));
    if (!fn) return;
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 5);
    const auto backRel = static_cast<int32_t>(
        (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
    tramp[5] = 0xE9;
    memcpy(tramp + 6, &backRel, 4);
    originalUnhandledExceptionFilter = reinterpret_cast<UnhandledFilterFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookUnhandledExceptionFilter);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        originalUnhandledExceptionFilter = nullptr;
        VirtualFree(tramp, 0, MEM_RELEASE);
        return;
    }
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log("UnhandledExceptionFilter hook applied");
}

// TerminateProcess hook: capture deliberate termination (the game/SDK may end the process
// without raising an exception). Logs the caller and exit code.
using TerminateProcessFn = BOOL(WINAPI*)(HANDLE, UINT);
TerminateProcessFn originalTerminateProcess = nullptr;

BOOL WINAPI HookTerminateProcess(HANDLE hProcess, UINT uExitCode) {
    char buf[256]{};
    sprintf_s(buf, sizeof(buf), "TERMINATE exit=%u caller=%s",
        static_cast<unsigned>(uExitCode), DescribeCaller(_ReturnAddress()).c_str());
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    if (originalTerminateProcess) return originalTerminateProcess(hProcess, uExitCode);
    return FALSE;
}

void TryApplyTerminateProcessHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto kernel32 = GetModuleHandleW(L"kernel32.dll");
    if (!kernel32) return;
    auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(kernel32, "TerminateProcess"));
    if (!fn) return;
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 5);
    const auto backRel = static_cast<int32_t>(
        (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
    tramp[5] = 0xE9;
    memcpy(tramp + 6, &backRel, 4);
    originalTerminateProcess = reinterpret_cast<TerminateProcessFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookTerminateProcess);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        originalTerminateProcess = nullptr;
        VirtualFree(tramp, 0, MEM_RELEASE);
        return;
    }
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log("TerminateProcess hook applied");
}

// KiUserExceptionDispatcher hook: ntdll entry for EVERY user-mode exception dispatch
// (hardware faults and software raises). bugly loads later and registers its own VEH in
// front of ours, so it swallows the real exception before our VEH runs; this hook sees the
// true exception record regardless. Signature: void(DISPATCHER_CONTEXT*), args on stack:
// [esp+4]=PEXCEPTION_RECORD, [esp+8]=PCONTEXT.
using KiDispatchFn = void(__stdcall*)(void*);
KiDispatchFn originalKiUserExceptionDispatcher = nullptr;

void LogKiExceptionRecord(void* record);

void __declspec(naked) HookKiUserExceptionDispatcherTrampoline() {
    __asm {
        push ebp
        mov ebp, esp
        pushad
        // Entry stack: [esp]=PEXCEPTION_RECORD, [esp+4]=PCONTEXT.
        // After push ebp: [ebp]=old ebp, [ebp+4]=PEXCEPTION_RECORD, [ebp+8]=PCONTEXT.
        mov eax, dword ptr [ebp + 4]    // PEXCEPTION_RECORD
        push eax
        call LogKiExceptionRecord
        add esp, 4
        popad
        pop ebp
        jmp dword ptr [originalKiUserExceptionDispatcher]
    }
}

void LogKiExceptionRecord(void* record) {
    if (!record) return;
    const auto rec = static_cast<EXCEPTION_RECORD*>(record);
    const auto code = rec->ExceptionCode;
    // Skip benign/constant exceptions.
    if (code == 0x406D1388 || code == 0x40010006 || code == 0x40010007 ||
        code == 0x80000003 || code == 0x80000004 || code == 0x40000001)
        return;
    const bool crash = code == 0xC0000005 || code == 0xC000001D || code == 0xC0000094 ||
        code == 0xC00000FD || code == 0xC000000D || code == 0xC0000409 ||
        code == 0xC0000374 || code == 0xC0000096 || code == 0xC0000026 ||
        code == 0xC0000008 || code == 0xC0000006 || code == 0xE06D7363;
    // After battle start log every dispatch (limit per code); before, only crash codes.
    if (!gBattleStarted && !crash) return;
    static volatile LONG dispCount[64] = {};
    const auto bucket = (static_cast<unsigned>(code) >> 4) & 63;
    if (InterlockedIncrement(&dispCount[bucket]) > 64) return;
    char buf[512]{};
    auto m = 0;
    m += sprintf_s(buf + m, sizeof(buf) - m, "DISPATCH code=0x%08X addr=0x%p flags=%u nargs=%lu",
        static_cast<unsigned>(code), rec->ExceptionAddress,
        static_cast<unsigned>(rec->ExceptionFlags),
        static_cast<unsigned long>(rec->NumberParameters));
    for (DWORD i = 0; i < rec->NumberParameters && i < 3; ++i) {
        m += sprintf_s(buf + m, sizeof(buf) - m, " a%lu=0x%p", i,
            reinterpret_cast<void*>(rec->ExceptionInformation[i]));
        if (rec->ExceptionInformation[i] && (rec->ExceptionInformation[i] >> 16) != 0) {
            const auto s = ReadAsciiCStr(rec->ExceptionInformation[i]);
            if (s.find("<") == std::string::npos)
                m += sprintf_s(buf + m, sizeof(buf) - m, "(\"%s\")", s.c_str());
        }
    }
    m += sprintf_s(buf + m, sizeof(buf) - m, " caller=%s", DescribeCaller(rec->ExceptionAddress).c_str());
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
}

void TryApplyKiUserExceptionDispatcherHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto ntdll = GetModuleHandleW(L"ntdll.dll");
    if (!ntdll) return;
    auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(ntdll, "KiUserExceptionDispatcher"));
    if (!fn) return;
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 5);
    const auto backRel = static_cast<int32_t>(
        (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
    tramp[5] = 0xE9;
    memcpy(tramp + 6, &backRel, 4);
    originalKiUserExceptionDispatcher = reinterpret_cast<KiDispatchFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookKiUserExceptionDispatcherTrampoline);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        originalKiUserExceptionDispatcher = nullptr;
        VirtualFree(tramp, 0, MEM_RELEASE);
        return;
    }
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log("KiUserExceptionDispatcher hook applied");
}

// ExitProcess / NtTerminateProcess hooks: capture deliberate process exit (the crash does
// NOT go through exception dispatch after battle starts - something calls ExitProcess or
// terminates the process directly).
using ExitProcessFn = void(WINAPI*)(UINT);
void DumpStackTrace(const char* tag);
using NtTerminateProcessFn = LONG(WINAPI*)(void*, LONG);
ExitProcessFn originalExitProcess = nullptr;
NtTerminateProcessFn originalNtTerminateProcess = nullptr;

void WINAPI HookExitProcess(UINT uExitCode) {
    char buf[256]{};
    sprintf_s(buf, sizeof(buf), "EXITPROCESS code=%u caller=%s",
        static_cast<unsigned>(uExitCode), DescribeCaller(_ReturnAddress()).c_str());
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    DumpStackTrace("EXITPROCESS_STACK");
    // Raw stack scan from the current esp: _wassert is noreturn so CaptureStackBackTrace
    // cannot see the real game frames. Scan a large window for any module return address.
    {
        uintptr_t esp = 0;
        __asm { mov esp, esp } // placeholder; use _AddressOfReturnAddress
        esp = reinterpret_cast<uintptr_t>(_AddressOfReturnAddress());
        std::string trace;
        auto found = 0;
        for (DWORD off = 0; off < 0x20000 && found < 60; off += 4) {
            const auto addr = ReadPtrSafe(esp + off);
            const auto desc = DescribeCaller(reinterpret_cast<void*>(addr));
            if (desc.find("unknown") == std::string::npos && desc.find("BlueOath.Payload") == std::string::npos) {
                trace += " " + desc;
                found++;
            }
        }
        std::ofstream o2(logPath, std::ios::app);
        o2 << "EXITPROCESS_RAWSTACK" << trace << '\n';
        o2.flush();
    }
    if (originalExitProcess) originalExitProcess(uExitCode);
}

LONG WINAPI HookNtTerminateProcess(void* handle, LONG exitCode) {
    char buf[256]{};
    sprintf_s(buf, sizeof(buf), "NTTERMINATE handle=0x%p exit=%ld caller=%s",
        handle, exitCode, DescribeCaller(_ReturnAddress()).c_str());
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    if (originalNtTerminateProcess) return originalNtTerminateProcess(handle, exitCode);
    return 0xC0000022L;
}

void TryApplyExitHooks() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto kernel32 = GetModuleHandleW(L"kernel32.dll");
    if (kernel32) {
        if (auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(kernel32, "ExitProcess"))) {
            auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
            if (tramp) {
                memcpy(tramp, fn, 5);
                const auto backRel = static_cast<int32_t>(
                    (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
                tramp[5] = 0xE9;
                memcpy(tramp + 6, &backRel, 4);
                originalExitProcess = reinterpret_cast<ExitProcessFn>(tramp);
                const auto target = reinterpret_cast<uintptr_t>(&HookExitProcess);
                const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
                unsigned char jump[5];
                jump[0] = 0xE9;
                memcpy(jump + 1, &rel, 4);
                DWORD oldProtect = 0;
                if (VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
                    memcpy(fn, jump, 5);
                    VirtualProtect(fn, 5, oldProtect, &oldProtect);
                    FlushInstructionCache(GetCurrentProcess(), fn, 5);
                    Log("ExitProcess hook applied");
                } else { originalExitProcess = nullptr; VirtualFree(tramp, 0, MEM_RELEASE); }
            }
        }
    }
    auto ntdll = GetModuleHandleW(L"ntdll.dll");
    if (ntdll) {
        if (auto fn = reinterpret_cast<unsigned char*>(GetProcAddress(ntdll, "NtTerminateProcess"))) {
            auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
            if (tramp) {
                memcpy(tramp, fn, 5);
                const auto backRel = static_cast<int32_t>(
                    (reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
                tramp[5] = 0xE9;
                memcpy(tramp + 6, &backRel, 4);
                originalNtTerminateProcess = reinterpret_cast<NtTerminateProcessFn>(tramp);
                const auto target = reinterpret_cast<uintptr_t>(&HookNtTerminateProcess);
                const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
                unsigned char jump[5];
                jump[0] = 0xE9;
                memcpy(jump + 1, &rel, 4);
                DWORD oldProtect = 0;
                if (VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) {
                    memcpy(fn, jump, 5);
                    VirtualProtect(fn, 5, oldProtect, &oldProtect);
                    FlushInstructionCache(GetCurrentProcess(), fn, 5);
                    Log("NtTerminateProcess hook applied");
                } else { originalNtTerminateProcess = nullptr; VirtualFree(tramp, 0, MEM_RELEASE); }
            }
        }
    }
}

// abort / _wassert / _invalid_parameter_noinfo_noreturn hooks: the crash terminates via
// ucrtbase!ExitProcess right after _wassert - an assertion or CRT fatal check failed.
// Capture the caller chain to find which game code tripped it.
using AbortFn = void(__cdecl*)(void);
using WassertFn = void(__cdecl*)(const wchar_t*, const wchar_t*, unsigned);
using InvParamNoRetFn = void(__cdecl*)(const wchar_t*, const wchar_t*, const wchar_t*, unsigned, uintptr_t);
AbortFn originalAbort = nullptr;
WassertFn originalWassert = nullptr;
InvParamNoRetFn originalInvParamNoRet = nullptr;

void DumpStackTrace(const char* tag) {
    unsigned long frames[32]{};
    const auto nf = CaptureStackBackTrace(0, 32, reinterpret_cast<void**>(frames), nullptr);
    std::string trace;
    for (DWORD i = 0; i < nf; ++i) {
        const auto desc = DescribeCaller(reinterpret_cast<void*>(frames[i]));
        if (desc.find("unknown") == std::string::npos) { trace += " " + desc; }
    }
    std::ofstream output(logPath, std::ios::app);
    output << tag << trace << '\n';
    output.flush();
}

void __cdecl HookAbort() {
    Log("ABORT called caller=" + DescribeCaller(_ReturnAddress()));
    DumpStackTrace("ABORT_STACK");
    // abort is noreturn; ALWAYS terminate so the process does not continue in a corrupted
    // stack and cascade into access violations. Fall back to ExitProcess if trampoline lost.
    if (originalAbort) originalAbort();
    ExitProcess(3);
}

// _purecall hook: captures the FULL call chain at the pure-virtual call site (the purecall
// handler runs with the real stack intact, unlike abort which is noreturn).
void __cdecl HookPurecall() {
    Log("PURECALL caller=" + DescribeCaller(_ReturnAddress()));
    DumpStackTrace("PURECALL_STACK");
    ExitProcess(3);
}

void __cdecl HookWassert(const wchar_t* expr, const wchar_t* file, unsigned line) {
    char buf[512]{};
    auto m = 0;
    m += sprintf_s(buf + m, sizeof(buf) - m, "WASSERT line=%u caller=%s", line, DescribeCaller(_ReturnAddress()).c_str());
    if (expr) {
        char e[256]{};
        WideCharToMultiByte(CP_UTF8, 0, expr, -1, e, sizeof(e), nullptr, nullptr);
        m += sprintf_s(buf + m, sizeof(buf) - m, " expr=%s", e);
    }
    if (file) {
        char f[256]{};
        WideCharToMultiByte(CP_UTF8, 0, file, -1, f, sizeof(f), nullptr, nullptr);
        m += sprintf_s(buf + m, sizeof(buf) - m, " file=%s", f);
    }
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    DumpStackTrace("WASSERT_STACK");
    if (originalWassert) originalWassert(expr, file, line);
}

void __cdecl HookInvParamNoRet(const wchar_t* expr, const wchar_t* func, const wchar_t* file, unsigned line, uintptr_t res) {
    char buf[512]{};
    auto m = 0;
    m += sprintf_s(buf + m, sizeof(buf) - m, "INVPPARAM_NORET line=%u caller=%s", line, DescribeCaller(_ReturnAddress()).c_str());
    if (func) {
        char e[256]{};
        WideCharToMultiByte(CP_UTF8, 0, func, -1, e, sizeof(e), nullptr, nullptr);
        m += sprintf_s(buf + m, sizeof(buf) - m, " func=%s", e);
    }
    std::ofstream output(logPath, std::ios::app);
    output << buf << '\n';
    output.flush();
    DumpStackTrace("INVPPARAM_STACK");
    if (originalInvParamNoRet) originalInvParamNoRet(expr, func, file, line, res);
}

void TryApplyCrtFatalHooks() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    // Hook BOTH the system ucrtbase and the client-private copy (the game loads a bundled
    // ucrtbase.dll; the crash may come from either instance).
    std::vector<HMODULE> crts;
    HMODULE exe = GetModuleHandleW(nullptr);
    if (exe) {
        wchar_t exePath[MAX_PATH]{};
        GetModuleFileNameW(exe, exePath, MAX_PATH);
        auto priv = std::filesystem::path(exePath).parent_path() / L"ucrtbase.dll";
        auto h = LoadLibraryW(priv.c_str());
        if (h) {
            crts.push_back(h);
            Log("CrtFatalHooks: private ucrtbase loaded");
        }
    }
    auto sys = GetModuleHandleW(L"ucrtbase.dll");
    if (sys) crts.push_back(sys);
    for (auto ucrt : crts) {
        if (!originalAbort)
            InstallCrtExportHook(ucrt, "abort", reinterpret_cast<void*>(&HookAbort),
                reinterpret_cast<void**>(&originalAbort));
        if (!originalWassert)
            InstallCrtExportHook(ucrt, "_wassert", reinterpret_cast<void*>(&HookWassert),
                reinterpret_cast<void**>(&originalWassert));
        if (!originalInvParamNoRet)
            InstallCrtExportHook(ucrt, "_invalid_parameter_noinfo_noreturn",
                reinterpret_cast<void*>(&HookInvParamNoRet),
                reinterpret_cast<void**>(&originalInvParamNoRet));
    }
    // VCRUNTIME140!__purecall: pure-virtual call -> abort. Hook it directly to capture the
    // FULL caller chain before abort unwinds the stack (abort itself is noreturn and the
    // stack trace there only shows our payload).
    auto vcruntime = GetModuleHandleW(L"VCRUNTIME140.dll");
    if (vcruntime) {
        InstallCrtExportHook(vcruntime, "_purecall", reinterpret_cast<void*>(&HookPurecall),
            reinterpret_cast<void**>(nullptr));
    }
    Log("CrtFatalHooks configured (" + std::to_string(crts.size()) + " ucrtbase copies)");
}

void InitializeHooks(HMODULE module) {
    wchar_t modulePath[MAX_PATH]{};
    GetModuleFileNameW(module, modulePath, MAX_PATH);
    const auto directory = std::filesystem::path(modulePath).parent_path();
    logPath = directory / L"BlueOath.Payload.log";

    // ͨ�ñ�������VEH + ExitProcess/NtTerminateProcess/CRT �쳣������
    AddVectoredExceptionHandler(1, &CrashVectoredHandler);
    TryApplyExitHooks();
    TryApplyInvalidParameterHook();
    Log("diagnostic crash hooks enabled");

    const auto config = (directory / L"bootstrap.ini").wstring();
    redirectEnabled = GetPrivateProfileIntW(L"redirect", L"enabled", 0, config.c_str()) != 0;
    redirectPort = static_cast<unsigned short>(GetPrivateProfileIntW(L"redirect", L"port", 0, config.c_str()));
    httpRedirectPort = static_cast<unsigned short>(GetPrivateProfileIntW(L"redirect", L"http_port", 0, config.c_str()));
    allowUntrusted = GetPrivateProfileIntW(L"trust", L"allow_untrusted", 0, config.c_str()) != 0;
    captureBugly = GetPrivateProfileIntW(L"redirect", L"capture_bugly", 0, config.c_str()) != 0;
    capturePort = static_cast<unsigned short>(GetPrivateProfileIntW(L"redirect", L"capture_port", 9887, config.c_str()));

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
#ifdef BLUEOATH_LUA_MODS
    StartLuaModLoader(module);
#endif

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
        // ���ܹ��ӣ�ά����Ϸ���߿��������裩�����̽����ȫ���Ƴ���
        TryApplyUnityTlsPatch();
        TryApplySdkTlsPatches();
        TryApplyNewSdkReportHooks();
#ifndef BLUEOATH_LUA_MODS
        TryApplyLuaPcallKHook();
#endif
        TryApplyDamageFacHook();
        TryApplyMainGunDamageFacPatch();
        TryApplyAttachedFleetsFix();
        TryApplyStageGotoHook();
        TryApplySdkLoginHook();
        TryApplyLoginMethodHook();
        TrySetSimulationMode();
        TrySetReview();
        const bool gameNetworkConnected = IsGameNetworkConnected();
        if (loginWebViewSuppressionEnabled && gameNetworkConnected) {
            loginWebViewSuppressionEnabled = false;
            Log("login WebView suppression disabled after game connection");
        }
        // Auto-login fallback: SDK event 29 (announcement WebView "open") does not always
        // fire headlessly. Repeatedly dispatch the fabricated login result (event 2) until
        // the game connects to the server. After login the server stays connected, so this
        // path is skipped once IsGameNetworkConnected() turns true.
        if (originalSdkCallback && !gameNetworkConnected &&
            GetTickCount64() >= loginFallbackStart) {
            if (!loginFallbackStarted) {
                loginFallbackStarted = true;
                Log("login fallback: auto-dispatching fabricated login result");
            }
            DispatchLoginEvent();
        }
        if (closeWebViewRequested && GetTickCount64() >= closeWebViewAt) {
            closeWebViewRequested = false;
            CloseSdkWebView();
        }
        if (loginWebViewSuppressionEnabled) HideCefWebView();
        if (getUserExtraSeen && GetTickCount64() - getUserExtraSeenAt >= 2000) {
            ForceMainStage();
        }
        Sleep(500);
    }
}
