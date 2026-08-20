#ifndef RUNNER_WINDOWS_NATIVE_TRANSPORT_H_
#define RUNNER_WINDOWS_NATIVE_TRANSPORT_H_

#include <winsock2.h>

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

class WindowsNativeTransport final {
 public:
  struct TransportFrame {
    std::string session_id;
    std::string sender_peer_id;
    std::string recipient_peer_id;
    uint32_t sequence = 0;
    std::vector<uint8_t> payload;
  };

  struct ReceiveScope {
    std::string session_id;
    std::string peer_id;
    std::chrono::steady_clock::time_point last_seen;
  };

  explicit WindowsNativeTransport(flutter::BinaryMessenger* messenger);
  ~WindowsNativeTransport();

  WindowsNativeTransport(const WindowsNativeTransport&) = delete;
  WindowsNativeTransport& operator=(const WindowsNativeTransport&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  bool InitializeSocket();
  bool EnsureSocket();
  bool InitializeSocketLocked();
  void ReceiveLoop();
  void RegisterReceiveScope(const std::string& session_id,
                            const std::string& peer_id);
  void PruneInactiveFrames();
  void PruneInactiveReceiveScopesLocked(
      std::chrono::steady_clock::time_point now);
  bool IsFrameAdmittedLocked(const TransportFrame& frame) const;

  static std::optional<TransportFrame> DecodeFrame(const uint8_t* bytes,
                                                   std::size_t length);
  static std::optional<TransportFrame> FrameFromArguments(
      const flutter::EncodableMap& arguments);
  static flutter::EncodableValue CapabilityPayload(bool available);
  static flutter::EncodableValue Failure(const char* warning);
  static flutter::EncodableValue Success();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  // Protects the socket handle across method calls, receive-thread startup,
  // and teardown.
  std::mutex lifecycle_mutex_;
  SOCKET socket_ = INVALID_SOCKET;
  bool wsa_started_ = false;
  std::thread receive_thread_;
  std::atomic_bool stopping_{false};
  std::mutex queue_mutex_;
  std::deque<TransportFrame> frames_;
  std::vector<ReceiveScope> active_receive_scopes_;
};

#endif  // RUNNER_WINDOWS_NATIVE_TRANSPORT_H_
