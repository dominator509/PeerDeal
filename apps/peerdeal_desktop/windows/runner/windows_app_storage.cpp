// This must be included before many other Windows headers.
#include <windows.h>

#include "windows_app_storage.h"

#include <shlobj.h>

#include <climits>
#include <cwchar>
#include <optional>
#include <string>
#include <utility>

#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannelName[] = "peerdeal/native_bridges/app_storage";
constexpr char kGetAppSupportDirectoryMethod[] = "getAppSupportDirectory";

using flutter::EncodableMap;
using flutter::EncodableValue;

std::optional<std::string> LocalAppDataPath() {
  PWSTR wide_path = nullptr;
  const HRESULT status = ::SHGetKnownFolderPath(
      FOLDERID_LocalAppData, KF_FLAG_DEFAULT, nullptr, &wide_path);
  if (FAILED(status) || wide_path == nullptr) {
    if (wide_path != nullptr) {
      ::CoTaskMemFree(wide_path);
    }
    return std::nullopt;
  }

  const std::size_t wide_length = ::wcslen(wide_path);
  if (wide_length == 0 || wide_length > INT_MAX) {
    ::CoTaskMemFree(wide_path);
    return std::nullopt;
  }
  const int input_size = static_cast<int>(wide_length);
  const int output_size = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, wide_path, input_size, nullptr, 0,
      nullptr, nullptr);
  if (output_size <= 0) {
    ::CoTaskMemFree(wide_path);
    return std::nullopt;
  }

  std::string path(static_cast<std::size_t>(output_size), '\0');
  const int converted = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, wide_path, input_size, path.data(),
      output_size, nullptr, nullptr);
  ::CoTaskMemFree(wide_path);
  if (converted != output_size || path.empty()) {
    return std::nullopt;
  }
  return path;
}

}  // namespace

WindowsAppStorage::WindowsAppStorage(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsAppStorage::~WindowsAppStorage() {
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
}

void WindowsAppStorage::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name() != kGetAppSupportDirectoryMethod) {
    result->NotImplemented();
    return;
  }

  const auto path = LocalAppDataPath();
  if (!path.has_value()) {
    result->Success(Failure());
    return;
  }
  result->Success(Success(path.value()));
}

EncodableValue WindowsAppStorage::Failure() {
  EncodableMap payload;
  payload[EncodableValue("available")] = EncodableValue(false);
  payload[EncodableValue("warning")] =
      EncodableValue("Native app storage directory is unavailable.");
  return EncodableValue(payload);
}

EncodableValue WindowsAppStorage::Success(const std::string& directory_path) {
  EncodableMap payload;
  payload[EncodableValue("available")] = EncodableValue(true);
  payload[EncodableValue("directoryPath")] = EncodableValue(directory_path);
  return EncodableValue(payload);
}
