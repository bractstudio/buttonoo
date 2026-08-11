package dev.buttonooo.essential_key.unlock.routes

import android.content.Context
import android.content.pm.PackageManager
import android.os.IBinder
import android.util.Log
import dev.buttonooo.essential_key.unlock.ConsumerPackages
import org.lsposed.hiddenapibypass.HiddenApiBypass
import rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper
import rikka.shizuku.SystemServiceHelper

/**
 * Shizuku unlock route.
 *
 * Availability is deliberately split into three separate facts. The previous version collapsed
 * them into one boolean that also required PERMISSION_GRANTED, so the UI reported "unavailable"
 * and never offered the prompt that would have granted it — the permission could never be
 * obtained. Callers need to know *which* precondition failed to show the right next step.
 */
class ShizukuRoute(private val context: Context) {

    companion object {
        private const val TAG = "ShizukuRoute"
        private const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
        const val PERMISSION_REQUEST_CODE = 4127

        /** Set by MainActivity once Shizuku hands us its binder. */
        @Volatile
        var binderReceived: Boolean = false
    }

    enum class State {
        NOT_INSTALLED,      // Shizuku app isn't on the device
        NOT_RUNNING,        // installed, but the service isn't started
        NEEDS_PERMISSION,   // running, but we haven't been granted API access
        READY
    }

    fun isInstalled(): Boolean = try {
        context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun isBinderAlive(): Boolean = try {
        Shizuku.pingBinder()
    } catch (e: Throwable) {
        // pingBinder throws if the binder was never received (cold start race).
        false
    }

    private fun hasPermission(): Boolean = try {
        if (Shizuku.isPreV11()) false
        else Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (e: Throwable) {
        false
    }

    fun state(): State = when {
        !isInstalled() -> State.NOT_INSTALLED
        !isBinderAlive() -> State.NOT_RUNNING
        !hasPermission() -> State.NEEDS_PERMISSION
        else -> State.READY
    }

    fun isReady(): Boolean = state() == State.READY

    /**
     * Fires Shizuku's permission dialog. The result arrives on the listener MainActivity
     * registered, not here — callers should re-read [state] afterwards.
     */
    fun requestPermission(): Boolean {
        if (!isBinderAlive()) return false
        return try {
            if (Shizuku.shouldShowRequestPermissionRationale()) {
                false // user permanently denied; they must fix it in the Shizuku app
            } else {
                Shizuku.requestPermission(PERMISSION_REQUEST_CODE)
                true
            }
        } catch (e: Throwable) {
            Log.w(TAG, "requestPermission failed", e)
            false
        }
    }

    fun disableConsumerPackages(): Boolean =
        setEnabledState(PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER)

    fun enableConsumerPackages(): Boolean =
        setEnabledState(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT)

    private fun setEnabledState(newState: Int): Boolean {
        if (!isReady()) return false
        val ipm = packageManagerProxy() ?: return false
        val ipmInterface = try {
            Class.forName("android.content.pm.IPackageManager")
        } catch (e: ClassNotFoundException) {
            Log.e(TAG, "IPackageManager interface missing", e)
            return false
        }

        var anySucceeded = false
        for (pkg in ConsumerPackages.forUnlock(context)) {
            try {
                // Invoke against the *interface* that declares the method. The previous version
                // passed ipm.javaClass — the generated proxy class — which does not declare
                // setApplicationEnabledSetting and raised NoSuchMethodException every time.
                HiddenApiBypass.invoke(
                    ipmInterface,
                    ipm,
                    "setApplicationEnabledSetting",
                    pkg,
                    newState,
                    0,
                    0,
                    context.packageName
                )
                anySucceeded = true
            } catch (e: Throwable) {
                Log.w(TAG, "setApplicationEnabledSetting failed for $pkg", e)
            }
        }
        return anySucceeded
    }

    private fun packageManagerProxy(): Any? = try {
        val binder: IBinder = SystemServiceHelper.getSystemService("package")
        val wrapped = ShizukuBinderWrapper(binder)
        val stub = Class.forName("android.content.pm.IPackageManager\$Stub")
        stub.getMethod("asInterface", IBinder::class.java).invoke(null, wrapped)
    } catch (e: Throwable) {
        Log.e(TAG, "Could not obtain IPackageManager through Shizuku", e)
        null
    }
}
