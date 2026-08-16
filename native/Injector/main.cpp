#include <windows.h>
#include <tlhelp32.h>
#include <bcrypt.h>
#include <filesystem>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#pragma comment(lib, "bcrypt.lib")

namespace {
struct Handle {
    HANDLE value = nullptr;
    Handle() = default;
    explicit Handle(HANDLE h) : value(h) {}
    ~Handle() { if (value && value != INVALID_HANDLE_VALUE) CloseHandle(value); }
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
    operator HANDLE() const { return value; }
};

std::wstring ErrorMessage(DWORD code = GetLastError()) {
    wchar_t* buffer = nullptr;
    FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr, code, 0, reinterpret_cast<wchar_t*>(&buffer), 0, nullptr);
    std::wstring result = buffer ? buffer : L"unknown error";
    if (buffer) LocalFree(buffer);
    return result;
}

std::wstring HashFile(const std::filesystem::path& path) {
    Handle file(CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
    if (file.value == INVALID_HANDLE_VALUE) throw std::runtime_error("cannot open hash target");
    BCRYPT_ALG_HANDLE algorithm = nullptr;
    BCRYPT_HASH_HANDLE hash = nullptr;
    DWORD objectLength = 0, hashLength = 0, bytes = 0;
    if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) != 0 ||
        BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH, reinterpret_cast<PUCHAR>(&objectLength), sizeof(objectLength), &bytes, 0) != 0 ||
        BCryptGetProperty(algorithm, BCRYPT_HASH_LENGTH, reinterpret_cast<PUCHAR>(&hashLength), sizeof(hashLength), &bytes, 0) != 0)
        throw std::runtime_error("cannot initialize SHA-256");
    std::vector<UCHAR> object(objectLength), digest(hashLength), buffer(64 * 1024);
    if (BCryptCreateHash(algorithm, &hash, object.data(), objectLength, nullptr, 0, 0) != 0) throw std::runtime_error("cannot create SHA-256 hash");
    for (;;) {
        DWORD read = 0;
        if (!ReadFile(file, buffer.data(), static_cast<DWORD>(buffer.size()), &read, nullptr)) throw std::runtime_error("cannot read hash target");
        if (!read) break;
        if (BCryptHashData(hash, buffer.data(), read, 0) != 0) throw std::runtime_error("cannot update SHA-256 hash");
    }
    if (BCryptFinishHash(hash, digest.data(), hashLength, 0) != 0) throw std::runtime_error("cannot finish SHA-256 hash");
    BCryptDestroyHash(hash); BCryptCloseAlgorithmProvider(algorithm, 0);
    std::wostringstream output;
    for (auto byte : digest) output << std::uppercase << std::hex << std::setw(2) << std::setfill(L'0') << static_cast<int>(byte);
    return output.str();
}

uintptr_t RemoteModuleBase(DWORD pid, const wchar_t* name) {
    Handle snapshot(CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid));
    if (snapshot.value == INVALID_HANDLE_VALUE) return 0;
    MODULEENTRY32W entry{sizeof(entry)};
    if (!Module32FirstW(snapshot, &entry)) return 0;
    do {
        if (_wcsicmp(entry.szModule, name) == 0) {
            return reinterpret_cast<uintptr_t>(entry.modBaseAddr);
        }
    } while (Module32NextW(snapshot, &entry));
    return 0;
}

bool StartProcessAndWaitForModule(DWORD pid, HANDLE process, HANDLE mainThread, const wchar_t* moduleName) {
    if (ResumeThread(mainThread) == static_cast<DWORD>(-1)) return false;
    for (int attempt = 0; attempt < 5000; ++attempt) {
        if (WaitForSingleObject(process, 0) == WAIT_OBJECT_0) return false;
        if (RemoteModuleBase(pid, moduleName)) return true;
        Sleep(1);
    }
    return false;
}

bool ResolveRemoteProcedure(DWORD pid, const wchar_t* moduleName, const char* procedureName,
    HANDLE process, LPTHREAD_START_ROUTINE& remoteProcedure, std::wstring& ownerName,
    bool& usedSharedAddress) {
    usedSharedAddress = false;
    const auto requestedModule = GetModuleHandleW(moduleName);
    if (!requestedModule) return false;
    const auto localProcedure = GetProcAddress(requestedModule, procedureName);
    if (!localProcedure) return false;

    HMODULE ownerModule = nullptr;
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
        GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
        reinterpret_cast<LPCWSTR>(localProcedure), &ownerModule)) return false;

    wchar_t ownerPath[MAX_PATH]{};
    if (!GetModuleFileNameW(ownerModule, ownerPath, MAX_PATH)) return false;
    ownerName = std::filesystem::path(ownerPath).filename().wstring();
    const auto remoteOwner = RemoteModuleBase(pid, ownerName.c_str());
    const auto rva = reinterpret_cast<uintptr_t>(localProcedure) - reinterpret_cast<uintptr_t>(ownerModule);
    if (remoteOwner) {
        remoteProcedure = reinterpret_cast<LPTHREAD_START_ROUTINE>(remoteOwner + rva);
        return true;
    }

    // System DLLs are normally shared at the same address between equal-bitness
    // processes. Validate the page in the target before using that address.
    MEMORY_BASIC_INFORMATION memory{};
    if (VirtualQueryEx(process, localProcedure, &memory, sizeof(memory)) != sizeof(memory) ||
        memory.State != MEM_COMMIT || (memory.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
        PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)) == 0) return false;
    remoteProcedure = reinterpret_cast<LPTHREAD_START_ROUTINE>(localProcedure);
    usedSharedAddress = true;
    return true;
}

std::wstring Argument(int argc, wchar_t** argv, const std::wstring& prefix) {
    for (int i = 1; i < argc; ++i) if (std::wstring(argv[i]).rfind(prefix, 0) == 0) return std::wstring(argv[i]).substr(prefix.size());
    return {};
}
}

int wmain(int argc, wchar_t** argv) {
    try {
        const auto exeArgument = Argument(argc, argv, L"--exe=");
        const auto payloadArgument = Argument(argc, argv, L"--payload=");
        if (exeArgument.empty() || payloadArgument.empty()) {
            std::wcerr << L"Usage: BlueOath.Injector --exe=<game.exe> --payload=<payload.dll> --game-hash=<sha256> [--args=<game args>]\n";
            return 2;
        }
        const auto exe = std::filesystem::absolute(exeArgument);
        const auto payload = std::filesystem::absolute(payloadArgument);
        const auto expectedHash = Argument(argc, argv, L"--game-hash=");
        const auto arguments = Argument(argc, argv, L"--args=");
        if (!std::filesystem::is_regular_file(exe) || !std::filesystem::is_regular_file(payload)) {
            std::wcerr << L"Usage: BlueOath.Injector --exe=<game.exe> --payload=<payload.dll> --game-hash=<sha256> [--args=<game args>]\n";
            return 2;
        }
        const auto gameAssembly = exe.parent_path() / L"GameAssembly.dll";
        const auto actualHash = HashFile(gameAssembly);
        if (!expectedHash.empty() && _wcsicmp(actualHash.c_str(), expectedHash.c_str()) != 0) {
            std::wcerr << L"Unsupported GameAssembly.dll: " << actualHash << L"\n";
            return 3;
        }
        std::wstring command = L"\"" + exe.wstring() + L"\"";
        if (!arguments.empty()) command += L" " + arguments;
        std::vector<wchar_t> mutableCommand(command.begin(), command.end()); mutableCommand.push_back(L'\0');
        STARTUPINFOW startup{sizeof(startup)}; PROCESS_INFORMATION process{};
        if (!CreateProcessW(exe.c_str(), mutableCommand.data(), nullptr, nullptr, FALSE, CREATE_SUSPENDED, nullptr, exe.parent_path().c_str(), &startup, &process)) {
            std::wcerr << L"CreateProcess failed: " << ErrorMessage(); return 4;
        }
        Handle processHandle(process.hProcess), mainThread(process.hThread);
        if (!StartProcessAndWaitForModule(process.dwProcessId, processHandle, mainThread, L"GameAssembly.dll")) {
            TerminateProcess(processHandle, 16);
            std::wcerr << L"GameAssembly initialization timed out\n";
            return 6;
        }
        const auto eventName = L"Local\\BlueOath.Inject." + std::to_wstring(process.dwProcessId);
        Handle readyEvent(CreateEventW(nullptr, TRUE, FALSE, eventName.c_str()));
        const auto path = payload.wstring(); const SIZE_T bytes = (path.size() + 1) * sizeof(wchar_t);
        void* remotePath = VirtualAllocEx(processHandle, nullptr, bytes, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        if (!remotePath || !WriteProcessMemory(processHandle, remotePath, path.c_str(), bytes, nullptr)) {
            TerminateProcess(processHandle, 10); std::wcerr << L"Cannot write payload path: " << ErrorMessage(); return 5;
        }
        LPTHREAD_START_ROUTINE remoteLoadLibrary = nullptr;
        std::wstring loadLibraryOwner;
        bool usedSharedAddress = false;
        if (!ResolveRemoteProcedure(process.dwProcessId, L"kernel32.dll", "LoadLibraryW",
            processHandle, remoteLoadLibrary, loadLibraryOwner, usedSharedAddress)) {
            TerminateProcess(processHandle, 11);
            std::wcerr << L"Cannot resolve remote LoadLibraryW (owner="
                       << (loadLibraryOwner.empty() ? L"unknown" : loadLibraryOwner) << L")\n";
            return 6;
        }
        Handle loader(CreateRemoteThread(processHandle, nullptr, 0, remoteLoadLibrary, remotePath, 0, nullptr));
        if (!loader.value || WaitForSingleObject(loader, 10000) != WAIT_OBJECT_0) { TerminateProcess(processHandle, 12); std::wcerr << L"Payload loader timed out\n"; return 7; }
        DWORD module = 0; GetExitCodeThread(loader, &module); VirtualFreeEx(processHandle, remotePath, 0, MEM_RELEASE);
        if (!module) { TerminateProcess(processHandle, 13); std::wcerr << L"LoadLibraryW rejected payload\n"; return 8; }
        if (WaitForSingleObject(readyEvent, 10000) != WAIT_OBJECT_0) { TerminateProcess(processHandle, 14); std::wcerr << L"Payload initialization timed out\n"; return 9; }
        std::wcout << L"Injected PID " << process.dwProcessId << L", GameAssembly " << actualHash
                   << L", LoadLibrary owner " << loadLibraryOwner
                   << (usedSharedAddress ? L" (validated shared address)" : L" (module RVA)") << L"\n";
        return 0;
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
