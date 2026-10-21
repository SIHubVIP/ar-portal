package com.petya.arportal

import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.util.Log
import com.google.ar.core.Anchor
import com.google.ar.core.DepthPoint
import com.google.ar.core.Frame
import com.google.ar.core.HitResult
import com.google.ar.core.LightEstimate
import com.google.ar.core.Plane
import com.google.ar.core.Pose
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.random.Random

class GameRenderer(private val activity: MainActivity) : GLSurfaceView.Renderer {

    companion object {
        private const val TAG = "ARPortal"
        const val WALK_SPEED = 0.16f      // m/s
        const val JUMP_SPEED = 0.48f      // m/s  -> about 7 cm high
        const val GRAVITY = 1.7f          // m/s^2, softened for game feel
        const val STEP_UP = 0.012f        // tiny steps he can walk up without jumping
        const val ROLL_TIME = 0.45f
        const val MAX_COINS = 6
    }

    // GL objects
    private val background = BackgroundRenderer()
    private lateinit var shader: MeshShader
    private lateinit var box: Mesh
    private lateinit var disc: Mesh
    private lateinit var ringDashed: Mesh
    private lateinit var ringThin: Mesh
    private lateinit var cylinder: Mesh
    private lateinit var tube: Mesh
    private lateinit var hero: CharacterModel
    private val planeVerts = floatBuffer(6 * 3 * 512)

    private var textureSession: Session? = null
    private var viewW = 1
    private var viewH = 1

    private val proj = FloatArray(16)
    private val view = FloatArray(16)
    private val vp = FloatArray(16)
    private val identity = FloatArray(16).also { Matrix.setIdentityM(it, 0) }
    private val tmp = FloatArray(16)
    private val tmpMvp = FloatArray(16)
    private val base = FloatArray(16)

    private var lastNanos = 0L
    private var time = 0f

    // world state
    private var portal: Anchor? = null
    private var portalAge = 0f
    private var reticlePose: Pose? = null

    // hero state
    private var px = 0f; private var py = 0f; private var pz = 0f
    private var vy = 0f
    private var pushX = 0f; private var pushZ = 0f
    private var onGround = false
    private var groundY = 0f
    private var yaw = 0f
    private var walkPhase = 0f
    private var moveAmount = 0f
    private var rollT = -1f
    private var spawnT = 1f
    private val pose = CharacterModel.Pose()

    private class Coin(val anchor: Anchor, val phase: Float) {
        var collectT = -1f
    }
    private val coins = mutableListOf<Coin>()
    private var coinTimer = 0f
    private var collected = 0

    private var lastStatus = ""
    private var placeVisible = false

    // colours
    private val cWhite = floatArrayOf(1f, 1f, 1f, 0.9f)
    private val cPlane = floatArrayOf(1f, 1f, 1f, 0.13f)
    private val cShadow = floatArrayOf(0f, 0f, 0f, 0.38f)
    private val cGlow = floatArrayOf(0.62f, 0.45f, 1f, 0.33f)
    private val cBeam = floatArrayOf(0.75f, 0.68f, 1f, 0.13f)
    private val cP1 = floatArrayOf(0.20f, 0.13f, 0.48f, 1f)
    private val cP2 = floatArrayOf(0.40f, 0.30f, 0.86f, 1f)
    private val cP3 = floatArrayOf(0.88f, 0.84f, 1f, 1f)
    private val cSwirl = floatArrayOf(0.93f, 0.90f, 1f, 1f)
    private val cGold = floatArrayOf(1f, 0.78f, 0.18f, 1f)
    private val cGoldDark = floatArrayOf(0.85f, 0.55f, 0.08f, 1f)

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        try {
            background.createOnGlThread()
            shader = MeshShader()
            box = Mesh(Geo.box())
            disc = Mesh(Geo.disc())
            ringDashed = Mesh(Geo.ring(0.82f, 72, 12))
            ringThin = Mesh(Geo.ring(0.9f, 72))
            cylinder = Mesh(Geo.cylinder(28))
            tube = Mesh(Geo.cylinder(36, caps = false))
            hero = CharacterModel(box)
        } catch (e: Exception) {
            Log.e(TAG, "GL init failed", e)
            activity.showError("Ошибка графики: ${e.message}")
        }
        textureSession = null
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
        viewW = width
        viewH = height
        activity.rotationHelper.onSurfaceChanged(width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        val session = activity.session ?: return
        if (!::shader.isInitialized) return

        val now = System.nanoTime()
        val dt = if (lastNanos == 0L) 0f else min(0.05f, (now - lastNanos) / 1e9f)
        lastNanos = now
        time += dt

        try {
            activity.rotationHelper.updateSessionIfNeeded(session)
            if (textureSession !== session) {
                session.setCameraTextureName(background.textureId)
                textureSession = session
            }
            val frame = session.update()
            background.draw(frame)
            step(session, frame, dt)
        } catch (t: Throwable) {
            Log.e(TAG, "frame failed", t)
        }
    }

    // ------------------------------------------------------------------ main step
    private fun step(session: Session, frame: Frame, dt: Float) {
        val camera = frame.camera

        if (activity.resetRequested.getAndSet(false)) resetWorld()

        if (camera.trackingState != TrackingState.TRACKING) {
            status("Медленно поводи телефоном — игра изучает комнату")
            setPlaceVisible(false)
            return
        }

        camera.getProjectionMatrix(proj, 0, 0.03f, 30f)
        camera.getViewMatrix(view, 0)
        Matrix.multiplyMM(vp, 0, proj, 0, view, 0)

        val le = frame.lightEstimate
        val light = if (le.state == LightEstimate.State.VALID)
            (le.pixelIntensity * 2.1f).coerceIn(0.45f, 1.3f) else 1f

        val planes = session.getAllTrackables(Plane::class.java).filter {
            it.trackingState == TrackingState.TRACKING && it.subsumedBy == null &&
                it.type == Plane.Type.HORIZONTAL_UPWARD_FACING
        }

        val p = portal
        if (p != null && p.trackingState == TrackingState.STOPPED) resetWorld()

        if (portal == null) {
            updatePlacement(frame, planes)
        } else {
            setPlaceVisible(false)
            updateHero(frame, camera.displayOrientedPose, dt)
            updateCoins(planes, dt)
            status(
                if (collected == 0) "Собирай звёзды! Запрыгивай на книги и коробки"
                else "Звёзд собрано: $collected — ищи следующую!"
            )
        }

        // ---------- draw opaque
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
        GLES20.glDisable(GLES20.GL_BLEND)
        shader.begin(light)
        portal?.let { drawPortalOpaque(it) }
        drawCoins()
        if (portal != null) drawHero()

        // ---------- draw translucent
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        GLES20.glDepthMask(false)
        drawPlanes(planes, if (portal == null) 0.13f else 0.05f)
        if (portal != null) drawShadow()
        portal?.let { drawPortalGlow(it) }
        if (portal == null) reticlePose?.let { drawReticle(it) }
        GLES20.glDepthMask(true)
        GLES20.glDisable(GLES20.GL_BLEND)
    }

    // ------------------------------------------------------------------ placement
    private fun updatePlacement(frame: Frame, planes: List<Plane>) {
        var hitFound: HitResult? = null
        for (hit in frame.hitTest(viewW / 2f, viewH / 2f)) {
            val t = hit.trackable
            if (t is Plane && t.type == Plane.Type.HORIZONTAL_UPWARD_FACING && t.isPoseInPolygon(hit.hitPose)) {
                hitFound = hit
                break
            }
        }
        reticlePose = hitFound?.hitPose
        setPlaceVisible(hitFound != null)
        status(
            when {
                hitFound != null -> "Поверхность найдена! Нажми «Открыть портал»"
                planes.isEmpty() -> "Наведи камеру на стол и плавно подвигай телефон"
                else -> "Наведи центр экрана на стол"
            }
        )
        if (activity.placeRequested.getAndSet(false) && hitFound != null) {
            val a = hitFound.createAnchor()
            portal = a
            portalAge = 0f
            spawnHero(a.pose, frame.camera.displayOrientedPose)
        }
    }

    private fun spawnHero(at: Pose, cam: Pose) {
        px = at.tx(); py = at.ty(); pz = at.tz()
        groundY = py
        vy = 0.62f
        onGround = false
        spawnT = 0f
        rollT = -1f
        // hop out of the portal towards the camera
        val dx = cam.tx() - px
        val dz = cam.tz() - pz
        val d = max(0.001f, hypot(dx, dz))
        pushX = dx / d * 0.12f
        pushZ = dz / d * 0.12f
        yaw = Math.toDegrees(atan2(dx, dz).toDouble()).toFloat()
    }

    private fun resetWorld() {
        portal?.detach()
        portal = null
        for (c in coins) c.anchor.detach()
        coins.clear()
        collected = 0
        activity.setCoins(0)
    }

    // ------------------------------------------------------------------ hero physics
    /** Height of the highest real surface right under (x, z), looking down from fromY. */
    private fun groundAt(frame: Frame, x: Float, z: Float, fromY: Float): Float? {
        val origin = floatArrayOf(x, fromY, z)
        val dir = floatArrayOf(0f, -1f, 0f)
        val hits = try { frame.hitTest(origin, 0, dir, 0) } catch (e: Exception) { return null }
        for (hit in hits) {
            when (val t = hit.trackable) {
                is Plane -> if (t.type == Plane.Type.HORIZONTAL_UPWARD_FACING &&
                    t.subsumedBy == null && t.isPoseInPolygon(hit.hitPose)
                ) return hit.hitPose.ty()
                is DepthPoint -> return hit.hitPose.ty()
                else -> {}
            }
        }
        return null
    }

    private fun updateHero(frame: Frame, cam: Pose, dt: Float) {
        portalAge += dt
        spawnT = min(1f, spawnT + dt * 2.4f)

        // camera-relative joystick direction on the floor plane
        val jx = activity.joystick.stickX
        val jy = activity.joystick.stickY
        val z = cam.zAxis
        val xA = cam.xAxis
        var fx = -z[0]; var fz = -z[2]
        val fl = max(0.0001f, hypot(fx, fz)); fx /= fl; fz /= fl
        var rx = xA[0]; var rz = xA[2]
        val rl = max(0.0001f, hypot(rx, rz)); rx /= rl; rz /= rl
        var mx = rx * jx - fx * jy
        var mz = rz * jx - fz * jy
        val mag = min(1f, hypot(mx, mz))
        moveAmount = if (mag > 0.15f) mag else 0f
        if (moveAmount > 0f) {
            val l = hypot(mx, mz)
            mx /= l; mz /= l
            yaw = Math.toDegrees(atan2(mx, mz).toDouble()).toFloat()
        } else {
            mx = 0f; mz = 0f
        }

        if (activity.jumpRequested.getAndSet(false) && onGround) {
            vy = JUMP_SPEED
            onGround = false
        }
        if (activity.rollRequested.getAndSet(false) && rollT < 0f) rollT = 0f

        var speed = WALK_SPEED * moveAmount
        var dirX = mx; var dirZ = mz
        if (rollT >= 0f) {
            rollT += dt
            val yr = Math.toRadians(yaw.toDouble())
            dirX = sin(yr).toFloat(); dirZ = kotlin.math.cos(yr).toFloat()
            speed = 0.26f
            if (rollT > ROLL_TIME) rollT = -1f
        }

        // horizontal move with "wall" check against the real surfaces
        val nx = px + dirX * speed * dt + pushX * dt
        val nz = pz + dirZ * speed * dt + pushZ * dt
        pushX *= 0.92f; pushZ *= 0.92f
        if (nx != px || nz != pz) {
            val g = groundAt(frame, nx, nz, py + 0.12f)
            val blocked = when {
                g == null -> true                                  // nothing known there
                g > py + STEP_UP && (onGround || py < g - 0.004f) -> true  // too high: jump!
                else -> false
            }
            if (!blocked) { px = nx; pz = nz }
        }

        // vertical
        val gHere = groundAt(frame, px, pz, py + 0.12f)
        if (gHere != null) groundY = gHere
        if (onGround) {
            if (gHere != null) {
                if (gHere < py - 0.01f) onGround = false else py = gHere
            }
        }
        if (!onGround) {
            vy -= GRAVITY * dt
            py += vy * dt
            if (gHere != null && vy <= 0f && py <= gHere) {
                py = gHere
                vy = 0f
                onGround = true
            }
        }
        // fell off the world -> back to the portal
        portal?.let {
            if (py < it.pose.ty() - 1.5f) spawnHero(it.pose, cam)
        }

        // animation
        if (moveAmount > 0f && onGround) walkPhase += dt * 15f * moveAmount
        val swing = if (onGround) sin(walkPhase) * 38f * moveAmount else 0f
        if (onGround) {
            val idle = sin(time * 2.2f) * 4f
            pose.legL = swing; pose.legR = -swing
            pose.armL = -swing * 1.1f + idle; pose.armR = swing * 1.1f - idle
            pose.flame = 0f
        } else {
            pose.legL = -30f; pose.legR = 18f
            pose.armL = -150f; pose.armR = -150f
            pose.flame = if (vy > 0f) 0.7f + 0.3f * sin(time * 40f) else 0.3f
        }
    }

    // ------------------------------------------------------------------ coins
    private fun updateCoins(planes: List<Plane>, dt: Float) {
        coinTimer += dt
        if (coinTimer > 2.5f && coins.count { it.collectT < 0f } < MAX_COINS && planes.isNotEmpty()) {
            coinTimer = 0f
            trySpawnCoin(planes)
        }
        val it = coins.iterator()
        while (it.hasNext()) {
            val c = it.next()
            if (c.anchor.trackingState == TrackingState.STOPPED) { it.remove(); continue }
            if (c.collectT >= 0f) {
                c.collectT += dt
                if (c.collectT > 0.35f) { c.anchor.detach(); it.remove() }
                continue
            }
            val cp = c.anchor.pose
            val d = hypot(cp.tx() - px, cp.tz() - pz)
            val cy = cp.ty() + 0.022f
            if (d < 0.035f && cy > py - 0.02f && cy < py + 0.1f) {
                c.collectT = 0f
                collected++
                activity.setCoins(collected)
            }
        }
    }

    private fun trySpawnCoin(planes: List<Plane>) {
        repeat(25) {
            val plane = planes[Random.nextInt(planes.size)]
            val lx = (Random.nextFloat() - 0.5f) * plane.extentX
            val lz = (Random.nextFloat() - 0.5f) * plane.extentZ
            val pose = plane.centerPose.compose(Pose.makeTranslation(lx, 0f, lz))
            if (!plane.isPoseInPolygon(pose)) return@repeat
            if (hypot(pose.tx() - px, pose.tz() - pz) < 0.1f) return@repeat
            if (coins.any { c -> hypot(c.anchor.pose.tx() - pose.tx(), c.anchor.pose.tz() - pose.tz()) < 0.06f }) return@repeat
            coins.add(Coin(plane.createAnchor(pose), Random.nextFloat() * 6f))
            return
        }
    }

    // ------------------------------------------------------------------ drawing
    private fun draw(mesh: Mesh, model: FloatArray, color: FloatArray, unlit: Boolean = false) {
        Matrix.multiplyMM(tmpMvp, 0, vp, 0, model, 0)
        shader.set(tmpMvp, model, color, unlit)
        mesh.draw(shader)
    }

    private fun anchorMatrix(pose: Pose, yOff: Float, sx: Float, sy: Float, sz: Float, rotY: Float = 0f): FloatArray {
        pose.toMatrix(tmp, 0)
        Matrix.translateM(tmp, 0, 0f, yOff, 0f)
        if (rotY != 0f) Matrix.rotateM(tmp, 0, rotY, 0f, 1f, 0f)
        Matrix.scaleM(tmp, 0, sx, sy, sz)
        return tmp
    }

    private fun portalOpen(): Float {
        val t = min(1f, portalAge / 0.6f)
        return t * t * (3 - 2 * t)
    }

    private fun drawPortalOpaque(a: Anchor) {
        if (a.trackingState != TrackingState.TRACKING) return
        val o = max(0.01f, portalOpen())
        val pose = a.pose
        draw(disc, anchorMatrix(pose, 0.002f, 0.15f * o, 1f, 0.15f * o), cP1)
        draw(disc, anchorMatrix(pose, 0.003f, 0.118f * o, 1f, 0.118f * o), cP2, unlit = true)
        draw(disc, anchorMatrix(pose, 0.004f, 0.065f * o, 1f, 0.065f * o), cP3, unlit = true)
        draw(ringDashed, anchorMatrix(pose, 0.005f, 0.1f * o, 1f, 0.1f * o, rotY = time * 90f), cSwirl, unlit = true)
        draw(ringThin, anchorMatrix(pose, 0.0025f, 0.152f * o, 1f, 0.152f * o), cP3, unlit = true)
    }

    private fun drawPortalGlow(a: Anchor) {
        if (a.trackingState != TrackingState.TRACKING) return
        val o = max(0.01f, portalOpen())
        val pose = a.pose
        draw(disc, anchorMatrix(pose, 0.0012f, 0.22f * o, 1f, 0.22f * o), cGlow, unlit = true)
        val beamH = 0.11f * o
        cBeam[3] = 0.10f + 0.04f * sin(time * 3f)
        draw(tube, anchorMatrix(pose, beamH / 2f, 0.1f * o, beamH, 0.1f * o, rotY = time * 30f), cBeam, unlit = true)
    }

    private fun drawReticle(pose: Pose) {
        draw(ringDashed, anchorMatrix(pose, 0.001f, 0.15f, 1f, 0.15f, rotY = time * 60f), cWhite, unlit = true)
        draw(disc, anchorMatrix(pose, 0.001f, 0.012f, 1f, 0.012f), cWhite, unlit = true)
    }

    private fun drawCoins() {
        for (c in coins) {
            if (c.anchor.trackingState != TrackingState.TRACKING) continue
            val pose = c.anchor.pose
            var s = 1f
            var lift = 0f
            if (c.collectT >= 0f) {
                s = 1f + c.collectT * 3f
                lift = c.collectT * 0.12f
            }
            val bob = 0.004f * sin(time * 3f + c.phase)
            pose.toMatrix(tmp, 0)
            Matrix.translateM(tmp, 0, 0f, 0.022f + bob + lift, 0f)
            Matrix.rotateM(tmp, 0, time * 140f + c.phase * 40f, 0f, 1f, 0f)
            Matrix.rotateM(tmp, 0, 90f, 1f, 0f, 0f)
            System.arraycopy(tmp, 0, base, 0, 16)
            Matrix.scaleM(tmp, 0, 0.024f * s, 0.004f * s, 0.024f * s)
            draw(cylinder, tmp, cGold)
            System.arraycopy(base, 0, tmp, 0, 16)
            Matrix.scaleM(tmp, 0, 0.013f * s, 0.0046f * s, 0.013f * s)
            draw(cylinder, tmp, cGoldDark)
        }
    }

    private fun heroBase(): FloatArray {
        Matrix.setIdentityM(base, 0)
        Matrix.translateM(base, 0, px, py, pz)
        Matrix.rotateM(base, 0, yaw, 0f, 1f, 0f)
        if (rollT >= 0f) {
            val a = -360f * min(1f, rollT / ROLL_TIME)
            Matrix.translateM(base, 0, 0f, 0.045f, 0f)
            Matrix.rotateM(base, 0, a, 1f, 0f, 0f)
            Matrix.translateM(base, 0, 0f, -0.045f, 0f)
        }
        val s = 0.3f + 0.7f * spawnT
        Matrix.scaleM(base, 0, s, s, s)
        return base
    }

    private fun drawHero() {
        hero.draw(shader, vp, heroBase(), pose)
    }

    private fun drawShadow() {
        val h = max(0f, py - groundY)
        val k = max(0.25f, 1f - h / 0.15f)
        Matrix.setIdentityM(tmp, 0)
        Matrix.translateM(tmp, 0, px, groundY + 0.0015f, pz)
        Matrix.scaleM(tmp, 0, 0.042f * k, 1f, 0.034f * k)
        cShadow[3] = 0.38f * k
        draw(disc, tmp, cShadow, unlit = true)
    }

    private fun drawPlanes(planes: List<Plane>, alpha: Float) {
        cPlane[3] = alpha
        for (plane in planes) {
            val poly = plane.polygon ?: continue
            val n = poly.limit() / 2
            if (n < 3) continue
            val center = plane.centerPose
            planeVerts.clear()
            val c = floatArrayOf(center.tx(), center.ty(), center.tz())
            var count = 0
            for (i in 0 until n) {
                if (count + 3 > 512 * 3) break
                val j = (i + 1) % n
                val a = center.transformPoint(floatArrayOf(poly.get(i * 2), 0f, poly.get(i * 2 + 1)))
                val b = center.transformPoint(floatArrayOf(poly.get(j * 2), 0f, poly.get(j * 2 + 1)))
                for (v in arrayOf(c, a, b)) {
                    planeVerts.put(v[0]); planeVerts.put(v[1] + 0.0005f); planeVerts.put(v[2])
                    planeVerts.put(0f); planeVerts.put(1f); planeVerts.put(0f)
                }
                count += 3
            }
            shader.set(vpCopy(), identity, cPlane, true)
            planeVerts.position(0)
            GLES20.glVertexAttribPointer(shader.aPos, 3, GLES20.GL_FLOAT, false, 24, planeVerts)
            GLES20.glEnableVertexAttribArray(shader.aPos)
            planeVerts.position(3)
            GLES20.glVertexAttribPointer(shader.aNormal, 3, GLES20.GL_FLOAT, false, 24, planeVerts)
            GLES20.glEnableVertexAttribArray(shader.aNormal)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, count)
            GLES20.glDisableVertexAttribArray(shader.aPos)
            GLES20.glDisableVertexAttribArray(shader.aNormal)
        }
    }

    private fun vpCopy(): FloatArray = vp

    // ------------------------------------------------------------------ UI bridge
    private fun status(s: String) {
        if (s != lastStatus) {
            lastStatus = s
            activity.setStatus(s)
        }
    }

    private fun setPlaceVisible(v: Boolean) {
        if (v != placeVisible) {
            placeVisible = v
            activity.setPlaceVisible(v)
        }
    }
}
