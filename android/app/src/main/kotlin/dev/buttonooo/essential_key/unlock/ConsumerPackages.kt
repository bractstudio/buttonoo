package dev.buttonooo.essential_key.unlock

import android.content.Context
import android.content.pm.PackageManager

/**
 * The Nothing OS packages that consume the Essential Key's presses in system policy.
 * Disabling them is what frees the single press.
 *
 * This is a fixed allowlist on purpose. The previous implementation swept every installed
 * package for the substring "essential" and disabled the matches, which on a real device also
 * caught unrelated apps — com.nothing.essential.search is present on Phone (3a) and has nothing
 * to do with the key. Disabling a user's search provider because its name contains a substring
 * is not a recoverable mistake for them to diagnose.
 */
object ConsumerPackages {

    /** Essential Space — owns single press (capture) and double press. */
    const val ESSENTIAL_SPACE = "com.nothing.ntessentialspace"

    /** Essential Recorder — owns long press (voice memo). */
    const val ESSENTIAL_RECORDER = "com.nothing.ntessentialrecorder"

    /** Reported as an additional consumer on Phone (3a) Lite. */
    const val ESSENTIAL_INTELLIGENCE = "com.essentialintelligence"

    /** Every candidate to probe, in display order. */
    val CANDIDATES: List<String> = listOf(
        ESSENTIAL_SPACE,
        ESSENTIAL_RECORDER,
        ESSENTIAL_INTELLIGENCE
    )

    /** Candidates that are actually installed — the only packages we will ever touch. */
    fun forUnlock(context: Context): List<String> =
        CANDIDATES.filter { isInstalled(context, it) }

    fun isInstalled(context: Context, packageName: String): Boolean = try {
        context.packageManager.getApplicationInfo(packageName, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}
