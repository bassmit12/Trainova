#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

// Static flag to track if console has been created
static bool g_console_created = false;

void CreateAndAttachConsole() {
  // Skip if already created to avoid redundant work
  if (g_console_created) {
    return;
  }

  // Only create console in debug mode or when explicitly needed
  #ifdef _DEBUG
  bool should_create_console = true;
  #else
  bool should_create_console = ::IsDebuggerPresent();
  #endif

  if (!should_create_console) {
    g_console_created = true; // Mark as handled
    return;
  }

  // Try to attach to existing console first (more efficient)
  if (::AttachConsole(ATTACH_PARENT_PROCESS)) {
    g_console_created = true;
    return;
  }

  // Only allocate new console if attach failed and we really need it
  if (::AllocConsole()) {
    FILE *unused;
    
    // Batch the file operations to reduce system calls
    bool stdout_redirected = (freopen_s(&unused, "CONOUT$", "w", stdout) == 0);
    bool stderr_redirected = (freopen_s(&unused, "CONOUT$", "w", stderr) == 0);
    
    // Only sync if redirections were successful
    if (stdout_redirected || stderr_redirected) {
      if (stdout_redirected) {
        _dup2(_fileno(stdout), 1);
      }
      if (stderr_redirected) {
        _dup2(_fileno(stdout), 2);
      }
      
      // Perform sync operations only once
      std::ios::sync_with_stdio();
      FlutterDesktopResyncOutputStreams();
    }
    
    g_console_created = true;
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
