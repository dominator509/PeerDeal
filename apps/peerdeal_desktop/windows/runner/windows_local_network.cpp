#include <winsock2.h>

#include "windows_local_network.h"

#include <iphlpapi.h>
#include <netioapi.h>

#include <algorithm>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannelName[] = "peerdeal/native_bridges/local_network";
constexpr char kGetCapabilityMethod[] = "getCapability";
constexpr char kDiscoverPeersMethod[] = "discoverPeers";
constexpr char kDiscoveryWarning[] =
    "Native local-network peer discovery is not configured.";
constexpr ULONG kInitialAddressBufferBytes = 16 * 1024;
constexpr ULONG kMaxAddressBufferBytes = 1024 * 1024;
constexpr std::size_t kMaxAdapterCount = 64;
constexpr std::size_t kMaxUnicastAddressCount = 256;

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

void AddHintIfMissing(std::vector<std::string>* hints, const char* hint) {
  if (std::find(hints->begin(), hints->end(), hint) == hints->end()) {
    hints->emplace_back(hint);
  }
}

const char* InterfaceHint(ULONG interface_type) {
  switch (interface_type) {
    case IF_TYPE_IEEE80211:
      return "wifi";
    case IF_TYPE_ETHERNET_CSMACD:
      return "ethernet";
    default:
      return "other";
  }
}

bool IsUsableIpv4Address(std::uint32_t host_address) {
  const bool is_unspecified = host_address == 0;
  const bool is_loopback = (host_address & 0xff000000u) == 0x7f000000u;
  const bool is_apipa = (host_address & 0xffff0000u) == 0xa9fe0000u;
  const bool is_broadcast = host_address == 0xffffffffu;
  return !is_unspecified && !is_loopback && !is_apipa && !is_broadcast;
}

}  // namespace

WindowsLocalNetwork::WindowsLocalNetwork(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsLocalNetwork::~WindowsLocalNetwork() {
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
}

void WindowsLocalNetwork::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto snapshot = ReadNetworkSnapshot();
  if (method_call.method_name() == kGetCapabilityMethod) {
    result->Success(CapabilityPayload(snapshot));
    return;
  }
  if (method_call.method_name() == kDiscoverPeersMethod) {
    result->Success(DiscoveryPayload(snapshot));
    return;
  }
  result->NotImplemented();
}

WindowsLocalNetwork::NetworkSnapshot
WindowsLocalNetwork::ReadNetworkSnapshot() {
  ULONG buffer_size = kInitialAddressBufferBytes;
  std::vector<std::uint8_t> buffer(buffer_size);
  ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_DNS_SERVER;
  ULONG status = ::GetAdaptersAddresses(
      AF_UNSPEC, flags, nullptr,
      reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  if (status == ERROR_BUFFER_OVERFLOW) {
    if (buffer_size > kMaxAddressBufferBytes) {
      return {};
    }
    buffer.resize(buffer_size);
    status = ::GetAdaptersAddresses(
        AF_UNSPEC, flags, nullptr,
        reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &buffer_size);
  }
  if (status != NO_ERROR) {
    return {};
  }

  NetworkSnapshot snapshot;
  const auto* adapters = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data());
  std::size_t adapter_count = 0;
  for (const auto* adapter = adapters;
       adapter != nullptr && adapter_count < kMaxAdapterCount;
       adapter = adapter->Next, ++adapter_count) {
    if (adapter->OperStatus != IfOperStatusUp ||
        adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) {
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
      if (!IsUsableIpv4Address(ntohl(ipv4->sin_addr.s_addr))) {
        continue;
      }
      has_ipv4_address = true;
      break;
    }
    if (!has_ipv4_address) {
      continue;
    }

    snapshot.available = true;
    snapshot.broadcast_supported = true;
    AddHintIfMissing(&snapshot.interface_hints, InterfaceHint(adapter->IfType));
  }
  return snapshot;
}

EncodableValue WindowsLocalNetwork::CapabilityPayload(
    const NetworkSnapshot& snapshot) {
  EncodableMap payload;
  payload[EncodableValue("discoverySupported")] = EncodableValue(false);
  payload[EncodableValue("permissionPromptSupported")] = EncodableValue(false);
  payload[EncodableValue("broadcastSupported")] =
      EncodableValue(snapshot.broadcast_supported);
  payload[EncodableValue("notes")] = EncodableValue(
      snapshot.available ? "windows-network-interface-ready" : "unavailable");
  payload[EncodableValue("warning")] = EncodableValue(
      snapshot.available ? kDiscoveryWarning
                         : "Native local network is unavailable.");
  return EncodableValue(payload);
}

EncodableValue WindowsLocalNetwork::DiscoveryPayload(
    const NetworkSnapshot& snapshot) {
  EncodableList hints;
  for (const auto& hint : snapshot.interface_hints) {
    hints.emplace_back(hint);
  }
  EncodableMap payload;
  payload[EncodableValue("permissionGranted")] =
      EncodableValue(snapshot.available);
  payload[EncodableValue("foundEndpoints")] = EncodableValue(EncodableList{});
  payload[EncodableValue("interfaceHints")] = EncodableValue(hints);
  payload[EncodableValue("warning")] = EncodableValue(
      snapshot.available ? kDiscoveryWarning
                         : "Native local network is unavailable.");
  return EncodableValue(payload);
}
