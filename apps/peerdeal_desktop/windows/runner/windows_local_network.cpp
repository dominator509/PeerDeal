#include "windows_local_network.h"

#include <iphlpapi.h>
#include <ws2tcpip.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cwctype>
#include <limits>
#include <utility>

#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannelName[] = "peerdeal/native_bridges/local_network";
constexpr char kGetCapabilityMethod[] = "getCapability";
constexpr char kDiscoverPeersMethod[] = "discoverPeers";
constexpr char kAnnouncePeerMethod[] = "announcePeer";
constexpr const char* kDiscoveryAddress = "239.255.42.100";
constexpr unsigned short kDiscoveryPort = 40443;
constexpr unsigned short kDefaultAdvertisedPort = 40442;
constexpr std::chrono::milliseconds kDiscoveryTimeout(750);
constexpr std::chrono::milliseconds kReceiveErrorBackoff(25);
constexpr std::size_t kMaxIdentityBytes = 256;
constexpr std::size_t kMaxDiscoveryEntries = 64;
constexpr std::size_t kHeaderBytes = 10;
constexpr std::size_t kMaxPacketBytes = kHeaderBytes + kMaxIdentityBytes;
constexpr uint8_t kVersion = 1;
constexpr uint8_t kQueryKind = 1;
constexpr uint8_t kAdvertisementKind = 2;
constexpr std::array<uint8_t, 4> kMagic = {'P', 'D', 'D', '1'};
constexpr ULONG kInitialAddressBufferBytes = 16 * 1024;
constexpr ULONG kMaxAddressBufferBytes = 1024 * 1024;
constexpr std::size_t kMaxAdapterCount = 64;
constexpr std::size_t kMaxUnicastAddressCount = 256;

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

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
  if (value.empty() || value.size() > kMaxIdentityBytes) return false;
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

bool IsSafePeerId(const std::string& value) {
  return IsSafeText(value) && value != "none" && value != "unresolved" &&
         value.find("::") == std::string::npos;
}

bool IsUsableIpv4Address(std::uint32_t host_address) {
  const bool is_unspecified = host_address == 0;
  const bool is_loopback = (host_address & 0xff000000u) == 0x7f000000u;
  const bool is_apipa = (host_address & 0xffff0000u) == 0xa9fe0000u;
  const bool is_broadcast = host_address == 0xffffffffu;
  return !is_unspecified && !is_loopback && !is_apipa && !is_broadcast;
}

void AppendUint16(std::vector<uint8_t>* output, uint16_t value) {
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

}  // namespace

WindowsLocalNetwork::WindowsLocalNetwork(flutter::BinaryMessenger* messenger)
    : announced_port_(kDefaultAdvertisedPort) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsLocalNetwork::~WindowsLocalNetwork() {
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  stopping_.store(true);
  SOCKET socket = INVALID_SOCKET;
  {
    std::lock_guard<std::mutex> lock(lifecycle_mutex_);
    socket = responder_socket_;
    responder_socket_ = INVALID_SOCKET;
  }
  if (socket != INVALID_SOCKET) ::closesocket(socket);
  if (responder_thread_.joinable()) responder_thread_.join();
  if (wsa_started_) {
    ::WSACleanup();
    wsa_started_ = false;
  }
}

void WindowsLocalNetwork::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto& method = method_call.method_name();
  if (method == kGetCapabilityMethod) {
    try {
      result->Success(CapabilityPayload(ReadNetworkSnapshot()));
    } catch (...) {
      result->Success(CapabilityPayload(NetworkSnapshot{}));
    }
    return;
  }
  if (method == kDiscoverPeersMethod) {
    try {
      const auto snapshot = ReadNetworkSnapshot();
      result->Success(DiscoveryPayload(snapshot));
    } catch (...) {
      result->Success(DiscoveryPayload(NetworkSnapshot{}));
    }
    return;
  }
  if (method == kAnnouncePeerMethod) {
    const auto* arguments = ArgumentsMap(method_call);
    const auto peer_id = PeerIdFromArguments(arguments);
    const auto port = PortFromArguments(arguments);
    if (!peer_id.has_value() || !port.has_value()) {
      result->Success(AnnouncementPayload(
          false, "Native local-network announcement request is invalid."));
      return;
    }
    if (!ReadNetworkSnapshot().available) {
      result->Success(
          AnnouncementPayload(false, "Native local network is unavailable."));
      return;
    }
    {
      std::lock_guard<std::mutex> lock(announcement_mutex_);
      announced_peer_id_ = peer_id.value();
      announced_port_ = port.value();
    }
    if (!EnsureResponder()) {
      result->Success(AnnouncementPayload(
          false, "Native local-network discovery responder is unavailable."));
      return;
    }
    result->Success(AnnouncementPayload(true));
    return;
  }
  result->NotImplemented();
}

bool WindowsLocalNetwork::EnsureWinsock() {
  std::lock_guard<std::mutex> lock(lifecycle_mutex_);
  if (wsa_started_) return true;
  WSADATA data{};
  if (::WSAStartup(MAKEWORD(2, 2), &data) != 0) return false;
  wsa_started_ = true;
  return true;
}

bool WindowsLocalNetwork::EnsureResponder() {
  {
    std::lock_guard<std::mutex> lock(lifecycle_mutex_);
    if (stopping_.load()) return false;
    if (responder_socket_ != INVALID_SOCKET) return true;
  }
  if (!EnsureWinsock()) return false;
  const auto multicast_interface = SelectMulticastInterface();
  if (!multicast_interface.has_value()) return false;

  SOCKET candidate = ::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if (candidate == INVALID_SOCKET) return false;
  const auto fail = [candidate]() {
    ::closesocket(candidate);
    return false;
  };
  const BOOL reuse = TRUE;
  if (::setsockopt(candidate, SOL_SOCKET, SO_REUSEADDR,
                   reinterpret_cast<const char*>(&reuse), sizeof(reuse)) ==
      SOCKET_ERROR) {
    return fail();
  }
  if (::setsockopt(candidate, IPPROTO_IP, IP_MULTICAST_IF,
                   reinterpret_cast<const char*>(&multicast_interface.value()),
                   sizeof(multicast_interface.value())) == SOCKET_ERROR) {
    return fail();
  }
  sockaddr_in local{};
  local.sin_family = AF_INET;
  local.sin_port = htons(kDiscoveryPort);
  local.sin_addr.s_addr = htonl(INADDR_ANY);
  if (::bind(candidate, reinterpret_cast<const sockaddr*>(&local),
             sizeof(local)) == SOCKET_ERROR) {
    return fail();
  }
  ip_mreq membership{};
  if (::InetPtonA(AF_INET, kDiscoveryAddress, &membership.imr_multiaddr) != 1) {
    return fail();
  }
  membership.imr_interface = multicast_interface.value();
  if (::setsockopt(candidate, IPPROTO_IP, IP_ADD_MEMBERSHIP,
                   reinterpret_cast<const char*>(&membership),
                   sizeof(membership)) == SOCKET_ERROR) {
    return fail();
  }
  const unsigned char ttl = 1;
  if (::setsockopt(candidate, IPPROTO_IP, IP_MULTICAST_TTL,
                   reinterpret_cast<const char*>(&ttl), sizeof(ttl)) ==
      SOCKET_ERROR) {
    return fail();
  }

  stopping_.store(false);
  {
    std::lock_guard<std::mutex> lock(lifecycle_mutex_);
    if (stopping_.load() || responder_socket_ != INVALID_SOCKET) {
      ::closesocket(candidate);
      return responder_socket_ != INVALID_SOCKET && !stopping_.load();
    }
    responder_socket_ = candidate;
    responder_thread_ = std::thread(
        [this, candidate]() { ResponderLoop(candidate); });
  }
  return true;
}

void WindowsLocalNetwork::ResponderLoop(SOCKET socket) {
  std::array<uint8_t, kMaxPacketBytes> buffer{};
  while (!stopping_.load()) {
    sockaddr_storage source{};
    int source_length = sizeof(source);
    const int received = ::recvfrom(
        socket, reinterpret_cast<char*>(buffer.data()),
        static_cast<int>(buffer.size()), 0,
        reinterpret_cast<sockaddr*>(&source), &source_length);
    if (received == SOCKET_ERROR) {
      if (stopping_.load()) return;
      std::this_thread::sleep_for(kReceiveErrorBackoff);
      continue;
    }
    if (source.ss_family != AF_INET) continue;
    const auto decoded = DecodePacket(buffer.data(),
                                      static_cast<std::size_t>(received));
    if (!decoded.has_value() || decoded->kind != kQueryKind) continue;
    std::string peer_id;
    uint16_t port = 0;
    {
      std::lock_guard<std::mutex> lock(announcement_mutex_);
      peer_id = announced_peer_id_;
      port = announced_port_;
    }
    if (peer_id.empty()) continue;
    const auto response = EncodeAdvertisement(peer_id, port);
    if (!response.has_value()) continue;
    const auto* source_address = reinterpret_cast<const sockaddr_in*>(&source);
    ::sendto(socket, reinterpret_cast<const char*>(response->data()),
              static_cast<int>(response->size()), 0,
              reinterpret_cast<const sockaddr*>(source_address),
              sizeof(sockaddr_in));
  }
}

std::optional<std::vector<std::string>> WindowsLocalNetwork::DiscoverEndpoints() {
  if (!EnsureWinsock()) return std::nullopt;
  const auto multicast_interface = SelectMulticastInterface();
  if (!multicast_interface.has_value()) return std::nullopt;
  SOCKET socket = ::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if (socket == INVALID_SOCKET) return std::nullopt;
  const auto close_socket = [socket]() { ::closesocket(socket); };
  const BOOL reuse = TRUE;
  if (::setsockopt(socket, SOL_SOCKET, SO_REUSEADDR,
                   reinterpret_cast<const char*>(&reuse), sizeof(reuse)) ==
      SOCKET_ERROR) {
    close_socket();
    return std::nullopt;
  }
  if (::setsockopt(socket, IPPROTO_IP, IP_MULTICAST_IF,
                   reinterpret_cast<const char*>(&multicast_interface.value()),
                   sizeof(multicast_interface.value())) == SOCKET_ERROR) {
    close_socket();
    return std::nullopt;
  }
  const unsigned char ttl = 1;
  if (::setsockopt(socket, IPPROTO_IP, IP_MULTICAST_TTL,
                   reinterpret_cast<const char*>(&ttl), sizeof(ttl)) ==
      SOCKET_ERROR) {
    close_socket();
    return std::nullopt;
  }
  sockaddr_in local{};
  local.sin_family = AF_INET;
  local.sin_port = 0;
  local.sin_addr.s_addr = htonl(INADDR_ANY);
  if (::bind(socket, reinterpret_cast<const sockaddr*>(&local), sizeof(local)) ==
      SOCKET_ERROR) {
    close_socket();
    return std::nullopt;
  }
  const auto query = EncodeQuery();
  sockaddr_in destination{};
  destination.sin_family = AF_INET;
  destination.sin_port = htons(kDiscoveryPort);
  if (::InetPtonA(AF_INET, kDiscoveryAddress, &destination.sin_addr) != 1 ||
      ::sendto(socket, reinterpret_cast<const char*>(query.data()),
               static_cast<int>(query.size()), 0,
               reinterpret_cast<const sockaddr*>(&destination),
               sizeof(destination)) == SOCKET_ERROR) {
    close_socket();
    return std::nullopt;
  }
  const DWORD timeout = 100;
  ::setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO,
               reinterpret_cast<const char*>(&timeout), sizeof(timeout));

  std::string own_peer_id;
  {
    std::lock_guard<std::mutex> lock(announcement_mutex_);
    own_peer_id = announced_peer_id_;
  }
  std::vector<std::string> endpoints;
  const auto deadline = std::chrono::steady_clock::now() + kDiscoveryTimeout;
  std::array<uint8_t, kMaxPacketBytes> buffer{};
  while (std::chrono::steady_clock::now() < deadline &&
         endpoints.size() < kMaxDiscoveryEntries) {
    sockaddr_storage source{};
    int source_length = sizeof(source);
    const int received = ::recvfrom(
        socket, reinterpret_cast<char*>(buffer.data()),
        static_cast<int>(buffer.size()), 0,
        reinterpret_cast<sockaddr*>(&source), &source_length);
    if (received == SOCKET_ERROR) {
      const int error = ::WSAGetLastError();
      if (error == WSAETIMEDOUT) continue;
      close_socket();
      return std::nullopt;
    }
    if (source.ss_family != AF_INET) continue;
    const auto decoded = DecodePacket(buffer.data(),
                                      static_cast<std::size_t>(received));
    if (!decoded.has_value() || decoded->kind != kAdvertisementKind ||
        decoded->peer_id.empty() ||
        decoded->peer_id == own_peer_id) {
      continue;
    }
    const auto* source_address = reinterpret_cast<const sockaddr_in*>(&source);
    char host[INET_ADDRSTRLEN]{};
    if (::InetNtopA(AF_INET, &source_address->sin_addr, host,
                    static_cast<DWORD>(sizeof(host))) == nullptr) {
      continue;
    }
    const std::string endpoint = decoded->peer_id + "@" + host + ":" +
                                 std::to_string(decoded->port);
    if (std::find(endpoints.begin(), endpoints.end(), endpoint) ==
        endpoints.end()) {
      endpoints.push_back(endpoint);
    }
  }
  close_socket();
  return endpoints;
}

WindowsLocalNetwork::NetworkSnapshot
WindowsLocalNetwork::ReadNetworkSnapshot() {
  ULONG buffer_size = kInitialAddressBufferBytes;
  std::vector<std::uint8_t> buffer(buffer_size);
  const ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_DNS_SERVER;
  ULONG status = ::GetAdaptersAddresses(
      AF_UNSPEC, flags, nullptr,
      reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  if (status == ERROR_BUFFER_OVERFLOW) {
    if (buffer_size > kMaxAddressBufferBytes) return {};
    buffer.resize(buffer_size);
    status = ::GetAdaptersAddresses(
        AF_UNSPEC, flags, nullptr,
        reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  }
  if (status != NO_ERROR) return {};

  NetworkSnapshot snapshot;
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
    bool has_ipv4_address = false;
    std::size_t address_count = 0;
    for (const auto* address = adapter->FirstUnicastAddress;
         address != nullptr && address_count < kMaxUnicastAddressCount;
         address = address->Next, ++address_count) {
      const auto* socket_address = address->Address.lpSockaddr;
      if (socket_address == nullptr || socket_address->sa_family != AF_INET) {
        continue;
      }
      const auto* ipv4 = reinterpret_cast<const sockaddr_in*>(socket_address);
      if (!IsUsableIpv4Address(ntohl(ipv4->sin_addr.s_addr))) continue;
      has_ipv4_address = true;
      break;
    }
    if (!has_ipv4_address) continue;
    snapshot.available = true;
    snapshot.broadcast_supported = true;
    const char* hint = adapter->IfType == IF_TYPE_IEEE80211
                           ? "wifi"
                           : adapter->IfType == IF_TYPE_ETHERNET_CSMACD
                                 ? "ethernet"
                                 : "other";
    if (std::find(snapshot.interface_hints.begin(),
                  snapshot.interface_hints.end(), hint) ==
        snapshot.interface_hints.end()) {
      snapshot.interface_hints.emplace_back(hint);
    }
  }
  return snapshot;
}

std::optional<in_addr> WindowsLocalNetwork::SelectMulticastInterface() {
  ULONG buffer_size = kInitialAddressBufferBytes;
  std::vector<uint8_t> buffer(buffer_size);
  const ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_DNS_SERVER;
  ULONG status = ::GetAdaptersAddresses(
      AF_INET, flags, nullptr,
      reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  if (status == ERROR_BUFFER_OVERFLOW) {
    if (buffer_size > kMaxAddressBufferBytes) return std::nullopt;
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
      if (!IsUsableIpv4Address(ntohl(ipv4->sin_addr.s_addr))) continue;
      if (!selected.has_value() || adapter->Ipv4Metric < selected_metric) {
        selected = ipv4->sin_addr;
        selected_metric = adapter->Ipv4Metric;
      }
      break;
    }
  }
  return selected;
}

EncodableValue WindowsLocalNetwork::CapabilityPayload(
    const NetworkSnapshot& snapshot) {
  EncodableMap payload;
  payload.emplace(EncodableValue("discoverySupported"),
                  EncodableValue(snapshot.available));
  payload.emplace(EncodableValue("permissionPromptSupported"),
                  EncodableValue(false));
  payload.emplace(EncodableValue("broadcastSupported"),
                  EncodableValue(snapshot.broadcast_supported));
  payload.emplace(EncodableValue("notes"),
                  EncodableValue(snapshot.available
                                     ? "windows-udp-multicast-discovery"
                                     : "unavailable"));
  if (!snapshot.available) {
    payload.emplace(EncodableValue("warning"),
                    EncodableValue("Native local network is unavailable."));
  }
  return EncodableValue(std::move(payload));
}

EncodableValue WindowsLocalNetwork::DiscoveryPayload(
    const NetworkSnapshot& snapshot) {
  EncodableList hints;
  for (const auto& hint : snapshot.interface_hints) hints.emplace_back(hint);
  EncodableList endpoints;
  const auto discovered = snapshot.available ? DiscoverEndpoints() : std::nullopt;
  if (discovered.has_value()) {
    for (const auto& endpoint : discovered.value()) endpoints.emplace_back(endpoint);
  }
  EncodableMap payload;
  payload.emplace(EncodableValue("permissionGranted"),
                  EncodableValue(snapshot.available));
  payload.emplace(EncodableValue("foundEndpoints"),
                  EncodableValue(std::move(endpoints)));
  payload.emplace(EncodableValue("interfaceHints"), EncodableValue(hints));
  if (!snapshot.available) {
    payload.emplace(EncodableValue("warning"),
                    EncodableValue("Native local network is unavailable."));
  } else if (!discovered.has_value()) {
    payload.emplace(EncodableValue("warning"), EncodableValue(
        "Native local-network discovery lookup failed."));
  }
  return EncodableValue(std::move(payload));
}

EncodableValue WindowsLocalNetwork::AnnouncementPayload(
    bool published,
    const char* warning) {
  EncodableMap payload;
  payload.emplace(EncodableValue("published"), EncodableValue(published));
  if (warning != nullptr) {
    payload.emplace(EncodableValue("warning"), EncodableValue(warning));
  }
  return EncodableValue(std::move(payload));
}

std::optional<std::string> WindowsLocalNetwork::PeerIdFromArguments(
    const EncodableMap* arguments) {
  if (arguments == nullptr) return std::nullopt;
  const auto* value = MapValue(*arguments, "peerId");
  const auto* peer_id = value == nullptr ? nullptr : std::get_if<std::string>(value);
  if (peer_id == nullptr || !IsSafePeerId(*peer_id)) return std::nullopt;
  return *peer_id;
}

std::optional<uint16_t> WindowsLocalNetwork::PortFromArguments(
    const EncodableMap* arguments) {
  if (arguments == nullptr) return std::nullopt;
  const auto* value = MapValue(*arguments, "port");
  if (value == nullptr) return std::nullopt;
  int64_t port = 0;
  if (const auto* int32_value = std::get_if<int32_t>(value);
      int32_value != nullptr) {
    port = *int32_value;
  } else if (const auto* int64_value = std::get_if<int64_t>(value);
             int64_value != nullptr) {
    port = *int64_value;
  } else {
    return std::nullopt;
  }
  if (port < 1 || port > 65535) return std::nullopt;
  return static_cast<uint16_t>(port);
}

std::vector<uint8_t> WindowsLocalNetwork::EncodeQuery() {
  std::vector<uint8_t> output(kMagic.begin(), kMagic.end());
  output.insert(output.end(), {kVersion, kQueryKind, 0, 0, 0, 0});
  return output;
}

std::optional<std::vector<uint8_t>> WindowsLocalNetwork::EncodeAdvertisement(
    const std::string& peer_id,
    uint16_t port) {
  if (!IsSafePeerId(peer_id) || port == 0) return std::nullopt;
  const auto identity = std::vector<uint8_t>(peer_id.begin(), peer_id.end());
  if (identity.size() > kMaxIdentityBytes) return std::nullopt;
  std::vector<uint8_t> output;
  output.reserve(kHeaderBytes + identity.size());
  output.insert(output.end(), kMagic.begin(), kMagic.end());
  output.push_back(kVersion);
  output.push_back(kAdvertisementKind);
  AppendUint16(&output, static_cast<uint16_t>(identity.size()));
  AppendUint16(&output, port);
  output.insert(output.end(), identity.begin(), identity.end());
  return output;
}

std::optional<WindowsLocalNetwork::DiscoveryAdvertisement>
WindowsLocalNetwork::DecodePacket(const uint8_t* bytes, std::size_t length) {
  if (bytes == nullptr || length < kHeaderBytes || length > kMaxPacketBytes) {
    return std::nullopt;
  }
  for (std::size_t index = 0; index < kMagic.size(); ++index) {
    if (bytes[index] != kMagic[index]) return std::nullopt;
  }
  if (bytes[4] != kVersion) return std::nullopt;
  const uint8_t kind = bytes[5];
  std::size_t offset = 6;
  uint16_t identity_length = 0;
  uint16_t port = 0;
  if (!ReadUint16(bytes, length, &offset, &identity_length) ||
      !ReadUint16(bytes, length, &offset, &port) ||
      identity_length > kMaxIdentityBytes ||
      length != kHeaderBytes + identity_length) {
    return std::nullopt;
  }
  if (kind == kQueryKind) {
    return identity_length == 0 && port == 0
               ? std::optional<DiscoveryAdvertisement>(
                     DiscoveryAdvertisement{kQueryKind, "", 0})
               : std::nullopt;
  }
  if (kind != kAdvertisementKind || port == 0) return std::nullopt;
  std::string peer_id(reinterpret_cast<const char*>(bytes + kHeaderBytes),
                      identity_length);
  if (!IsSafePeerId(peer_id)) return std::nullopt;
  return DiscoveryAdvertisement{kAdvertisementKind, std::move(peer_id), port};
}

bool WindowsLocalNetwork::IsSafePeerId(const std::string& value) {
  return ::IsSafePeerId(value);
}
