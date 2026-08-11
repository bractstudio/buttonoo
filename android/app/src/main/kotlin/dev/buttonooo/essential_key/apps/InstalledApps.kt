package dev.buttonooo.essential_key.apps

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.LruCache
import java.io.ByteArrayOutputStream

/** One launcher-visible app. Icons are fetched separately — see [InstalledApps.iconFor]. */
data class AppEntry(
    val packageName: String,
    val label: String
)

/**
 * The launcher app list and its icons.
 *
 * Labels and icons are served separately because the two have very different costs. Building the
 * label list is a single [PackageManager] query; rendering icons means allocating and compressing
 * one bitmap per app, which is far too expensive to do for a whole device just to show a list of
 * names. Callers that only need names never pay for pixels.
 *
 * Both caches live for the process and are dropped when a package is installed, removed or changed.
 */
class InstalledApps private constructor(private val context: Context) {

    @Volatile
    private var entries: List<AppEntry>? = null

    /** Bounded by bytes rather than count: icon sizes vary by an order of magnitude. */
    private val icons = object : LruCache<String, ByteArray>(ICON_CACHE_BYTES) {
        override fun sizeOf(key: String, value: ByteArray) = value.size
    }

    init {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) = invalidate()
        }
        context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

    /** Every app with a launcher entry, one row per package, sorted by label. */
    fun launcherApps(): List<AppEntry> = entries ?: query().also { entries = it }

    /** Labels for a specific set of packages. Unknown packages are omitted. */
    fun labelsFor(packages: Collection<String>): Map<String, String> {
        val wanted = packages.toSet()
        if (wanted.isEmpty()) return emptyMap()
        return launcherApps()
            .filter { it.packageName in wanted }
            .associate { it.packageName to it.label }
    }

    /**
     * The launcher icon for one package, drawn at [sizePx] square and encoded as lossy WebP.
     *
     * Adaptive icons report an intrinsic size of several hundred pixels; encoding at that size
     * losslessly produced roughly 700 KB per app, all of it thrown away by the list that only ever
     * draws a 40 dp row. Returns null if the package has no launcher entry.
     */
    fun iconFor(packageName: String, sizePx: Int): ByteArray? {
        val key = "$packageName@$sizePx"
        icons.get(key)?.let { return it }

        val drawable = launcherActivity(packageName)?.loadIcon(context.packageManager) ?: return null
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).let { canvas ->
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
        }

        val bytes = ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, ICON_QUALITY, stream)
            stream.toByteArray()
        }
        bitmap.recycle()

        icons.put(key, bytes)
        return bytes
    }

    private fun invalidate() {
        entries = null
        icons.evictAll()
    }

    private fun query(): List<AppEntry> {
        val pm = context.packageManager
        return pm.queryIntentActivities(launcherIntent(), noFlags())
            // An app may declare more than one launcher activity; the pickers act on the package,
            // so collapse those into a single row rather than showing the same app twice.
            .distinctBy { it.activityInfo.packageName }
            .map { AppEntry(it.activityInfo.packageName, it.loadLabel(pm).toString()) }
            .sortedBy { it.label.lowercase() }
    }

    private fun launcherActivity(packageName: String): ResolveInfo? {
        val intent = launcherIntent().setPackage(packageName)
        return context.packageManager.queryIntentActivities(intent, noFlags()).firstOrNull()
    }

    private fun launcherIntent() = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

    private fun noFlags() = PackageManager.ResolveInfoFlags.of(0)

    companion object {
        private const val ICON_CACHE_BYTES = 4 * 1024 * 1024
        private const val ICON_QUALITY = 90

        @Volatile
        private var instance: InstalledApps? = null

        fun get(context: Context): InstalledApps = instance ?: synchronized(this) {
            instance ?: InstalledApps(context.applicationContext).also { instance = it }
        }
    }
}
