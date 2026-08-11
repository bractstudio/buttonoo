package dev.buttonooo.essential_key.overlay

import android.content.Context
import android.graphics.*
import android.text.TextPaint
import android.text.TextUtils
import android.util.AttributeSet
import android.view.View
import dev.buttonooo.essential_key.actions.ActionState
import dev.buttonooo.essential_key.actions.KeyAction

class StockPillView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val density = resources.displayMetrics.density

    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#1C1D22")
        style = Paint.Style.FILL
    }
    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#34363F")
        style = Paint.Style.STROKE
        strokeWidth = 1.5f * density
    }
    private val badgePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.BLACK
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
        strokeWidth = 2.2f * density
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 13.5f * density
        typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
    }

    private val rectF = RectF()
    private var label: String = ""
    private var accentColor: Int = Color.parseColor("#FFD400")
    private var currentAction: KeyAction = KeyAction.None

    init {
        setLayerType(LAYER_TYPE_SOFTWARE, null)
    }

    fun configure(action: KeyAction, state: ActionState, accentHex: String) {
        try {
            accentColor = Color.parseColor(accentHex)
        } catch (e: Exception) {
            accentColor = Color.parseColor("#FFD400")
        }
        badgePaint.color = accentColor
        currentAction = action
        label = state.label.ifEmpty { "Triggered" }

        // Animate pop-in
        alpha = 0f
        scaleX = 0.85f
        scaleY = 0.85f
        animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(180)
            .setInterpolator(android.view.animation.OvershootInterpolator(1.1f))
            .start()

        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = (155 * density).toInt()
        val h = (52 * density).toInt()
        setMeasuredDimension(w, h)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val pad = 4f * density
        rectF.set(pad, pad, width - pad, height - pad)
        val radius = rectF.height() / 2f

        canvas.drawRoundRect(rectF, radius, radius, bgPaint)
        canvas.drawRoundRect(rectF, radius, radius, borderPaint)

        val badgeSize = 34f * density
        val badgeLeft = rectF.left + 8f * density
        val badgeCenterY = rectF.centerY()
        canvas.drawCircle(badgeLeft + badgeSize / 2f, badgeCenterY, badgeSize / 2f, badgePaint)

        // Draw Icon inside badge
        val iconRadius = badgeSize * 0.35f
        val cx = badgeLeft + badgeSize / 2f
        val cy = badgeCenterY
        canvas.drawCircle(cx, cy, iconRadius * 0.5f, iconPaint)

        val textLeft = badgeLeft + badgeSize + 12f * density
        val fontMetrics = textPaint.fontMetrics
        val textY = rectF.centerY() - (fontMetrics.ascent + fontMetrics.descent) / 2f

        val maxTextWidth = rectF.right - textLeft - (10f * density)
        val textToDraw = TextUtils.ellipsize(label, TextPaint(textPaint), maxTextWidth, TextUtils.TruncateAt.END).toString()
        canvas.drawText(textToDraw, textLeft, textY, textPaint)
    }
}
