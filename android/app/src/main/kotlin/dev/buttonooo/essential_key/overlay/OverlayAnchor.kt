package dev.buttonooo.essential_key.overlay

import android.graphics.PointF
import android.view.Surface

enum class Edge { LEFT, RIGHT, TOP, BOTTOM }

data class Anchor(val edge: Edge, val fraction: Float)

object OverlayAnchor {
    /**
     * Map natural-orientation normalized anchor (xn, yn) to current screen orientation PointF (0.0 .. 1.0)
     */
    fun screenPosition(xn: Float, yn: Float, rotation: Int): PointF = when (rotation) {
        Surface.ROTATION_0   -> PointF(xn,       yn)
        Surface.ROTATION_90  -> PointF(yn,       1f - xn)
        Surface.ROTATION_180 -> PointF(1f - xn,  1f - yn)
        else /* 270 */       -> PointF(1f - yn,  xn)
    }

    fun getNormalizedCoords(edge: Edge, fraction: Float): Pair<Float, Float> {
        return when (edge) {
            Edge.LEFT -> Pair(0.0f, fraction)
            Edge.RIGHT -> Pair(1.0f, fraction)
            Edge.TOP -> Pair(fraction, 0.0f)
            Edge.BOTTOM -> Pair(fraction, 1.0f)
        }
    }
}
