package com.petya.arportal

import android.opengl.Matrix

/**
 * Blocky hero built from boxes. Units are metres: the hero is about 9 cm tall,
 * so he fits on a desk next to a book or a mug.
 */
class CharacterModel(private val box: Mesh) {

    private val orange = floatArrayOf(0.93f, 0.46f, 0.20f, 1f)
    private val pants = floatArrayOf(0.20f, 0.25f, 0.38f, 1f)
    private val skin = floatArrayOf(0.95f, 0.80f, 0.64f, 1f)
    private val cap = floatArrayOf(0.17f, 0.59f, 0.43f, 1f)
    private val capDark = floatArrayOf(0.12f, 0.44f, 0.32f, 1f)
    private val pack = floatArrayOf(0.67f, 0.70f, 0.75f, 1f)
    private val yellow = floatArrayOf(1.00f, 0.84f, 0.27f, 1f)
    private val shoes = floatArrayOf(0.15f, 0.15f, 0.18f, 1f)
    private val dark = floatArrayOf(0.09f, 0.08f, 0.11f, 1f)
    private val hair = floatArrayOf(0.36f, 0.23f, 0.14f, 1f)
    private val flameOuter = floatArrayOf(1.00f, 0.55f, 0.15f, 1f)
    private val flameInner = floatArrayOf(1.00f, 0.95f, 0.70f, 1f)

    private val m = FloatArray(16)
    private val mvp = FloatArray(16)

    class Pose(
        var legL: Float = 0f, var legR: Float = 0f,
        var armL: Float = 0f, var armR: Float = 0f,
        var flame: Float = 0f
    )

    private fun part(
        sh: MeshShader, vp: FloatArray, base: FloatArray,
        px: Float, py: Float, pz: Float, angle: Float,
        ox: Float, oy: Float, oz: Float,
        sx: Float, sy: Float, sz: Float,
        color: FloatArray, unlit: Boolean = false
    ) {
        System.arraycopy(base, 0, m, 0, 16)
        Matrix.translateM(m, 0, px, py, pz)
        if (angle != 0f) Matrix.rotateM(m, 0, angle, 1f, 0f, 0f)
        Matrix.translateM(m, 0, ox, oy, oz)
        Matrix.scaleM(m, 0, sx, sy, sz)
        Matrix.multiplyMM(mvp, 0, vp, 0, m, 0)
        sh.set(mvp, m, color, unlit)
        box.draw(sh)
    }

    fun draw(sh: MeshShader, vp: FloatArray, base: FloatArray, p: Pose) {
        // jetpack
        part(sh, vp, base, 0f, 0.046f, -0.0165f, 0f, 0f, 0f, 0f, 0.022f, 0.026f, 0.011f, pack)
        part(sh, vp, base, 0f, 0.047f, -0.0225f, 0f, 0f, 0f, 0f, 0.006f, 0.019f, 0.002f, yellow)
        if (p.flame > 0.01f) {
            part(sh, vp, base, 0f, 0.033f, -0.0165f, 0f, 0f, -0.009f * p.flame, 0f,
                0.012f, 0.018f * p.flame, 0.008f, flameOuter, unlit = true)
            part(sh, vp, base, 0f, 0.033f, -0.0165f, 0f, 0f, -0.006f * p.flame, 0f,
                0.006f, 0.011f * p.flame, 0.0085f, flameInner, unlit = true)
        }
        // legs + shoes
        for ((side, a) in arrayOf(-1f to p.legL, 1f to p.legR)) {
            val x = 0.0085f * side
            part(sh, vp, base, x, 0.029f, 0f, a, 0f, -0.0125f, 0f, 0.012f, 0.025f, 0.012f, pants)
            part(sh, vp, base, x, 0.029f, 0f, a, 0f, -0.0255f, 0.003f, 0.014f, 0.007f, 0.019f, shoes)
        }
        // torso
        part(sh, vp, base, 0f, 0.045f, 0f, 0f, 0f, 0f, 0f, 0.032f, 0.032f, 0.021f, orange)
        part(sh, vp, base, 0f, 0.032f, 0f, 0f, 0f, 0f, 0f, 0.033f, 0.004f, 0.022f, yellow)
        part(sh, vp, base, 0.006f, 0.051f, 0.0108f, 0f, 0f, 0f, 0f, 0.008f, 0.008f, 0.002f, yellow)
        // head
        part(sh, vp, base, 0f, 0.0745f, 0f, 0f, 0f, 0f, 0f, 0.034f, 0.032f, 0.032f, skin)
        part(sh, vp, base, 0f, 0.076f, -0.0165f, 0f, 0f, 0f, 0f, 0.034f, 0.024f, 0.004f, hair)
        part(sh, vp, base, 0f, 0.0915f, 0f, 0f, 0f, 0f, 0f, 0.0365f, 0.008f, 0.0355f, cap)
        part(sh, vp, base, 0f, 0.0885f, 0.022f, 0f, 0f, 0f, 0f, 0.030f, 0.003f, 0.014f, capDark)
        for (side in floatArrayOf(-1f, 1f)) {
            part(sh, vp, base, 0.007f * side, 0.0765f, 0.0162f, 0f, 0f, 0f, 0f, 0.0048f, 0.0075f, 0.002f, dark)
        }
        part(sh, vp, base, 0f, 0.0668f, 0.0162f, 0f, 0f, 0f, 0f, 0.008f, 0.0018f, 0.002f, dark)
        // arms + hands
        for ((side, a) in arrayOf(-1f to p.armL, 1f to p.armR)) {
            val x = 0.0215f * side
            part(sh, vp, base, x, 0.059f, 0f, a, 0f, -0.0125f, 0f, 0.010f, 0.026f, 0.010f, orange)
            part(sh, vp, base, x, 0.059f, 0f, a, 0f, -0.0285f, 0f, 0.0105f, 0.008f, 0.0105f, skin)
        }
    }
}
