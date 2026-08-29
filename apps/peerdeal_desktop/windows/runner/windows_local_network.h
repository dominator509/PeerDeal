#ifndef RUNNER_WINDOWS_LOCAL_NETWORK_H_
#define RUNNER_WINDOWS_LOCAL_NETWORK_H_

#include <winsock2.h>

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
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

  struct DiscoveryAdvertisement {
    uint8_t kind = 0;
    std::string peer_id;
    uint16_t port = 0;
  };

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool EnsureWinsock();
  bool EnsureResponder();
  void ResponderLoop(SOCKET socket);
  std::optional<std::vector<std::string>> DiscoverEndpoints();

  static NetworkSnapshot ReadNetworkSnapshot();
  static std::optional<in_addr> SelectMulticastInterface();
  static flutter::EncodableValue CapabilityPayload(
      const NetworkSnapshot& snapshot);
  flutter::EncodableValue DiscoveryPayload(
      const NetworkSnapshot& snapshot);
  static flutter::EncodableValue AnnouncementPayload(
      bool published,
      const char* warning = nullptr);
  static std::optional<std::string> PeerIdFromArguments(
      const flutter::EncodableMap* arguments);
  static std::optional<uint16_t> PortFromArguments(
      const flutter::EncodableMap* arguments);
  static std::vector<uint8_t> EncodeQuery();
  static std::optional<std::vector<uint8_t>> EncodeAdvertisement(
      const std::string& peer_id,
      uint16_t port);
  static std::optional<DiscoveryAdvertisement> DecodePacket(
      const uint8_t* bytes,
      std::size_t length);
  static bool IsSafePeerId(const std::string& value);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::mutex lifecycle_mutex_;
  SOCKET responder_socket_ = INVALID_SOCKET;
  bool wsa_started_ = false;
  std::thread responder_thread_;
  std::atomic_bool stopping_{false};
  std::mutex announcement_mutex_;
  std::string announced_peer_id_;
  uint16_t announced_port_;
};

#endif  // RUNNER_WINDOWS_LOCAL_NETWORK_H_
