#ifndef RUNNER_WINDOWS_CAPTURE_PROTECTION_H_
#define RUNNER_WINDOWS_CAPTURE_PROTECTION_H_

#include <windows.h>

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class WindowsCaptureProtection final {
 public:
  WindowsCaptureProtection(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsCaptureProtection();

  WindowsCaptureProtection(const WindowsCaptureProtection&) = delete;
  WindowsCaptureProtection& operator=(const WindowsCaptureProtection&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_ = nullptr;
};

#endif  // RUNNER_WINDOWS_CAPTURE_PROTECTION_H_
