package dev.buttonooo.essential_key.overlay

import android.os.Build

/**
 * Seed positions only. Every entry here was previously Edge.LEFT, which is why the overlay
 * could never appear on the right — there was no right-edge path at all. These are starting
 * points; the saved config always wins once the user has set a position.
 */
object DeviceAnchors {
    private val TABLE = mapOf(
        // Design reference specifies "A059 · right edge · 41%".
        "Asteroids" to Anchor(edge = Edge.RIGHT, fraction = 0.41f),
        "A059" to Anchor(edge = Edge.RIGHT, fraction = 0.41f),
        "Pacman" to Anchor(edge = Edge.RIGHT, fraction = 0.41f),
        "Spacewar" to Anchor(edge = Edge.RIGHT, fraction = 0.41f)
    )

    val FALLBACK = Anchor(Edge.RIGHT, 0.41f)

    fun forCurrentDevice(): Anchor = TABLE[Build.DEVICE] ?: TABLE[Build.MODEL] ?: FALLBACK
}
