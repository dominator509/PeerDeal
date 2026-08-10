#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"

class WindowsSecureKeyStorage;
class WindowsCaptureProtection;
class WindowsAppStorage;
class WindowsNativeTransport;

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // The generic secure-key channel owned by this app host.
  std::unique_ptr<WindowsSecureKeyStorage> secure_key_storage_;

  // The native capture policy action channel owned by this app host.
  std::unique_ptr<WindowsCaptureProtection> capture_protection_;

  // The generic app-private support-directory channel owned by this host.
  std::unique_ptr<WindowsAppStorage> app_storage_;

  // The generic byte-frame transport channel owned by this host.
  std::unique_ptr<WindowsNativeTransport> native_transport_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
