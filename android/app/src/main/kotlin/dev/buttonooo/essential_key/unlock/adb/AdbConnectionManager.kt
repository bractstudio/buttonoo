package dev.buttonooo.essential_key.unlock.adb

import android.content.Context
import android.os.Build
import android.util.Log
import io.github.muntashirakon.adb.AbsAdbConnectionManager
import java.io.File
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.cert.Certificate
import java.security.cert.CertificateFactory
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Date
// sun-security-android relocates these under `android.sun.security.x509`, not `sun.security.x509`.
import android.sun.security.x509.AlgorithmId
import android.sun.security.x509.CertificateAlgorithmId
import android.sun.security.x509.CertificateIssuerName
import android.sun.security.x509.CertificateSerialNumber
import android.sun.security.x509.CertificateSubjectName
import android.sun.security.x509.CertificateValidity
import android.sun.security.x509.CertificateVersion
import android.sun.security.x509.CertificateX509Key
import android.sun.security.x509.X500Name
import android.sun.security.x509.X509CertImpl
import android.sun.security.x509.X509CertInfo

/**
 * Real ADB connection manager backed by libadb-android.
 *
 * The identity (RSA keypair + self-signed certificate) is generated once and persisted in the
 * app's private files dir, so a paired device stays paired across app restarts. adbd remembers
 * the public key, so regenerating it on every launch would force the user to re-pair every time.
 */
class AdbConnectionManager private constructor(context: Context) : AbsAdbConnectionManager() {

    private val storedPrivateKey: PrivateKey
    private val storedCertificate: Certificate

    init {
        setApi(Build.VERSION.SDK_INT)
        val dir = File(context.filesDir, "adb").apply { mkdirs() }
        val keyFile = File(dir, "adbkey")
        val certFile = File(dir, "adbkey.cert")

        if (keyFile.exists() && certFile.exists()) {
            storedPrivateKey = KeyFactory.getInstance("RSA")
                .generatePrivate(PKCS8EncodedKeySpec(keyFile.readBytes()))
            storedCertificate = CertificateFactory.getInstance("X.509")
                .generateCertificate(certFile.inputStream())
        } else {
            val generator = KeyPairGenerator.getInstance("RSA")
            generator.initialize(2048, SecureRandom.getInstance("SHA1PRNG"))
            val keyPair = generator.generateKeyPair()
            val certificate = selfSign(keyPair.private, keyPair.public)

            keyFile.writeBytes(keyPair.private.encoded)
            certFile.writeBytes(certificate.encoded)

            storedPrivateKey = keyPair.private
            storedCertificate = certificate
        }
    }

    override fun getPrivateKey(): PrivateKey = storedPrivateKey

    override fun getCertificate(): Certificate = storedCertificate

    override fun getDeviceName(): String = DEVICE_NAME

    private fun selfSign(privateKey: PrivateKey, publicKey: java.security.PublicKey): Certificate {
        val subject = X500Name("CN=$DEVICE_NAME, OU=EssentialKey, O=buttonooo, C=US")
        val now = System.currentTimeMillis()
        val notBefore = Date(now)
        val notAfter = Date(now + VALIDITY_MS)

        val certInfo = X509CertInfo()
        certInfo.set(X509CertInfo.VERSION, CertificateVersion(CertificateVersion.V3))
        certInfo.set(
            X509CertInfo.SERIAL_NUMBER,
            CertificateSerialNumber(BigInteger(64, SecureRandom()))
        )
        // This build of sun-security-android is the JDK 8-style API: SUBJECT and ISSUER take the
        // CertificateSubjectName / CertificateIssuerName wrappers, not a bare X500Name. Passing
        // the X500Name directly compiles fine but throws at runtime:
        //   CertificateException: Subject class type invalid.
        certInfo.set(X509CertInfo.SUBJECT, CertificateSubjectName(subject))
        certInfo.set(X509CertInfo.ISSUER, CertificateIssuerName(subject))
        certInfo.set(X509CertInfo.VALIDITY, CertificateValidity(notBefore, notAfter))
        certInfo.set(X509CertInfo.KEY, CertificateX509Key(publicKey))
        certInfo.set(
            X509CertInfo.ALGORITHM_ID,
            CertificateAlgorithmId(AlgorithmId.get(SIGNATURE_ALGORITHM))
        )

        return X509CertImpl(certInfo).apply { sign(privateKey, SIGNATURE_ALGORITHM) }
    }

    companion object {
        private const val TAG = "AdbConnectionManager"
        private const val DEVICE_NAME = "EssentialKey"
        private const val SIGNATURE_ALGORITHM = "SHA512withRSA"
        private const val VALIDITY_MS = 10L * 365 * 24 * 60 * 60 * 1000

        @Volatile
        private var instance: AdbConnectionManager? = null

        fun getInstance(context: Context): AdbConnectionManager? =
            instance ?: synchronized(this) {
                instance ?: try {
                    AdbConnectionManager(context.applicationContext).also { instance = it }
                } catch (e: Throwable) {
                    Log.e(TAG, "Could not build ADB identity", e)
                    null
                }
            }
    }
}
