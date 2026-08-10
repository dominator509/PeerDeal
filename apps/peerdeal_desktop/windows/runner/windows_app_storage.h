#ifndef RUNNER_WINDOWS_APP_STORAGE_H_
#define RUNNER_WINDOWS_APP_STORAGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

class WindowsAppStorage final {
 public:
  explicit WindowsAppStorage(flutter::BinaryMessenger* messenger);
  ~WindowsAppStorage();

  WindowsAppStorage(const WindowsAppStorage&) = delete;
  WindowsAppStorage& operator=(const WindowsAppStorage&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  static flutter::EncodableValue Failure();
  static flutter::EncodableValue Success(const std::string& directory_path);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_WINDOWS_APP_STORAGE_H_
