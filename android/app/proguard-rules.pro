# The ADB pairing route reflects over its own protocol classes, so R8 cannot see
# the references and strips them. Without this, release builds fail to compile
# with "Missing class io.github.muntashirakon.adb.AdbProtocol$AuthType".
-keep class io.github.muntashirakon.adb.** { *; }
-dontwarn io.github.muntashirakon.adb.**

# Bundled crypto used by the ADB handshake; it references JCA providers that are
# not present on Android and would otherwise be reported as missing.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Shizuku hands its binder over through a provider named only in the manifest.
-keep class rikka.shizuku.** { *; }
-keep class moe.shizuku.** { *; }

# The Shizuku route calls IPackageManager over the hidden API, reached
# reflectively through HiddenApiBypass.
-keep class android.content.pm.IPackageManager { *; }
-keep class android.content.pm.IPackageManager$Stub { *; }
-keep class org.lsposed.hiddenapibypass.** { *; }
