package dev.buttonooo.essential_key.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import dev.buttonooo.essential_key.actions.ActionState
import dev.buttonooo.essential_key.actions.KeyAction
import dev.buttonooo.essential_key.config.OverlayConfig

class OverlayController(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())

    private var currentConfig = OverlayConfig()
    private var anchorEdge: Edge = Edge.LEFT
    private var anchorFraction: Float = 0.34f

    private var nothingView: NothingGlowView? = null
    private var stockView: StockPillView? = null

    private var activeView: View? = null
    private var isAttached = false
    private var activeAction: KeyAction = KeyAction.None

    private var hideRunnable: Runnable? = null
    private var removeRunnable: Runnable? = null

    init {
        nothingView = NothingGlowView(context).apply {
            onAppLaunchedListener = {
                dismiss()
            }
        }
        stockView = StockPillView(context)
    }

    fun updateConfig(cfg: OverlayConfig) {
        currentConfig = cfg
    }

    fun updateAnchor(edge: String, fraction: Float) {
        anchorEdge = when (edge.lowercase()) {
            "right" -> Edge.RIGHT
            "top" -> Edge.TOP
            "bottom" -> Edge.BOTTOM
            else -> Edge.LEFT
        }
        anchorFraction = fraction.coerceIn(0.1f, 0.9f)
    }

    /**
     * @param sticky keeps the overlay on screen indefinitely instead of fading after holdMs.
     *   Used while the overlay settings page is open so a change can be seen for real rather
     *   than approximated by an in-page drawing.
     */
    fun show(action: KeyAction, state: ActionState, sticky: Boolean = false) {
        if (!sticky && !currentConfig.enabled) return
        if (!Settings.canDrawOverlays(context)) return

        handler.post {
            cancelTimers()
            activeAction = action

            val viewToShow = if (currentConfig.style == "stock") {
                stockView?.apply { configure(action, state, currentConfig.accentHex) }
            } else {
                nothingView?.apply {
                    setAnchorFraction(anchorFraction)
                    setGeometry(
                        currentConfig.cardWidthDp,
                        currentConfig.cardHeightDp,
                        currentConfig.panelWidthDp,
                        currentConfig.panelHeightDp,
                        currentConfig.edgeMarginDp,
                        currentConfig.cornerRadiusDp
                    )
                    configure(
                        action,
                        state,
                        currentConfig.accentHex,
                        currentConfig.glow,
                        anchorEdge,
                        currentConfig.panelSize,
                        currentConfig.cardStyle,
                        animate = !isAttached || this.visibility != View.VISIBLE
                    )
                }
            } ?: return@post

            activeView = viewToShow
            viewToShow.visibility = View.VISIBLE

            val params = createLayoutParams(action)
            if (!isAttached) {
                try {
                    windowManager.addView(viewToShow, params)
                    isAttached = true
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            } else {
                try {
                    windowManager.updateViewLayout(viewToShow, params)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            if (sticky) return@post   // caller owns dismissal

            // Hide view visually after holdMs
            hideRunnable = Runnable {
                val view = activeView
                if (view is NothingGlowView) {
                    view.startHideAnimation {
                        if (activeView == view) {
                            view.visibility = View.INVISIBLE
                        }
                    }
                } else {
                    view?.visibility = View.INVISIBLE
                }
            }
            handler.postDelayed(hideRunnable!!, currentConfig.holdMs.toLong())

            // Remove view from WindowManager after 10 seconds idle keep-alive
            removeRunnable = Runnable {
                detachView()
            }
            handler.postDelayed(removeRunnable!!, 10000L)
        }
    }

    /** Tears down a sticky preview when the settings page closes. */
    fun dismiss() {
        handler.post {
            cancelTimers()
            detachView()
        }
    }

    fun onRotationChanged() {
        if (isAttached && activeView != null) {
            try {
                windowManager.updateViewLayout(activeView, createLayoutParams(activeAction))
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun createLayoutParams(action: KeyAction): WindowManager.LayoutParams {
        // The Nothing overlay is a full-height strip pinned to the edge: the hairline runs 560dp
        // and the bloom spills past the edge, so it cannot be a wrap-content box at the anchor.
        // The view places the panel itself from anchorFraction.
        if (currentConfig.style != "stock") {
            val rot = windowManager.defaultDisplay.rotation
            val (xn0, yn0) = OverlayAnchor.getNormalizedCoords(anchorEdge, anchorFraction)
            val p = OverlayAnchor.screenPosition(xn0, yn0, rot)
            
            val flags = if (action is KeyAction.AppsColumn) {
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            } else {
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            }

            return WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                flags,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = (if (p.x >= 0.5f) Gravity.END else Gravity.START) or Gravity.TOP
                x = 0
                y = 0
            }
        }

        val rotation = windowManager.defaultDisplay.rotation
        val (xn, yn) = OverlayAnchor.getNormalizedCoords(anchorEdge, anchorFraction)
        val pos = OverlayAnchor.screenPosition(xn, yn, rotation)

        val displayMetrics = context.resources.displayMetrics
        val screenW = displayMetrics.widthPixels
        val screenH = displayMetrics.heightPixels

        val gravity = when {
            pos.x == 1.0f -> Gravity.END or Gravity.TOP
            pos.y == 0.0f -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
            pos.y == 1.0f -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            else -> Gravity.START or Gravity.TOP
        }

        val viewW = activeView?.measuredWidth ?: (180 * displayMetrics.density).toInt()
        val viewH = activeView?.measuredHeight ?: (72 * displayMetrics.density).toInt()

        val xPos = when {
            pos.x == 1.0f -> 0
            pos.y == 0.0f || pos.y == 1.0f -> (pos.x * screenW - viewW / 2f).toInt().coerceIn(0, screenW - viewW)
            else -> (pos.x * screenW).toInt()
        }

        val yPos = when {
            pos.y == 0.0f || pos.y == 1.0f -> 0
            else -> (pos.y * screenH - viewH / 2f).toInt().coerceIn(0, (screenH - viewH).coerceAtLeast(0))
        }

        val flags = if (action is KeyAction.AppsColumn) {
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        } else {
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        }

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            flags,
            PixelFormat.TRANSLUCENT
        ).apply {
            this.gravity = gravity
            this.x = xPos
            this.y = yPos
        }
    }

    private fun cancelTimers() {
        hideRunnable?.let { handler.removeCallbacks(it) }
        removeRunnable?.let { handler.removeCallbacks(it) }
        hideRunnable = null
        removeRunnable = null
    }

    private fun detachView() {
        if (isAttached && activeView != null) {
            try {
                windowManager.removeView(activeView)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            isAttached = false
            activeView = null
        }
    }
}
