package com.petya.arportal

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.hypot
import kotlin.math.min

/** On-screen joystick. stickX/stickY are in [-1, 1]; stickY is negative when pushed up. */
class JoystickView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : View(context, attrs) {

    @Volatile var stickX = 0f
        private set
    @Volatile var stickY = 0f
        private set

    private var knobX = 0f
    private var knobY = 0f
    private var pointerId = -1

    private val base = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(70, 10, 10, 16) }
    private val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = 4f; color = Color.argb(170, 255, 255, 255)
    }
    private val inner = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = 2f; color = Color.argb(70, 255, 255, 255)
    }
    private val knob = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(200, 255, 255, 255) }

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f
        val cy = height / 2f
        val r = min(width, height) / 2f - 4f
        canvas.drawCircle(cx, cy, r, base)
        canvas.drawCircle(cx, cy, r, ring)
        canvas.drawCircle(cx, cy, r * 0.6f, inner)
        canvas.drawCircle(cx + knobX, cy + knobY, r * 0.42f, knob)
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        val cx = width / 2f
        val cy = height / 2f
        val maxR = min(width, height) / 2f * 0.55f
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                if (pointerId == -1) {
                    pointerId = e.getPointerId(e.actionIndex)
                    move(e.getX(e.actionIndex) - cx, e.getY(e.actionIndex) - cy, maxR)
                }
            }
            MotionEvent.ACTION_MOVE -> {
                val idx = e.findPointerIndex(pointerId)
                if (idx >= 0) move(e.getX(idx) - cx, e.getY(idx) - cy, maxR)
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_CANCEL -> {
                if (e.actionMasked == MotionEvent.ACTION_POINTER_UP &&
                    e.getPointerId(e.actionIndex) != pointerId
                ) return true
                pointerId = -1
                knobX = 0f; knobY = 0f; stickX = 0f; stickY = 0f
                invalidate()
            }
        }
        return true
    }

    private fun move(dx: Float, dy: Float, maxR: Float) {
        val d = hypot(dx, dy)
        val k = if (d > maxR) maxR / d else 1f
        knobX = dx * k
        knobY = dy * k
        stickX = knobX / maxR
        stickY = knobY / maxR
        invalidate()
    }
}
