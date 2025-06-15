#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // Calculate dimensions once to avoid repeated calculations
  int width = frame.right - frame.left;
  int height = frame.bottom - frame.top;

  // Create Flutter controller with optimized settings
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      width, height, project_);
  
  // Early validation to fail fast if something is wrong
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  // Register plugins before setting up the window to avoid layout issues
  RegisterPlugins(flutter_controller_->engine());
  
  // Set up the child content
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Optimize the window showing process
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    // Show window immediately when first frame is ready
    this->Show();
  });

  // Force the first frame to be rendered to minimize perceived startup time
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    // Clean shutdown of Flutter controller
    flutter_controller_->engine()->SetNextFrameCallback(nullptr);
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      // Only reload fonts if the controller is still valid
      if (flutter_controller_ && flutter_controller_->engine()) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
