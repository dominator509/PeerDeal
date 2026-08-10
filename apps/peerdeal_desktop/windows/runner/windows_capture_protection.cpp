// This must be included before many other Windows headers.
#include <windows.h>

#include "windows_capture_protection.h"

#include <VersionHelpers.h>

#include <string>
#include <utility>
#include <variant>

#include <flutter/standard_method_codec.h>

#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x11
#endif

namespace {

constexpr char kChannelName[] =
    "peerdeal/native_bridges/capture_protection";
constexpr char kGetCapabilityMethod[] = "getCapability";
constexpr char kSetBlockingMethod[] = "setBlocking";
constexpr DWORD kCaptureExclusionMinimumBuild = 19041;

using flutter::EncodableMap;
using flutter::EncodableValue;

const EncodableMap* ArgumentsMap(
    const flutter::MethodCall<EncodableValue>& method_call) {
  const auto* arguments = method_call.arguments();
  if (arguments == nullptr) {
    return nullptr;
  }
  return std::get_if<EncodableMap>(arguments);
}

const EncodableValue* MapValue(const EncodableMap& map, const char* key) {
  const auto found = map.find(EncodableValue(std::string(key)));
  return found == map.end() ? nullptr : &found->second;
}

bool IsWindowsBuildOrGreater(DWORD minimum_build) {
  OSVERSIONINFOEXW version{};
  version.dwOSVersionInfoSize = sizeof(version);
  version.dwMajorVersion = 10;
  version.dwMinorVersion = 0;
  version.dwBuildNumber = minimum_build;

  DWORDLONG condition_mask = 0;
  condition_mask = ::VerSetConditionMask(
      condition_mask, VER_MAJORVERSION, VER_GREATER_EQUAL);
  condition_mask = ::VerSetConditionMask(
      condition_mask, VER_MINORVERSION, VER_GREATER_EQUAL);
  condition_mask = ::VerSetConditionMask(
      condition_mask, VER_BUILDNUMBER, VER_GREATER_EQUAL);
  return ::VerifyVersionInfoW(
             &version, VER_MAJORVERSION | VER_MINORVERSION | VER_BUILDNUMBER,
             condition_mask) != FALSE;
}

bool SupportsCaptureExclusion(HWND window) {
  return window != nullptr && IsWindows10OrGreater() &&
         IsWindowsBuildOrGreater(kCaptureExclusionMinimumBuild);
}

EncodableValue CapabilityPayload(HWND window) {
  EncodableMap payload;
  const bool supported = SupportsCaptureExclusion(window);
  payload.emplace(EncodableValue("blockingSupported"),
                  EncodableValue(supported));
  payload.emplace(EncodableValue("obscuringSupported"),
                  EncodableValue(supported));
  payload.emplace(EncodableValue("notes"),
                  EncodableValue(supported ? "windows-display-affinity"
                                            : "unavailable"));
  if (!supported) {
    payload.emplace(
        EncodableValue("warning"),
        EncodableValue("Windows capture protection is unavailable."));
  }
  return EncodableValue(std::move(payload));
}

EncodableValue ActionFailure(const char* warning) {
  EncodableMap payload;
  payload.emplace(EncodableValue("success"), EncodableValue(false));
  payload.emplace(EncodableValue("blockingEnabled"), EncodableValue(false));
  payload.emplace(EncodableValue("warning"), EncodableValue(warning));
  return EncodableValue(std::move(payload));
}

EncodableValue ActionSuccess(bool enabled) {
  EncodableMap payload;
  payload.emplace(EncodableValue("success"), EncodableValue(true));
  payload.emplace(EncodableValue("blockingEnabled"), EncodableValue(enabled));
  return EncodableValue(std::move(payload));
}

}  // namespace

WindowsCaptureProtection::WindowsCaptureProtection(
    flutter::BinaryMessenger* messenger,
    HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsCaptureProtection::~WindowsCaptureProtection() {
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
}

void WindowsCaptureProtection::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  try {
    if (method_call.method_name() == kGetCapabilityMethod) {
      result->Success(CapabilityPayload(window_));
      return;
    }

    if (method_call.method_name() == kSetBlockingMethod) {
      const auto* arguments = ArgumentsMap(method_call);
      const auto* enabled_value =
          arguments == nullptr ? nullptr : MapValue(*arguments, "enabled");
      const auto* enabled = enabled_value == nullptr
                                ? nullptr
                                : std::get_if<bool>(enabled_value);
      if (enabled == nullptr) {
        result->Success(
            ActionFailure("Capture protection request is invalid."));
        return;
      }
      if (window_ == nullptr ||
          (*enabled && !SupportsCaptureExclusion(window_))) {
        result->Success(
            ActionFailure("Windows capture protection is unavailable."));
        return;
      }

      const DWORD affinity = *enabled ? WDA_EXCLUDEFROMCAPTURE : WDA_NONE;
      if (::SetWindowDisplayAffinity(window_, affinity) == FALSE) {
        result->Success(ActionFailure("Capture protection action failed."));
        return;
      }
      result->Success(ActionSuccess(*enabled));
      return;
    }

    result->NotImplemented();
  } catch (...) {
    if (method_call.method_name() == kGetCapabilityMethod) {
      result->Success(CapabilityPayload(nullptr));
    } else {
      result->Success(ActionFailure("Capture protection action failed."));
    }
  }
}
