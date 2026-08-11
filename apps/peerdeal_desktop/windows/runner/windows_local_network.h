#ifndef RUNNER_WINDOWS_LOCAL_NETWORK_H_
#define RUNNER_WINDOWS_LOCAL_NETWORK_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>
#include <vector>

class WindowsLocalNetwork final {
 public:
  explicit WindowsLocalNetwork(flutter::BinaryMessenger* messenger);
  ~WindowsLocalNetwork();

  WindowsLocalNetwork(const WindowsLocalNetwork&) = delete;
  WindowsLocalNetwork& operator=(const WindowsLocalNetwork&) = delete;

 private:
  struct NetworkSnapshot {
    bool available = false;
    bool broadcast_supported = false;
    std::vector<std::string> interface_hints;
  };

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  static NetworkSnapshot ReadNetworkSnapshot();
  static flutter::EncodableValue CapabilityPayload(
      const NetworkSnapshot& snapshot);
  static flutter::EncodableValue DiscoveryPayload(
      const NetworkSnapshot& snapshot);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_WINDOWS_LOCAL_NETWORK_H_
