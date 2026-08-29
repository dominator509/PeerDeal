// Winsock must be included before Windows headers.
#include "windows_native_transport.h"

#include <iphlpapi.h>
#include <ws2tcpip.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cwctype>
#include <limits>
#include <optional>
#include <utility>
#include <variant>

#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannelName[] = "peerdeal/native_bridges/transport";
constexpr char kGetCapabilityMethod[] = "getCapability";
constexpr char kSendFrameMethod[] = "sendFrame";
constexpr char kReceiveFramesMethod[] = "receiveFrames";
constexpr char kMulticastAddress[] = "239.255.42.99";
constexpr unsigned short kPort = 40442;
constexpr std::size_t kMaxPayloadBytes = 60 * 1024;
constexpr std::size_t kMaxIdBytes = 256;
constexpr std::size_t kMaxQueueSize = 512;
constexpr std::size_t kMaxBatchSize = 64;
constexpr std::size_t kMaxActiveReceiveScopes = 32;
constexpr auto kActiveReceiveScopeTtl = std::chrono::seconds(15);
constexpr auto kReceiveErrorBackoff = std::chrono::milliseconds(25);
constexpr ULONG kInitialAdapterBufferBytes = 16 * 1024;
constexpr ULONG kMaxAdapterBufferBytes = 1024 * 1024;
constexpr std::size_t kMaxAdapterCount = 64;
constexpr std::size_t kMaxUnicastAddressCount = 256;
constexpr std::size_t kHeaderBytes = 19;
constexpr uint8_t kVersion = 1;
constexpr std::array<uint8_t, 4> kMagic = {'P', 'D', 'L', '1'};

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

const char* SendFailureWarning(int error) {
  switch (error) {
    case WSAEACCES:
      return "Native transport multicast send is blocked by host policy.";
    case WSAEADDRNOTAVAIL:
      return "Native transport multicast interface is unavailable.";
    case WSAENETUNREACH:
    case WSAEHOSTUNREACH:
      return "Native transport multicast route is unavailable.";
    default:
      return "Native transport send failed.";
  }
}

std::optional<in_addr> SelectMulticastInterface() {
  ULONG buffer_size = kInitialAdapterBufferBytes;
  std::vector<uint8_t> buffer(buffer_size);
  const ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_DNS_SERVER;
  ULONG status = ::GetAdaptersAddresses(
      AF_INET, flags, nullptr,
      reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  if (status == ERROR_BUFFER_OVERFLOW) {
    if (buffer_size > kMaxAdapterBufferBytes) {
      return std::nullopt;
    }
    buffer.resize(buffer_size);
    status = ::GetAdaptersAddresses(
        AF_INET, flags, nullptr,
        reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  }
  if (status != NO_ERROR) return std::nullopt;

  std::optional<in_addr> selected;
  ULONG selected_metric = std::numeric_limits<ULONG>::max();
  const auto* adapters =
      reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data());
  std::size_t adapter_count = 0;
  for (const auto* adapter = adapters;
       adapter != nullptr && adapter_count < kMaxAdapterCount;
       adapter = adapter->Next, ++adapter_count) {
    if (adapter->OperStatus != IfOperStatusUp ||
        adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK ||
        (adapter->Flags & IP_ADAPTER_NO_MULTICAST) != 0) {
      continue;
    }
    std::size_t address_count = 0;
    for (const auto* address = adapter->FirstUnicastAddress;
         address != nullptr && address_count < kMaxUnicastAddressCount;
         address = address->Next, ++address_count) {
      const auto* socket_address = address->Address.lpSockaddr;
      if (socket_address == nullptr || socket_address->sa_family != AF_INET) {
        continue;
      }
      const auto* ipv4 = reinterpret_cast<const sockaddr_in*>(socket_address);
      const uint32_t host_address = ntohl(ipv4->sin_addr.s_addr);
      const bool is_unspecified = host_address == 0;
      const bool is_loopback = (host_address & 0xff000000u) == 0x7f000000u;
      const bool is_apipa = (host_address & 0xffff0000u) == 0xa9fe0000u;
      const bool is_broadcast = host_address == 0xffffffffu;
      if (is_unspecified || is_loopback || is_apipa || is_broadcast) continue;
      if (!selected.has_value() || adapter->Ipv4Metric < selected_metric) {
        selected = ipv4->sin_addr;
        selected_metric = adapter->Ipv4Metric;
      }
      break;
    }
  }
  return selected;
}

const EncodableMap* ArgumentsMap(
    const flutter::MethodCall<EncodableValue>& method_call) {
  const auto* arguments = method_call.arguments();
  if (arguments == nullptr) return nullptr;
  return std::get_if<EncodableMap>(arguments);
}

const EncodableValue* MapValue(const EncodableMap& map, const char* key) {
  const auto found = map.find(EncodableValue(std::string(key)));
  return found == map.end() ? nullptr : &found->second;
}

bool Utf8ToWide(const std::string& value, std::wstring* output) {
  if (value.empty() ||
      value.size() > static_cast<std::size_t>(std::numeric_limits<int>::max())) {
    return false;
  }
  const int input_size = static_cast<int>(value.size());
  const int output_size = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), input_size, nullptr, 0);
  if (output_size <= 0) return false;
  output->resize(static_cast<std::size_t>(output_size));
  return ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                               input_size, output->data(), output_size) ==
         output_size;
}

bool IsSafeText(const std::string& value) {
  if (value.empty() || value.size() > kMaxIdBytes) return false;
  std::wstring wide;
  if (!Utf8ToWide(value, &wide) || wide.empty() ||
      std::iswspace(wide.front()) || std::iswspace(wide.back())) {
    return false;
  }
  for (const wchar_t character : wide) {
    const auto code_point = static_cast<std::uint32_t>(character);
    if (code_point < 0x20 || (code_point >= 0x7f && code_point <= 0x9f)) {
      return false;
    }
  }
  return true;
}

std::optional<std::string> StringValue(const EncodableValue* value) {
  const auto* text =
      value == nullptr ? nullptr : std::get_if<std::string>(value);
  if (text == nullptr || !IsSafeText(*text)) return std::nullopt;
  return *text;
}

std::optional<uint32_t> SequenceValue(const EncodableValue* value) {
  if (value == nullptr) return std::nullopt;
  int64_t sequence = 0;
  if (const auto* int32_value = std::get_if<int32_t>(value);
      int32_value != nullptr) {
    sequence = *int32_value;
  } else if (const auto* int64_value = std::get_if<int64_t>(value);
             int64_value != nullptr) {
    sequence = *int64_value;
  } else {
    return std::nullopt;
  }
  if (sequence < 1 ||
      sequence > std::numeric_limits<int32_t>::max()) {
    return std::nullopt;
  }
  return static_cast<uint32_t>(sequence);
}

std::optional<std::vector<uint8_t>> ByteListValue(const EncodableValue* value) {
  if (value == nullptr) return std::nullopt;
  if (const auto* bytes = std::get_if<std::vector<uint8_t>>(value);
      bytes != nullptr) {
    if (bytes->empty() || bytes->size() > kMaxPayloadBytes) {
      return std::nullopt;
    }
    return *bytes;
  }

  const auto* list = std::get_if<EncodableList>(value);
  if (list == nullptr || list->empty() || list->size() > kMaxPayloadBytes) {
    return std::nullopt;
  }
  std::vector<uint8_t> bytes;
  bytes.reserve(list->size());
  for (const auto& item : *list) {
    int64_t byte = -1;
    if (const auto* int32_value = std::get_if<int32_t>(&item);
        int32_value != nullptr) {
      byte = *int32_value;
    } else if (const auto* int64_value = std::get_if<int64_t>(&item);
               int64_value != nullptr) {
      byte = *int64_value;
    }
    if (byte < 0 || byte > 255) return std::nullopt;
    bytes.push_back(static_cast<uint8_t>(byte));
  }
  return bytes;
}

void AppendUint16(std::vector<uint8_t>* output, uint16_t value) {
  output->push_back(static_cast<uint8_t>((value >> 8) & 0xff));
  output->push_back(static_cast<uint8_t>(value & 0xff));
}

void AppendUint32(std::vector<uint8_t>* output, uint32_t value) {
  output->push_back(static_cast<uint8_t>((value >> 24) & 0xff));
  output->push_back(static_cast<uint8_t>((value >> 16) & 0xff));
  output->push_back(static_cast<uint8_t>((value >> 8) & 0xff));
  output->push_back(static_cast<uint8_t>(value & 0xff));
}

bool ReadUint16(const uint8_t* bytes, std::size_t length, std::size_t* offset,
                uint16_t* value) {
  if (*offset + 2 > length) return false;
  *value = static_cast<uint16_t>(bytes[*offset] << 8 | bytes[*offset + 1]);
  *offset += 2;
  return true;
}

bool ReadUint32(const uint8_t* bytes, std::size_t length, std::size_t* offset,
                uint32_t* value) {
  if (*offset + 4 > length) return false;
  *value = (static_cast<uint32_t>(bytes[*offset]) << 24) |
           (static_cast<uint32_t>(bytes[*offset + 1]) << 16) |
           (static_cast<uint32_t>(bytes[*offset + 2]) << 8) |
           static_cast<uint32_t>(bytes[*offset + 3]);
  *offset += 4;
  return true;
}

EncodableValue ReceivePayload(
    std::deque<WindowsNativeTransport::TransportFrame>* queue,
    std::mutex* queue_mutex, const std::string& session_id,
    const std::string& peer_id) {
  EncodableList output_frames;
  std::deque<WindowsNativeTransport::TransportFrame> retained;
  {
    std::lock_guard<std::mutex> lock(*queue_mutex);
    const std::size_t count = queue->size();
    for (std::size_t index = 0; index < count; ++index) {
      auto frame = std::move(queue->front());
      queue->pop_front();
      if (output_frames.size() < kMaxBatchSize &&
          frame.session_id == session_id &&
          frame.recipient_peer_id == peer_id) {
        EncodableMap payload;
        payload.emplace(EncodableValue("sessionId"),
                        EncodableValue(frame.session_id));
        payload.emplace(EncodableValue("senderPeerId"),
                        EncodableValue(frame.sender_peer_id));
        payload.emplace(EncodableValue("recipientPeerId"),
                        EncodableValue(frame.recipient_peer_id));
        payload.emplace(EncodableValue("sequence"),
                        EncodableValue(static_cast<int64_t>(frame.sequence)));
        EncodableList bytes;
        bytes.reserve(frame.payload.size());
        for (const uint8_t byte : frame.payload) {
          bytes.emplace_back(static_cast<int32_t>(byte));
        }
        payload.emplace(EncodableValue("payloadBytes"),
                        EncodableValue(std::move(bytes)));
        output_frames.emplace_back(EncodableValue(std::move(payload)));
      } else {
        retained.push_back(std::move(frame));
      }
    }
    queue->swap(retained);
  }

  EncodableMap payload;
  payload.emplace(EncodableValue("available"), EncodableValue(true));
  payload.emplace(EncodableValue("frames"),
                  EncodableValue(std::move(output_frames)));
  return EncodableValue(std::move(payload));
}

}  // namespace

WindowsNativeTransport::WindowsNativeTransport(
    flutter::BinaryMessenger* messenger) {
  InitializeSocket();
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsNativeTransport::~WindowsNativeTransport() {
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  stopping_.store(true);
  SOCKET socket = INVALID_SOCKET;
  {
    std::lock_guard<std::mutex> lock(lifecycle_mutex_);
    socket = socket_;
    socket_ = INVALID_SOCKET;
  }
  if (socket != INVALID_SOCKET) {
    ::closesocket(socket);
  }
  if (receive_thread_.joinable()) receive_thread_.join();
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    frames_.clear();
    active_receive_scopes_.clear();
  }
  if (wsa_started_) ::WSACleanup();
}

bool WindowsNativeTransport::InitializeSocket() {
  std::lock_guard<std::mutex> lock(lifecycle_mutex_);
  return InitializeSocketLocked();
}

bool WindowsNativeTransport::EnsureSocket() {
  std::lock_guard<std::mutex> lock(lifecycle_mutex_);
  if (socket_ != INVALID_SOCKET) return true;
  return InitializeSocketLocked();
}

bool WindowsNativeTransport::InitializeSocketLocked() {
  WSADATA data{};
  if (::WSAStartup(MAKEWORD(2, 2), &data) != 0) return false;
  wsa_started_ = true;

  const auto fail_initialization = [this]() {
    if (socket_ != INVALID_SOCKET) {
      ::closesocket(socket_);
      socket_ = INVALID_SOCKET;
    }
    if (wsa_started_) {
      ::WSACleanup();
      wsa_started_ = false;
    }
    return false;
  };

  socket_ = ::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if (socket_ == INVALID_SOCKET) return fail_initialization();
  const auto multicast_interface = SelectMulticastInterface();
  if (!multicast_interface.has_value()) return fail_initialization();
  if (::setsockopt(
          socket_, IPPROTO_IP, IP_MULTICAST_IF,
          reinterpret_cast<const char*>(&multicast_interface.value()),
          sizeof(multicast_interface.value())) == SOCKET_ERROR) {
    return fail_initialization();
  }
  const BOOL reuse = TRUE;
  if (::setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR,
                   reinterpret_cast<const char*>(&reuse), sizeof(reuse)) ==
      SOCKET_ERROR) {
    return fail_initialization();
  }

  sockaddr_in local{};
  local.sin_family = AF_INET;
  local.sin_port = htons(kPort);
  local.sin_addr.s_addr = htonl(INADDR_ANY);
  if (::bind(socket_, reinterpret_cast<const sockaddr*>(&local), sizeof(local)) ==
      SOCKET_ERROR) {
    return fail_initialization();
  }

  ip_mreq membership{};
  if (::InetPtonA(AF_INET, kMulticastAddress, &membership.imr_multiaddr) != 1) {
    return fail_initialization();
  }
  membership.imr_interface = multicast_interface.value();
  if (::setsockopt(socket_, IPPROTO_IP, IP_ADD_MEMBERSHIP,
                   reinterpret_cast<const char*>(&membership),
                   sizeof(membership)) == SOCKET_ERROR) {
    return fail_initialization();
  }

  const unsigned char ttl = 1;
  if (::setsockopt(socket_, IPPROTO_IP, IP_MULTICAST_TTL,
                   reinterpret_cast<const char*>(&ttl), sizeof(ttl)) ==
      SOCKET_ERROR) {
    return fail_initialization();
  }
  stopping_ = false;
  receive_thread_ = std::thread([this]() { ReceiveLoop(); });
  return true;
}

void WindowsNativeTransport::ReceiveLoop() {
  std::array<uint8_t, kHeaderBytes + kMaxPayloadBytes> buffer{};
  SOCKET receive_socket = INVALID_SOCKET;
  {
    std::lock_guard<std::mutex> lock(lifecycle_mutex_);
    receive_socket = socket_;
  }
  if (receive_socket == INVALID_SOCKET) return;

  while (!stopping_) {
    sockaddr_storage source{};
    int source_length = sizeof(source);
    const int received = ::recvfrom(
        receive_socket, reinterpret_cast<char*>(buffer.data()),
        static_cast<int>(buffer.size()), 0,
        reinterpret_cast<sockaddr*>(&source), &source_length);
    if (received == SOCKET_ERROR) {
      if (stopping_) return;
      // Keep persistent host/socket errors from becoming a busy retry loop.
      std::this_thread::sleep_for(kReceiveErrorBackoff);
      continue;
    }
    auto frame = DecodeFrame(buffer.data(), static_cast<std::size_t>(received));
    if (!frame.has_value()) continue;
    std::lock_guard<std::mutex> lock(queue_mutex_);
    const auto now = std::chrono::steady_clock::now();
    PruneInactiveReceiveScopesLocked(now);
    if (IsFrameAdmittedLocked(frame.value())) {
      while (frames_.size() >= kMaxQueueSize) frames_.pop_front();
      frames_.push_back(std::move(frame.value()));
    }
  }
}

void WindowsNativeTransport::RegisterReceiveScope(
    const std::string& session_id, const std::string& peer_id) {
  std::lock_guard<std::mutex> lock(queue_mutex_);
  const auto now = std::chrono::steady_clock::now();
  PruneInactiveReceiveScopesLocked(now);
  const auto existing = std::find_if(
      active_receive_scopes_.begin(), active_receive_scopes_.end(),
      [&session_id, &peer_id](const ReceiveScope& scope) {
        return scope.session_id == session_id && scope.peer_id == peer_id;
      });
  if (existing != active_receive_scopes_.end()) {
    active_receive_scopes_.erase(existing);
    active_receive_scopes_.push_back(ReceiveScope{session_id, peer_id, now});
    return;
  }
  active_receive_scopes_.push_back(ReceiveScope{session_id, peer_id, now});
  if (active_receive_scopes_.size() > kMaxActiveReceiveScopes) {
    active_receive_scopes_.erase(active_receive_scopes_.begin());
  }
}

void WindowsNativeTransport::PruneInactiveFrames() {
  std::lock_guard<std::mutex> lock(queue_mutex_);
  const auto now = std::chrono::steady_clock::now();
  PruneInactiveReceiveScopesLocked(now);
  std::deque<TransportFrame> retained;
  while (!frames_.empty()) {
    auto frame = std::move(frames_.front());
    frames_.pop_front();
    if (IsFrameAdmittedLocked(frame)) retained.push_back(std::move(frame));
  }
  frames_.swap(retained);
}

void WindowsNativeTransport::PruneInactiveReceiveScopesLocked(
    std::chrono::steady_clock::time_point now) {
  active_receive_scopes_.erase(
      std::remove_if(
          active_receive_scopes_.begin(), active_receive_scopes_.end(),
          [now](const ReceiveScope& scope) {
            return now - scope.last_seen > kActiveReceiveScopeTtl;
          }),
      active_receive_scopes_.end());
}

bool WindowsNativeTransport::IsFrameAdmittedLocked(
    const TransportFrame& frame) const {
  return std::any_of(
      active_receive_scopes_.begin(), active_receive_scopes_.end(),
      [&frame](const ReceiveScope& scope) {
        return scope.session_id == frame.session_id &&
               scope.peer_id == frame.recipient_peer_id;
      });
}

void WindowsNativeTransport::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  try {
    if (method_call.method_name() == kGetCapabilityMethod) {
      EnsureSocket();
      bool available = false;
      {
        std::lock_guard<std::mutex> lock(lifecycle_mutex_);
        available = socket_ != INVALID_SOCKET;
      }
      result->Success(CapabilityPayload(available));
      return;
    }
    if (method_call.method_name() == kSendFrameMethod) {
      const auto* arguments = ArgumentsMap(method_call);
      const auto* frame_value =
          arguments == nullptr ? nullptr : MapValue(*arguments, "frame");
      const auto* frame_arguments =
          frame_value == nullptr ? nullptr
                                 : std::get_if<EncodableMap>(frame_value);
      const auto frame = frame_arguments == nullptr
                             ? std::nullopt
                             : FrameFromArguments(*frame_arguments);
      if (!frame.has_value()) {
        result->Success(Failure("Native transport frame is invalid."));
        return;
      }
      if (!EnsureSocket()) {
        result->Success(Failure("Native transport frame is unavailable."));
        return;
      }
      std::vector<uint8_t> bytes;
      bytes.reserve(kHeaderBytes + frame->payload.size());
      bytes.insert(bytes.end(), kMagic.begin(), kMagic.end());
      bytes.push_back(kVersion);
      AppendUint16(&bytes, static_cast<uint16_t>(frame->session_id.size()));
      AppendUint16(&bytes, static_cast<uint16_t>(frame->sender_peer_id.size()));
      AppendUint16(&bytes,
                   static_cast<uint16_t>(frame->recipient_peer_id.size()));
      AppendUint32(&bytes, frame->sequence);
      AppendUint32(&bytes, static_cast<uint32_t>(frame->payload.size()));
      bytes.insert(bytes.end(), frame->session_id.begin(), frame->session_id.end());
      bytes.insert(bytes.end(), frame->sender_peer_id.begin(), frame->sender_peer_id.end());
      bytes.insert(bytes.end(), frame->recipient_peer_id.begin(), frame->recipient_peer_id.end());
      bytes.insert(bytes.end(), frame->payload.begin(), frame->payload.end());

      sockaddr_in destination{};
      destination.sin_family = AF_INET;
      destination.sin_port = htons(kPort);
      if (::InetPtonA(AF_INET, kMulticastAddress, &destination.sin_addr) != 1) {
        result->Success(Failure("Native transport destination is invalid."));
        return;
      }
      int sent = SOCKET_ERROR;
      int send_error = 0;
      bool available = false;
      {
        std::lock_guard<std::mutex> lock(lifecycle_mutex_);
        if (socket_ != INVALID_SOCKET) {
          available = true;
          sent = ::sendto(
              socket_, reinterpret_cast<const char*>(bytes.data()),
              static_cast<int>(bytes.size()), 0,
              reinterpret_cast<const sockaddr*>(&destination),
              sizeof(destination));
          if (sent == SOCKET_ERROR) send_error = ::WSAGetLastError();
        }
      }
      if (!available) {
        result->Success(Failure("Native transport frame is unavailable."));
        return;
      }
      if (sent != static_cast<int>(bytes.size())) {
        result->Success(Failure(SendFailureWarning(send_error)));
        return;
      }
      result->Success(Success());
      return;
    }
    if (method_call.method_name() == kReceiveFramesMethod) {
      const auto* arguments = ArgumentsMap(method_call);
      const auto session_id = arguments == nullptr
                                  ? std::nullopt
                                  : StringValue(MapValue(*arguments, "sessionId"));
      const auto peer_id = arguments == nullptr
                               ? std::nullopt
                               : StringValue(MapValue(*arguments, "peerId"));
      if (!session_id.has_value() || !peer_id.has_value()) {
        result->Success(
            Failure("Native transport receive request is invalid."));
        return;
      }
      EnsureSocket();
      bool available = false;
      {
        std::lock_guard<std::mutex> lock(lifecycle_mutex_);
        available = socket_ != INVALID_SOCKET;
      }
      if (!available) {
        result->Success(Failure("Native transport receive is unavailable."));
        return;
      }
      RegisterReceiveScope(session_id.value(), peer_id.value());
      PruneInactiveFrames();
      result->Success(ReceivePayload(&frames_, &queue_mutex_, session_id.value(),
                                     peer_id.value()));
      return;
    }
    result->NotImplemented();
  } catch (...) {
    result->Success(Failure("Native transport action failed."));
  }
}

std::optional<WindowsNativeTransport::TransportFrame>
WindowsNativeTransport::FrameFromArguments(const EncodableMap& arguments) {
  const auto session_id = StringValue(MapValue(arguments, "sessionId"));
  const auto sender_peer_id = StringValue(MapValue(arguments, "senderPeerId"));
  const auto recipient_peer_id =
      StringValue(MapValue(arguments, "recipientPeerId"));
  const auto sequence = SequenceValue(MapValue(arguments, "sequence"));
  const auto payload = ByteListValue(MapValue(arguments, "payloadBytes"));
  if (!session_id.has_value() || !sender_peer_id.has_value() ||
      !recipient_peer_id.has_value() || !sequence.has_value() ||
      !payload.has_value() || sender_peer_id == recipient_peer_id) {
    return std::nullopt;
  }
  return TransportFrame{session_id.value(), sender_peer_id.value(),
                        recipient_peer_id.value(), sequence.value(),
                        payload.value()};
}

std::optional<WindowsNativeTransport::TransportFrame>
WindowsNativeTransport::DecodeFrame(const uint8_t* bytes, std::size_t length) {
  if (bytes == nullptr || length < kHeaderBytes ||
      !std::equal(kMagic.begin(), kMagic.end(), bytes)) {
    return std::nullopt;
  }
  std::size_t offset = kMagic.size();
  if (bytes[offset++] != kVersion) return std::nullopt;
  uint16_t session_length = 0;
  uint16_t sender_length = 0;
  uint16_t recipient_length = 0;
  uint32_t sequence = 0;
  uint32_t payload_length = 0;
  if (!ReadUint16(bytes, length, &offset, &session_length) ||
      !ReadUint16(bytes, length, &offset, &sender_length) ||
      !ReadUint16(bytes, length, &offset, &recipient_length) ||
      !ReadUint32(bytes, length, &offset, &sequence) ||
      !ReadUint32(bytes, length, &offset, &payload_length) || sequence < 1 ||
      sequence > static_cast<uint32_t>(std::numeric_limits<int32_t>::max()) ||
      session_length > kMaxIdBytes || sender_length > kMaxIdBytes ||
      recipient_length > kMaxIdBytes || payload_length < 1 ||
      payload_length > static_cast<uint32_t>(kMaxPayloadBytes) ||
      length != offset + session_length + sender_length + recipient_length +
                    payload_length) {
    return std::nullopt;
  }

  const std::string session_id(reinterpret_cast<const char*>(bytes + offset),
                               session_length);
  offset += session_length;
  const std::string sender_peer_id(
      reinterpret_cast<const char*>(bytes + offset), sender_length);
  offset += sender_length;
  const std::string recipient_peer_id(
      reinterpret_cast<const char*>(bytes + offset), recipient_length);
  offset += recipient_length;
  if (!IsSafeText(session_id) || !IsSafeText(sender_peer_id) ||
      !IsSafeText(recipient_peer_id) || sender_peer_id == recipient_peer_id) {
    return std::nullopt;
  }
  std::vector<uint8_t> payload(bytes + offset, bytes + offset + payload_length);
  return TransportFrame{session_id, sender_peer_id, recipient_peer_id, sequence,
                        std::move(payload)};
}

EncodableValue WindowsNativeTransport::CapabilityPayload(bool available) {
  EncodableMap payload;
  payload.emplace(EncodableValue("available"), EncodableValue(available));
  payload.emplace(EncodableValue("sendSupported"), EncodableValue(available));
  payload.emplace(EncodableValue("receiveSupported"),
                  EncodableValue(available));
  payload.emplace(EncodableValue("maxPayloadBytes"),
                  EncodableValue(static_cast<int32_t>(
                      available ? kMaxPayloadBytes : 0)));
  payload.emplace(EncodableValue("notes"),
                  EncodableValue(available ? "windows-udp-multicast"
                                            : "unavailable"));
  if (!available) {
    payload.emplace(EncodableValue("warning"),
                    EncodableValue("Native transport socket is unavailable."));
  }
  return EncodableValue(std::move(payload));
}

EncodableValue WindowsNativeTransport::Failure(const char* warning) {
  EncodableMap payload;
  payload.emplace(EncodableValue("success"), EncodableValue(false));
  payload.emplace(EncodableValue("warning"), EncodableValue(warning));
  return EncodableValue(std::move(payload));
}

EncodableValue WindowsNativeTransport::Success() {
  EncodableMap payload;
  payload.emplace(EncodableValue("success"), EncodableValue(true));
  return EncodableValue(std::move(payload));
}
