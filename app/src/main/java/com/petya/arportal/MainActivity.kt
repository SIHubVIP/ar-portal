package com.petya.arportal

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.UnavailableApkTooOldException
import com.google.ar.core.exceptions.UnavailableArcoreNotInstalledException
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableSdkTooOldException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "ARPortal"
        private const val CAMERA_REQ = 7
    }

    @Volatile
    var session: Session? = null
        private set

    lateinit var rotationHelper: DisplayRotationHelper
        private set
    lateinit var joystick: JoystickView
        private set

    val jumpRequested = AtomicBoolean(false)
    val rollRequested = AtomicBoolean(false)
    val placeRequested = AtomicBoolean(false)
    val resetRequested = AtomicBoolean(false)

    private lateinit var surface: GLSurfaceView
    private lateinit var statusView: TextView
    private lateinit var coinsView: TextView
    private lateinit var placeBtn: View
    private lateinit var renderer: GameRenderer
    private var installRequested = false

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        hideSystemBars()

        surface = findViewById(R.id.surface)
        statusView = findViewById(R.id.status)
        coinsView = findViewById(R.id.coins)
        placeBtn = findViewById(R.id.btnPlace)
        joystick = findViewById(R.id.joystick)
        rotationHelper = DisplayRotationHelper(this)
        renderer = GameRenderer(this)

        surface.preserveEGLContextOnPause = true
        surface.setEGLContextClientVersion(2)
        surface.setEGLConfigChooser(8, 8, 8, 8, 16, 0)
        surface.setRenderer(renderer)
        surface.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        surface.setWillNotDraw(false)

        val press = { flag: AtomicBoolean ->
            View.OnTouchListener { v, e ->
                when (e.actionMasked) {
                    MotionEvent.ACTION_DOWN -> { flag.set(true); v.isPressed = true }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> { v.isPressed = false }
                }
                true
            }
        }
        findViewById<View>(R.id.btnJump).setOnTouchListener(press(jumpRequested))
        findViewById<View>(R.id.btnRoll).setOnTouchListener(press(rollRequested))
        placeBtn.setOnClickListener { placeRequested.set(true) }
        findViewById<View>(R.id.btnReset).setOnClickListener { resetRequested.set(true) }

        setStatus("Запускаю камеру…")
    }

    override fun onResume() {
        super.onResume()
        if (session == null) {
            try {
                val install = ArCoreApk.getInstance().requestInstall(this, !installRequested)
                if (install == ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                    installRequested = true
                    return
                }
                if (!hasCameraPermission()) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_REQ)
                    return
                }
                val s = Session(this)
                configure(s)
                session = s
            } catch (e: UnavailableDeviceNotCompatibleException) {
                showError("Этот телефон не поддерживает ARCore, AR-режим недоступен")
                return
            } catch (e: UnavailableUserDeclinedInstallationException) {
                showError("Для игры нужно установить «Сервисы Google Play для AR»")
                return
            } catch (e: UnavailableArcoreNotInstalledException) {
                showError("Установи «Сервисы Google Play для AR» из Google Play")
                return
            } catch (e: UnavailableApkTooOldException) {
                showError("Обнови «Сервисы Google Play для AR» в Google Play")
                return
            } catch (e: UnavailableSdkTooOldException) {
                showError("Нужна новая версия игры")
                return
            } catch (e: Exception) {
                Log.e(TAG, "AR session failed", e)
                showError("Не удалось запустить AR: ${e.message}")
                return
            }
        }
        try {
            session?.resume()
        } catch (e: CameraNotAvailableException) {
            showError("Камера занята другим приложением. Закрой его и перезапусти игру")
            session = null
            return
        }
        surface.onResume()
        rotationHelper.onResume()
    }

    override fun onPause() {
        super.onPause()
        if (session != null) {
            rotationHelper.onPause()
            surface.onPause()
            session?.pause()
        }
    }

    override fun onDestroy() {
        session?.close()
        session = null
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_REQ && !hasCameraPermission()) {
            Toast.makeText(this, "Без камеры AR-игра не работает", Toast.LENGTH_LONG).show()
            showError("Разреши доступ к камере в настройках приложения")
        }
    }

    private fun configure(s: Session) {
        val cfg = Config(s)
        cfg.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
        cfg.lightEstimationMode = Config.LightEstimationMode.AMBIENT_INTENSITY
        cfg.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
        cfg.focusMode = Config.FocusMode.AUTO
        cfg.depthMode = if (s.isDepthModeSupported(Config.DepthMode.AUTOMATIC))
            Config.DepthMode.AUTOMATIC else Config.DepthMode.DISABLED
        s.configure(cfg)
    }

    private fun hasCameraPermission() =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

    private fun hideSystemBars() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val c = WindowInsetsControllerCompat(window, window.decorView)
        c.hide(WindowInsetsCompat.Type.systemBars())
        c.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }

    // ---- called from the GL thread
    fun setStatus(text: String) = runOnUiThread { statusView.text = text }
    fun setCoins(n: Int) = runOnUiThread { coinsView.text = "★ $n" }
    fun setPlaceVisible(v: Boolean) = runOnUiThread { placeBtn.visibility = if (v) View.VISIBLE else View.GONE }
    fun showError(text: String) = runOnUiThread { statusView.text = text }
}
