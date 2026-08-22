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
void* getJsonDataGroupStolen = nullptr;
bool getJsonDataGroupHookApplied = false;
void* getJsonStrByBytesStolen = nullptr;
bool getJsonStrByBytesHookApplied = false;
void* assetLoadAsyncStolen = nullptr;
bool assetLoadAsyncHookApplied = false;
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
void* getComponentsNeedStolen = nullptr;
bool getComponentsNeedHookApplied = false;
uintptr_t getComponentsNeedResult = 0;
void* luaPcallKStolen = nullptr;
bool luaPcallKHookApplied = false;
int luaPcallKResult = 0;
uintptr_t luaPcallKLState = 0;

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

// GetJsonDataGroup(TableName, key) -> string[]: observe batch config reads.
void LogGetJsonDataGroup(void* self, void* tableName, void* key) {
    const auto t = ReadIl2CppString(tableName);
    Log("GetJsonDataGroup table=" + t + " key=" + ReadIl2CppString(key));
}

// GetJsonStrByBytes(bytes) -> string: static; record caller.
// GetJsonStrByBytes: called on EVERY config read; rate-limit to avoid flooding.
void LogGetJsonStrByBytes(void* bytes) {
    static volatile LONG bytesCount = 0;
    static volatile LONG lastLogMs = 0;
    const auto n = InterlockedIncrement(&bytesCount);
    const auto now = GetTickCount();
    const auto last = lastLogMs;
    if (n > 20) return;                       // first 20 total
    if (InterlockedCompareExchange(&lastLogMs, now, last) != last) return;
    Log(std::string("GetJsonStrByBytes caller=") + DescribeCaller(_ReturnAddress()));
}

void LogAssetLoadAsync(void* self, void* resourcePath, void* act) {
    const auto p = ReadIl2CppString(resourcePath);
    Log("LoadAsync " + p + " caller=" + DescribeCaller(_ReturnAddress()));
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

void LogStageGoto(void* self, int nextStateType, void* enterParam) {
    const char* typeName = "?";
    if (nextStateType == 1) typeName = "eStageLogin";
    else if (nextStateType == 2) typeName = "eStageMain";
    else if (nextStateType == 3) typeName = "eStageSimpleBattle";
    else if (nextStateType == 4) typeName = "eStagePvpBattle";
    else if (nextStateType == 5) typeName = "eStageLaunch";
    Log("StageMgr.Goto nextStateType=" + std::to_string(nextStateType) +
        " (" + typeName + ")" +
        " self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " enterParam=" + std::to_string(reinterpret_cast<uintptr_t>(enterParam)));
    if (nextStateType == 1) {
        stageMgrInstance = reinterpret_cast<uintptr_t>(self);
    }
    // 读取 MessageHelper.pbMap（在战斗阶段打印一次）
    if (nextStateType == 3 || nextStateType == 4) {
        auto ga = GetModuleHandleW(L"GameAssembly.dll");
        if (ga) {
            const auto base = reinterpret_cast<uintptr_t>(ga);
            const uintptr_t mhTypeInfo = ReadPtrSafe(base + 0x1D2E0C0);
            uintptr_t mhStatic = 0;
            if (mhTypeInfo) mhStatic = ReadPtrSafe(mhTypeInfo + 0x5C);
            uintptr_t pbMap = 0;
            if (mhStatic) pbMap = ReadPtrSafe(mhStatic);
            Log("  MessageHelper pbMap=" + std::to_string(pbMap) + " typeInfo=" + std::to_string(mhTypeInfo));
        }
    }
    // 战斗阶段：尝试读取 enterParam 中的 BattleStartData
    if (nextStateType == 3 || nextStateType == 4) {
        if (enterParam) {
            // enterParam 是 LuaTable（FSMParam），尝试读取关键字段
            const auto luaTable = reinterpret_cast<uintptr_t>(enterParam);
            Log("  Battle enterParam addr=" + std::to_string(luaTable));
            // 尝试读取 BattlePlayer (TBattlePlayerList)
            const auto bp = ReadPtrSafe(luaTable + 0x10); // LuaTable._array
            const auto bpLen = bp ? *reinterpret_cast<const int*>(reinterpret_cast<const char*>(luaTable) + 0x18) : 0;
            Log("  BattlePlayer ref=" + std::to_string(bp) + " len=" + std::to_string(bpLen));
            // 尝试读取 EnemyFleet
            const auto enemyRef = ReadPtrSafe(luaTable + 0x20);
            Log("  EnemyFleet ref=" + std::to_string(enemyRef));
        } else {
            Log("  enterParam is NULL — StageMgr.Goto called without battle data!");
        }
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

// xLua Lua 5.3 native layer (xlua.dll), used to inject shop_reddot into the
// widget LuaTable returned by GetComponentsNeed.
typedef void* LuaStateRaw;
typedef int(__cdecl* lua_rawgeti_t)(LuaStateRaw, int, long long);
typedef int(__cdecl* lua_getfield_t)(LuaStateRaw, int, const char*);
typedef void(__cdecl* lua_setfield_t)(LuaStateRaw, int, const char*);
typedef void(__cdecl* lua_settop_t)(LuaStateRaw, int);
typedef int(__cdecl* lua_type_t)(LuaStateRaw, int);
typedef int(__cdecl* lua_gettop_t)(LuaStateRaw);
typedef int(__cdecl* lua_next_t)(LuaStateRaw, int);
typedef void(__cdecl* lua_pushnil_t)(LuaStateRaw);
typedef const char*(__cdecl* lua_tolstring_t)(LuaStateRaw, int, size_t*);
typedef void(__cdecl* lua_createtable_t)(LuaStateRaw, int, int);
typedef void(__cdecl* lua_pushcclosure_t)(LuaStateRaw, int(__cdecl*)(LuaStateRaw), int);
typedef void(__cdecl* lua_pushinteger_t)(LuaStateRaw, long long);

lua_pushinteger_t g_pushInteger = nullptr;
lua_createtable_t g_createTable = nullptr;
lua_setfield_t g_setField = nullptr;

void LogLuaPcallError(void* L, int status) {
    if (status == 0) return;
    auto xlua = GetModuleHandleW(L"xlua.dll");
    if (!xlua) return;
    const auto tolstring = reinterpret_cast<lua_tolstring_t>(GetProcAddress(xlua, "lua_tolstring"));
    const auto gettop = reinterpret_cast<lua_gettop_t>(GetProcAddress(xlua, "lua_gettop"));
    size_t len = 0;
    const char* msg = tolstring ? tolstring(L, -1, &len) : nullptr;
    const int top = gettop ? gettop(L) : -1;
    if (msg && len > 0 && len < 65536) {
        Log("LuaPcallError status=" + std::to_string(status) + " top=" + std::to_string(top) +
            " msg=" + std::string(msg, len));
    } else {
        Log("LuaPcallError status=" + std::to_string(status) + " top=" + std::to_string(top) +
            " msg=<unreadable>");
    }
}

static int RedDotNoop(LuaStateRaw) { return 0; }

static int RedDotReturn0(LuaStateRaw L) {
    if (g_pushInteger) g_pushInteger(L, 0LL);
    return 1;
}

static int RedDotReturn2(LuaStateRaw L) {
    if (g_pushInteger) g_pushInteger(L, 2LL);
    return 1;
}

static int RedDotReturnEmptyTable(LuaStateRaw L) {
    if (g_createTable) g_createTable(L, 0, 0);
    return 1;
}

static int RedDotReturnImageTable(LuaStateRaw L) {
    if (g_createTable && g_setField) {
        g_createTable(L, 0, 0);  // outer {image = ...}
        g_createTable(L, 0, 0);  // inner image table
        g_setField(L, -2, "image");
    }
    return 1;
}

void InjectShopRedDot(void* table) {
    const auto luaEnv = ReadPtrSafe(reinterpret_cast<uintptr_t>(table) + 0x10);
    const auto L = reinterpret_cast<LuaStateRaw>(luaEnv ? ReadPtrSafe(luaEnv + 0x8) : 0);
    const auto luaRef = *reinterpret_cast<const int*>(reinterpret_cast<const char*>(table) + 0xC);
    if (!L || !luaRef) return;
    const auto xlua = GetModuleHandleW(L"xlua.dll");
    if (!xlua) return;
    const auto resolve = [&](const char* n) { return reinterpret_cast<void*>(GetProcAddress(xlua, n)); };
    const auto rawgeti = reinterpret_cast<lua_rawgeti_t>(resolve("lua_rawgeti"));
    const auto setfield = reinterpret_cast<lua_setfield_t>(resolve("lua_setfield"));
    const auto settop = reinterpret_cast<lua_settop_t>(resolve("lua_settop"));
    const auto gettop = reinterpret_cast<lua_gettop_t>(resolve("lua_gettop"));
    const auto createTable = reinterpret_cast<lua_createtable_t>(resolve("lua_createtable"));
    const auto pushcclosure = reinterpret_cast<lua_pushcclosure_t>(resolve("lua_pushcclosure"));
    const auto pushInteger = reinterpret_cast<lua_pushinteger_t>(resolve("lua_pushinteger"));
    if (!rawgeti || !setfield || !settop || !gettop || !createTable || !pushcclosure || !pushInteger) {
        Log("InjectShopRedDot: Lua API unresolved");
        return;
    }
    g_pushInteger = pushInteger;
    g_createTable = createTable;
    g_setField = setfield;
    constexpr int LUA_REGISTRYINDEX = -1001000;
    const int top = gettop(L);
    rawgeti(L, LUA_REGISTRYINDEX, static_cast<long long>(luaRef));  // push widget table

    const auto nextFn = reinterpret_cast<lua_next_t>(resolve("lua_next"));
    const auto pushnil = reinterpret_cast<lua_pushnil_t>(resolve("lua_pushnil"));
    const auto tolstring = reinterpret_cast<lua_tolstring_t>(resolve("lua_tolstring"));
    if (nextFn && pushnil && tolstring) {
        std::string keys;
        pushnil(L);
        while (nextFn(L, -2) != 0) {
            size_t len = 0;
            const char* k = tolstring(L, -2, &len);
            if (k && len > 0 && len < 256) {
                if (!keys.empty()) keys += ",";
                keys += std::string(k, len);
            }
            settop(L, -2);
        }
        Log("WidgetKeys: " + keys);
    }

    // Build a dummy red-dot Lua table with no-op methods so RegisterRedDotById
    // doesn't throw on the missing shop_reddot prefab widget.
    createTable(L, 0, 0);  // dummy
    pushcclosure(L, &RedDotNoop, 0); setfield(L, -2, "SetKeys");
    createTable(L, 0, 0);  // dummy.gameObject
    pushcclosure(L, &RedDotNoop, 0); setfield(L, -2, "SetActive");
    setfield(L, -2, "gameObject");
    pushcclosure(L, &RedDotReturn0, 0); setfield(L, -2, "GetId");
    pushcclosure(L, &RedDotNoop, 0); setfield(L, -2, "SetLuaFunction");
    pushcclosure(L, &RedDotReturnEmptyTable, 0); setfield(L, -2, "GetKeys");
    pushcclosure(L, &RedDotReturnEmptyTable, 0); setfield(L, -2, "GetImage");
    pushcclosure(L, &RedDotReturn2, 0); setfield(L, -2, "GetRedDotType");
    pushcclosure(L, &RedDotNoop, 0); setfield(L, -2, "GetToggle");
    pushcclosure(L, &RedDotNoop, 0); setfield(L, -2, "SetComment");
    pushcclosure(L, &RedDotNoop, 0); setfield(L, -2, "SetTextByNumber");

    setfield(L, -2, "shop_reddot");  // widgetTable["shop_reddot"] = dummy
    settop(L, top);
    Log("InjectShopRedDot: injected dummy shop_reddot");
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
    const int preview = length < 2048 ? length : 2048;
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

// MessageHelper.Unpack(Message message) - RVA 0x2A0830
// prologue: push ebp(1) mov ebp,esp(2) cmp(7) = 10 bytes
bool InstallStrArgHook(uintptr_t rva, void* trampoline, void** stolenOut, size_t stolenLen, const char* name);
void* messageHelperUnpackStolen = nullptr;
bool messageHelperUnpackHookApplied = false;
void LogMessageHelperUnpack(void* messageStart) {
    // messageStart = Message struct start (pushad + [esp+36])
    uintptr_t mStart = reinterpret_cast<uintptr_t>(messageStart);
    // Message layout: Time(0) Token(4) Payload(8) ErrCode(0xC) ErrMsg(0x10) Handle(0x14) Method(0x18) Seq(0x1C) IsResponse(0x20)
    uintptr_t methodPtr = 0;
    std::string methodStr = "null";
    uintptr_t payloadArr = 0;
    int payloadLen = 0;
    int isResp = 0;
    if (mStart) {
        methodPtr = ReadPtrSafe(mStart + 0x18);
        if (methodPtr) methodStr = ReadIl2CppString(reinterpret_cast<void*>(methodPtr));
        payloadArr = ReadPtrSafe(mStart + 0x8);
        if (payloadArr) payloadLen = static_cast<int>(ReadPtrSafe(payloadArr + 0xC));
        isResp = static_cast<int>(ReadPtrSafe(mStart + 0x20));
    }
    Log("MessageHelper.Unpack msg=" + std::to_string(mStart) +
        " method=" + methodStr +
        " payloadLen=" + std::to_string(payloadLen) +
        " isResponse=" + std::to_string(isResp));
    // Save the raw protobuf payload bytes of battle start responses to a dedicated file so
    // we can diff wire bytes against the decoded object without log truncation.
    if (methodStr == "copy.StartBase" && payloadArr && payloadLen > 0) {
        const uintptr_t items = ReadPtrSafe(payloadArr + 0x8);   // byte[] _items
        const auto base = reinterpret_cast<unsigned char*>(items);
        if (base) {
            auto path = logPath.parent_path() / L"startbase_wire.bin";
            std::ofstream out(path, std::ios::binary | std::ios::trunc);
            out.write(reinterpret_cast<const char*>(base), payloadLen);
            out.close();
            Log("startbase wire saved len=" + std::to_string(payloadLen));
        }
    }
}
__declspec(naked) void MessageHelperUnpackTrampoline() {
    __asm {
        // 入口: [esp]=retaddr, [esp+4]=Message 起始（或 Message*）
        mov eax, dword ptr [esp + 4]
        pushad
        push eax
        call LogMessageHelperUnpack
        add esp, 4
        popad
        jmp dword ptr [messageHelperUnpackStolen]
    }
}
void TryApplyMessageHelperUnpackHook() {
    if (messageHelperUnpackHookApplied) return;
    messageHelperUnpackHookApplied = true;
    InstallStrArgHook(0x2A0830, &MessageHelperUnpackTrampoline, &messageHelperUnpackStolen, 10, "MessageHelper.Unpack");
}

// CSharpToLuaFunc.GetQucikConditions(copyid, safelv) - RVA 0x33D8D0
// prologue: push ebp(1) mov ebp,esp(2) push ecx(1) cmp(7) = 11 bytes
void* getQucikConditionsStolen = nullptr;
bool getQucikConditionsHookApplied = false;
void LogGetQucikConditions(void* copyid, int safelv) {
    const auto s = copyid ? ReadIl2CppString(copyid) : "null";
    Log("GetQucikConditions copyid=" + s + " safelv=" + std::to_string(safelv));
}
__declspec(naked) void GetQucikConditionsTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]   // copyid (string)
        mov ecx, dword ptr [esp + 40]   // safelv (int)
        push ecx
        push eax
        call LogGetQucikConditions
        add esp, 8
        popad
        jmp dword ptr [getQucikConditionsStolen]
    }
}
void TryApplyGetQucikConditionsHook() {
    if (getQucikConditionsHookApplied) return;
    getQucikConditionsHookApplied = true;
    InstallStrArgHook(0x33D8D0, &GetQucikConditionsTrampoline, &getQucikConditionsStolen, 11, "GetQucikConditions");
}

// PVEStartData..ctor(TStartBaseRet ret) - RVA 0x58E780, prologue 24 bytes (SEH)
void* pveStartDataCtorStolen = nullptr;
bool pveStartDataCtorHookApplied = false;
void DumpStartBaseDecoded(uintptr_t r);
void LogPVEStartDataCtor(void* self, void* ret) {
    const auto s = reinterpret_cast<uintptr_t>(self);
    const auto r = reinterpret_cast<uintptr_t>(ret);
    // 读取 TStartBaseRet 字段: BattlePlayer(0x8) RandomSeed(0xC) Rid(0x10) CopyId(0x18)
    const auto battlePlayer = r ? ReadPtrSafe(r + 0x8) : 0;
    const auto randomSeed = r ? static_cast<int>(ReadPtrSafe(r + 0xC)) : 0;
    const auto rid = r ? static_cast<int>(ReadPtrSafe(r + 0x10)) : 0;
    int bpListLen = 0;
    uintptr_t fleetInfo = 0;
    int shipsLen = 0;
    int heroListLen = 0;
    uintptr_t firstBp = 0;
    if (battlePlayer) {
        // TBattlePlayerList: BattlePlayerList(List) 在 +0x8
        const auto bpList = ReadPtrSafe(battlePlayer + 0x8);
        if (bpList) {
            bpListLen = static_cast<int>(ReadPtrSafe(bpList + 0xC));
            if (bpListLen > 0) {
                // List 元素从 +0x10 开始
                firstBp = ReadPtrSafe(bpList + 0x10);
                if (firstBp) {
                    // TBattlePlayer.FleetInfo at +0x28
                    fleetInfo = ReadPtrSafe(firstBp + 0x28);
                    if (fleetInfo) {
                        // TBattleFleet.Ships(List) at +0x14
                        const auto ships = ReadPtrSafe(fleetInfo + 0x14);
                        if (ships) shipsLen = static_cast<int>(ReadPtrSafe(ships + 0xC));
                        // TBattleFleet.HeroList at +0x24
                        const auto heroList = ReadPtrSafe(fleetInfo + 0x24);
                        if (heroList) heroListLen = static_cast<int>(ReadPtrSafe(heroList + 0xC));
                    }
                }
            }
        }
    }
    Log("PVEStartData..ctor self=" + std::to_string(s) +
        " ret=" + std::to_string(r) +
        " BattlePlayer=" + std::to_string(battlePlayer) + " bpLen=" + std::to_string(bpListLen) +
        " FleetInfo=" + std::to_string(fleetInfo) +
        " shipsLen=" + std::to_string(shipsLen) +
        " heroListLen=" + std::to_string(heroListLen) +
        " RandomSeed=" + std::to_string(randomSeed) +
        " Rid=" + std::to_string(rid));
    DumpStartBaseDecoded(r);
}
__declspec(naked) void PVEStartDataCtorTrampoline() {
    __asm {
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        mov eax, dword ptr [esp + 68]   // self
        mov ecx, dword ptr [esp + 72]   // ret
        push ecx
        push eax
        call LogPVEStartDataCtor
        add esp, 8
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        jmp dword ptr [pveStartDataCtorStolen]
    }
}
void TryApplyPVEStartDataCtorHook() {
    if (pveStartDataCtorHookApplied) return;
    pveStartDataCtorHookApplied = true;
    InstallStrArgHook(0x58E780, &PVEStartDataCtorTrampoline, &pveStartDataCtorStolen, 24, "PVEStartData..ctor");
}

// Dump the fully-deserialized TStartBaseRet object to startbase_decoded.txt (readable),
// alongside the raw wire bytes saved by the Unpack hook. Fields per dump.cs TypeDefIndex 8980.
void DumpStartBaseDecoded(uintptr_t r) {
    if (!r) return;
    auto path = logPath.parent_path() / L"startbase_decoded.txt";
    std::ofstream out(path, std::ios::trunc);
    if (!out) return;
    char tmp[512]{};
    auto line = [&](const std::string& s) { out << s << '\n'; };
    auto il = [](uintptr_t p) -> std::string { return p ? std::to_string(p) : "null"; };
    auto readInt = [](uintptr_t p, int off) { return static_cast<int>(ReadPtrSafe(p + off)); };
    auto readStr = [](uintptr_t p, int off) -> std::string {
        auto s = ReadPtrSafe(p + off);
        return s ? ReadIl2CppString(reinterpret_cast<void*>(s)) : "<null>";
    };
    auto readListLen = [](uintptr_t p, int off) {
        auto l = ReadPtrSafe(p + off);
        return l ? static_cast<int>(ReadPtrSafe(l + 0xC)) : -1;
    };
    auto readListElem = [](uintptr_t p, int off, int idx) -> uintptr_t {
        auto l = ReadPtrSafe(p + off);          // List object
        if (!l) return 0;
        auto arr = ReadPtrSafe(l + 0x8);        // _items (array)
        if (!arr) return 0;
        auto size = static_cast<int>(ReadPtrSafe(l + 0xC));
        if (idx >= size) return 0;
        return ReadPtrSafe(arr + 0x10 + idx * 4);  // array element refs start at +0x10
    };

    line("=== TStartBaseRet obj=" + il(r) + " ===");
    line("BattlePlayer(0x8)=" + il(ReadPtrSafe(r + 0x8)));
    line("RandomSeed(0xC)=" + std::to_string(readInt(r, 0xC)));
    line("Rid(0x10)=" + std::to_string(readInt(r, 0x10)));
    line("arrRes(0x14) len=" + std::to_string(readListLen(r, 0x14)));
    line("EnemyFleet(0x18) len=" + std::to_string(readListLen(r, 0x18)));
    line("CopyId(0x1C)=" + std::to_string(readInt(r, 0x1C)));
    line("CopyType(0x20)=" + std::to_string(readInt(r, 0x20)));
    line("CopyPass(0x24)=" + std::to_string(readInt(r, 0x24)));
    line("BossProgress(0x28)=" + std::to_string(readInt(r, 0x28)));
    line("IsRunningFight(0x2C)=" + std::to_string(readInt(r, 0x2C)));
    line("ShipEquipGridInfo(0x30) len=" + std::to_string(readListLen(r, 0x30)));
    line("RandomFactors(0x34) len=" + std::to_string(readListLen(r, 0x34)));
    line("SafeLv(0x38)=" + std::to_string(readInt(r, 0x38)));
    line("Verify(0x3C)=" + il(ReadPtrSafe(r + 0x3C)));
    line("ExtraBattlePlayerList(0x40) len=" + std::to_string(readListLen(r, 0x40)));
    line("Token(0x44)=" + readStr(r, 0x44));
    line("SkipVcr(0x48) len=" + std::to_string(readListLen(r, 0x48)));
    line("BattleMode(0x4C)=" + std::to_string(readInt(r, 0x4C)));
    line("IsFinal(0x50)=" + std::to_string(readInt(r, 0x50)));
    line("AnimMode(0x54)=" + std::to_string(readInt(r, 0x54)));
    line("WeatherGroupId(0x58)=" + std::to_string(readInt(r, 0x58)));
    line("CopyMission(0x5C) len=" + std::to_string(readListLen(r, 0x5C)));
    line("EnemyFleets(0x60) len=" + std::to_string(readListLen(r, 0x60)));
    line("ConfigData(0x64) len=" + std::to_string(readListLen(r, 0x64)));
    line("MatchType(0x68)=" + std::to_string(readInt(r, 0x68)));

    // BattlePlayer -> TBattlePlayerList.BattlePlayerList(List at +0x8)
    auto bp = ReadPtrSafe(r + 0x8);
    auto bpList = bp ? ReadPtrSafe(bp + 0x8) : 0;
    auto bpLen = bpList ? static_cast<int>(ReadPtrSafe(bpList + 0xC)) : 0;
    line("  BattlePlayerList len=" + std::to_string(bpLen));
    for (int i = 0; i < bpLen && i < 4; ++i) {
        auto p = readListElem(bp, 0x8, i);
        if (!p) continue;
        line("    Player[" + std::to_string(i) + "] Pid=" + std::to_string(readInt(p, 0x8)) +
             " Uid=" + std::to_string(ReadPtrSafe(p + 0x10)) +
             " Uname=" + readStr(p, 0x18) +
             " Level=" + std::to_string(readInt(p, 0x1C)) +
             " PlayerCamp=" + std::to_string(readInt(p, 0x20)) +
             " Index=" + std::to_string(readInt(p, 0x24)) +
             " FleetInfo=" + il(ReadPtrSafe(p + 0x28)) +
             " OpenFunc len=" + std::to_string(readListLen(p, 0x2C)) +
             " BattleMode=" + std::to_string(readInt(p, 0x30)));
        auto fleet = ReadPtrSafe(p + 0x28);
        if (fleet) {
            line("      Fleet: FleetId=" + std::to_string(readInt(fleet, 0x8)) +
                 " FormationId=" + std::to_string(readInt(fleet, 0xC)) +
                 " Index=" + std::to_string(readInt(fleet, 0x10)) +
                 " Ships len=" + std::to_string(readListLen(fleet, 0x14)) +
                 " StrategyId=" + std::to_string(readInt(fleet, 0x18)) +
                 " KillTimes=" + std::to_string(readInt(fleet, 0x20)) +
                 " HeroList len=" + std::to_string(readListLen(fleet, 0x24)) +
                 " TacticType=" + std::to_string(readInt(fleet, 0x28)));
            // dump ship ids/templates
            auto n = readListLen(fleet, 0x14);
            for (int j = 0; j < n && j < 8; ++j) {
                auto sh = readListElem(fleet, 0x14, j);
                if (!sh) continue;
                line("        Ship[" + std::to_string(j) + "] HeroId=" + std::to_string(readInt(sh, 0x8)) +
                     " TemplateId=" + std::to_string(readInt(sh, 0xC)) +
                     " Level=" + std::to_string(readInt(sh, 0x10)) +
                     " Index=" + std::to_string(readInt(sh, 0x14)) +
                     " Attr len=" + std::to_string(readListLen(sh, 0x18)) +
                     " CurHp=" + std::to_string(ReadPtrSafe(sh + 0x20)) +
                     " PSkill len=" + std::to_string(readListLen(sh, 0x2C)) +
                     " EquipGridNum=" + std::to_string(readInt(sh, 0x38)) +
                     " Fashioning=" + std::to_string(readInt(sh, 0x3C)));
            }
        }
    }

    // EnemyFleets (0x60): List<TBattleEnemyFleet>
    auto efs = ReadPtrSafe(r + 0x60);
    auto efn = efs ? static_cast<int>(ReadPtrSafe(efs + 0xC)) : 0;
    line("  EnemyFleets len=" + std::to_string(efn));
    for (int i = 0; i < efn && i < 4; ++i) {
        auto ef = readListElem(r, 0x60, i);
        if (!ef) continue;
        line("    EF[" + std::to_string(i) + "] FleetId=" + std::to_string(readInt(ef, 0x8)) +
             " State=" + std::to_string(readInt(ef, 0xC)) +
             " Ships len=" + std::to_string(readListLen(ef, 0x10)));
        auto esn = readListLen(ef, 0x10);
        for (int j = 0; j < esn && j < 6; ++j) {
            auto sh = readListElem(ef, 0x10, j);
            if (!sh) continue;
            line("      Ship[" + std::to_string(j) + "] ShipId=" + std::to_string(readInt(sh, 0x8)) +
                 " shipInfoId=" + std::to_string(readInt(sh, 0x10)) +
                 " lv=" + std::to_string(readInt(sh, 0x18)));
        }
    }
    out.close();
    Log("startbase decoded written");
}

// IL2CPP throw exception - RVA 0x11633DF0
// prologue: push ebp(1) mov ebp,esp(2) sub esp,8(3) = 6 bytes
void* throwExceptionStolen = nullptr;
bool throwExceptionHookApplied = false;
void LogThrowException(void* arg0) {
    // arg0 = 异常参数（可能是类型 index 或对象）
    Log("IL2CPP ThrowException arg0=" + std::to_string(reinterpret_cast<uintptr_t>(arg0)));
}
__declspec(naked) void ThrowExceptionTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogThrowException
        add esp, 4
        popad
        jmp dword ptr [throwExceptionStolen]
    }
}
void TryApplyThrowExceptionHook() {
    if (throwExceptionHookApplied) return;
    throwExceptionHookApplied = true;
    InstallStrArgHook(0x11633DF0, &ThrowExceptionTrampoline, &throwExceptionStolen, 6, "IL2CPP.ThrowException");
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

__declspec(naked) void GetJsonDataGroupTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 44]
        push edx
        push ecx
        push eax
        call LogGetJsonDataGroup
        add esp, 12
        popad
        jmp dword ptr [getJsonDataGroupStolen]
    }
}

__declspec(naked) void GetJsonStrByBytesTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogGetJsonStrByBytes
        add esp, 4
        popad
        jmp dword ptr [getJsonStrByBytesStolen]
    }
}

__declspec(naked) void AssetLoadAsyncTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 44]
        push edx
        push ecx
        push eax
        call LogAssetLoadAsync
        add esp, 12
        popad
        jmp dword ptr [assetLoadAsyncStolen]
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

// POST-CALL hook: after the original GetComponentsNeed returns, inject shop_reddot.
__declspec(naked) void GetComponentsNeedTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 44]
        mov ecx, dword ptr [esp + 40]
        mov edx, dword ptr [esp + 36]
        push eax
        push ecx
        push edx
        call dword ptr [getComponentsNeedStolen]
        add esp, 12
        mov dword ptr [getComponentsNeedResult], eax
        push eax
        call InjectShopRedDot
        add esp, 4
        popad
        mov eax, dword ptr [getComponentsNeedResult]
        ret
    }
}

// POST-CALL hook on xlua.dll lua_pcallk (L, nargs, nresults, errfunc, ctx, k).
// Captures the error message left on the Lua stack when the protected call fails.
__declspec(naked) void LuaPcallKTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]   ; L
        mov dword ptr [luaPcallKLState], eax
        mov ecx, dword ptr [esp + 40]   ; nargs
        mov edx, dword ptr [esp + 44]   ; nresults
        mov ebx, dword ptr [esp + 48]   ; errfunc
        mov esi, dword ptr [esp + 52]   ; ctx
        mov edi, dword ptr [esp + 56]   ; k
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
        je no_err
        push eax
        push dword ptr [luaPcallKLState]
        call LogLuaPcallError
        add esp, 8
    no_err:
        popad
        mov eax, dword ptr [luaPcallKResult]
        ret
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

bool InstallXluaExportHook(const char* exportName, void* trampoline, void** stolenOut, size_t stolenLen, const char* name) {
    auto xlua = GetModuleHandleW(L"xlua.dll");
    if (!xlua) return false;
    const auto proc = GetProcAddress(xlua, exportName);
    if (!proc) return false;
    auto address = reinterpret_cast<unsigned char*>(proc);
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

void* stageGetStartDataStolen = nullptr;
bool stageGetStartDataHookApplied = false;

// StageSimpleBattle._getStartData(FSMParam enterParam) - RVA 0x1EFC00
// NOTE: prologue is push ebp(1)+mov ebp,esp(2)+sub esp,0x28(3)+cmp byte[0x11D453A1],0(7).
// stolenLen must be 13 (covers the full cmp) - 11 cuts through it and crashes.
void LogStageGetStartData(void* self, void* enterParam) {
    const auto ep = reinterpret_cast<uintptr_t>(enterParam);
    // FSMParam.param at +0xC (boxed Message)
    const auto boxedMsg = ReadPtrSafe(ep + 0xC);
    // boxed Message: value fields start at +0x8, Method struct offset 0x18 => boxed+0x20
    const auto methodStr = boxedMsg ? ReadIl2CppString(reinterpret_cast<void*>(ReadPtrSafe(boxedMsg + 0x20))) : "null";
    // Payload (byte[]) struct offset 0x8 => boxed+0x10; Il2CppArray: klass(0) monitor(4) bounds(8) max_length(0xC)
    uintptr_t payloadArr = 0;
    uintptr_t payloadLen = 0;
    payloadArr = boxedMsg ? ReadPtrSafe(boxedMsg + 0x10) : 0;
    if (payloadArr) payloadLen = ReadPtrSafe(payloadArr + 0xC);
    Log("StageSimpleBattle._getStartData self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " enterParam=" + std::to_string(ep) +
        " boxedMsg=" + std::to_string(boxedMsg) +
        " method=" + methodStr +
        " payloadArr=" + std::to_string(payloadArr) +
        " payloadLen=" + std::to_string(payloadLen));
    // Read MessageHelper.pbMap keys
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (ga) {
        const auto base = reinterpret_cast<uintptr_t>(ga);
        const uintptr_t mhTypeInfo = ReadPtrSafe(base + 0x1D2E0C0);
        uintptr_t mhStatic = 0;
        if (mhTypeInfo) mhStatic = ReadPtrSafe(mhTypeInfo + 0x5C);
        uintptr_t pbMap = 0;
        if (mhStatic) pbMap = ReadPtrSafe(mhStatic);
        // Mono Dictionary<string,Type> IL2CPP object: fields start at +0x8
        // table(+0x8) linkSlots(+0xC) keySlots(+0x10) valueSlots(+0x14) touchedSlots(+0x18)
        // emptySlot(+0x1C) count(+0x20) threshold(+0x24) hcp(+0x28)
        const auto keySlots = pbMap ? ReadPtrSafe(pbMap + 0x10) : 0;
        const auto count = pbMap ? static_cast<int>(ReadPtrSafe(pbMap + 0x20)) : 0;
        Log("  pbMap=" + std::to_string(pbMap) + " count=" + std::to_string(count) +
            " keySlots=" + std::to_string(keySlots));
        // keySlots is string[] (Il2CppArray): elements start at +0xC
        if (keySlots && count > 0) {
            const auto elemBase = keySlots + 0xC;
            for (int i = 0; i < std::min(count, 12); i++) {
                const auto key = ReadPtrSafe(elemBase + (uintptr_t)i * 4);
                const auto keyStr = key ? ReadIl2CppString(reinterpret_cast<void*>(key)) : "null";
                Log("    keySlots[" + std::to_string(i) + "]=" + keyStr);
            }
        }
    }
}

__declspec(naked) void StageGetStartDataTrampoline() {
    __asm {
        // 保存 XMM0/XMM1，避免 Log 破坏 _getStartData 的浮点状态
        // 入口: [esp]=retaddr, [esp+4]=self, [esp+8]=enterParam
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        // pushad 32 + xmm区 32 = 64; [esp+64]=retaddr, [esp+68]=self, [esp+72]=enterParam
        mov eax, dword ptr [esp + 68]
        mov ecx, dword ptr [esp + 72]
        push ecx
        push eax
        call LogStageGetStartData
        add esp, 8
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        jmp dword ptr [stageGetStartDataStolen]
    }
}

void TryApplyStageGetStartDataHook() {
    if (stageGetStartDataHookApplied) return;
    stageGetStartDataHookApplied = true;
    InstallStrArgHook(0x1EFC00, &StageGetStartDataTrampoline, &stageGetStartDataStolen, 13, "StageSimpleBattle._getStartData");
}

// ---- 战斗初始化链追踪 ----
void DumpBattleStartData(uintptr_t d);
// initBattle(self, enterParam) - RVA 0x1F0150, prologue: push ebp(1) mov ebp,esp(2) push esi(1) mov esi,[ebp+8](3) = 7 bytes
void* initBattleStolen = nullptr;
bool initBattleHookApplied = false;
void LogInitBattle(void* self, void* enterParam) {
    const auto s = reinterpret_cast<uintptr_t>(self);
    // StageSimpleBattle 字段: 0x18=changeState, 0x24=mBattleFrame, 0x2C=mStartData, 0x30=mSingleFrame
    const auto changeState = ReadPtrSafe(s + 0x18);
    const auto mBattleFrame = ReadPtrSafe(s + 0x24);
    const auto mStartData = ReadPtrSafe(s + 0x2C);
    const auto mSingleFrame = ReadPtrSafe(s + 0x30);
    Log("StageSimpleBattle.initBattle self=" + std::to_string(s) +
        " enterParam=" + std::to_string(reinterpret_cast<uintptr_t>(enterParam)) +
        " changeState=" + std::to_string(changeState) +
        " mBattleFrame=" + std::to_string(mBattleFrame) +
        " mStartData=" + std::to_string(mStartData) +
        " mSingleFrame=" + std::to_string(mSingleFrame));
}
static void* gStartDataResult = nullptr;
static int gStartDataException = 0;
static uintptr_t gStartDataExObj = 0;
static uintptr_t gStartDataExAddr = 0;
static DWORD gExParamCount = 0;
static uintptr_t gExParams[4] = {0,0,0,0};

typedef void* (__cdecl* GetStartDataFn)(void*, void*, void*);

static int StartDataFilter(void* exceptInfoPtr) {
    gStartDataExObj = 0;
    gStartDataExAddr = 0;
    gExParamCount = 0;
    auto* rec = reinterpret_cast<EXCEPTION_RECORD*>(exceptInfoPtr);
    if (rec) {
        gStartDataExAddr = (uintptr_t)rec->ExceptionAddress;
        gExParamCount = rec->NumberParameters;
        for (DWORD i = 0; i < rec->NumberParameters && i < 4; i++)
            gExParams[i] = (uintptr_t)rec->ExceptionInformation[i];
        // MSVC C++ exception ABI (code 0xE0434352): [0]=0x19930520 magic,
        // [1]=thrown object = Il2CppExceptionWrapper*, [2]=ThrowInfo*.
        if (rec->NumberParameters > 1) gStartDataExObj = (uintptr_t)rec->ExceptionInformation[1];
    }
    return EXCEPTION_EXECUTE_HANDLER;
}

void* CallStartDataSafe(GetStartDataFn fn, void* self, void* enterParam) {
    __try {
        return fn(self, enterParam, 0);
    } __except (StartDataFilter(GetExceptionInformation()->ExceptionRecord)) {
        gStartDataException = GetExceptionCode();
        return nullptr;
    }
}

typedef int (__cdecl* IsInGuideFn)();

int CallIsInGuideSafe(IsInGuideFn fn) {
    __try {
        return fn();
    } __except (StartDataFilter(GetExceptionInformation()->ExceptionRecord)) {
        gStartDataException = GetExceptionCode();
        return 0;
    }
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

// Read a null-terminated UTF-16 string in-process (CRT _invalid_parameter args are wchar_t*).
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

static volatile bool gInBattleStartData = false;
static volatile bool gBattleStarted = false;
static volatile bool gInCxxThrowHook = false;
static int gCxxThrowCount = 0;

void* LogCallGetStartData(void* self, void* enterParam) {
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) { Log("initBattle GetModuleHandle failed"); return nullptr; }
    // 先单独测试 IsInGuide (0x33DEA0)，确认异常是否在它里面
    gStartDataException = 0;
    gStartDataExObj = 0;
    gExParamCount = 0;
    typedef int (__cdecl* IsInGuideFn)();
    auto isInGuide = reinterpret_cast<IsInGuideFn>(reinterpret_cast<uintptr_t>(ga) + 0x33DEA0);
    int guideResult = CallIsInGuideSafe(isInGuide);
    if (gStartDataException) {
        Log("IsInGuide EXCEPTION code=" + std::to_string(gStartDataException));
        return nullptr;
    }
    Log("IsInGuide result=" + std::to_string(guideResult));

    auto fn = reinterpret_cast<GetStartDataFn>(reinterpret_cast<uintptr_t>(ga) + 0x1EFC00);
    gStartDataResult = nullptr;
    gStartDataException = 0;
    gStartDataExObj = 0;
    gExParamCount = 0;
    gInBattleStartData = true;
    gStartDataResult = CallStartDataSafe(fn, self, enterParam);
    gInBattleStartData = false;
    if (gStartDataException) {
        uintptr_t wrapper = gStartDataExObj;
        // At the SEH filter the wrapper may be clobbered by _CxxThrowException;
        // try several candidate offsets to find the Il2CppException*.
        uintptr_t ex = 0;
        if (wrapper) {
            for (int off = 0; off <= 0x10; off += 4) {
                uintptr_t cand = ReadPtrSafe(wrapper + off);
                if (!cand) continue;
                uintptr_t k = ReadPtrSafe(cand + 0x0);
                uintptr_t nm = ReadPtrSafe(k + 0x8);
                if (k && nm) { ex = cand; break; }
            }
        }
        if (ex) {
            uintptr_t klass = ReadPtrSafe(ex + 0x0);
            uintptr_t msgPtr = ReadPtrSafe(ex + 0x8);
            uintptr_t stPtr = ReadPtrSafe(ex + 0xC);
            uintptr_t traceIps = ReadPtrSafe(ex + 0x18);
            std::string className = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0x8)) : "?";
            std::string nameSpace = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0xC)) : "?";
            Log("initBattle _getStartData EXCEPTION code=" + std::to_string(gStartDataException) +
                " wrapper=" + std::to_string(wrapper) +
                " ex=" + std::to_string(ex) +
                " class=" + nameSpace + "." + className +
                " msg=" + (msgPtr ? ReadIl2CppString(reinterpret_cast<void*>(msgPtr)) : "<null>") +
                " st=" + (stPtr ? ReadIl2CppString(reinterpret_cast<void*>(stPtr)) : "<null>") +
                " traceIps=" + std::to_string(traceIps) +
                " p0=" + std::to_string(gExParams[0]) +
                " p1=" + std::to_string(gExParams[1]) +
                " p2=" + std::to_string(gExParams[2]));
        } else {
            Log("initBattle _getStartData EXCEPTION code=" + std::to_string(gStartDataException) +
                " wrapper=" + std::to_string(wrapper) +
                " p0=" + std::to_string(gExParams[0]) +
                " p1=" + std::to_string(gExParams[1]) +
                " p2=" + std::to_string(gExParams[2]));
        }
    } else {
        Log("initBattle _getStartData result=" + std::to_string(reinterpret_cast<uintptr_t>(gStartDataResult)));
        if (gStartDataResult) {
            gBattleStarted = true;
            DumpBattleStartData(reinterpret_cast<uintptr_t>(gStartDataResult));
        }
    }
    return gStartDataResult;
}

// Dump the constructed BattleStartData object fields to startdata_decoded.txt. This reveals
// how the client interpreted our TStartBaseRet: players/enemys/skipVcrs/battleMode etc.
void DumpBattleStartData(uintptr_t d) {
    if (!d) return;
    auto path = logPath.parent_path() / L"startdata_decoded.txt";
    std::ofstream out(path, std::ios::trunc);
    if (!out) return;
    char tmp[256]{};
    auto w = [&](const std::string& s) { out << s << '\n'; };
    auto p = [&](const char* name, int off) {
        sprintf_s(tmp, "%s(0x%X)=0x%X", name, off, static_cast<unsigned>(ReadPtrSafe(d + off)));
        w(tmp);
    };
    w("=== BattleStartData obj=" + std::to_string(d) + " ===");
    p("copyDisplayId", 0x8);
    p("copyDictId", 0xC);
    p("players", 0x38);
    p("enemys", 0x3C);
    p("copyRess", 0x70);
    p("skipVcrs", 0x88);
    p("safeLv", 0x8C);
    p("functionRet", 0x90);
    p("enemyFleetId", 0x94);
    p("battleMode", 0x98);
    p("battleAnimMode", 0x9C);
    p("weatherGroupId", 0xA0);
    p("ConfigDatas", 0xA4);
    p("copyMissionId", 0xA8);
    // players list
    auto pl = ReadPtrSafe(d + 0x38);
    if (pl) {
        auto arr = ReadPtrSafe(pl + 0x8);
        auto n = static_cast<int>(ReadPtrSafe(pl + 0xC));
        sprintf_s(tmp, "  players len=%d", n); w(tmp);
        for (int i = 0; i < n && i < 4; ++i) {
            auto e = arr ? ReadPtrSafe(arr + 0x10 + i * 4) : 0;
            sprintf_s(tmp, "    player[%d]=0x%X", i, static_cast<unsigned>(e)); w(tmp);
            if (e) {
                auto fl = ReadPtrSafe(e + 0x28);
                sprintf_s(tmp, "      fleet=0x%X ships=", static_cast<unsigned>(fl)); w(tmp);
                if (fl) {
                    auto s = ReadPtrSafe(fl + 0x14);
                    auto sn = s ? static_cast<int>(ReadPtrSafe(s + 0xC)) : 0;
                    auto sa = s ? ReadPtrSafe(s + 0x8) : 0;
                    sprintf_s(tmp, "      ships len=%d ids=", sn); w(tmp);
                    for (int j = 0; j < sn && j < 6; ++j) {
                        auto sh = sa ? ReadPtrSafe(sa + 0x10 + j * 4) : 0;
                        if (sh) sprintf_s(tmp, "        ship[%d] hero=%d tmpl=%d", j,
                            static_cast<int>(ReadPtrSafe(sh + 0x8)),
                            static_cast<int>(ReadPtrSafe(sh + 0xC))), w(tmp);
                    }
                }
            }
        }
    }
    // enemys list
    auto el = ReadPtrSafe(d + 0x3C);
    if (el) {
        auto arr = ReadPtrSafe(el + 0x8);
        auto n = static_cast<int>(ReadPtrSafe(el + 0xC));
        sprintf_s(tmp, "  enemys len=%d", n); w(tmp);
        for (int i = 0; i < n && i < 4; ++i) {
            auto e = arr ? ReadPtrSafe(arr + 0x10 + i * 4) : 0;
            sprintf_s(tmp, "    enemy[%d]=0x%X", i, static_cast<unsigned>(e)); w(tmp);
            if (e) {
                sprintf_s(tmp, "      dictID=%d ships=%X attached=%X", 
                    static_cast<int>(ReadPtrSafe(e + 0x8)),
                    static_cast<unsigned>(ReadPtrSafe(e + 0x10)),
                    static_cast<unsigned>(ReadPtrSafe(e + 0x14))); w(tmp);
            }
        }
    }
    // skipVcrs
    auto sv = ReadPtrSafe(d + 0x88);
    if (sv) {
        auto arr = ReadPtrSafe(sv + 0x8);
        auto n = static_cast<int>(ReadPtrSafe(sv + 0xC));
        sprintf_s(tmp, "  skipVcrs len=%d", n); w(tmp);
    }
    // enemyFleetId int[]
    auto ef = ReadPtrSafe(d + 0x94);
    if (ef) {
        auto arr = ReadPtrSafe(ef + 0x8);
        auto n = static_cast<int>(ReadPtrSafe(ef + 0xC));
        sprintf_s(tmp, "  enemyFleetId len=%d values=", n); w(tmp);
        for (int j = 0; j < n && j < 6; ++j) {
            int v = arr ? static_cast<int>(ReadPtrSafe(arr + 0x10 + j * 4)) : 0;
            sprintf_s(tmp, "    [%d]=%d", j, v); w(tmp);
        }
    }
    out.close();
    Log("startdata decoded written");
}

// ---- _CxxThrowException (GameAssembly static CRT, RVA 0x169F9EF) ----
// Prologue: push ebp(1) mov ebp,esp(2) mov ecx,[ebp+0xC](3) = 6 bytes.
// Entry: [esp]=retaddr, [esp+4]=pExceptionObject(Il2CppExceptionWrapper*),
//        [esp+8]=pThrowInfo. At entry the wrapper is intact: ex = *(wrapper).
// This is the single funnel for ALL C++ throws from GameAssembly managed code;
// the thrower's native stack is still intact here (RaiseException runs later).
void* cxxThrowStolen = nullptr;
bool cxxThrowHookApplied = false;

void LogCxxThrow(void* exObj, void* throwInfo) {
    if (gInCxxThrowHook) return;
    if (!gInBattleStartData) return;
    if (gCxxThrowCount >= 8) return;
    gCxxThrowCount++;
    gInCxxThrowHook = true;
    uintptr_t ga = reinterpret_cast<uintptr_t>(GetModuleHandleW(L"GameAssembly.dll"));
    std::string stack;
    void* frames[16] = {nullptr};
    const USHORT n = RtlCaptureStackBackTrace(0, 16, frames, nullptr);
    for (USHORT i = 0; i < n; i++) {
        uintptr_t fRva = ga ? reinterpret_cast<uintptr_t>(frames[i]) - ga : 0;
        char tmp[24]{};
        sprintf_s(tmp, "%llX,", static_cast<unsigned long long>(fRva));
        stack += tmp;
    }
    // wrapper intact here: ex = *(wrapper)
    uintptr_t ex = exObj ? ReadPtrSafe(reinterpret_cast<uintptr_t>(exObj)) : 0;
    uintptr_t klass = ex ? ReadPtrSafe(ex + 0x0) : 0;
    uintptr_t msgPtr = ex ? ReadPtrSafe(ex + 0x8) : 0;
    uintptr_t stPtr = ex ? ReadPtrSafe(ex + 0xC) : 0;
    std::string className = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0x8)) : "?";
    std::string nameSpace = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0xC)) : "?";
    Log("CxxThrow wrapper=" + std::to_string(reinterpret_cast<uintptr_t>(exObj)) +
        " ex=" + std::to_string(ex) +
        " class=" + nameSpace + "." + className +
        " msg=" + (msgPtr ? ReadIl2CppString(reinterpret_cast<void*>(msgPtr)) : "<null>") +
        " st=" + (stPtr ? ReadIl2CppString(reinterpret_cast<void*>(stPtr)) : "<null>") +
        " stack=" + stack);
    gInCxxThrowHook = false;
}

__declspec(naked) void CxxThrowTrampoline() {
    __asm {
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        // pushad 32 + xmm 32 = 64: [esp+64]=retaddr, [esp+68]=exObj, [esp+72]=throwInfo
        mov eax, dword ptr [esp + 68]
        mov ecx, dword ptr [esp + 72]
        push ecx
        push eax
        call LogCxxThrow
        add esp, 8
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        jmp dword ptr [cxxThrowStolen]
    }
}
void TryApplyCxxThrowHook() {
    if (cxxThrowHookApplied) return;
    cxxThrowHookApplied = true;
    InstallStrArgHook(0x169F9EF, &CxxThrowTrampoline, &cxxThrowStolen, 6, "_CxxThrowException");
}

// ---- IL2CPP managed raise helper (RVA 0x1633D20) ----
// Common funnel for ALL managed exception raises (IndexOutOfRange, NRE, ...):
// NRE: 0x3025CB -> 0x1633DF0 -> 0x1633DD0 -> 0x1633D20.
// Prologue: push ebp(1) mov ebp,esp(2) push ecx(1) mov eax,[ebp+8](3) = 7 bytes.
// Entry: [esp]=retaddr, [esp+4]=Il2CppException* (arg0), thrower stack intact.
void* raiseHelperStolen = nullptr;
bool raiseHelperHookApplied = false;
static int gRaiseHelperCount = 0;

void LogRaiseHelper(void* exPtr) {
    if (!gInBattleStartData) return;
    if (gRaiseHelperCount >= 12) return;
    gRaiseHelperCount++;
    uintptr_t ga = reinterpret_cast<uintptr_t>(GetModuleHandleW(L"GameAssembly.dll"));
    std::string stack;
    void* frames[16] = {nullptr};
    const USHORT n = RtlCaptureStackBackTrace(0, 16, frames, nullptr);
    for (USHORT i = 0; i < n; i++) {
        uintptr_t fRva = ga ? reinterpret_cast<uintptr_t>(frames[i]) - ga : 0;
        char tmp[24]{};
        sprintf_s(tmp, "%llX,", static_cast<unsigned long long>(fRva));
        stack += tmp;
    }
    const uintptr_t p = reinterpret_cast<uintptr_t>(exPtr);
    uintptr_t klass = p ? ReadPtrSafe(p + 0x0) : 0;
    uintptr_t msgPtr = p ? ReadPtrSafe(p + 0x8) : 0;
    uintptr_t stPtr = p ? ReadPtrSafe(p + 0xC) : 0;
    std::string className = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0x8)) : "?";
    std::string nameSpace = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0xC)) : "?";
    Log("RaiseHelper ex=" + std::to_string(p) +
        " class=" + nameSpace + "." + className +
        " msg=" + (msgPtr ? ReadIl2CppString(reinterpret_cast<void*>(msgPtr)) : "<null>") +
        " st=" + (stPtr ? ReadIl2CppString(reinterpret_cast<void*>(stPtr)) : "<null>") +
        " stack=" + stack);
}

__declspec(naked) void RaiseHelperTrampoline() {
    __asm {
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        // pushad 32 + xmm 32 = 64: [esp+68]=arg0 (Il2CppException*)
        mov eax, dword ptr [esp + 68]
        push eax
        call LogRaiseHelper
        add esp, 4
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        jmp dword ptr [raiseHelperStolen]
    }
}
void TryApplyRaiseHelperHook() {
    if (raiseHelperHookApplied) return;
    raiseHelperHookApplied = true;
    InstallStrArgHook(0x1633D20, &RaiseHelperTrampoline, &raiseHelperStolen, 7, "raiseHelper");
}

// ---- config_copy lookup (RVA 0x95B750) ----
// PVEStartData..ctor calls it with arg1 = boxed CopyId; if it returns null the
// ctor raises NRE at 0x58F93B. Log the copyId used for the lookup.
// Prologue: push ebp(1) mov ebp,esp(2) cmp byte[mem],0(7) = 10 bytes.
void* configLookupStolen = nullptr;
bool configLookupHookApplied = false;

void LogConfigLookup(void* boxed, uintptr_t ctorEbp) {
    if (!gInBattleStartData) return;
    int val = -1;
    std::string raw;
    std::string klassName = "?";
    if (boxed) {
        uintptr_t p = reinterpret_cast<uintptr_t>(boxed);
        uintptr_t k = ReadPtrSafe(p);
        if (k) {
            klassName = ReadAsciiCStr(ReadPtrSafe(k + 0x8));
            val = *reinterpret_cast<int*>(reinterpret_cast<char*>(boxed) + 8);
        }
        char tmp[16];
        for (int i = 0; i < 16; i++) {
            sprintf_s(tmp, "%02X ", *reinterpret_cast<unsigned char*>(p + i));
            raw += tmp;
        }
    }
    std::string locals;
    if (ctorEbp) {
        char tmp[24];
        for (int off = -0x40; off <= -0x14; off += 4) {
            sprintf_s(tmp, " [e%X]=0x%X", -off, static_cast<unsigned>(ReadPtrSafe(ctorEbp + off)));
            locals += tmp;
        }
    }
    std::string tbl;
    {
        uintptr_t ga = reinterpret_cast<uintptr_t>(GetModuleHandleW(L"GameAssembly.dll"));
        uintptr_t singleton = ga ? ReadPtrSafe(ga + 0x1D2CB64) : 0;
        uintptr_t mid = singleton ? ReadPtrSafe(singleton + 0x5C) : 0;
        uintptr_t mgr = mid ? ReadPtrSafe(mid + 0x4) : 0;
        uintptr_t table = mgr ? ReadPtrSafe(mgr + 0xF4) : 0;
        uintptr_t dict = table ? ReadPtrSafe(table + 0x8) : 0;
        char tmp[96];
        sprintf_s(tmp, " sing=0x%X mgr=0x%X tbl=0x%X dict=0x%X",
            static_cast<unsigned>(singleton), static_cast<unsigned>(mgr),
            static_cast<unsigned>(table), static_cast<unsigned>(dict));
        tbl = tmp;
        // dict raw (first 0x24 bytes) + count candidates
        if (dict) {
            char r[160];
            int n = 0;
            n += sprintf_s(r + n, sizeof(r) - n, " dictRaw=");
            for (int i = 0; i < 0x24; i += 4) {
                n += sprintf_s(r + n, sizeof(r) - n, "%X ",
                    static_cast<unsigned>(ReadPtrSafe(dict + i)));
            }
            n += sprintf_s(r + n, sizeof(r) - n, " cnt8=%u cnt10=%u cnt20=%u",
                static_cast<unsigned>(ReadPtrSafe(dict + 0x8)),
                static_cast<unsigned>(ReadPtrSafe(dict + 0x10)),
                static_cast<unsigned>(ReadPtrSafe(dict + 0x20)));
            tbl += r;
        }
        // mgr klass name
        uintptr_t mgrKlass = mgr ? ReadPtrSafe(mgr) : 0;
        std::string mgrName = mgrKlass ? ReadAsciiCStr(ReadPtrSafe(mgrKlass + 0x8)) : "?";
        tbl += " mgrClass=" + mgrName;
        uintptr_t tblKlass = table ? ReadPtrSafe(table) : 0;
        std::string tblName = tblKlass ? ReadAsciiCStr(ReadPtrSafe(tblKlass + 0x8)) : "?";
        tbl += " tblClass=" + tblName;
    }
    Log("ConfigLookup boxed=" + std::to_string(reinterpret_cast<uintptr_t>(boxed)) +
        " klass=" + klassName +
        " val8=" + std::to_string(val) +
        " raw=" + raw +
        " ctor" + locals +
        tbl);
}

__declspec(naked) void ConfigLookupTrampoline() {
    __asm {
        // entry: [esp]=retaddr, [esp+4]=arg0(0), [esp+8]=arg1(boxed), [esp+0xC]=arg2(0)
        // EBP = ctor frame (0x95b750 does push ebp; mov ebp,esp so EBP currently = caller's frame)
        mov eax, ebp
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        // pushad 32 + xmm 32 = 64: [esp+64]=retaddr, [esp+68]=arg0, [esp+72]=arg1(boxed)
        // saved ctor EBP (from mov eax,ebp) at [esp+76]? no: pushad pushed 8 regs, eax saved
        push eax                    // ctor EBP (we saved it in eax)
        push dword ptr [esp + 4 + 72]   // arg1 boxed
        call LogConfigLookup
        add esp, 8
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        jmp dword ptr [configLookupStolen]
    }
}
void TryApplyConfigLookupHook() {
    if (configLookupHookApplied) return;
    configLookupHookApplied = true;
    InstallStrArgHook(0x95B750, &ConfigLookupTrampoline, &configLookupStolen, 10, "configLookup");
}

// ---- PVEStartData..ctor NRE raise state dump (RVA 0x58F960) ----
// The ctor converges all null-checks to 0x58F960 (call NRE raise). We patch the
// call with a jmp that dumps the ctor's EBP-frame locals + this->fields so the
// failing check can be identified. Then mimic the call into 0x1633df0.
void* ctorRaiseNreTarget = nullptr;

void LogCtorRaise(uintptr_t ebp) {
    if (!gInBattleStartData) return;
    char tmp[48];
    std::string line = "CtorRaise";
    sprintf_s(tmp, " ebp=0x%X", static_cast<unsigned>(ebp)); line += tmp;
    const uintptr_t self = ReadPtrSafe(ebp + 8);
    const uintptr_t ret = ReadPtrSafe(ebp + 0xC);
    sprintf_s(tmp, " this=0x%X ret=0x%X", static_cast<unsigned>(self), static_cast<unsigned>(ret)); line += tmp;
    if (self) {
        for (int off = 0x8; off <= 0xb8; off += 4) {
            sprintf_s(tmp, " [%02X]=0x%X", off, static_cast<unsigned>(ReadPtrSafe(self + off))); line += tmp;
        }
    }
    if (ret) {
        // TStartBaseRet list/object fields: arrRes(0x14) EnemyFleet(0x18) ShipEquipGridInfo(0x30)
        // RandomFactors(0x34) Verify(0x3C) ExtraBattlePlayerList(0x40) Token(0x44) SkipVcr(0x48)
        // CopyMission(0x5C) EnemyFleets(0x60) ConfigData(0x64)
        for (int off = 0x14; off <= 0x64; off += 4) {
            sprintf_s(tmp, " r[%02X]=0x%X", off, static_cast<unsigned>(ReadPtrSafe(ret + off))); line += tmp;
        }
    }
    if (ebp) {
        for (int off = -0x40; off <= -0x14; off += 4) {
            const int o = off < 0 ? -off : off;
            sprintf_s(tmp, " [e%X]=0x%X", o, static_cast<unsigned>(ReadPtrSafe(ebp + off))); line += tmp;
        }
        // enemy container [ebp-0x1c]: List layout _items(+8) _size(+0xC); elements at _items array +0x10
        uintptr_t container = ReadPtrSafe(ebp - 0x1C);
        if (container) {
            uintptr_t items = ReadPtrSafe(container + 0x8);
            sprintf_s(tmp, " contCnt=%u cont0=0x%X",
                static_cast<unsigned>(ReadPtrSafe(container + 0xC)),
                static_cast<unsigned>(items ? ReadPtrSafe(items + 0x10) : 0));
            line += tmp;
        }
        // [ebp-0x20] = config lookup result (e20); dump its klass name + +0x28
        uintptr_t e20 = ReadPtrSafe(ebp - 0x20);
        if (e20) {
            uintptr_t ek = ReadPtrSafe(e20);
            std::string en = ek ? ReadAsciiCStr(ReadPtrSafe(ek + 0x8)) : "?";
            sprintf_s(tmp, " e20Class=%s e2028=0x%X",
                en.c_str(), static_cast<unsigned>(ReadPtrSafe(e20 + 0x28)));
            line += tmp;
        }
    }
    Log(line);
}

__declspec(naked) void CtorRaiseTrampoline() {
    __asm {
        // entry: EBP = ctor frame, [esp]=0 (pushed arg), no call retaddr pushed
        push ebp
        mov ebp, esp
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        // saved ctor EBP is at [esp+64] (pushed at entry before our frame)
        mov eax, dword ptr [esp + 64]
        push eax
        call LogCtorRaise
        add esp, 4
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        pop ebp
        push 0x58F965              // mimic original call return address
        jmp dword ptr [ctorRaiseNreTarget]
    }
}
void TryApplyCtorRaiseHook() {
    static bool applied = false;
    if (applied) return;
    applied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    uintptr_t base = reinterpret_cast<uintptr_t>(ga);
    ctorRaiseNreTarget = reinterpret_cast<void*>(base + 0x1633DF0);
    auto address = reinterpret_cast<unsigned char*>(base + 0x58F960);
    const unsigned char expected[] = { 0xE8 };
    if (memcmp(address, expected, 1) != 0) {
        Log("CtorRaise hook refused: not a call");
        return;
    }
    const auto tramp = reinterpret_cast<uintptr_t>(&CtorRaiseTrampoline);
    const auto rel = static_cast<int32_t>(tramp - (reinterpret_cast<uintptr_t>(address) + 5));
    DWORD oldProtect = 0;
    if (!VirtualProtect(address, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    address[0] = 0xE9;
    memcpy(address + 1, &rel, 4);
    VirtualProtect(address, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), address, 5);
    Log("CtorRaise hook applied");
}

__declspec(naked) void InitBattleTrampoline() {
    __asm {
        // 接管 initBattle: 调用原始 _getStartData 并记录返回值
        // 入口(jmp进入): [esp]=retaddr, [esp+4]=self, [esp+8]=enterParam
        push ebp
        mov ebp, esp
        // [ebp+0]=旧ebp, [ebp+4]=retaddr, [ebp+8]=self, [ebp+0xc]=enterParam
        sub esp, 32
        movups xmmword ptr [esp], xmm0
        movups xmmword ptr [esp + 16], xmm1
        pushad
        push dword ptr [ebp + 0xc]    // enterParam
        push dword ptr [ebp + 8]      // self
        call LogInitBattle
        add esp, 8
        popad
        movups xmm0, xmmword ptr [esp]
        movups xmm1, xmmword ptr [esp + 16]
        add esp, 32
        // LogCallGetStartData(self, enterParam) -> eax
        push dword ptr [ebp + 0xc]
        push dword ptr [ebp + 8]
        call LogCallGetStartData
        add esp, 8
        // 保存到 [self+0x2c]
        mov ecx, dword ptr [ebp + 8]
        mov dword ptr [ecx + 0x2c], eax
        pop ebp
        ret
    }
}
void TryApplyInitBattleHook() {
    if (initBattleHookApplied) return;
    initBattleHookApplied = true;
    InstallStrArgHook(0x1F0150, &InitBattleTrampoline, &initBattleStolen, 7, "StageSimpleBattle.initBattle");
}

// StageBegin(self) - RVA 0x1EF2F0, prologue: push ebp(1) mov ebp,esp(2) push ecx(1) cmp byte[0x11D453A7],0(7) = 11 bytes
void* stageBeginStolen = nullptr;
bool stageBeginHookApplied = false;
void LogStageBegin(void* self) {
    Log("StageSimpleBattle.StageBegin self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}
__declspec(naked) void StageBeginTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogStageBegin
        add esp, 4
        popad
        jmp dword ptr [stageBeginStolen]
    }
}
void TryApplyStageBeginHook() {
    if (stageBeginHookApplied) return;
    stageBeginHookApplied = true;
    InstallStrArgHook(0x1EF2F0, &StageBeginTrampoline, &stageBeginStolen, 11, "StageSimpleBattle.StageBegin");
}

// LoadingTick(self) - RVA 0x1EF290, prologue: push ebp(1) mov ebp,esp(2) mov eax,[ebp+8](3) push esi(1) = 7 bytes
void* loadingTickStolen = nullptr;
bool loadingTickHookApplied = false;
void LogLoadingTick(void* self) {
    const auto s = reinterpret_cast<uintptr_t>(self);
    const auto changeState = ReadPtrSafe(s + 0x18);
    const auto mBattleFrame = ReadPtrSafe(s + 0x24);
    const auto mStartData = ReadPtrSafe(s + 0x2C);
    const auto mSingleFrame = ReadPtrSafe(s + 0x30);
    static int loadingTickCount = 0;
    if (loadingTickCount < 8) {
        char tmp[64];
        std::string extra;
        uintptr_t ga = reinterpret_cast<uintptr_t>(GetModuleHandleW(L"GameAssembly.dll"));
        uintptr_t loader = ga ? ReadPtrSafe(ga + 0x1D2C350) : 0;
        uintptr_t mid = loader ? ReadPtrSafe(loader + 0x5C) : 0;
        uintptr_t obj = mid ? ReadPtrSafe(mid + 0x4) : 0;
        int f19 = -1, f1a = -1;
        int f25 = -1;
        if (obj) {
            MEMORY_BASIC_INFORMATION m{};
            if (VirtualQuery(reinterpret_cast<void*>(obj + 0x19), &m, sizeof(m)) &&
                m.State == MEM_COMMIT && !(m.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
                f19 = *reinterpret_cast<unsigned char*>(obj + 0x19);
                f1a = *reinterpret_cast<unsigned char*>(obj + 0x1A);
            }
        }
        if (mid) {
            MEMORY_BASIC_INFORMATION m{};
            if (VirtualQuery(reinterpret_cast<void*>(mid + 0x25), &m, sizeof(m)) &&
                m.State == MEM_COMMIT && !(m.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
                f25 = *reinterpret_cast<unsigned char*>(mid + 0x25);
            }
        }
        sprintf_s(tmp, " loader=0x%X mid=0x%X obj=0x%X f19=%d f1a=%d mid25=%d",
            static_cast<unsigned>(loader), static_cast<unsigned>(mid),
            static_cast<unsigned>(obj), f19, f1a, f25);
        extra = tmp;
        if (mSingleFrame) {
            MEMORY_BASIC_INFORMATION m{};
            int fin18 = -1, fin19 = -1;
            if (VirtualQuery(reinterpret_cast<void*>(mSingleFrame + 0x18), &m, sizeof(m)) &&
                m.State == MEM_COMMIT && !(m.Protect & (PAGE_NOACCESS | PAGE_GUARD))) {
                fin18 = *reinterpret_cast<unsigned char*>(mSingleFrame + 0x18);
                fin19 = *reinterpret_cast<unsigned char*>(mSingleFrame + 0x19);
            }
            sprintf_s(tmp, " frame18=%d frame19=%d view=0x%X field=0x%X",
                fin18, fin19,
                static_cast<unsigned>(ReadPtrSafe(mSingleFrame + 0x34)),
                static_cast<unsigned>(ReadPtrSafe(mSingleFrame + 0x38)));
            extra += tmp;
        }
        Log("StageSimpleBattle.LoadingTick self=" + std::to_string(s) +
            " changeState=" + std::to_string(changeState) +
            " mBattleFrame=" + std::to_string(mBattleFrame) +
            " mStartData=" + std::to_string(mStartData) +
            " mSingleFrame=" + std::to_string(mSingleFrame) +
            " ctrl=0x" + std::to_string(ReadPtrSafe(s + 0x8)) +
            " ctrlLoading=" + std::to_string(ReadPtrSafe(ReadPtrSafe(s + 0x8) + 0x18)) +
            " rlm=0x" + std::to_string(ReadPtrSafe(ReadPtrSafe(s + 0x8) + 0x24)) +
            " tSum=" + std::to_string(ReadPtrSafe(ReadPtrSafe(ReadPtrSafe(s + 0x8) + 0x24) + 0x10)) +
            " tLoader=" + std::to_string(ReadPtrSafe(ReadPtrSafe(ReadPtrSafe(s + 0x8) + 0x24) + 0x18)) +
            " fin=" + std::to_string(ReadPtrSafe(ReadPtrSafe(ReadPtrSafe(s + 0x8) + 0x24) + 0x1C)) +
            extra);
        loadingTickCount++;
    }
}
__declspec(naked) void LoadingTickTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogLoadingTick
        add esp, 4
        popad
        jmp dword ptr [loadingTickStolen]
    }
}
void TryApplyLoadingTickHook() {
    if (loadingTickHookApplied) return;
    loadingTickHookApplied = true;
    InstallStrArgHook(0x1EF290, &LoadingTickTrampoline, &loadingTickStolen, 7, "StageSimpleBattle.LoadingTick");
}

// ---- ResLoadMgr.AddRes(self, type, res, userCB, maxNum) RVA 0x1E4B90 ----
// Log the resource being queued for loading.
void* addResStolen = nullptr;
bool addResHookApplied = false;
void LogAddRes(void* self, void* type, void* res) {
    Log("AddRes self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " type=" + std::to_string(reinterpret_cast<uintptr_t>(type)) +
        " res=" + ReadIl2CppString(res));
}
__declspec(naked) void AddResTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]   // self
        mov ecx, dword ptr [esp + 40]   // type
        mov edx, dword ptr [esp + 44]   // res
        push edx
        push ecx
        push eax
        call LogAddRes
        add esp, 12
        popad
        jmp dword ptr [addResStolen]
    }
}
void TryApplyAddResHook() {
    if (addResHookApplied) return;
    addResHookApplied = true;
    InstallStrArgHook(0x1E4B90, &AddResTrampoline, &addResStolen, 10, "ResLoadMgr.AddRes");
}

// ---- SceneLoader.StartLoad (RVA 0x1E81B0) ----
void* sceneLoadStartStolen = nullptr;
bool sceneLoadStartHookApplied = false;
void LogSceneLoadStart(void* self) {
    Log("SceneLoader.StartLoad self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}
__declspec(naked) void SceneLoadStartTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogSceneLoadStart
        add esp, 4
        popad
        jmp dword ptr [sceneLoadStartStolen]
    }
}
void TryApplySceneLoadStartHook() {
    if (sceneLoadStartHookApplied) return;
    sceneLoadStartHookApplied = true;
    InstallStrArgHook(0x1E81B0, &SceneLoadStartTrampoline, &sceneLoadStartStolen, 10, "SceneLoader.StartLoad");
}

// ---- scene load resolve (RVA 0x12500B0) ----
void* sceneLoadResolveStolen = nullptr;
bool sceneLoadResolveHookApplied = false;
void LogSceneLoadResolve(void* self, void* sceneName) {
    Log("SceneLoadResolve sceneName=" + ReadIl2CppString(sceneName));
}
__declspec(naked) void SceneLoadResolveTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]   // arg1 = sceneName
        push eax
        call LogSceneLoadResolve
        add esp, 4
        popad
        jmp dword ptr [sceneLoadResolveStolen]
    }
}
void TryApplySceneLoadResolveHook() {
    if (sceneLoadResolveHookApplied) return;
    sceneLoadResolveHookApplied = true;
    InstallStrArgHook(0x12500B0, &SceneLoadResolveTrampoline, &sceneLoadResolveStolen, 8, "sceneLoadResolve");
}

// ---- ResLoadMgr.StartLoad (RVA 0x1E5800) ----
void* startLoadStolen = nullptr;
bool startLoadHookApplied = false;
void LogStartLoad(void* self, void* cb) {
    Log("ResLoadMgr.StartLoad self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " cb=" + std::to_string(reinterpret_cast<uintptr_t>(cb)));
}
__declspec(naked) void StartLoadTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogStartLoad
        add esp, 8
        popad
        jmp dword ptr [startLoadStolen]
    }
}
void TryApplyStartLoadHook() {
    if (startLoadHookApplied) return;
    startLoadHookApplied = true;
    InstallStrArgHook(0x1E5800, &StartLoadTrampoline, &startLoadStolen, 6, "ResLoadMgr.StartLoad");
}

// ---- ResLoadMgr.StartLoadPrior (RVA 0x1E56D0) ----
void* startLoadPriorStolen = nullptr;
bool startLoadPriorHookApplied = false;
void LogStartLoadPrior(void* self, void* prior) {
    Log("ResLoadMgr.StartLoadPrior self=" + std::to_string(reinterpret_cast<uintptr_t>(self)) +
        " prior=" + std::to_string(reinterpret_cast<uintptr_t>(prior)));
}
__declspec(naked) void StartLoadPriorTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        mov ecx, dword ptr [esp + 40]
        push ecx
        push eax
        call LogStartLoadPrior
        add esp, 8
        popad
        jmp dword ptr [startLoadPriorStolen]
    }
}
void TryApplyStartLoadPriorHook() {
    if (startLoadPriorHookApplied) return;
    startLoadPriorHookApplied = true;
    InstallStrArgHook(0x1E56D0, &StartLoadPriorTrampoline, &startLoadPriorStolen, 11, "ResLoadMgr.StartLoadPrior");
}

// ---- changeScene(sceneID) RVA 0x1EAD80 ----
void* changeSceneStolen = nullptr;
bool changeSceneHookApplied = false;
void LogChangeScene(void* self, void* sceneId) {
    Log("changeScene sceneId=" + ReadIl2CppString(sceneId));
}
__declspec(naked) void ChangeSceneTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]   // arg1 = sceneId
        push eax
        call LogChangeScene
        add esp, 4
        popad
        jmp dword ptr [changeSceneStolen]
    }
}
void TryApplyChangeSceneHook() {
    if (changeSceneHookApplied) return;
    changeSceneHookApplied = true;
    InstallStrArgHook(0x1EAD80, &ChangeSceneTrampoline, &changeSceneStolen, 10, "changeScene");
}

// ---- scene lookup (DictDataManager) RVA 0x956450 ----
void* sceneLookupStolen = nullptr;
bool sceneLookupHookApplied = false;
void LogSceneLookup(void* self, void* sceneId) {
    Log("SceneLookup sceneId=" + std::to_string(reinterpret_cast<uintptr_t>(sceneId)));
}
__declspec(naked) void SceneLookupTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]   // arg1 = sceneId (an int)
        push eax
        call LogSceneLookup
        add esp, 4
        popad
        jmp dword ptr [sceneLookupStolen]
    }
}
void TryApplySceneLookupHook() {
    if (sceneLookupHookApplied) return;
    sceneLookupHookApplied = true;
    InstallStrArgHook(0x956450, &SceneLookupTrampoline, &sceneLookupStolen, 10, "SceneLookup");
}

// ---- DelayGoto (RVA 0x1ECBD0) ----
void* delayGotoStolen = nullptr;
bool delayGotoHookApplied = false;
void LogDelayGoto(void* self) {
    Log("DelayGoto self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}
__declspec(naked) void DelayGotoTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogDelayGoto
        add esp, 4
        popad
        jmp dword ptr [delayGotoStolen]
    }
}
void TryApplyDelayGotoHook() {
    if (delayGotoHookApplied) return;
    delayGotoHookApplied = true;
    InstallStrArgHook(0x1ECBD0, &DelayGotoTrampoline, &delayGotoStolen, 10, "DelayGoto");
}

// ---- OnStageStartFin (RVA 0x1ECF40) ----
void* onStageStartFinStolen = nullptr;
bool onStageStartFinHookApplied = false;
void LogOnStageStartFin(void* self) {
    Log("OnStageStartFin self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}
__declspec(naked) void OnStageStartFinTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogOnStageStartFin
        add esp, 4
        popad
        jmp dword ptr [onStageStartFinStolen]
    }
}
void TryApplyOnStageStartFinHook() {
    if (onStageStartFinHookApplied) return;
    onStageStartFinHookApplied = true;
    InstallStrArgHook(0x1ECF40, &OnStageStartFinTrampoline, &onStageStartFinStolen, 6, "OnStageStartFin");
}

// initBattleFrame(self) - RVA 0x1F00E0, prologue: push ebp(1) mov ebp,esp(2) cmp byte[0x11D453A5],0(7) = 10 bytes
void* initBattleFrameStolen = nullptr;
bool initBattleFrameHookApplied = false;
void LogInitBattleFrame(void* self) {
    Log("StageSimpleBattle.initBattleFrame self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}
__declspec(naked) void InitBattleFrameTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogInitBattleFrame
        add esp, 4
        popad
        jmp dword ptr [initBattleFrameStolen]
    }
}
void TryApplyInitBattleFrameHook() {
    if (initBattleFrameHookApplied) return;
    initBattleFrameHookApplied = true;
    InstallStrArgHook(0x1F00E0, &InitBattleFrameTrampoline, &initBattleFrameStolen, 10, "StageSimpleBattle.initBattleFrame");
}

// createBattleFrame(self) - RVA 0x1EFAB0, prologue: push ebp(1) mov ebp,esp(2) cmp byte[0x11D453A4],0(7) = 10 bytes
void* createBattleFrameStolen = nullptr;
bool createBattleFrameHookApplied = false;
void LogCreateBattleFrame(void* self) {
    Log("StageSimpleBattle.createBattleFrame self=" + std::to_string(reinterpret_cast<uintptr_t>(self)));
}
__declspec(naked) void CreateBattleFrameTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]
        push eax
        call LogCreateBattleFrame
        add esp, 4
        popad
        jmp dword ptr [createBattleFrameStolen]
    }
}
void TryApplyCreateBattleFrameHook() {
    if (createBattleFrameHookApplied) return;
    createBattleFrameHookApplied = true;
    InstallStrArgHook(0x1EFAB0, &CreateBattleFrameTrampoline, &createBattleFrameStolen, 10, "StageSimpleBattle.createBattleFrame");
}

void* shipPBConvertStolen = nullptr;
bool shipPBConvertHookApplied = false;

void LogShipPBConvert(void* lShip, void* retAddr) {
    const auto ls = reinterpret_cast<uintptr_t>(lShip);
    const auto heroId = ReadPtrSafe(ls + 0x8);
    const auto templateId = ReadPtrSafe(ls + 0xC);
    uintptr_t retVa = reinterpret_cast<uintptr_t>(retAddr);
    uintptr_t rva = retVa >= 0x10000000u ? (retVa - 0x10000000u) : retVa;
    char hexBuf[16];
    sprintf_s(hexBuf, "%X", static_cast<unsigned int>(rva));
    Log("Ship.PBConvert lShip=" + std::to_string(ls) +
        " retRVA=0x" + hexBuf +
        " HeroId=" + std::to_string(heroId) +
        " TemplateId=" + std::to_string(templateId));
}

__declspec(naked) void ShipPBConvertTrampoline() {
    __asm {
        pushad
        // 静态方法：IL2CPP 调用约定第一个栈参数是 this(=null)，lShip 在第二个参数位置
        // pushad 后: [esp+32]=返回地址, [esp+40]=lShip
        mov edx, dword ptr [esp + 32]   // 返回地址（调用者）
        mov ecx, dword ptr [esp + 40]   // lShip
        push edx
        push ecx
        call LogShipPBConvert
        add esp, 8
        popad
        jmp dword ptr [shipPBConvertStolen]
    }
}

void TryApplyShipPBConvertHook() {
    if (shipPBConvertHookApplied) return;
    shipPBConvertHookApplied = true;
    // prologue: push ebp(1) mov ebp,esp(2) push -1(2) push imm(5) mov eax,fs:[0](6) push eax(1)
    // boundary at offset 17 (after push eax) - 17 bytes covers these instructions fully
    InstallStrArgHook(0x307F20, &ShipPBConvertTrampoline, &shipPBConvertStolen, 17, "Ship.PBConvert");
}

void TryApplyLuaPcallKHook() {
    if (luaPcallKHookApplied) return;
    if (InstallXluaExportHook("lua_pcallk", &LuaPcallKTrampoline, &luaPcallKStolen, 14, "lua_pcallk")) {
        luaPcallKHookApplied = true;
    }
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

void* internalLogExceptionStolen = nullptr;
bool internalLogExceptionHookApplied = false;

void LogInternalLogException(void* ex, void* obj) {
    std::string type = "?";
    std::string msg = "?";
    std::string st = "?";
    if (ex) {
        const auto exAddr = reinterpret_cast<uintptr_t>(ex);
        const auto klass = ReadPtrSafe(exAddr);
        const auto className = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0x8)) : "";
        const auto nameSpace = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0xC)) : "";
        type = nameSpace + "." + className;
        msg = ReadIl2CppString(reinterpret_cast<void*>(ReadPtrSafe(exAddr + 0x8)));
        st = ReadIl2CppString(reinterpret_cast<void*>(ReadPtrSafe(exAddr + 0xC)));
    }
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "UnityException type=" << type << " msg=" << msg
        << " caller=" << DescribeCaller(_ReturnAddress()) << '\n';
    output << "UnityException stack=" << st << '\n';
    output.flush();
}

__declspec(naked) void InternalLogExceptionTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 40]   // obj
        push eax
        mov ecx, dword ptr [esp + 40]   // ex
        push ecx
        call LogInternalLogException
        add esp, 8
        popad
        jmp dword ptr [internalLogExceptionStolen]
    }
}

void TryApplyInternalLogExceptionHook() {
    if (internalLogExceptionHookApplied) return;
    internalLogExceptionHookApplied = true;
    InstallStrArgHook(0xE50220, &InternalLogExceptionTrampoline, &internalLogExceptionStolen, 10, "UnityEngine.DebugLogHandler.Internal_LogException");
}

void* isHitStolen = nullptr;
bool isHitHookApplied = false;
using IsHitFn = bool (__cdecl*)(void*, double, double);
IsHitFn originalIsHit = nullptr;

void LogIsHitResult(double hit, double dodge, bool result) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "__IsHit hit=" << std::to_string(hit) << " dodge=" << std::to_string(dodge)
        << " result=" << (result ? "true" : "false")
        << " caller=" << DescribeCaller(_ReturnAddress()) << '\n';
    output.flush();
}

bool __cdecl HookIsHit(void* this_, double hit, double dodge) {
    const auto caller = _ReturnAddress();
    const auto result = originalIsHit(this_, hit, dodge);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "__IsHit hit=" << std::to_string(hit) << " dodge=" << std::to_string(dodge)
        << " result=" << (result ? "true" : "false")
        << " caller=" << DescribeCaller(caller) << '\n';
    output.flush();
    return result;
}

void TryApplyIsHitHook() {
    if (isHitHookApplied) return;
    isHitHookApplied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    auto fn = reinterpret_cast<unsigned char*>(ga) + 0x5281B0;
    // stolenLen=13: push ebp(1) mov ebp,esp(2) movsd(5) subsd(5) = 13, clean boundary
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 13);
    const auto backRel = static_cast<int32_t>((reinterpret_cast<uintptr_t>(fn) + 13) - (reinterpret_cast<uintptr_t>(tramp) + 18));
    tramp[13] = 0xE9;
    memcpy(tramp + 14, &backRel, 4);
    originalIsHit = reinterpret_cast<IsHitFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookIsHit);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 13, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    memcpy(fn, jump, 5);
    for (size_t i = 5; i < 13; ++i) fn[i] = 0x90;
    VirtualProtect(fn, 13, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 13);
    Log("Battle.Logic.__IsHit hook applied (result)");
}

using GetAttrDoubleFn = double (__cdecl*)(void*, void*);
GetAttrDoubleFn originalGetAttrAttack = nullptr;
bool getAttrAttackHookApplied = false;
static volatile LONG getAttrAttackCount = 0;

double __cdecl HookGetAttrAttack(void* ship, void* api) {
    const auto value = originalGetAttrAttack(ship, api);
    const auto n = InterlockedIncrement(&getAttrAttackCount);
    if (n <= 60 || n % 200 == 0) {
        std::lock_guard<std::mutex> guard(logMutex);
        std::ofstream output(logPath, std::ios::app);
        output << "GetAttr_Attack ship=0x" << std::hex << reinterpret_cast<uintptr_t>(ship)
            << std::dec << " value=" << std::to_string(value) << '\n';
        output.flush();
    }
    return value;
}

void TryApplyGetAttrAttackHook() {
    if (getAttrAttackHookApplied) return;
    getAttrAttackHookApplied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    auto fn = reinterpret_cast<unsigned char*>(ga) + 0x50AD40;
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 5);
    const auto backRel = static_cast<int32_t>((reinterpret_cast<uintptr_t>(fn) + 5) - (reinterpret_cast<uintptr_t>(tramp) + 10));
    tramp[5] = 0xE9;
    memcpy(tramp + 6, &backRel, 4);
    originalGetAttrAttack = reinterpret_cast<GetAttrDoubleFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookGetAttrAttack);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    memcpy(fn, jump, 5);
    VirtualProtect(fn, 5, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 5);
    Log("Battle.Logic.GetAttr_Attack hook applied");
}

using GetAttributeFn = double (__cdecl*)(void*, void*, int);
GetAttributeFn originalShipGetAttribute = nullptr;
bool shipGetAttributeHookApplied = false;
static volatile LONG shipGetAttrCount = 0;

double __cdecl HookShipGetAttribute(void* ship, void* api, int propId) {
    const auto value = originalShipGetAttribute(ship, api, propId);
    if (propId == 8 || propId == 9 || propId == 19 || propId == 20 || propId == 1 ||
        propId == 64 || propId == 102 || propId == 178 || propId == 600 || propId == 700 ||
        propId == 800 || propId == 901 || propId == 931 || propId == 961) {
        const auto n = InterlockedIncrement(&shipGetAttrCount);
        if (n <= 200 || n % 200 == 0) {
            std::lock_guard<std::mutex> guard(logMutex);
            std::ofstream output(logPath, std::ios::app);
            output << "GetAttribute ship=0x" << std::hex << reinterpret_cast<uintptr_t>(ship)
                << std::dec << " prop=" << propId << " value=" << std::to_string(value) << '\n';
            output.flush();
        }
    }
    return value;
}

void TryApplyShipGetAttributeHook() {
    if (shipGetAttributeHookApplied) return;
    shipGetAttributeHookApplied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    auto fn = reinterpret_cast<unsigned char*>(ga) + 0x50B1F0;
    // stolenLen=6: push ebp(1) mov ebp,esp(2) sub esp,0x20(3) = 6, clean boundary
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 6);
    const auto backRel = static_cast<int32_t>((reinterpret_cast<uintptr_t>(fn) + 6) - (reinterpret_cast<uintptr_t>(tramp) + 11));
    tramp[6] = 0xE9;
    memcpy(tramp + 7, &backRel, 4);
    originalShipGetAttribute = reinterpret_cast<GetAttributeFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookShipGetAttribute);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 6, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    memcpy(fn, jump, 5);
    for (size_t i = 5; i < 6; ++i) fn[i] = 0x90;
    VirtualProtect(fn, 6, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 6);
    Log("Battle.Logic.Ship.GetAttribute hook applied");
}

void* setAttackDmgInfoStolen = nullptr;
bool setAttackDmgInfoHookApplied = false;

void LogSetAttackDmgInfo(void* dmg) {
    const auto d = reinterpret_cast<uintptr_t>(dmg);
    const auto targetUid = ReadPtrSafe(d + 0x8);
    const auto value = ReadPtrSafe(d + 0x1C);
    const auto realValue = ReadPtrSafe(d + 0x24);
    const auto isCrit = ReadPtrSafe(d + 0x28);
    const auto isMiss = ReadPtrSafe(d + 0x29);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "SetAttackDmgInfo dmg=0x" << std::hex << d
        << " target=0x" << targetUid << std::dec
        << " value=" << value << " realValue=" << realValue
        << " isCrit=" << isCrit << " isMiss=" << isMiss << '\n';
    output.flush();
}

void LogSetAttackDmgInfoRaw(unsigned int a1, unsigned int a2, unsigned int a3, unsigned int a4,
    unsigned int a5, unsigned int a6, unsigned int a7, unsigned int a8, unsigned int a9, unsigned int a10) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "SetAttackDmgInfo raw=" << std::hex << a1 << " " << a2 << " " << a3 << " " << a4 << " "
        << a5 << " " << a6 << " " << a7 << " " << a8 << " " << a9 << " " << a10 << std::dec << '\n';
    output.flush();
}

__declspec(naked) void SetAttackDmgInfoTrampoline() {
    __asm {
        pushad
        // after pushad: orig arg1 at [esp+0x24], arg10 at [esp+0x44]
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        mov eax, dword ptr [esp + 0x44]
        push eax
        call LogSetAttackDmgInfoRaw
        add esp, 40
        popad
        jmp dword ptr [setAttackDmgInfoStolen]
    }
}

void TryApplySetAttackDmgInfoHook() {
    if (setAttackDmgInfoHookApplied) return;
    setAttackDmgInfoHookApplied = true;
    InstallStrArgHook(0x41E860, &SetAttackDmgInfoTrampoline, &setAttackDmgInfoStolen, 11, "Battle.Display.Context.Anim.Fun.SetAttackDmgInfo0");
}

void* afterExecuteStolen = nullptr;
bool afterExecuteHookApplied = false;
using AfterExecuteFn = void* (__cdecl*)(void*, long long, void*, int, long long, long long, int);
AfterExecuteFn originalAfterExecute = nullptr;

void DumpAttackInfos(void* container, uintptr_t attackInfoOffset) {
    if (!container) return;
    const auto attackInfoList = ReadPtrSafe(reinterpret_cast<uintptr_t>(container) + attackInfoOffset);
    if (!attackInfoList) return;
    const auto items = ReadPtrSafe(attackInfoList + 0x8);
    const auto size = ReadPtrSafe(attackInfoList + 0xC);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    for (unsigned i = 0; i < size && i < 8; ++i) {
        const auto attackInfo = ReadPtrSafe(items + 0x10 + static_cast<uintptr_t>(i) * 4);
        if (!attackInfo) continue;
        const auto dmgList = ReadPtrSafe(attackInfo + 0x18);
        if (!dmgList) continue;
        const auto dmgItems = ReadPtrSafe(dmgList + 0x8);
        const auto dmgSize = ReadPtrSafe(dmgList + 0xC);
        for (unsigned j = 0; j < dmgSize && j < 8; ++j) {
            const auto dmg = ReadPtrSafe(dmgItems + 0x10 + static_cast<uintptr_t>(j) * 4);
            if (!dmg) continue;
            const auto target = ReadPtrSafe(dmg + 0x8);
            const auto value = ReadPtrSafe(dmg + 0x1C);
            const auto realValue = ReadPtrSafe(dmg + 0x24);
            const auto isCrit = ReadPtrSafe(dmg + 0x28);
            const auto isMiss = ReadPtrSafe(dmg + 0x29);
            output << "L2DResult attack[" << i << "] dmg[" << j << "] target=0x"
                << std::hex << target << std::dec
                << " value=" << value << " realValue=" << realValue
                << " isCrit=" << isCrit << " isMiss=" << isMiss << '\n';
        }
    }
    output.flush();
}

void* __cdecl HookAfterExecute(void* this_, long long serviceId, void* selectInfo, int qte,
    long long exportFleet, long long targetFleet, int isSpecial) {
    auto result = originalAfterExecute(this_, serviceId, selectInfo, qte, exportFleet, targetFleet, isSpecial);
    DumpAttackInfos(result, 0x14);
    return result;
}

void TryApplyAfterExecuteHook() {
    if (afterExecuteHookApplied) return;
    afterExecuteHookApplied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    auto fn = reinterpret_cast<unsigned char*>(ga) + 0x520D60;
    // stolenLen=10: push ebp(1) mov ebp,esp(2) cmp byte[disp32],imm8(7) = 10
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 10);
    const auto backRel = static_cast<int32_t>((reinterpret_cast<uintptr_t>(fn) + 10) - (reinterpret_cast<uintptr_t>(tramp) + 15));
    tramp[10] = 0xE9;
    memcpy(tramp + 11, &backRel, 4);
    originalAfterExecute = reinterpret_cast<AfterExecuteFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookAfterExecute);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 10, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    memcpy(fn, jump, 5);
    for (size_t i = 5; i < 10; ++i) fn[i] = 0x90;
    VirtualProtect(fn, 10, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 10);
    Log("Battle.Logic.EPU_MainGun.AfterExecute hook applied");
}

void* executeStolen = nullptr;
bool executeHookApplied = false;
using ExecuteFn = void* (__cdecl*)(void*, long long, long long, void*, int, int, int);
ExecuteFn originalExecute = nullptr;

void* __cdecl HookExecute(void* this_, long long sourceFleet, long long targetFleet, void* selectInfo,
    int qte, int cutin, int isSpecial) {
    auto result = originalExecute(this_, sourceFleet, targetFleet, selectInfo, qte, cutin, isSpecial);
    DumpAttackInfos(result, 0x38);
    return result;
}

void TryApplyExecuteHook() {
    if (executeHookApplied) return;
    executeHookApplied = true;
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    auto fn = reinterpret_cast<unsigned char*>(ga) + 0x520EC0;
    // stolenLen=12: push ebp(1) mov ebp,esp(2) push esi(1) push 0(2) push [ebp+0x28](3) mov esi,[ebp+8](3) = 12
    auto tramp = static_cast<unsigned char*>(VirtualAlloc(nullptr, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
    if (!tramp) return;
    memcpy(tramp, fn, 12);
    const auto backRel = static_cast<int32_t>((reinterpret_cast<uintptr_t>(fn) + 12) - (reinterpret_cast<uintptr_t>(tramp) + 17));
    tramp[12] = 0xE9;
    memcpy(tramp + 13, &backRel, 4);
    originalExecute = reinterpret_cast<ExecuteFn>(tramp);
    const auto target = reinterpret_cast<uintptr_t>(&HookExecute);
    const auto rel = static_cast<int32_t>(target - (reinterpret_cast<uintptr_t>(fn) + 5));
    unsigned char jump[5];
    jump[0] = 0xE9;
    memcpy(jump + 1, &rel, 4);
    DWORD oldProtect = 0;
    if (!VirtualProtect(fn, 12, PAGE_EXECUTE_READWRITE, &oldProtect)) return;
    memcpy(fn, jump, 5);
    for (size_t i = 5; i < 12; ++i) fn[i] = 0x90;
    VirtualProtect(fn, 12, oldProtect, &oldProtect);
    FlushInstructionCache(GetCurrentProcess(), fn, 12);
    Log("Battle.Logic.EPU_MainGun.Execute hook applied");
}

void* eventDamageAfterStolen = nullptr;
bool eventDamageAfterHookApplied = false;

void LogEventDamageAfter(void* this_, void* source, void* sourceOwner, void* target, int skillType,
    int damageValue, int hit, int crit) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "EventDamageAfter this=0x" << std::hex << reinterpret_cast<uintptr_t>(this_)
        << " source=0x" << reinterpret_cast<uintptr_t>(source)
        << " owner=0x" << reinterpret_cast<uintptr_t>(sourceOwner)
        << " target=0x" << reinterpret_cast<uintptr_t>(target) << std::dec
        << " skillType=" << skillType << " damage=" << damageValue << " hit=" << hit << " crit=" << crit << '\n';
    output.flush();
}

__declspec(naked) void EventDamageAfterTrampoline() {
    __asm {
        pushad
        // _EventDamageAfter(this, source, sourceOwner, target, logicSkillType,
        //                   damageValue, hit, crit) + one trailing zero slot.
        // after pushad (8 regs=0x20): [esp+0x24]=this, +0x28=source, +0x2C=owner,
        //               +0x30=target, +0x34=skillType, +0x38=damage, +0x3C=hit, +0x40=crit
        mov eax, dword ptr [esp + 0x40]   // crit
        push eax
        mov eax, dword ptr [esp + 0x40]   // hit
        push eax
        mov eax, dword ptr [esp + 0x40]   // damage
        push eax
        mov eax, dword ptr [esp + 0x40]   // skillType
        push eax
        mov eax, dword ptr [esp + 0x40]   // target
        push eax
        mov eax, dword ptr [esp + 0x40]   // owner
        push eax
        mov eax, dword ptr [esp + 0x40]   // source
        push eax
        mov eax, dword ptr [esp + 0x40]   // this
        push eax
        call LogEventDamageAfter
        add esp, 32
        popad
        jmp dword ptr [eventDamageAfterStolen]
    }
}

void TryApplyEventDamageAfterHook() {
    if (eventDamageAfterHookApplied) return;
    eventDamageAfterHookApplied = true;
    // prologue: push ebp(1) mov ebp,esp(2) sub esp,0x10(3) cmp byte[disp32],imm8(7) = 13
    InstallStrArgHook(0x527380, &EventDamageAfterTrampoline, &eventDamageAfterStolen, 13, "Battle.Logic._EventDamageAfter");
}

void* executeAtomStolen = nullptr;
bool executeAtomHookApplied = false;

void LogExecuteAtom(void* this_, void* exportShip, void* targetShip, int qteNum,
    uint32_t dmgLow, uint32_t dmgHigh, int cutin, int clipIndex, int isSpecial) {
    uint64_t bits = (static_cast<uint64_t>(dmgHigh) << 32) | dmgLow;
    double dmgAdd = 0.0;
    memcpy(&dmgAdd, &bits, 8);
    const auto es = reinterpret_cast<uintptr_t>(exportShip);
    const auto ts = reinterpret_cast<uintptr_t>(targetShip);
    // Ship+0x64 = actSkillInfo; +0x28 = damageFac (active-skill damage factor)
    double actSkillDamFac = -1.0;
    const auto actSkillInfo = ReadPtrSafe(es + 0x64);
    if (actSkillInfo)
        memcpy(&actSkillDamFac, reinterpret_cast<const void*>(actSkillInfo + 0x28), 8);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "ExecuteAtom this=0x" << std::hex << reinterpret_cast<uintptr_t>(this_)
        << " exportShip=0x" << es
        << " targetShip=0x" << ts << std::dec
        << " qteNum=" << qteNum << " mainGunDamageAdd=" << dmgAdd
        << " cutin=" << cutin << " clipIndex=" << clipIndex << " isSpecial=" << isSpecial
        << " actSkillInfo=0x" << std::hex << actSkillInfo << std::dec
        << " actSkillDamFac=" << actSkillDamFac << '\n';
    output.flush();
}

__declspec(naked) void ExecuteAtomTrampoline() {
    __asm {
        pushad
        // __ExecuteAtom(this, exportShip, targetShip, qteNum, mainGunDamageAdd(double),
        //               cutin, clipIndex, isSpecial, 0)
        // after pushad (8 regs = 0x20): [esp+0x20]=retaddr, +0x24=this, +0x28=exportShip,
        //               +0x2C=targetShip, +0x30=qteNum, +0x34/+0x38=damageAdd,
        //               +0x3C=cutin, +0x40=clipIndex, +0x44=isSpecial.
        // Reading [esp+0x44] repeatedly works because each push shifts the next arg into
        // that slot (pushing is right-to-left: isSpecial ... this).
        mov eax, dword ptr [esp + 0x44]   // isSpecial (9th param)
        push eax
        mov eax, dword ptr [esp + 0x44]   // clipIndex
        push eax
        mov eax, dword ptr [esp + 0x44]   // cutin
        push eax
        mov eax, dword ptr [esp + 0x44]   // damageAdd high
        push eax
        mov eax, dword ptr [esp + 0x44]   // damageAdd low
        push eax
        mov eax, dword ptr [esp + 0x44]   // qteNum
        push eax
        mov eax, dword ptr [esp + 0x44]   // targetShip
        push eax
        mov eax, dword ptr [esp + 0x44]   // exportShip
        push eax
        mov eax, dword ptr [esp + 0x44]   // this
        push eax
        call LogExecuteAtom
        add esp, 36
        popad
        jmp dword ptr [executeAtomStolen]
    }
}

void TryApplyExecuteAtomHook() {
    if (executeAtomHookApplied) return;
    executeAtomHookApplied = true;
    // prologue: push ebp(1) mov ebp,esp(2) sub esp,0x78(3) cmp byte[disp32],imm8(7) = 13
    InstallStrArgHook(0x521E40, &ExecuteAtomTrampoline, &executeAtomStolen, 13, "Battle.Logic.EPU_MainGun.__ExecuteAtom");
}

// ---------------------------------------------------------------------------
// MISS fix: several EPU damage paths compute
//   damage = ceil(baseDamage * <active-skill damage factor>)
// where the factor is Ship.actSkillInfo.damageFac (0x28). In the offline server
// the ships carry no configured A-skill, so the factor reads back 0 and every
// attack computes 0 damage -> DamageInfo.isMiss=true -> "MISS".
// Neutralize each damageFac multiply (treat factor as 1.0):
//   EPU_BuffAttack.__Execute         0x52044A  F2 0F 59 45 F4  mulsd xmm0,[ebp-0xc]
//   EPU_MainGun_Torpedo.__ExecuteAtom 0x521910  F2 0F 59 4D DC  mulsd xmm1,[ebp-0x24]
//   EPU_MainGun.__ExecuteAtom        0x5222F1  F2 0F 59 45 A0  mulsd xmm0,[ebp-0x60]
//   EPU_PSkill.__EcecuteMain         0x52314B  F2 0F 59 45 F0  mulsd xmm0,[ebp-0x10]
//   EPU_PSkill.__Execute             0x5232F0  F2 0F 59 45 F8  mulsd xmm0,[ebp-8]
//   EPU_AirAttack.__ExecuteAtom      0x523C03  F2 0F 59 45 C0  mulsd xmm0,[ebp-0x40]
// ---------------------------------------------------------------------------
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

// ---- damage coefficient probes (log return values; each returns double in ST0) ----

using DamageOddFn = double (__cdecl*)(void*, void*, void*);
DamageOddFn originalDamageOdd = nullptr;
bool damageOddHookApplied = false;

double __cdecl HookDamageOdd(void* this_, void* exportShip, void* targetShip) {
    const auto result = originalDamageOdd(this_, exportShip, targetShip);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "GetDamageOdd_BCS export=0x" << std::hex << reinterpret_cast<uintptr_t>(exportShip)
        << " target=0x" << reinterpret_cast<uintptr_t>(targetShip) << std::dec
        << " result=" << std::to_string(result) << '\n';
    output.flush();
    return result;
}

void TryApplyDamageOddHook() {
    if (damageOddHookApplied) return;
    damageOddHookApplied = true;
    InstallReturnHook(0x521A20, &HookDamageOdd, &originalDamageOdd, 6, "GetDamageOdd_BCS");
}

using AmmoEffectFn = double (__cdecl*)(void*, int, void*);
AmmoEffectFn originalAmmoEffect = nullptr;
bool ammoEffectHookApplied = false;

double __cdecl HookAmmoEffect(void* this_, int propId, void* ship) {
    const auto result = originalAmmoEffect(this_, propId, ship);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "GetAmmounitionEffect prop=" << propId
        << " ship=0x" << std::hex << reinterpret_cast<uintptr_t>(ship) << std::dec
        << " result=" << std::to_string(result) << '\n';
    output.flush();
    return result;
}

void TryApplyAmmoEffectHook() {
    if (ammoEffectHookApplied) return;
    ammoEffectHookApplied = true;
    InstallReturnHook(0x66A190, &HookAmmoEffect, &originalAmmoEffect, 6, "GetAmmounitionEffect");
}

using ShipDamageCoeFn = double (__cdecl*)(void*, void*, int);
ShipDamageCoeFn originalShipDamageCoe = nullptr;
bool shipDamageCoeHookApplied = false;

double __cdecl HookShipDamageCoe(void* this_, void* ship, int skillType) {
    const auto result = originalShipDamageCoe(this_, ship, skillType);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "GetShipDamageCoe skillType=" << skillType
        << " ship=0x" << std::hex << reinterpret_cast<uintptr_t>(ship) << std::dec
        << " result=" << std::to_string(result) << '\n';
    output.flush();
    return result;
}

void TryApplyShipDamageCoeHook() {
    if (shipDamageCoeHookApplied) return;
    shipDamageCoeHookApplied = true;
    InstallReturnHook(0x66A3F0, &HookShipDamageCoe, &originalShipDamageCoe, 6, "GetShipDamageCoe");
}

using QteDamageCoeFn = double (__cdecl*)(void*, int, void*);
QteDamageCoeFn originalQteDamageCoe = nullptr;
bool qteDamageCoeHookApplied = false;

double __cdecl HookQteDamageCoe(void* this_, int qteStep, void* ship) {
    const auto result = originalQteDamageCoe(this_, qteStep, ship);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "GetBattleQteDamageCoe qteStep=" << qteStep
        << " ship=0x" << std::hex << reinterpret_cast<uintptr_t>(ship) << std::dec
        << " result=" << std::to_string(result) << '\n';
    output.flush();
    return result;
}

void TryApplyQteDamageCoeHook() {
    if (qteDamageCoeHookApplied) return;
    qteDamageCoeHookApplied = true;
    InstallReturnHook(0x66A260, &HookQteDamageCoe, &originalQteDamageCoe, 6, "GetBattleQteDamageCoe");
}

using RelationCoeFn = double (__cdecl*)(void*, int, void*);
RelationCoeFn originalRelationCoe = nullptr;
bool relationCoeHookApplied = false;

double __cdecl HookRelationCoe(void* this_, int relation, void* fleet) {
    const auto result = originalRelationCoe(this_, relation, fleet);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "AttackCoeOfRelation relation=" << relation
        << " fleet=0x" << std::hex << reinterpret_cast<uintptr_t>(fleet) << std::dec
        << " result=" << std::to_string(result) << '\n';
    output.flush();
    return result;
}

void TryApplyRelationCoeHook() {
    if (relationCoeHookApplied) return;
    relationCoeHookApplied = true;
    InstallReturnHook(0x66BEE0, &HookRelationCoe, &originalRelationCoe, 6, "AttackCoeOfRelation");
}

using GetASkillAttrFn = void* (__cdecl*)(void*, long long, int, int);
GetASkillAttrFn originalGetASkillAttr = nullptr;
bool getASkillAttrHookApplied = false;

void* __cdecl HookGetASkillAttr(void* this_, long long shipUID, int skillType, int isSpecial) {
    const auto result = originalGetASkillAttr(this_, shipUID, skillType, isSpecial);
    double damFac = 0.0;
    if (result)
        memcpy(&damFac, reinterpret_cast<const void*>(reinterpret_cast<uintptr_t>(result) + 0x10), 8);
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "GetASkillAttr shipUID=" << shipUID << " skillType=" << skillType
        << " isSpecial=" << isSpecial
        << " result=0x" << std::hex << reinterpret_cast<uintptr_t>(result) << std::dec
        << " damageFac=" << damFac << '\n';
    output.flush();
    return result;
}

void TryApplyGetASkillAttrHook() {
    if (getASkillAttrHookApplied) return;
    getASkillAttrHookApplied = true;
    // prologue: push ebp(1) mov ebp,esp(2) sub esp,? (3) -> need full prologue
    auto ga = GetModuleHandleW(L"GameAssembly.dll");
    if (!ga) return;
    const auto fn = reinterpret_cast<unsigned char*>(ga) + 0x65BA80;
    if (fn[0] != 0x55 || fn[1] != 0x8B || fn[2] != 0xEC) {
        char actual[16]{};
        for (int i = 0; i < 6; ++i) { char b[4]{}; sprintf_s(b, "%02X ", fn[i]); strcat_s(actual, b); }
        Log(std::string("GetASkillAttr hook refused: prologue mismatch actual=") + actual);
        return;
    }
    // determine stolenLen: 55 8B EC + 83 EC imm8(3) or 83 EC imm32(6); check byte 4
    size_t len = 5;
    if (fn[3] == 0x83 && fn[4] == 0xEC) len = 6; // sub esp, imm8
    else if (fn[3] == 0x81 && fn[4] == 0xEC) len = 9; // sub esp, imm32
    else if (fn[3] == 0x80 && fn[4] == 0x3D) len = 13; // cmp byte [disp],imm8
    InstallReturnHook(0x65BA80, &HookGetASkillAttr, &originalGetASkillAttr, len, "GetASkillAttr");
}

// Unity log callback registration. Bugly (new_sdk) registers a logMessageReceived callback
// that runs its crash-handler flow (report + exit) when Unity logs errors during the battle
// transition. Replacing every registered callback with a no-op stops bugly's crash trigger
// without touching the game's managed logic.
void* addLogMessageReceivedStolen = nullptr;
bool addLogMessageReceivedHookApplied = false;

void __cdecl NoopLogCallback(void* condition, void* stack, int type) { }

void LogAddLogMessageReceived(void* cb) {
    std::lock_guard<std::mutex> guard(logMutex);
    std::ofstream output(logPath, std::ios::app);
    output << "logMessageReceived registration suppressed (cb=0x"
        << std::hex << reinterpret_cast<uintptr_t>(cb) << std::dec << ")" << '\n';
    output.flush();
}

__declspec(naked) void AddLogMessageReceivedTrampoline() {
    __asm {
        pushad
        mov eax, dword ptr [esp + 36]   // cb delegate
        push eax
        call LogAddLogMessageReceived
        add esp, 4
        mov eax, dword ptr [esp + 36]   // cb (for forwarding, replaced with no-op)
        mov dword ptr [esp + 36], 0     // placeholder; call original with &NoopLogCallback below
        popad
        jmp dword ptr [addLogMessageReceivedStolen]
    }
}

void TryApplyAddLogMessageReceivedHook() {
    if (addLogMessageReceivedHookApplied) return;
    addLogMessageReceivedHookApplied = true;
    InstallStrArgHook(0xE43420, &AddLogMessageReceivedTrampoline, &addLogMessageReceivedStolen, 10, "Application.add_logMessageReceived");
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

void TryApplyGetJsonDataGroupHook() {
    if (getJsonDataGroupHookApplied) return;
    getJsonDataGroupHookApplied = true;
    InstallStrArgHook(0x2E2A50, &GetJsonDataGroupTrampoline, &getJsonDataGroupStolen, 11, "SQLiteConfigManager.GetJsonDataGroup");
}

void TryApplyGetJsonStrByBytesHook() {
    if (getJsonStrByBytesHookApplied) return;
    getJsonStrByBytesHookApplied = true;
    // DISABLED temporarily for isolation testing (may interact badly with new_sdk).
    //InstallStrArgHook(0x2E2DC0, &GetJsonStrByBytesTrampoline, &getJsonStrByBytesStolen, 10, "SQLiteConfigManager.GetJsonStrByBytes");
}

void TryApplyAssetLoadAsyncHook() {
    if (assetLoadAsyncHookApplied) return;
    assetLoadAsyncHookApplied = true;
    // DISABLED temporarily for isolation testing (may interact badly with new_sdk).
    //InstallStrArgHook(0x28E790, &AssetLoadAsyncTrampoline, &assetLoadAsyncStolen, 11, "BabelTime.Res.AssetManager.LoadAsync");
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

void TryApplyGetComponentsNeedHook() {
    if (getComponentsNeedHookApplied) return;
    getComponentsNeedHookApplied = true;
    InstallStrArgHook(0x279EB0, &GetComponentsNeedTrampoline, &getComponentsNeedStolen, 11, "UILuaPage.GetComponentsNeed");
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
    if (code == 0xE06D7363 && info->ContextRecord && rec->NumberParameters >= 2 &&
        (afterBattle || unhandledCxx)) {
        const auto esp = info->ContextRecord->Esp;
        std::string trace = " throwEip=" + DescribeCaller(reinterpret_cast<void*>(info->ContextRecord->Eip));
        const auto exceptObj = static_cast<uintptr_t>(rec->ExceptionInformation[1]);
        if (exceptObj) {
            const auto klass = ReadPtrSafe(exceptObj);
            const auto className = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0x8)) : "";
            const auto nameSpace = klass ? ReadAsciiCStr(ReadPtrSafe(klass + 0xC)) : "";
            if (!className.empty()) trace += " type=" + nameSpace + "." + className;
            const auto msgPtr = ReadPtrSafe(exceptObj + 0x8);
            if (msgPtr) trace += " msg=" + ReadIl2CppString(reinterpret_cast<void*>(msgPtr));
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

    // Vectored exception handler + ExitProcess/NtTerminateProcess hooks re-enabled to capture
    // the EXACT crash site during battle frame init / scene teardown. The raw stack scan at
    // ExitProcess reveals the real caller chain (CaptureStackBackTrace is unreliable here).
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
        TryApplyNewSdkReportHooks();
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
        TryApplyMessageHelperUnpackHook();
        TryApplyGetQucikConditionsHook();
        TryApplyCxxThrowHook();
        TryApplyRaiseHelperHook();
        TryApplyConfigLookupHook();
        TryApplyCtorRaiseHook();
        TryApplyAddResHook();
        TryApplySceneLoadStartHook();
        TryApplySceneLoadResolveHook();
        TryApplyStartLoadHook();
        TryApplyStartLoadPriorHook();
        TryApplyChangeSceneHook();
        TryApplySceneLookupHook();
        TryApplyDelayGotoHook();
        TryApplyOnStageStartFinHook();
        TryApplyPVEStartDataCtorHook();
        TryApplyInitBattleHook();
        TryApplyStageBeginHook();
        TryApplyLoadingTickHook();
        TryApplyInitBattleFrameHook();
        TryApplyCreateBattleFrameHook();
        TryApplyShipPBConvertHook();
        TryApplyUIShipProxyLoadModelHook();
        TryApplyUIShipProxyCtorHook();
        TryApplyGetJsonDataHook();
        TryApplyGetAllHook();
        TryApplyGetJsonDataGroupHook();
        TryApplyGetJsonStrByBytesHook();
        TryApplyAssetLoadAsyncHook();
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
        TryApplyInternalLogExceptionHook();
        TryApplyIsHitHook();
        TryApplyGetAttrAttackHook();
        TryApplyShipGetAttributeHook();
        TryApplySetAttackDmgInfoHook();
        TryApplyAfterExecuteHook();
        TryApplyExecuteHook();
        TryApplyExecuteAtomHook();
        TryApplyMainGunDamageFacPatch();
        TryApplyEventDamageAfterHook();
        TryApplyDamageOddHook();
        TryApplyAmmoEffectHook();
        TryApplyShipDamageCoeHook();
        TryApplyQteDamageCoeHook();
        TryApplyRelationCoeHook();
        TryApplyGetASkillAttrHook();
        TryApplyGetComponentsNeedHook();
        TryApplyLuaPcallKHook();
        TryApplySdkLoginHook();
        TryApplyLoginMethodHook();
        TrySetSimulationMode();
        TrySetReview();
        // Auto-login fallback: the normal trigger is SDK event 29 (announcement WebView
        // "open"), which does not always fire headlessly. If the game is still sitting at
        // the SDK login screen (network not connected) long after boot, repeatedly
        // dispatch the fabricated login result (event 2) until the game connects.
        if (originalSdkCallback && !IsGameNetworkConnected() &&
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
        HideCefWebView();
        LogHotPatchState();
        LogNetLogicState();
        if (getUserExtraSeen && GetTickCount64() - getUserExtraSeenAt >= 2000) {
            ForceMainStage();
        }
        Sleep(500);
    }
}
