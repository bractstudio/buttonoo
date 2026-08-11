package dev.buttonooo.essential_key.overlay

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.*
import android.text.TextPaint
import android.text.TextUtils
import android.util.AttributeSet
import android.view.View
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.PathInterpolator
import dev.buttonooo.essential_key.actions.ActionState
import dev.buttonooo.essential_key.actions.KeyAction

class NothingGlowView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val density = resources.displayMetrics.density

    // Paints
    private val edgeBarPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val cardBgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#0C0D10")
        style = Paint.Style.FILL
    }
    private val cardBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3.5f * density
    }
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
        strokeWidth = 2.5f * density
    }
    private val iconFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 13.5f * density
        typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
    }

    private val cardRect = RectF()
    private val edgeBarRect = RectF()
    private val bloomPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }

    // Reusable animation/drawing objects to avoid onDraw allocations
    private val path1 = Path()
    private val path2 = Path()
    private val seg1 = Path()
    private val seg2 = Path()
    private val pm1 = PathMeasure()
    private val pm2 = PathMeasure()
    private val arcRectTmp = RectF()
    private val panelClipPath = Path()

    private var accentColor: Int = Color.parseColor("#FFD400")
    private var glowEnabled: Boolean = true
    private var stateText: String = "Action"
    private var currentEdge: Edge = Edge.LEFT
    private var currentAction: KeyAction = KeyAction.None
    private var currentState: ActionState = ActionState()
    private var cardStyle: String = "filled"

    // Animation transition variables
    private var torchTransition = 0f
    private var playPauseTransition = 0f
    private var rotationTransition = 0f
    private var scaleTransition = 1f

    private var lastTorchOn: Boolean? = null
    private var lastMediaPlaying: Boolean? = null
    private var lastRotationLocked: Boolean? = null

    // Overlay reveal/hide animations
    private var revealProgress = 0f
    private var revealAnimator: ValueAnimator? = null
    private val revealInterpolator = PathInterpolator(0.22f, 1f, 0.36f, 1f)
    private val hideInterpolator = PathInterpolator(0.3f, 0f, 0.8f, 0.15f)

    private var glowPulseAnimator: ValueAnimator? = null
    private var torchAnimator: ValueAnimator? = null
    private var playPauseAnimator: ValueAnimator? = null
    private var rotationAnimator: ValueAnimator? = null
    private var bounceAnimator: ValueAnimator? = null
    private var glowPulseFactor: Float = 1.0f

    var onAppLaunchedListener: (() -> Unit)? = null

    private companion object {
        val OFF_OUTLINE: Int = Color.parseColor("#2A2E2A")
        val OFF_SQUIRCLE: Int = Color.parseColor("#161916")
        val OFF_ICON: Int = Color.parseColor("#6C726B")
        /** Amber core the edge hairline passes through at the key. */
        val HIGHLIGHT: Int = Color.parseColor("#F0A020")
    }

    init {
        setLayerType(LAYER_TYPE_SOFTWARE, null)
    }

    private var panelSize: String = "Regular"

    fun startRevealAnimation() {
        revealAnimator?.removeAllListeners()
        revealAnimator?.cancel()
        revealAnimator = ValueAnimator.ofFloat(revealProgress, 1f).apply {
            duration = 450
            interpolator = revealInterpolator
            addUpdateListener { anim ->
                revealProgress = anim.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    fun startHideAnimation(onComplete: () -> Unit) {
        revealAnimator?.removeAllListeners()
        revealAnimator?.cancel()
        revealAnimator = ValueAnimator.ofFloat(revealProgress, 0f).apply {
            duration = 300
            interpolator = hideInterpolator
            addUpdateListener { anim ->
                revealProgress = anim.animatedValue as Float
                invalidate()
            }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    onComplete()
                }
            })
            start()
        }
    }

    fun configure(
        action: KeyAction,
        state: ActionState,
        accentHex: String,
        glow: Boolean,
        edge: Edge = Edge.LEFT,
        size: String = "Regular",
        styleCard: String = "filled",
        animate: Boolean = true
    ) {
        try {
            accentColor = Color.parseColor(accentHex)
        } catch (e: Exception) {
            accentColor = Color.parseColor("#D71921")
        }
        glowEnabled = glow
        currentEdge = edge
        currentAction = action
        currentState = state
        panelSize = size
        cardStyle = styleCard
        stateText = state.label.ifEmpty { action.javaClass.simpleName }

        edgeBarPaint.color = accentColor
        cardBorderPaint.color = accentColor

        stopGlowAnimation()
        if (glowEnabled) {
            startGlowAnimation()
        } else {
            edgeBarPaint.clearShadowLayer()
            cardBorderPaint.clearShadowLayer()
        }

        if (action is KeyAction.AppsColumn) {
            setColumn(action.packageNames.size, -1)
        } else {
            setColumn(0, -1)
        }

        // Animate torch state transition
        val targetTorch = currentState.torchOn
        if (lastTorchOn == null) {
            lastTorchOn = targetTorch
            torchTransition = if (targetTorch) 1f else 0f
        } else if (lastTorchOn != targetTorch) {
            lastTorchOn = targetTorch
            torchAnimator?.cancel()
            torchAnimator = ValueAnimator.ofFloat(torchTransition, if (targetTorch) 1f else 0f).apply {
                duration = 250
                addUpdateListener { anim ->
                    torchTransition = anim.animatedValue as Float
                    invalidate()
                }
                start()
            }
        }

        // Animate media play/pause state transition
        val targetPlaying = currentState.mediaPlaying
        if (lastMediaPlaying == null) {
            lastMediaPlaying = targetPlaying
            playPauseTransition = if (targetPlaying) 1f else 0f
        } else if (lastMediaPlaying != targetPlaying) {
            lastMediaPlaying = targetPlaying
            playPauseAnimator?.cancel()
            playPauseAnimator = ValueAnimator.ofFloat(playPauseTransition, if (targetPlaying) 1f else 0f).apply {
                duration = 250
                addUpdateListener { anim ->
                    playPauseTransition = anim.animatedValue as Float
                    invalidate()
                }
                start()
            }
        }

        // Animate rotation lock transition
        val targetLocked = currentState.rotationLocked
        if (lastRotationLocked == null) {
            lastRotationLocked = targetLocked
            rotationTransition = if (targetLocked) 1f else 0f
        } else if (lastRotationLocked != targetLocked) {
            lastRotationLocked = targetLocked
            rotationAnimator?.cancel()
            rotationAnimator = ValueAnimator.ofFloat(rotationTransition, if (targetLocked) 1f else 0f).apply {
                duration = 300
                addUpdateListener { anim ->
                    rotationTransition = anim.animatedValue as Float
                    invalidate()
                }
                start()
            }
        }

        // Trigger scale bounce pulse animation for click feedback
        triggerBounce()

        // Handle path reveal animation
        val shouldAnimate = animate || revealProgress < 1f
        if (shouldAnimate) {
            startRevealAnimation()
        } else {
            revealAnimator?.cancel()
            revealProgress = 1f
        }

        alpha = 1f
        scaleX = 1f
        scaleY = 1f

        requestLayout()
        invalidate()
    }

    private fun startGlowAnimation() {
        glowPulseAnimator = ValueAnimator.ofFloat(0.4f, 1.0f).apply {
            duration = 750
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.REVERSE
            interpolator = AccelerateDecelerateInterpolator()
            addUpdateListener { anim ->
                glowPulseFactor = anim.animatedValue as Float
                val blurRadius = (14f + 10f * glowPulseFactor) * density
                val alphaInt = (0x99 + (0x66 * glowPulseFactor)).toInt().coerceIn(0, 255)
                val glowColor = Color.argb(alphaInt, Color.red(accentColor), Color.green(accentColor), Color.blue(accentColor))
                edgeBarPaint.setShadowLayer(blurRadius, 0f, 0f, glowColor)
                cardBorderPaint.setShadowLayer(blurRadius * 0.7f, 0f, 0f, glowColor)
                invalidate()
            }
            start()
        }
    }

    private fun stopGlowAnimation() {
        glowPulseAnimator?.cancel()
        glowPulseAnimator = null
    }

    private fun stopAllAnimators() {
        revealAnimator?.cancel()
        revealAnimator = null
        glowPulseAnimator?.cancel()
        glowPulseAnimator = null
        torchAnimator?.cancel()
        torchAnimator = null
        playPauseAnimator?.cancel()
        playPauseAnimator = null
        rotationAnimator?.cancel()
        rotationAnimator = null
        bounceAnimator?.cancel()
        bounceAnimator = null
    }

    private fun triggerBounce() {
        bounceAnimator?.cancel()
        bounceAnimator = ValueAnimator.ofFloat(1f, 1.15f, 1f).apply {
            duration = 200
            interpolator = AccelerateDecelerateInterpolator()
            addUpdateListener { anim ->
                scaleTransition = anim.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopAllAnimators()
    }

    private object Spec {
        const val VIEW_WIDTH = 100f      // room for panel + margin + bloom spill
        const val EDGE_MARGIN = 22f      // panel's gap from the screen edge
        const val PANEL_W = 56f
        const val SQUIRCLE = 56f
        const val CORNER = 18f
        const val GAP = 10f              // squircle bottom -> panel top
        const val BORDER = 2.5f
        const val HAIRLINE_W = 2f
        const val HAIRLINE_H = 560f
        const val BLOOM_W = 20f
        const val BLOOM_H = 160f
        const val BLOOM_BLUR = 20f
        /** Panel top relative to the key, as a fraction of panel height (58/148 in the mock). */
        const val PANEL_TOP_RATIO = 0.392f
    }

    /** Where the physical key sits along the edge, 0..1 of view height. */
    private var anchorFraction: Float = 0.41f

    /** Non-null puts the panel in track mode: the outline fills from the bottom. */
    private var trackProgress: Float? = null

    /** Non-empty draws the shortcut column instead of a track. */
    private var columnCount: Int = 0
    private var columnSelected: Int = 0

    // Live geometry, driven by the overlay settings page.
    private var cardW = 52f
    private var cardH = 40f
    private var panelW = 56f
    private var panelH = 148f
    private var edgeMargin = 22f
    private var cornerRadius = 18f * density

    private fun needsPanel(): Boolean = trackProgress != null || columnCount > 0

    fun setAnchorFraction(fraction: Float) {
        anchorFraction = fraction.coerceIn(0.05f, 0.95f)
    }

    fun setTrackProgress(progress: Float?) {
        trackProgress = progress?.coerceIn(0f, 1f)
    }

    fun setColumn(count: Int, selected: Int) {
        columnCount = count.coerceIn(0, 6)
        columnSelected = selected
    }

    private fun getAppColumnMetrics(): AppColumnMetrics {
        val dot = 42f * density
        val gap = 8f * density
        val padding = 10f * density
        val actualPanelH = columnCount * dot + (columnCount - 1) * gap + 2 * padding
        return AppColumnMetrics(dot, gap, padding, actualPanelH)
    }

    private data class AppColumnMetrics(
        val dot: Float,
        val gap: Float,
        val padding: Float,
        val actualPanelH: Float
    )

    fun setGeometry(cardWDp: Int, cardHDp: Int, panelWDp: Int, panelHDp: Int, edgeMarginDp: Int, cornerRadiusDp: Int) {
        cardW = cardWDp * density
        cardH = cardHDp * density
        panelW = panelWDp * density
        panelH = panelHDp * density
        edgeMargin = edgeMarginDp * density
        cornerRadius = cornerRadiusDp * density
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val maxContentW = Math.max(cardW, panelW)
        val requiredW = (maxContentW + edgeMargin + 40f * density).toInt()
        setMeasuredDimension(
            requiredW,
            MeasureSpec.getSize(heightMeasureSpec)
        )
    }

    private fun isActiveState(): Boolean = when (currentAction) {
        is KeyAction.ToggleFlashlight -> currentState.torchOn
        is KeyAction.ToggleRotationLock -> currentState.rotationLocked
        else -> true
    }

    private fun buildHalfPath(path: Path, rect: RectF, r: Float, onRight: Boolean, topHalf: Boolean) {
        path.reset()
        val L = rect.left
        val T = rect.top
        val R = rect.right
        val B = rect.bottom
        val cy = (T + B) / 2f

        if (!onRight) {
            if (topHalf) {
                path.moveTo(L, cy)
                path.lineTo(L, T + r)
                arcRectTmp.set(L, T, L + 2 * r, T + 2 * r)
                path.arcTo(arcRectTmp, 180f, 90f, false)
                path.lineTo(R - r, T)
                arcRectTmp.set(R - 2 * r, T, R, T + 2 * r)
                path.arcTo(arcRectTmp, 270f, 90f, false)
                path.lineTo(R, cy)
            } else {
                path.moveTo(L, cy)
                path.lineTo(L, B - r)
                arcRectTmp.set(L, B - 2 * r, L + 2 * r, B)
                path.arcTo(arcRectTmp, 180f, -90f, false)
                path.lineTo(R - r, B)
                arcRectTmp.set(R - 2 * r, B - 2 * r, R, B)
                path.arcTo(arcRectTmp, 90f, -90f, false)
                path.lineTo(R, cy)
            }
        } else {
            if (topHalf) {
                path.moveTo(R, cy)
                path.lineTo(R, T + r)
                arcRectTmp.set(R - 2 * r, T, R, T + 2 * r)
                path.arcTo(arcRectTmp, 0f, -90f, false)
                path.lineTo(L + r, T)
                arcRectTmp.set(L, T, L + 2 * r, T + 2 * r)
                path.arcTo(arcRectTmp, 270f, -90f, false)
                path.lineTo(L, cy)
            } else {
                path.moveTo(R, cy)
                path.lineTo(R, B - r)
                arcRectTmp.set(R - 2 * r, B - 2 * r, R, B)
                path.arcTo(arcRectTmp, 0f, 90f, false)
                path.lineTo(L + r, B)
                arcRectTmp.set(L, B - 2 * r, L + 2 * r, B)
                path.arcTo(arcRectTmp, 90f, 90f, false)
                path.lineTo(L, cy)
            }
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val onState = isActiveState()
        val chrome = if (onState) accentColor else OFF_OUTLINE
        val squircleFill = if (onState) accentColor else OFF_SQUIRCLE
        val iconTint = if (onState) Color.parseColor("#0A0A0A") else OFF_ICON

        val keyY = height * anchorFraction
        val corner = cornerRadius
        val onRight = currentEdge != Edge.LEFT
        val showPanel = needsPanel()

        // Calculate progress segments based on revealProgress
        val hairlineProgress = (revealProgress / 0.4f).coerceIn(0f, 1f)
        val strokeProgress = ((revealProgress - 0.2f) / 0.6f).coerceIn(0f, 1f)
        val contentProgress = ((revealProgress - 0.6f) / 0.4f).coerceIn(0f, 1f)

        if (glowEnabled) drawEdgeGlow(canvas, keyY, onRight, chrome, hairlineProgress)

        fun rightEdgeFor(w: Float) = if (onRight) width - edgeMargin else edgeMargin + w

        cardBorderPaint.strokeWidth = Spec.BORDER * density
        cardBorderPaint.color = chrome
        val half = cardBorderPaint.strokeWidth / 2f

        val cardRight = rightEdgeFor(cardW)
        val cardTop = if (showPanel) {
            keyY - panelH * Spec.PANEL_TOP_RATIO - Spec.GAP * density - cardH
        } else {
            keyY - cardH / 2f
        }
        val card = RectF(cardRight - cardW, cardTop, cardRight, cardTop + cardH)

        val actualPanelH = if (columnCount > 0) {
            getAppColumnMetrics().actualPanelH
        } else {
            panelH
        }

        if (showPanel) {
            val panelTop = keyY - actualPanelH * Spec.PANEL_TOP_RATIO
            val panelRight = rightEdgeFor(panelW)
            cardRect.set(panelRight - panelW, panelTop, panelRight, panelTop + actualPanelH)

            val progress = trackProgress
            if (progress != null && contentProgress > 0f) {
                canvas.save()
                panelClipPath.reset()
                panelClipPath.addRoundRect(cardRect, corner, corner, Path.Direction.CW)
                canvas.clipPath(panelClipPath)
                iconFillPaint.color = Color.argb(
                    (Color.alpha(chrome) * contentProgress).toInt(),
                    Color.red(chrome), Color.green(chrome), Color.blue(chrome)
                )
                canvas.drawRect(
                    cardRect.left,
                    cardRect.bottom - cardRect.height() * progress,
                    cardRect.right, cardRect.bottom, iconFillPaint
                )
                canvas.restore()
            }

            if (strokeProgress > 0f) {
                // Symmetrical panel border drawing
                val panelStrokeRect = RectF(cardRect.left + half, cardRect.top + half, cardRect.right - half, cardRect.bottom - half)
                val strokeRadius = corner - half
                
                buildHalfPath(path1, panelStrokeRect, strokeRadius, onRight, topHalf = true)
                buildHalfPath(path2, panelStrokeRect, strokeRadius, onRight, topHalf = false)
                
                pm1.setPath(path1, false)
                pm2.setPath(path2, false)
                
                seg1.reset()
                seg2.reset()
                
                pm1.getSegment(0f, pm1.length * strokeProgress, seg1, true)
                pm2.getSegment(0f, pm2.length * strokeProgress, seg2, true)
                
                canvas.drawPath(seg1, cardBorderPaint)
                canvas.drawPath(seg2, cardBorderPaint)
            }

            if (columnCount > 0 && contentProgress > 0f) {
                drawColumn(canvas, cardRect, chrome, contentProgress)
            }
        }

        // Draw card according to cardStyle - ONLY if showPanel is false
        if (!showPanel) {
            val r = corner * 0.85f
            if (strokeProgress > 0f) {
                // Symmetrical card border drawing
                val cardStrokeRect = RectF(card.left + half, card.top + half, card.right - half, card.bottom - half)
                val strokeRadius = r - half
                
                buildHalfPath(path1, cardStrokeRect, strokeRadius, onRight, topHalf = true)
                buildHalfPath(path2, cardStrokeRect, strokeRadius, onRight, topHalf = false)
                
                pm1.setPath(path1, false)
                pm2.setPath(path2, false)
                
                seg1.reset()
                seg2.reset()
                
                pm1.getSegment(0f, pm1.length * strokeProgress, seg1, true)
                pm2.getSegment(0f, pm2.length * strokeProgress, seg2, true)
                
                canvas.drawPath(seg1, cardBorderPaint)
                canvas.drawPath(seg2, cardBorderPaint)
            }

            if (contentProgress > 0f) {
                if (cardStyle == "stroke") {
                    // Stroke Only (handled above by cardBorderPaint drawing)
                } else if (cardStyle == "transparent") {
                    // Low transparency
                    val baseColor = Color.parseColor("#0C0D10")
                    iconFillPaint.color = Color.argb(
                        (0x33 * contentProgress).toInt().coerceIn(0, 255),
                        Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor)
                    )
                    canvas.drawRoundRect(card, r, r, iconFillPaint)
                } else {
                    // Filled
                    iconFillPaint.color = Color.argb(
                        (255 * contentProgress).toInt().coerceIn(0, 255),
                        Color.red(squircleFill), Color.green(squircleFill), Color.blue(squircleFill)
                    )
                    canvas.drawRoundRect(card, r, r, iconFillPaint)
                }

                // Setup colors for drawing the icon inside
                val drawColor = if (cardStyle == "filled") iconTint else chrome
                val fadedColor = Color.argb(
                    (255 * contentProgress).toInt().coerceIn(0, 255),
                    Color.red(drawColor), Color.green(drawColor), Color.blue(drawColor)
                )

                // Setup paint colors
                iconPaint.color = fadedColor
                iconFillPaint.color = fadedColor

                val iconSize = minOf(cardW, cardH) * 0.52f * scaleTransition * (0.8f + 0.2f * contentProgress)
                val iconRect = RectF(
                    card.centerX() - iconSize / 2f, card.centerY() - iconSize / 2f,
                    card.centerX() + iconSize / 2f, card.centerY() + iconSize / 2f
                )
                drawPhosphorStyleIcon(canvas, iconRect, fadedColor)
            }
        }
    }

    private fun drawColumn(canvas: Canvas, panel: RectF, tint: Int, contentProgress: Float) {
        val metrics = getAppColumnMetrics()
        val dot = metrics.dot
        val gap = metrics.gap
        val padding = metrics.padding
        var cy = panel.top + padding + dot / 2f

        val packageNames = (currentAction as? KeyAction.AppsColumn)?.packageNames

        for (i in 0 until columnCount) {
            // Draw background circle with opacity scaled by contentProgress
            iconFillPaint.color = Color.argb(
                (255 * contentProgress).toInt().coerceIn(0, 255),
                0x1C, 0x1E, 0x22
            )
            val scale = 0.8f + 0.2f * contentProgress
            val radius = (dot / 2f) * scale
            canvas.drawCircle(panel.centerX(), cy, radius, iconFillPaint)

            // Draw app icon inside
            if (packageNames != null && i < packageNames.size) {
                try {
                    val pkg = packageNames[i]
                    val pm = context.packageManager
                    val iconDrawable = pm.getApplicationIcon(pkg)
                    val iconSize = (dot * 0.72f * scale).toInt().coerceAtLeast(1)
                    val bitmap = Bitmap.createBitmap(iconSize, iconSize, Bitmap.Config.ARGB_8888)
                    val canvasTmp = Canvas(bitmap)
                    iconDrawable.setBounds(0, 0, iconSize, iconSize)
                    iconDrawable.draw(canvasTmp)
                    val bmpPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        alpha = (255 * contentProgress).toInt().coerceIn(0, 255)
                    }
                    canvas.drawBitmap(bitmap, panel.centerX() - iconSize / 2f, cy - iconSize / 2f, bmpPaint)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            cy += dot + gap
        }
    }

    private fun drawEdgeGlow(canvas: Canvas, keyY: Float, onRight: Boolean, tint: Int, hairlineProgress: Float) {
        if (hairlineProgress <= 0f) return
        val hairH = Spec.HAIRLINE_H * density * hairlineProgress
        val top = keyY - hairH / 2f
        val hairW = Spec.HAIRLINE_W * density
        val x = if (onRight) width - hairW else 0f

        val transparent = Color.argb(0, Color.red(tint), Color.green(tint), Color.blue(tint))
        val strong = Color.argb(230, Color.red(tint), Color.green(tint), Color.blue(tint))
        edgeBarPaint.shader = LinearGradient(
            0f, top, 0f, top + hairH,
            intArrayOf(transparent, strong, HIGHLIGHT, strong, transparent),
            floatArrayOf(0f, 0.32f, 0.46f, 0.60f, 1f),
            Shader.TileMode.CLAMP
        )
        canvas.drawRect(x, top, x + hairW, top + hairH, edgeBarPaint)
        edgeBarPaint.shader = null

        val bloomW = Spec.BLOOM_W * density
        val bloomH = Spec.BLOOM_H * density * hairlineProgress
        bloomPaint.color = Color.argb(
            (255 * 0.7f * glowPulseFactor * hairlineProgress).toInt().coerceIn(0, 255),
            Color.red(tint), Color.green(tint), Color.blue(tint)
        )
        bloomPaint.maskFilter = BlurMaskFilter(Spec.BLOOM_BLUR * density, BlurMaskFilter.Blur.NORMAL)
        val bloomCx = if (onRight) width.toFloat() else 0f
        canvas.drawRect(
            bloomCx - bloomW / 2f, keyY - bloomH / 2f,
            bloomCx + bloomW / 2f, keyY + bloomH / 2f,
            bloomPaint
        )
    }

    private val phosphorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
    }

    private val phosphorTypeface by lazy {
        try {
            Typeface.createFromAsset(context.assets, "flutter_assets/packages/phosphor_flutter/lib/fonts/Phosphor.ttf")
        } catch (e: Exception) {
            try {
                Typeface.createFromAsset(context.assets, "flutter_assets/packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf")
            } catch (ex: Exception) {
                Typeface.DEFAULT
            }
        }
    }

    private fun drawPhosphorStyleIcon(canvas: Canvas, rect: RectF, drawColor: Int) {
        val cx = rect.centerX()
        val cy = rect.centerY()

        if (currentAction is KeyAction.LaunchApp) {
            drawAppIcon(canvas, (currentAction as KeyAction.LaunchApp).packageName, rect, Color.alpha(drawColor))
            return
        } else if (currentAction is KeyAction.LaunchShortcut) {
            drawAppIcon(canvas, (currentAction as KeyAction.LaunchShortcut).packageName, rect, Color.alpha(drawColor))
            return
        } else if (currentAction is KeyAction.LaunchActivity) {
            drawAppIcon(canvas, (currentAction as KeyAction.LaunchActivity).packageName, rect, Color.alpha(drawColor))
            return
        }

        val iconChar = when (currentAction) {
            is KeyAction.ToggleFlashlight -> "\uE246"
            is KeyAction.ToggleRotationLock -> "\uE1E0"
            is KeyAction.RingerCycle -> when (currentState.ringerMode) {
                0 -> "\uE0D2"
                1 -> "\uE4D8"
                else -> "\uE5E8"
            }
            is KeyAction.ToggleDnd -> "\uE330"
            is KeyAction.VoiceAssistant -> "\uE326"
            is KeyAction.VolumeUp -> "\uE44A"
            is KeyAction.VolumeDown -> "\uE44C"
            is KeyAction.VolumeMute -> "\uE45A"
            is KeyAction.VolumeSlider -> "\uE44A"
            is KeyAction.BrightnessUp -> "\uE472"
            is KeyAction.BrightnessDown -> "\uE474"
            is KeyAction.TakeScreenshot -> "\uE10E"
            is KeyAction.LockScreen -> "\uE2FA"
            is KeyAction.MediaPlayPause -> if (currentState.mediaPlaying) "\uE39E" else "\uE3D0"
            is KeyAction.MediaNext -> "\uE5A6"
            is KeyAction.MediaPrev -> "\uE5A4"
            is KeyAction.AppsColumn -> "\uE464"
            else -> "\uE6A2"
        }

        phosphorPaint.apply {
            color = drawColor
            typeface = phosphorTypeface
            textSize = rect.width() * 0.95f
        }

        val fontMetrics = phosphorPaint.fontMetrics
        val textY = cy - (fontMetrics.ascent + fontMetrics.descent) / 2f

        canvas.drawText(iconChar, cx, textY, phosphorPaint)
    }

    private fun drawAppIcon(canvas: Canvas, packageName: String, rect: RectF, alphaVal: Int) {
        try {
            val pm = context.packageManager
            val iconDrawable = pm.getApplicationIcon(packageName)
            val w = rect.width().toInt().coerceAtLeast(1)
            val h = rect.height().toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvasTmp = Canvas(bitmap)
            iconDrawable.setBounds(0, 0, w, h)
            iconDrawable.draw(canvasTmp)
            val bmpPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                alpha = alphaVal
            }
            canvas.drawBitmap(bitmap, rect.left, rect.top, bmpPaint)
        } catch (e: Exception) {
            drawGridIcon(canvas, rect, alphaVal)
        }
    }

    private fun drawGridIcon(canvas: Canvas, rect: RectF, alphaVal: Int) {
        val w = rect.width()
        val size = w * 0.35f
        val gap = w * 0.1f
        val cx = rect.centerX()
        val cy = rect.centerY()
        iconPaint.alpha = alphaVal
        canvas.drawRoundRect(RectF(cx - size - gap/2, cy - size - gap/2, cx - gap/2, cy - gap/2), 1f*density, 1f*density, iconPaint)
        canvas.drawRoundRect(RectF(cx + gap/2, cy - size - gap/2, cx + size + gap/2, cy - gap/2), 1f*density, 1f*density, iconPaint)
        canvas.drawRoundRect(RectF(cx - size - gap/2, cy + gap/2, cx - gap/2, cy + size + gap/2), 1f*density, 1f*density, iconPaint)
        canvas.drawRoundRect(RectF(cx + gap/2, cy + gap/2, cx + size + gap/2, cy + size + gap/2), 1f*density, 1f*density, iconPaint)
    }

    override fun onTouchEvent(event: android.view.MotionEvent): Boolean {
        if (columnCount <= 0 || currentAction !is KeyAction.AppsColumn) return super.onTouchEvent(event)
        
        if (event.action == android.view.MotionEvent.ACTION_UP) {
            val tx = event.x
            val ty = event.y
            
            val onRight = currentEdge != Edge.LEFT
            fun rightEdgeFor(w: Float) = if (onRight) width - edgeMargin else edgeMargin + w
            val panelRight = rightEdgeFor(panelW)
            val panelCenterX = panelRight - panelW / 2f
            
            val keyY = height * anchorFraction
            val metrics = getAppColumnMetrics()
            val actualPanelH = metrics.actualPanelH
            val panelTop = keyY - actualPanelH * Spec.PANEL_TOP_RATIO
            
            val dot = metrics.dot
            val gap = metrics.gap
            val padding = metrics.padding
            var cy = panelTop + padding + dot / 2f
            
            for (i in 0 until columnCount) {
                val dx = tx - panelCenterX
                val dy = ty - cy
                if (dx * dx + dy * dy <= (dot / 2f) * (dot / 2f)) {
                    val packageNames = (currentAction as? KeyAction.AppsColumn)?.packageNames
                    if (packageNames != null && i < packageNames.size) {
                        try {
                            val intent = context.packageManager.getLaunchIntentForPackage(packageNames[i])
                            if (intent != null) {
                                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                                onAppLaunchedListener?.invoke()
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    return true
                }
                cy += dot + gap
            }
        }
        return true
    }
}
