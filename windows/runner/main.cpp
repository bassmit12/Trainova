#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Optimized console attachment - only when actually needed
  CreateAndAttachConsole();

  // Initialize COM with apartment threading for better performance
  HRESULT hr = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
  if (FAILED(hr)) {
    return EXIT_FAILURE;
  }

  // Create project with optimized settings
  flutter::DartProject project(L"data");

  // Get command line arguments efficiently
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  if (!command_line_arguments.empty()) {
    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
  }

  // Create window with optimized initial position and size
  FlutterWindow window(project);
  
  // Use system metrics for better initial positioning
  int screen_width = ::GetSystemMetrics(SM_CXSCREEN);
  int screen_height = ::GetSystemMetrics(SM_CYSCREEN);
  
  // Center the window and use reasonable default size
  int window_width = 1280;
  int window_height = 720;
  Win32Window::Point origin(
    (screen_width - window_width) / 2,
    (screen_height - window_height) / 2
  );
  Win32Window::Size size(window_width, window_height);
  
  if (!window.Create(L"Trainova", origin, size)) {
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  
  window.SetQuitOnClose(true);

  // Optimized message loop with better performance characteristics
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
