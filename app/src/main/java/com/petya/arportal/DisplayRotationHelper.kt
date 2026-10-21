package com.petya.arportal

import android.content.Context
import android.hardware.display.DisplayManager
import android.view.Display
import android.view.WindowManager
import com.google.ar.core.Session

/** Keeps ARCore informed about screen rotation and size. */
class DisplayRotationHelper(context: Context) : DisplayManager.DisplayListener {
    private var viewportChanged = false
    private var width = 0
    private var height = 0

    @Suppress("DEPRECATION")
    private val display: Display =
        (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay
    private val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    fun onResume() = displayManager.registerDisplayListener(this, null)
    fun onPause() = displayManager.unregisterDisplayListener(this)

    fun onSurfaceChanged(w: Int, h: Int) {
        width = w
        height = h
        viewportChanged = true
    }

    fun updateSessionIfNeeded(session: Session) {
        if (viewportChanged) {
            session.setDisplayGeometry(display.rotation, width, height)
            viewportChanged = false
        }
    }

    override fun onDisplayAdded(displayId: Int) {}
    override fun onDisplayRemoved(displayId: Int) {}
    override fun onDisplayChanged(displayId: Int) {
        viewportChanged = true
    }
}
