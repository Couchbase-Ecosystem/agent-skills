package com.couchbase.app.data

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * CredentialStore — secure App User credential storage backed by the Android Keystore.
 *
 * The Android equivalent of the iOS skill's KeychainHelper. An AES-256-GCM key is
 * generated in (and never leaves) the Android Keystore — hardware-backed where
 * available. Only the IV + ciphertext are persisted in SharedPreferences, so the
 * plaintext password is never stored on disk.
 *
 * Deliberately NO third-party dependency: does not use the deprecated
 * androidx.security EncryptedSharedPreferences.
 *
 * Usage:
 *   CredentialStore(context).savePassword(username, password)   // on login
 *   val pw = CredentialStore(context).loadPassword(username)     // for reconnect after relaunch
 *   CredentialStore(context).clear(username)                     // on sign-out
 *
 * ADAPT: change PREFS_NAME / package to match your app if desired.
 */
class CredentialStore(context: Context) {

    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun savePassword(username: String, password: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.ENCRYPT_MODE, secretKey()) }
        val ciphertext = cipher.doFinal(password.toByteArray(Charsets.UTF_8))
        prefs.edit()
            .putString(ivKey(username), ciphertext.encode(cipher.iv))
            .putString(dataKey(username), ciphertext.encode())
            .apply()
    }

    fun loadPassword(username: String): String? {
        val iv = prefs.getString(ivKey(username), null)?.decode() ?: return null
        val data = prefs.getString(dataKey(username), null)?.decode() ?: return null
        return try {
            val cipher = Cipher.getInstance(TRANSFORMATION).apply {
                init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(GCM_TAG_BITS, iv))
            }
            String(cipher.doFinal(data), Charsets.UTF_8)
        } catch (e: Exception) {
            // Key invalidated (e.g. device lock changed) or corrupt entry — force re-login
            clear(username)
            null
        }
    }

    fun clear(username: String) {
        prefs.edit().remove(ivKey(username)).remove(dataKey(username)).apply()
    }

    // --- internals -----------------------------------------------------------

    private fun secretKey(): SecretKey {
        val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (ks.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        gen.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return gen.generateKey()
    }

    private fun ivKey(u: String) = "iv::$u"
    private fun dataKey(u: String) = "ct::$u"

    private fun ByteArray.encode(bytes: ByteArray = this) = Base64.encodeToString(bytes, Base64.NO_WRAP)
    private fun String.decode(): ByteArray = Base64.decode(this, Base64.NO_WRAP)

    companion object {
        private const val KEYSTORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "cbl_credential_key"
        private const val PREFS_NAME = "cbl_credentials"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_TAG_BITS = 128
    }
}
