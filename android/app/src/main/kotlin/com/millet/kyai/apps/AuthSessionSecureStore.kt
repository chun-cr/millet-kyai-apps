package com.millet.kyai.apps

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.json.JSONObject

class AuthSessionSecureStore(
    context: Context,
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.error(
                "UNSUPPORTED_SECURE_STORAGE",
                "Secure session storage requires Android 6.0 or newer.",
                null,
            )
            return
        }

        try {
            when (call.method) {
                "readAll" -> result.success(readAll())
                "writeAll" -> {
                    @Suppress("UNCHECKED_CAST")
                    val arguments =
                        (call.arguments as? Map<*, *>)?.entries?.associate { entry ->
                            entry.key.toString() to entry.value
                        } ?: emptyMap()
                    writeAll(arguments)
                    result.success(null)
                }
                "clear" -> {
                    clear()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("SECURE_STORAGE_ERROR", error.message, null)
        }
    }

    private fun readAll(): Map<String, Any>? {
        val encryptedPayload = prefs().getString(ENCRYPTED_PAYLOAD_KEY, null) ?: return null
        val iv = prefs().getString(IV_KEY, null) ?: return null
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.DECRYPT_MODE,
            getOrCreateSecretKey(),
            GCMParameterSpec(GCM_TAG_LENGTH_BITS, Base64.decode(iv, Base64.NO_WRAP)),
        )
        val clearText =
            cipher.doFinal(Base64.decode(encryptedPayload, Base64.NO_WRAP)).toString(StandardCharsets.UTF_8)
        val json = JSONObject(clearText)
        val values = mutableMapOf<String, Any>()
        val iterator = json.keys()
        while (iterator.hasNext()) {
            val key = iterator.next()
            when (val value = json.get(key)) {
                // Session payload numeric fields are integer-based; preserve
                // them as 64-bit values so epoch timestamps survive reloads.
                is Int -> values[key] = value.toLong()
                is Long -> values[key] = value
                is Number -> values[key] = value.toLong()
                is String -> values[key] = value
            }
        }
        return values
    }

    private fun writeAll(values: Map<String, Any?>) {
        val json = JSONObject()
        values.forEach { (key, value) -> json.put(key, value) }

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecretKey())
        val encrypted =
            cipher.doFinal(json.toString().toByteArray(StandardCharsets.UTF_8))
        prefs()
            .edit()
            .putString(ENCRYPTED_PAYLOAD_KEY, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .putString(IV_KEY, Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .apply()
    }

    private fun clear() {
        prefs().edit().clear().apply()
    }

    private fun prefs() = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        val existingKey = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
        if (existingKey != null) {
            return existingKey
        }

        val keyGenerator =
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER)
        val parameterSpec =
            KeyGenParameterSpec.Builder(
                    KEY_ALIAS,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build()
        keyGenerator.init(parameterSpec)
        return keyGenerator.generateKey()
    }

    companion object {
        private const val PREFS_NAME = "secure_auth_session"
        private const val ENCRYPTED_PAYLOAD_KEY = "payload"
        private const val IV_KEY = "iv"
        private const val KEY_ALIAS = "auth_session_key"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_TAG_LENGTH_BITS = 128
    }
}
