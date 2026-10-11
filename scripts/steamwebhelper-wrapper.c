// Replaces steamwebhelper.exe: runs steamwebhelper_orig.exe with --disable-gpu --single-process
// so the Steam UI renders under Wine on Apple Silicon instead of a black window.
#include <windows.h>
#include <wchar.h>

int wmain(void) {
    wchar_t exe[MAX_PATH];
    GetModuleFileNameW(NULL, exe, MAX_PATH);
    wcscpy(wcsrchr(exe, L'\\') + 1, L"steamwebhelper_orig.exe");

    // Skip argv[0] in the raw command line to keep the original arguments untouched.
    wchar_t *args = GetCommandLineW();
    if (*args == L'"') {
        args = wcschr(args + 1, L'"');
        args = args ? args + 1 : L"";
    } else {
        while (*args && *args != L' ') args++;
    }

    static wchar_t cmd[32768];
    _snwprintf(cmd, 32767, L"\"%ls\" --disable-gpu --single-process%ls", exe, args);

    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    if (!CreateProcessW(exe, cmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) return 1;
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 1;
    GetExitCodeProcess(pi.hProcess, &code);
    return (int)code;
}
