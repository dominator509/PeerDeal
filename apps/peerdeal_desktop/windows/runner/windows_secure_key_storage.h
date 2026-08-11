#ifndef RUNNER_WINDOWS_SECURE_KEY_STORAGE_H_
#define RUNNER_WINDOWS_SECURE_KEY_STORAGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

class WindowsSecureKeyStorage final {
 public:
  explicit WindowsSecureKeyStorage(flutter::BinaryMessenger* messenger);
  ~WindowsSecureKeyStorage();

  WindowsSecureKeyStorage(const WindowsSecureKeyStorage&) = delete;
  WindowsSecureKeyStorage& operator=(const WindowsSecureKeyStorage&) = delete;

 private:
  struct StoredKey {
    std::string key_id;
    std::string purpose;
    std::string algorithm;
    std::string secret;
    bool active;
  };

  enum class ReadStatus { kSuccess, kNotFound, kFailure };

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  static const flutter::EncodableValue* MapValue(
      const flutter::EncodableMap& map,
      const char* key);
  static const std::string* StringValue(
      const flutter::EncodableMap& map,
      const char* key);
  static std::optional<std::uint64_t> RevisionValue(
      const flutter::EncodableMap& map);
  static std::optional<StoredKey> DecodeKey(
      const flutter::EncodableMap& map);

  static bool IsValidText(const std::string& value, std::size_t max_bytes);
  static bool IsValidNamespace(const std::string& value);
  static bool IsValidKeyId(const std::string& value);

  static std::wstring CredentialTarget(const std::string& namespace_name);
  static ReadStatus ReadRecords(const std::string& namespace_name,
                                std::vector<StoredKey>* records,
                                std::uint64_t* revision);
  static bool WriteRecords(const std::string& namespace_name,
                           const std::vector<StoredKey>& records,
                           std::uint64_t revision);
  static ReadStatus ReadCredentialBlob(const std::wstring& target,
                                       std::vector<std::uint8_t>* blob);
  static bool SerializeRecords(const std::vector<StoredKey>& records,
                               std::uint64_t revision,
                               std::vector<std::uint8_t>* blob);
  static bool DeserializeRecords(const std::vector<std::uint8_t>& blob,
                                 std::vector<StoredKey>* records,
                                 std::uint64_t* revision);

  static flutter::EncodableValue SnapshotFailure(const char* warning);
  static flutter::EncodableValue SnapshotSuccess(
      const std::vector<StoredKey>& records,
      std::uint64_t revision);
  static flutter::EncodableValue MutationFailure(const char* warning,
                                                 bool conflict = false);
  static flutter::EncodableValue MutationSuccess(std::uint64_t revision);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::mutex storage_mutex_;
};

#endif  // RUNNER_WINDOWS_SECURE_KEY_STORAGE_H_
