package com.peerdeal.peerdeal_mobile

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.json.JSONArray
import org.json.JSONObject

/** Generic encrypted key-record storage for the locked Flutter method channel. */
internal class SecureKeyStorageHandler(context: Context) :
    MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "peerdeal/native_bridges/secure_key_storage"

        private const val LOAD_KEY_RING = "loadKeyRing"
        private const val SAVE_KEY = "saveKey"
        private const val DELETE_KEY = "deleteKey"
        private const val KEYSTORE = "AndroidKeyStore"
        private const val PREFERENCES_NAME = "peerdeal_secure_key_storage"
        private const val STORAGE_VERSION = 1
        private const val MAX_NAMESPACE_LENGTH = 128
        private const val MAX_RECORDS = 128
        private const val MAX_KEY_ID_LENGTH = 256
        private const val MAX_PURPOSE_LENGTH = 128
        private const val MAX_ALGORITHM_LENGTH = 128
        private const val MAX_SECRET_LENGTH = 4096
        private const val MAX_PLAINTEXT_BYTES = 512 * 1024
        private const val MAX_ENCODED_BYTES = 768 * 1024
        private const val GCM_TAG_BITS = 128
        private const val GCM_NONCE_BYTES = 12

        private fun unavailablePayload(warning: String): Map<String, Any?> =
            mapOf(
                "available" to false,
                "keys" to emptyList<Any?>(),
                "warning" to warning,
            )

        private fun mutationFailure(warning: String): Map<String, Any?> =
            mapOf(
                "success" to false,
                "warning" to warning,
            )
    }

    private val applicationContext = context.applicationContext
    private val preferences: SharedPreferences =
        applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "peerdeal-secure-key-storage").apply { isDaemon = true }
    }
    private val secureRandom = SecureRandom()
    @Volatile
    private var closed = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            LOAD_KEY_RING -> loadKeyRing(call, result)
            SAVE_KEY -> saveKey(call, result)
            DELETE_KEY -> deleteKey(call, result)
            else -> result.notImplemented()
        }
    }

    fun close() {
        closed = true
        worker.shutdown()
    }

    private fun loadKeyRing(call: MethodCall, result: MethodChannel.Result) {
        val namespace = call.argument<Any?>("namespace") as? String
        if (!isValidNamespace(namespace)) {
            result.success(unavailablePayload("Secure key storage request is invalid."))
            return
        }

        submit(
            result,
            failurePayload = { unavailablePayload("Secure key storage is unavailable.") },
        ) {
            when (val read = readRecords(namespace)) {
                is ReadResult.Success -> snapshotPayload(read.records)
                ReadResult.Failure -> unavailablePayload("Secure key storage is unavailable.")
            }
        }
    }

    private fun saveKey(call: MethodCall, result: MethodChannel.Result) {
        val namespace = call.argument<Any?>("namespace") as? String
        val keyPayload = call.argument<Any?>("key") as? Map<*, *>
        val key = keyPayload?.let(::decodeIncomingKey)
        if (!isValidNamespace(namespace) || key == null) {
            result.success(mutationFailure("Secure key storage request is invalid."))
            return
        }

        submit(
            result,
            failurePayload = { mutationFailure("Secure key storage is unavailable.") },
        ) {
            when (val read = readRecords(namespace)) {
                is ReadResult.Success -> {
                    val nextRecords = read.records.filterNot { it.keyId == key.keyId } + key
                    if (nextRecords.size > MAX_RECORDS || !writeRecords(namespace, nextRecords)) {
                        mutationFailure("Secure key storage mutation failed.")
                    } else {
                        mapOf("success" to true)
                    }
                }
                ReadResult.Failure -> mutationFailure("Secure key storage is unavailable.")
            }
        }
    }

    private fun deleteKey(call: MethodCall, result: MethodChannel.Result) {
        val namespace = call.argument<Any?>("namespace") as? String
        val keyId = call.argument<Any?>("keyId") as? String
        if (!isValidNamespace(namespace) || !isValidKeyId(keyId)) {
            result.success(mutationFailure("Secure key storage request is invalid."))
            return
        }

        submit(
            result,
            failurePayload = { mutationFailure("Secure key storage is unavailable.") },
        ) {
            when (val read = readRecords(namespace)) {
                is ReadResult.Success -> {
                    val nextRecords = read.records.filterNot { it.keyId == keyId }
                    if (nextRecords.size == read.records.size || writeRecords(namespace, nextRecords)) {
                        mapOf("success" to true)
                    } else {
                        mutationFailure("Secure key storage mutation failed.")
                    }
                }
                ReadResult.Failure -> mutationFailure("Secure key storage is unavailable.")
            }
        }
    }

    private fun submit(
        result: MethodChannel.Result,
        failurePayload: () -> Map<String, Any?>,
        operation: () -> Map<String, Any?>,
    ) {
        if (closed) {
            result.success(failurePayload())
            return
        }
        try {
            worker.execute {
                val payload = try {
                    operation()
                } catch (_: Exception) {
                    failurePayload()
                }
                mainHandler.post { result.success(payload) }
            }
        } catch (_: RejectedExecutionException) {
            result.success(failurePayload())
        }
    }

    private fun readRecords(namespace: String): ReadResult {
        val masterKey = loadOrCreateMasterKey(namespace) ?: return ReadResult.Failure
        val stored = preferences.getString(preferenceKey(namespace), null)
            ?: return ReadResult.Success(emptyList())
        if (!isWithinEncodedLimit(stored)) return ReadResult.Failure

        val envelope = JSONObject(stored)
        if (envelope.optInt("version", -1) != STORAGE_VERSION) return ReadResult.Failure
        val iv = decodeBase64(envelope.getString("iv")) ?: return ReadResult.Failure
        val ciphertext = decodeBase64(envelope.getString("ciphertext")) ?: return ReadResult.Failure
        if (iv.size !in 12..16 || ciphertext.size <= GCM_TAG_BITS / 8) {
            return ReadResult.Failure
        }

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, masterKey, GCMParameterSpec(GCM_TAG_BITS, iv))
        cipher.updateAAD(namespace.toByteArray(StandardCharsets.UTF_8))
        val plaintext = cipher.doFinal(ciphertext)
        if (plaintext.size > MAX_PLAINTEXT_BYTES) return ReadResult.Failure

        val root = JSONObject(String(plaintext, StandardCharsets.UTF_8))
        if (root.optInt("version", -1) != STORAGE_VERSION) return ReadResult.Failure
        val keyArray = root.getJSONArray("keys")
        if (keyArray.length() > MAX_RECORDS) return ReadResult.Failure

        val records = ArrayList<StoredKey>(keyArray.length())
        val keyIds = HashSet<String>(keyArray.length())
        for (index in 0 until keyArray.length()) {
            val record = decodeStoredKey(keyArray.getJSONObject(index)) ?: return ReadResult.Failure
            if (!keyIds.add(record.keyId)) return ReadResult.Failure
            records.add(record)
        }
        return ReadResult.Success(records)
    }

    private fun writeRecords(namespace: String, records: List<StoredKey>): Boolean {
        if (records.size > MAX_RECORDS || records.any { !it.isValid() }) return false
        if (records.isEmpty()) {
            return preferences.edit().remove(preferenceKey(namespace)).commit()
        }

        val root = JSONObject().put("version", STORAGE_VERSION)
        val keyArray = JSONArray()
        records.forEach { keyArray.put(encodeKey(it)) }
        root.put("keys", keyArray)
        val plaintext = root.toString().toByteArray(StandardCharsets.UTF_8)
        if (plaintext.size > MAX_PLAINTEXT_BYTES) return false

        val masterKey = loadOrCreateMasterKey(namespace) ?: return false
        val iv = ByteArray(GCM_NONCE_BYTES)
        secureRandom.nextBytes(iv)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, masterKey, GCMParameterSpec(GCM_TAG_BITS, iv))
        cipher.updateAAD(namespace.toByteArray(StandardCharsets.UTF_8))
        val ciphertext = cipher.doFinal(plaintext)
        val envelope = JSONObject()
            .put("version", STORAGE_VERSION)
            .put("iv", Base64.encodeToString(iv, Base64.NO_WRAP))
            .put("ciphertext", Base64.encodeToString(ciphertext, Base64.NO_WRAP))
            .toString()
        if (!isWithinEncodedLimit(envelope)) return false

        return preferences.edit()
            .putString(preferenceKey(namespace), envelope)
            .commit()
    }

    private fun isWithinEncodedLimit(value: String): Boolean =
        value.length <= MAX_ENCODED_BYTES &&
            value.toByteArray(StandardCharsets.UTF_8).size <= MAX_ENCODED_BYTES

    private fun loadOrCreateMasterKey(namespace: String): SecretKey? {
        val alias = keyAlias(namespace)
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        val existing = keyStore.getKey(alias, null)
        if (existing != null) return existing as? SecretKey

        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(false)
                .build(),
        )
        return generator.generateKey()
    }

    private fun decodeIncomingKey(payload: Map<*, *>): StoredKey? {
        val keyId = payload["keyId"] as? String ?: return null
        val purpose = payload["purpose"] as? String ?: return null
        val algorithm = payload["algorithm"] as? String ?: return null
        val secret = payload["secret"] as? String ?: return null
        val active = payload["active"] as? Boolean ?: return null
        val key = StoredKey(keyId, purpose, algorithm, secret, active)
        return key.takeIf { it.isValid() }
    }

    private fun decodeStoredKey(payload: JSONObject): StoredKey? {
        val active = payload.opt("active") as? Boolean ?: return null
        val key = StoredKey(
            payload.getString("keyId"),
            payload.getString("purpose"),
            payload.getString("algorithm"),
            payload.getString("secret"),
            active,
        )
        return key.takeIf { it.isValid() }
    }

    private fun encodeKey(key: StoredKey): JSONObject =
        JSONObject()
            .put("keyId", key.keyId)
            .put("purpose", key.purpose)
            .put("algorithm", key.algorithm)
            .put("secret", key.secret)
            .put("active", key.active)

    private fun snapshotPayload(records: List<StoredKey>): Map<String, Any?> =
        mapOf(
            "available" to true,
            "keys" to records.map { key ->
                mapOf(
                    "keyId" to key.keyId,
                    "purpose" to key.purpose,
                    "algorithm" to key.algorithm,
                    "secret" to key.secret,
                    "active" to key.active,
                )
            },
        )

    private fun isValidNamespace(namespace: String?): Boolean =
        namespace != null && isValidText(namespace, MAX_NAMESPACE_LENGTH)

    private fun isValidKeyId(keyId: String?): Boolean =
        keyId != null &&
            isValidText(keyId, MAX_KEY_ID_LENGTH) &&
            !keyId.contains(':')

    private fun isValidText(value: String, maxLength: Int): Boolean {
        if (value.isEmpty() || value.length > maxLength || value.trim() != value) return false
        return value.none { character ->
            character.code < 0x20 || character.code in 0x7F..0x9F
        }
    }

    private fun preferenceKey(namespace: String): String =
        "namespace_${digestHex(namespace.toByteArray(StandardCharsets.UTF_8))}"

    private fun keyAlias(namespace: String): String =
        "peerdeal_secure_${digestHex(namespace.toByteArray(StandardCharsets.UTF_8))}"

    private fun digestHex(value: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value)
        val output = StringBuilder(digest.size * 2)
        digest.forEach { byte ->
            val unsigned = byte.toInt() and 0xff
            output.append(Character.forDigit(unsigned ushr 4, 16))
            output.append(Character.forDigit(unsigned and 0x0f, 16))
        }
        return output.toString()
    }

    private fun decodeBase64(value: String): ByteArray? = try {
        if (value.isEmpty() || value.length > MAX_ENCODED_BYTES) null
        else Base64.decode(value, Base64.DEFAULT)
    } catch (_: IllegalArgumentException) {
        null
    }

    private data class StoredKey(
        val keyId: String,
        val purpose: String,
        val algorithm: String,
        val secret: String,
        val active: Boolean,
    ) {
        fun isValid(): Boolean =
            isValidTextValue(keyId, MAX_KEY_ID_LENGTH) &&
                !keyId.contains(':') &&
                isValidTextValue(purpose, MAX_PURPOSE_LENGTH) &&
                isValidTextValue(algorithm, MAX_ALGORITHM_LENGTH) &&
                isValidTextValue(secret, MAX_SECRET_LENGTH)

        private fun isValidTextValue(value: String, maxLength: Int): Boolean =
            value.isNotEmpty() &&
                value.length <= maxLength &&
                value.trim() == value &&
                value.none { character ->
                    character.code < 0x20 || character.code in 0x7F..0x9F
                }
    }

    private sealed class ReadResult {
        data class Success(val records: List<StoredKey>) : ReadResult()

        data object Failure : ReadResult()
    }
}
