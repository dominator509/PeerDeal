// This must be included before many other Windows headers.
#include <windows.h>

#include "windows_secure_key_storage.h"

#include <bcrypt.h>
#include <wincred.h>

#include <algorithm>
#include <array>
#include <cwctype>
#include <limits>
#include <set>
#include <utility>

#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannelName[] =
    "peerdeal/native_bridges/secure_key_storage";
constexpr char kLoadKeyRingMethod[] = "loadKeyRing";
constexpr char kSaveKeyMethod[] = "saveKey";
constexpr char kDeleteKeyMethod[] = "deleteKey";

constexpr std::uint32_t kStorageVersion = 1;
constexpr std::size_t kMaxNamespaceBytes = 128;
constexpr std::size_t kMaxRecords = 128;
constexpr std::size_t kMaxKeyIdBytes = 256;
constexpr std::size_t kMaxPurposeBytes = 128;
constexpr std::size_t kMaxAlgorithmBytes = 128;
constexpr std::size_t kMaxSecretBytes = 4096;
constexpr std::size_t kMaxBlobBytes = 512 * 1024;
constexpr std::size_t kSha256Bytes = 32;
constexpr DWORD kStorageMutexWaitMs = 5000;
constexpr std::array<std::uint8_t, 4> kStorageMagic = {'P', 'D', 'K', '1'};

using flutter::EncodableMap;
using flutter::EncodableValue;

struct CredentialGuard final {
  PCREDENTIALW credential = nullptr;

  ~CredentialGuard() {
    if (credential != nullptr) {
      ::CredFree(credential);
    }
  }
};

class ScopedStorageMutex final {
 public:
  explicit ScopedStorageMutex(const std::wstring& target) {
    if (target.empty()) {
      return;
    }

    std::wstring mutex_name = L"Local\\";
    mutex_name.append(target);
    mutex_name.append(L".lock");
    handle_ = ::CreateMutexW(nullptr, FALSE, mutex_name.c_str());
    if (handle_ == nullptr) {
      return;
    }

    const auto wait_result =
        ::WaitForSingleObject(handle_, kStorageMutexWaitMs);
    acquired_ = wait_result == WAIT_OBJECT_0 || wait_result == WAIT_ABANDONED;
    if (!acquired_) {
      ::CloseHandle(handle_);
      handle_ = nullptr;
    }
  }

  ~ScopedStorageMutex() {
    if (handle_ == nullptr) {
      return;
    }
    if (acquired_) {
      ::ReleaseMutex(handle_);
    }
    ::CloseHandle(handle_);
  }

  ScopedStorageMutex(const ScopedStorageMutex&) = delete;
  ScopedStorageMutex& operator=(const ScopedStorageMutex&) = delete;

  bool acquired() const { return acquired_; }

 private:
  HANDLE handle_ = nullptr;
  bool acquired_ = false;
};

const EncodableMap* ArgumentsMap(
    const flutter::MethodCall<EncodableValue>& method_call) {
  const auto* arguments = method_call.arguments();
  if (arguments == nullptr) {
    return nullptr;
  }
  return std::get_if<EncodableMap>(arguments);
}

bool Utf8ToWide(const std::string& value, std::wstring* output) {
  if (value.empty() || value.size() > INT_MAX) {
    return false;
  }
  const int input_size = static_cast<int>(value.size());
  const int output_size = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), input_size, nullptr, 0);
  if (output_size <= 0) {
    return false;
  }
  output->resize(static_cast<std::size_t>(output_size));
  return ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                               input_size, output->data(), output_size) ==
         output_size;
}

bool IsValidTextValue(const std::string& value, std::size_t max_bytes) {
  if (value.empty() || value.size() > max_bytes) {
    return false;
  }
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

void AppendUint32(std::uint32_t value, std::vector<std::uint8_t>* output) {
  output->push_back(static_cast<std::uint8_t>(value & 0xff));
  output->push_back(static_cast<std::uint8_t>((value >> 8) & 0xff));
  output->push_back(static_cast<std::uint8_t>((value >> 16) & 0xff));
  output->push_back(static_cast<std::uint8_t>((value >> 24) & 0xff));
}

bool ReadUint32(const std::vector<std::uint8_t>& input,
                std::size_t* offset,
                std::uint32_t* value) {
  if (*offset > input.size() || input.size() - *offset < 4) {
    return false;
  }
  *value = static_cast<std::uint32_t>(input[*offset]) |
           (static_cast<std::uint32_t>(input[*offset + 1]) << 8) |
           (static_cast<std::uint32_t>(input[*offset + 2]) << 16) |
           (static_cast<std::uint32_t>(input[*offset + 3]) << 24);
  *offset += 4;
  return true;
}

bool HashNamespace(const std::string& namespace_name,
                   std::array<std::uint8_t, kSha256Bytes>* digest) {
  BCRYPT_ALG_HANDLE algorithm = nullptr;
  BCRYPT_HASH_HANDLE hash = nullptr;
  ULONG object_length = 0;
  ULONG result_length = 0;
  std::vector<UCHAR> hash_object;
  bool success = false;

  do {
    if (!BCRYPT_SUCCESS(::BCryptOpenAlgorithmProvider(
            &algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0))) {
      break;
    }
    if (!BCRYPT_SUCCESS(::BCryptGetProperty(
            algorithm, BCRYPT_OBJECT_LENGTH,
            reinterpret_cast<PUCHAR>(&object_length), sizeof(object_length),
            &result_length, 0)) ||
        object_length == 0) {
      break;
    }
    hash_object.resize(object_length);
    if (!BCRYPT_SUCCESS(::BCryptCreateHash(
            algorithm, &hash, hash_object.data(), object_length, nullptr, 0,
            0))) {
      break;
    }
    auto* input = reinterpret_cast<PUCHAR>(
        const_cast<char*>(namespace_name.data()));
    if (!BCRYPT_SUCCESS(::BCryptHashData(
            hash, input, static_cast<ULONG>(namespace_name.size()), 0))) {
      break;
    }
    if (!BCRYPT_SUCCESS(::BCryptFinishHash(
            hash, digest->data(), static_cast<ULONG>(digest->size()), 0))) {
      break;
    }
    success = true;
  } while (false);

  if (hash != nullptr) {
    ::BCryptDestroyHash(hash);
  }
  if (algorithm != nullptr) {
    ::BCryptCloseAlgorithmProvider(algorithm, 0);
  }
  return success;
}

bool ReadString(const std::vector<std::uint8_t>& input,
                std::size_t* offset,
                std::size_t max_bytes,
                std::string* value) {
  std::uint32_t length = 0;
  if (!ReadUint32(input, offset, &length) ||
      length > max_bytes || *offset > input.size() ||
      input.size() - *offset < length) {
    return false;
  }
  value->assign(reinterpret_cast<const char*>(input.data() + *offset),
                static_cast<std::size_t>(length));
  *offset += length;
  return IsValidTextValue(*value, max_bytes);
}

bool AppendString(const std::string& value,
                  std::size_t max_bytes,
                  std::vector<std::uint8_t>* output) {
  if (!IsValidTextValue(value, max_bytes) ||
      value.size() > std::numeric_limits<std::uint32_t>::max() ||
      output->size() > kMaxBlobBytes - 4 - value.size()) {
    return false;
  }
  AppendUint32(static_cast<std::uint32_t>(value.size()), output);
  output->insert(output->end(), value.begin(), value.end());
  return true;
}

}  // namespace

WindowsSecureKeyStorage::WindowsSecureKeyStorage(
    flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& method_call, auto result) {
        HandleMethodCall(method_call, std::move(result));
      });
}

WindowsSecureKeyStorage::~WindowsSecureKeyStorage() {
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
}

void WindowsSecureKeyStorage::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  try {
    const auto* arguments = ArgumentsMap(method_call);
    if (method_call.method_name() == kLoadKeyRingMethod) {
      const auto* namespace_name =
          arguments == nullptr ? nullptr : StringValue(*arguments, "namespace");
      if (namespace_name == nullptr || !IsValidNamespace(*namespace_name)) {
        result->Success(SnapshotFailure(
            "Secure key storage request is invalid."));
        return;
      }

      std::lock_guard<std::mutex> lock(storage_mutex_);
      ScopedStorageMutex cross_process_lock(CredentialTarget(*namespace_name));
      if (!cross_process_lock.acquired()) {
        result->Success(
            SnapshotFailure("Secure key storage is unavailable."));
        return;
      }
      std::vector<StoredKey> records;
      const auto status = ReadRecords(*namespace_name, &records);
      if (status == ReadStatus::kFailure) {
        result->Success(SnapshotFailure(
            "Secure key storage is unavailable."));
        return;
      }
      result->Success(SnapshotSuccess(records));
      return;
    }

    if (method_call.method_name() == kSaveKeyMethod) {
      const auto* namespace_name =
          arguments == nullptr ? nullptr : StringValue(*arguments, "namespace");
      const auto key = arguments == nullptr ? std::nullopt : DecodeKey(*arguments);
      if (namespace_name == nullptr || !IsValidNamespace(*namespace_name) ||
          !key.has_value()) {
        result->Success(
            MutationFailure("Secure key storage request is invalid."));
        return;
      }

      std::lock_guard<std::mutex> lock(storage_mutex_);
      ScopedStorageMutex cross_process_lock(CredentialTarget(*namespace_name));
      if (!cross_process_lock.acquired()) {
        result->Success(
            MutationFailure("Secure key storage is unavailable."));
        return;
      }
      std::vector<StoredKey> records;
      const auto status = ReadRecords(*namespace_name, &records);
      if (status == ReadStatus::kFailure) {
        result->Success(
            MutationFailure("Secure key storage is unavailable."));
        return;
      }
      records.erase(std::remove_if(records.begin(), records.end(),
                                   [&key](const StoredKey& current) {
                                     return current.key_id == key->key_id;
                                   }),
                    records.end());
      records.push_back(*key);
      if (records.size() > kMaxRecords ||
          !WriteRecords(*namespace_name, records)) {
        result->Success(
            MutationFailure("Secure key storage mutation failed."));
        return;
      }
      result->Success(MutationSuccess());
      return;
    }

    if (method_call.method_name() == kDeleteKeyMethod) {
      const auto* namespace_name =
          arguments == nullptr ? nullptr : StringValue(*arguments, "namespace");
      const auto* key_id =
          arguments == nullptr ? nullptr : StringValue(*arguments, "keyId");
      if (namespace_name == nullptr || !IsValidNamespace(*namespace_name) ||
          key_id == nullptr || !IsValidKeyId(*key_id)) {
        result->Success(
            MutationFailure("Secure key storage request is invalid."));
        return;
      }

      std::lock_guard<std::mutex> lock(storage_mutex_);
      ScopedStorageMutex cross_process_lock(CredentialTarget(*namespace_name));
      if (!cross_process_lock.acquired()) {
        result->Success(
            MutationFailure("Secure key storage is unavailable."));
        return;
      }
      std::vector<StoredKey> records;
      const auto status = ReadRecords(*namespace_name, &records);
      if (status == ReadStatus::kFailure) {
        result->Success(
            MutationFailure("Secure key storage is unavailable."));
        return;
      }
      records.erase(std::remove_if(records.begin(), records.end(),
                                   [&key_id](const StoredKey& current) {
                                     return current.key_id == *key_id;
                                   }),
                    records.end());
      if (!WriteRecords(*namespace_name, records)) {
        result->Success(
            MutationFailure("Secure key storage mutation failed."));
        return;
      }
      result->Success(MutationSuccess());
      return;
    }

    result->NotImplemented();
  } catch (...) {
    if (method_call.method_name() == kLoadKeyRingMethod) {
      result->Success(SnapshotFailure("Secure key storage is unavailable."));
    } else {
      result->Success(MutationFailure("Secure key storage is unavailable."));
    }
  }
}

const EncodableValue* WindowsSecureKeyStorage::MapValue(
    const EncodableMap& map,
    const char* key) {
  const auto found = map.find(EncodableValue(std::string(key)));
  return found == map.end() ? nullptr : &found->second;
}

const std::string* WindowsSecureKeyStorage::StringValue(
    const EncodableMap& map,
    const char* key) {
  const auto* value = MapValue(map, key);
  return value == nullptr ? nullptr : std::get_if<std::string>(value);
}

std::optional<WindowsSecureKeyStorage::StoredKey>
WindowsSecureKeyStorage::DecodeKey(const EncodableMap& map) {
  const auto* key_value = MapValue(map, "key");
  if (key_value == nullptr) {
    return std::nullopt;
  }
  const auto* key_map = std::get_if<EncodableMap>(key_value);
  if (key_map == nullptr) {
    return std::nullopt;
  }
  const auto* key_id = StringValue(*key_map, "keyId");
  const auto* purpose = StringValue(*key_map, "purpose");
  const auto* algorithm = StringValue(*key_map, "algorithm");
  const auto* secret = StringValue(*key_map, "secret");
  const auto* active_value = MapValue(*key_map, "active");
  const auto* active = active_value == nullptr
                           ? nullptr
                           : std::get_if<bool>(active_value);
  if (key_id == nullptr || purpose == nullptr || algorithm == nullptr ||
      secret == nullptr || active == nullptr || !IsValidKeyId(*key_id) ||
      !IsValidText(*purpose, kMaxPurposeBytes) ||
      !IsValidText(*algorithm, kMaxAlgorithmBytes) ||
      !IsValidText(*secret, kMaxSecretBytes)) {
    return std::nullopt;
  }
  return StoredKey{*key_id, *purpose, *algorithm, *secret, *active};
}

bool WindowsSecureKeyStorage::IsValidText(const std::string& value,
                                          std::size_t max_bytes) {
  return IsValidTextValue(value, max_bytes);
}

bool WindowsSecureKeyStorage::IsValidNamespace(const std::string& value) {
  return IsValidText(value, kMaxNamespaceBytes);
}

bool WindowsSecureKeyStorage::IsValidKeyId(const std::string& value) {
  return IsValidText(value, kMaxKeyIdBytes) && value.find(':') == std::string::npos;
}

std::wstring WindowsSecureKeyStorage::CredentialTarget(
    const std::string& namespace_name) {
  std::array<std::uint8_t, kSha256Bytes> digest{};
  if (!HashNamespace(namespace_name, &digest)) {
    return {};
  }
  constexpr wchar_t kHex[] = L"0123456789abcdef";
  std::wstring target = L"PeerDeal.SecureKeyStorage.v1.";
  target.reserve(target.size() + digest.size() * 2);
  for (const auto value : digest) {
    target.push_back(kHex[(value >> 4) & 0x0f]);
    target.push_back(kHex[value & 0x0f]);
  }
  return target;
}

WindowsSecureKeyStorage::ReadStatus WindowsSecureKeyStorage::ReadRecords(
    const std::string& namespace_name,
    std::vector<StoredKey>* records) {
  const auto target = CredentialTarget(namespace_name);
  if (target.empty()) {
    return ReadStatus::kFailure;
  }
  std::vector<std::uint8_t> blob;
  const auto status = ReadCredentialBlob(target, &blob);
  if (status != ReadStatus::kSuccess) {
    return status;
  }
  return DeserializeRecords(blob, records) ? ReadStatus::kSuccess
                                            : ReadStatus::kFailure;
}

WindowsSecureKeyStorage::ReadStatus
WindowsSecureKeyStorage::ReadCredentialBlob(
    const std::wstring& target,
    std::vector<std::uint8_t>* blob) {
  if (blob == nullptr) {
    return ReadStatus::kFailure;
  }
  blob->clear();

  PCREDENTIALW raw_credential = nullptr;
  if (!::CredReadW(target.c_str(), CRED_TYPE_GENERIC, 0, &raw_credential)) {
    return ::GetLastError() == ERROR_NOT_FOUND ? ReadStatus::kNotFound
                                                : ReadStatus::kFailure;
  }
  CredentialGuard credential{raw_credential};
  if (raw_credential == nullptr ||
      raw_credential->CredentialBlobSize > kMaxBlobBytes ||
      (raw_credential->CredentialBlobSize != 0 &&
       raw_credential->CredentialBlob == nullptr)) {
    return ReadStatus::kFailure;
  }
  if (raw_credential->CredentialBlobSize == 0) {
    return ReadStatus::kSuccess;
  }
  blob->assign(raw_credential->CredentialBlob,
               raw_credential->CredentialBlob +
                   raw_credential->CredentialBlobSize);
  return ReadStatus::kSuccess;
}

bool WindowsSecureKeyStorage::WriteRecords(
    const std::string& namespace_name,
    const std::vector<StoredKey>& records) {
  const auto target = CredentialTarget(namespace_name);
  if (target.empty() || records.size() > kMaxRecords) {
    return false;
  }
  if (records.empty()) {
    return ::CredDeleteW(target.c_str(), CRED_TYPE_GENERIC, 0) ||
           ::GetLastError() == ERROR_NOT_FOUND;
  }

  std::vector<std::uint8_t> blob;
  if (!SerializeRecords(records, &blob) || blob.empty() ||
      blob.size() > std::numeric_limits<DWORD>::max()) {
    return false;
  }
  CREDENTIALW credential{};
  credential.Type = CRED_TYPE_GENERIC;
  credential.TargetName = const_cast<LPWSTR>(target.c_str());
  credential.CredentialBlobSize = static_cast<DWORD>(blob.size());
  credential.CredentialBlob = blob.data();
  credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
  return ::CredWriteW(&credential, 0) == TRUE;
}

bool WindowsSecureKeyStorage::SerializeRecords(
    const std::vector<StoredKey>& records,
    std::vector<std::uint8_t>* blob) {
  if (records.empty() || records.size() > kMaxRecords) {
    return false;
  }
  blob->clear();
  blob->reserve(16);
  blob->insert(blob->end(), kStorageMagic.begin(), kStorageMagic.end());
  AppendUint32(kStorageVersion, blob);
  AppendUint32(static_cast<std::uint32_t>(records.size()), blob);
  for (const auto& record : records) {
    if (!IsValidKeyId(record.key_id) ||
        !IsValidText(record.purpose, kMaxPurposeBytes) ||
        !IsValidText(record.algorithm, kMaxAlgorithmBytes) ||
        !IsValidText(record.secret, kMaxSecretBytes) ||
        blob->size() >= kMaxBlobBytes) {
      return false;
    }
    if (!AppendString(record.key_id, kMaxKeyIdBytes, blob) ||
        !AppendString(record.purpose, kMaxPurposeBytes, blob) ||
        !AppendString(record.algorithm, kMaxAlgorithmBytes, blob) ||
        !AppendString(record.secret, kMaxSecretBytes, blob) ||
        blob->size() == kMaxBlobBytes) {
      return false;
    }
    blob->push_back(record.active ? 1 : 0);
  }
  return blob->size() <= kMaxBlobBytes;
}

bool WindowsSecureKeyStorage::DeserializeRecords(
    const std::vector<std::uint8_t>& blob,
    std::vector<StoredKey>* records) {
  if (blob.size() < kStorageMagic.size() + 8 ||
      blob.size() > kMaxBlobBytes ||
      !std::equal(kStorageMagic.begin(), kStorageMagic.end(), blob.begin())) {
    return false;
  }
  std::size_t offset = kStorageMagic.size();
  std::uint32_t version = 0;
  std::uint32_t record_count = 0;
  if (!ReadUint32(blob, &offset, &version) || version != kStorageVersion ||
      !ReadUint32(blob, &offset, &record_count) ||
      record_count > kMaxRecords) {
    return false;
  }

  records->clear();
  records->reserve(record_count);
  std::set<std::string> key_ids;
  for (std::uint32_t index = 0; index < record_count; ++index) {
    StoredKey record{};
    if (!ReadString(blob, &offset, kMaxKeyIdBytes, &record.key_id) ||
        !IsValidKeyId(record.key_id) ||
        !ReadString(blob, &offset, kMaxPurposeBytes, &record.purpose) ||
        !ReadString(blob, &offset, kMaxAlgorithmBytes, &record.algorithm) ||
        !ReadString(blob, &offset, kMaxSecretBytes, &record.secret) ||
        offset >= blob.size() || (blob[offset] != 0 && blob[offset] != 1) ||
        !key_ids.insert(record.key_id).second) {
      return false;
    }
    record.active = blob[offset++] == 1;
    records->push_back(std::move(record));
  }
  return offset == blob.size();
}

flutter::EncodableValue WindowsSecureKeyStorage::SnapshotFailure(
    const char* warning) {
  EncodableMap payload;
  payload.emplace(EncodableValue("available"), EncodableValue(false));
  payload.emplace(EncodableValue("keys"),
                  EncodableValue(flutter::EncodableList()));
  payload.emplace(EncodableValue("warning"), EncodableValue(warning));
  return EncodableValue(std::move(payload));
}

flutter::EncodableValue WindowsSecureKeyStorage::SnapshotSuccess(
    const std::vector<StoredKey>& records) {
  flutter::EncodableList keys;
  keys.reserve(records.size());
  for (const auto& record : records) {
    EncodableMap key;
    key.emplace(EncodableValue("keyId"), EncodableValue(record.key_id));
    key.emplace(EncodableValue("purpose"), EncodableValue(record.purpose));
    key.emplace(EncodableValue("algorithm"),
                EncodableValue(record.algorithm));
    key.emplace(EncodableValue("secret"), EncodableValue(record.secret));
    key.emplace(EncodableValue("active"), EncodableValue(record.active));
    keys.emplace_back(EncodableValue(std::move(key)));
  }
  EncodableMap payload;
  payload.emplace(EncodableValue("available"), EncodableValue(true));
  payload.emplace(EncodableValue("keys"), EncodableValue(std::move(keys)));
  return EncodableValue(std::move(payload));
}

flutter::EncodableValue WindowsSecureKeyStorage::MutationFailure(
    const char* warning) {
  EncodableMap payload;
  payload.emplace(EncodableValue("success"), EncodableValue(false));
  payload.emplace(EncodableValue("warning"), EncodableValue(warning));
  return EncodableValue(std::move(payload));
}

flutter::EncodableValue WindowsSecureKeyStorage::MutationSuccess() {
  EncodableMap payload;
  payload.emplace(EncodableValue("success"), EncodableValue(true));
  return EncodableValue(std::move(payload));
}
