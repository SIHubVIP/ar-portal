package com.petya.arportal

import android.opengl.GLES20
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.cos
import kotlin.math.sin

private const val TAG = "ARPortalGL"

object ShaderUtil {
    fun compile(type: Int, src: String): Int {
        val sh = GLES20.glCreateShader(type)
        GLES20.glShaderSource(sh, src)
        GLES20.glCompileShader(sh)
        val ok = IntArray(1)
        GLES20.glGetShaderiv(sh, GLES20.GL_COMPILE_STATUS, ok, 0)
        if (ok[0] == 0) {
            val log = GLES20.glGetShaderInfoLog(sh)
            GLES20.glDeleteShader(sh)
            throw RuntimeException("Shader compile error: $log")
        }
        return sh
    }

    fun program(vs: String, fs: String): Int {
        val p = GLES20.glCreateProgram()
        GLES20.glAttachShader(p, compile(GLES20.GL_VERTEX_SHADER, vs))
        GLES20.glAttachShader(p, compile(GLES20.GL_FRAGMENT_SHADER, fs))
        GLES20.glLinkProgram(p)
        val ok = IntArray(1)
        GLES20.glGetProgramiv(p, GLES20.GL_LINK_STATUS, ok, 0)
        if (ok[0] == 0) {
            val log = GLES20.glGetProgramInfoLog(p)
            throw RuntimeException("Program link error: $log")
        }
        return p
    }

    fun checkError(where: String) {
        val e = GLES20.glGetError()
        if (e != GLES20.GL_NO_ERROR) Log.w(TAG, "GL error 0x${Integer.toHexString(e)} at $where")
    }
}

fun floatBuffer(n: Int): FloatBuffer =
    ByteBuffer.allocateDirect(n * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()

fun floatBufferOf(vararg v: Float): FloatBuffer {
    val b = floatBuffer(v.size)
    b.put(v)
    b.position(0)
    return b
}

/** Simple lit, single-colour shader. Vertex layout: x y z nx ny nz. */
class MeshShader {
    private val vs = """
        uniform mat4 u_MVP;
        uniform mat4 u_Model;
        attribute vec3 a_Position;
        attribute vec3 a_Normal;
        varying vec3 v_Normal;
        void main() {
            v_Normal = (u_Model * vec4(a_Normal, 0.0)).xyz;
            gl_Position = u_MVP * vec4(a_Position, 1.0);
        }
    """.trimIndent()

    private val fs = """
        precision mediump float;
        uniform vec4 u_Color;
        uniform vec3 u_LightDir;
        uniform float u_Light;
        uniform float u_Unlit;
        varying vec3 v_Normal;
        void main() {
            vec3 n = normalize(v_Normal + vec3(0.0, 0.0001, 0.0));
            float d = max(dot(n, u_LightDir), 0.0);
            float l = mix(0.52 + 0.62 * d, 1.0, u_Unlit) * mix(u_Light, 1.0, u_Unlit * 0.6);
            gl_FragColor = vec4(u_Color.rgb * l, u_Color.a);
        }
    """.trimIndent()

    val program = ShaderUtil.program(vs, fs)
    val aPos = GLES20.glGetAttribLocation(program, "a_Position")
    val aNormal = GLES20.glGetAttribLocation(program, "a_Normal")
    private val uMvp = GLES20.glGetUniformLocation(program, "u_MVP")
    private val uModel = GLES20.glGetUniformLocation(program, "u_Model")
    private val uColor = GLES20.glGetUniformLocation(program, "u_Color")
    private val uLightDir = GLES20.glGetUniformLocation(program, "u_LightDir")
    private val uLight = GLES20.glGetUniformLocation(program, "u_Light")
    private val uUnlit = GLES20.glGetUniformLocation(program, "u_Unlit")

    fun begin(light: Float) {
        GLES20.glUseProgram(program)
        GLES20.glUniform3f(uLightDir, 0.35f, 0.85f, 0.39f)
        GLES20.glUniform1f(uLight, light)
    }

    fun set(mvp: FloatArray, model: FloatArray, color: FloatArray, unlit: Boolean) {
        GLES20.glUniformMatrix4fv(uMvp, 1, false, mvp, 0)
        GLES20.glUniformMatrix4fv(uModel, 1, false, model, 0)
        GLES20.glUniform4fv(uColor, 1, color, 0)
        GLES20.glUniform1f(uUnlit, if (unlit) 1f else 0f)
    }
}

class Mesh(data: FloatArray, private val mode: Int = GLES20.GL_TRIANGLES) {
    private val count = data.size / 6
    private val buf: FloatBuffer = floatBuffer(data.size).also { it.put(data); it.position(0) }

    fun draw(sh: MeshShader) {
        buf.position(0)
        GLES20.glVertexAttribPointer(sh.aPos, 3, GLES20.GL_FLOAT, false, 24, buf)
        GLES20.glEnableVertexAttribArray(sh.aPos)
        buf.position(3)
        GLES20.glVertexAttribPointer(sh.aNormal, 3, GLES20.GL_FLOAT, false, 24, buf)
        GLES20.glEnableVertexAttribArray(sh.aNormal)
        GLES20.glDrawArrays(mode, 0, count)
        GLES20.glDisableVertexAttribArray(sh.aPos)
        GLES20.glDisableVertexAttribArray(sh.aNormal)
        buf.position(0)
    }
}

/** Geometry builders. All meshes are unit-sized and scaled by the model matrix. */
object Geo {
    private fun MutableList<Float>.v(x: Float, y: Float, z: Float, nx: Float, ny: Float, nz: Float) {
        add(x); add(y); add(z); add(nx); add(ny); add(nz)
    }

    fun box(): FloatArray {
        val o = mutableListOf<Float>()
        // each face: normal, then 4 corners (counter-clockwise when looking at face)
        val faces = arrayOf(
            floatArrayOf(0f, 0f, 1f, -1f, -1f, 1f, 1f, -1f, 1f, 1f, 1f, 1f, -1f, 1f, 1f),
            floatArrayOf(0f, 0f, -1f, 1f, -1f, -1f, -1f, -1f, -1f, -1f, 1f, -1f, 1f, 1f, -1f),
            floatArrayOf(1f, 0f, 0f, 1f, -1f, 1f, 1f, -1f, -1f, 1f, 1f, -1f, 1f, 1f, 1f),
            floatArrayOf(-1f, 0f, 0f, -1f, -1f, -1f, -1f, -1f, 1f, -1f, 1f, 1f, -1f, 1f, -1f),
            floatArrayOf(0f, 1f, 0f, -1f, 1f, 1f, 1f, 1f, 1f, 1f, 1f, -1f, -1f, 1f, -1f),
            floatArrayOf(0f, -1f, 0f, -1f, -1f, -1f, 1f, -1f, -1f, 1f, -1f, 1f, -1f, -1f, 1f),
        )
        for (f in faces) {
            val nx = f[0]; val ny = f[1]; val nz = f[2]
            val c = Array(4) { i -> floatArrayOf(f[3 + i * 3] * 0.5f, f[4 + i * 3] * 0.5f, f[5 + i * 3] * 0.5f) }
            for (idx in intArrayOf(0, 1, 2, 0, 2, 3)) o.v(c[idx][0], c[idx][1], c[idx][2], nx, ny, nz)
        }
        return o.toFloatArray()
    }

    /** Flat disc of radius 0.5 in the XZ plane, normal up. */
    fun disc(seg: Int = 48): FloatArray {
        val o = mutableListOf<Float>()
        for (i in 0 until seg) {
            val a0 = (i * 2 * Math.PI / seg).toFloat()
            val a1 = ((i + 1) * 2 * Math.PI / seg).toFloat()
            o.v(0f, 0f, 0f, 0f, 1f, 0f)
            o.v(0.5f * cos(a0), 0f, 0.5f * sin(a0), 0f, 1f, 0f)
            o.v(0.5f * cos(a1), 0f, 0.5f * sin(a1), 0f, 1f, 0f)
        }
        return o.toFloatArray()
    }

    /** Annulus in XZ plane (outer radius 0.5). dashes > 0 leaves gaps. */
    fun ring(inner: Float, seg: Int = 64, dashes: Int = 0): FloatArray {
        val o = mutableListOf<Float>()
        val outer = 0.5f
        for (i in 0 until seg) {
            if (dashes > 0 && (i * dashes * 2 / seg) % 2 == 1) continue
            val a0 = (i * 2 * Math.PI / seg).toFloat()
            val a1 = ((i + 1) * 2 * Math.PI / seg).toFloat()
            val p = arrayOf(
                floatArrayOf(inner * cos(a0), inner * sin(a0)), floatArrayOf(outer * cos(a0), outer * sin(a0)),
                floatArrayOf(outer * cos(a1), outer * sin(a1)), floatArrayOf(inner * cos(a1), inner * sin(a1)),
            )
            for (idx in intArrayOf(0, 1, 2, 0, 2, 3)) o.v(p[idx][0], 0f, p[idx][1], 0f, 1f, 0f)
        }
        return o.toFloatArray()
    }

    /** Closed cylinder, radius 0.5, height 1 (y from -0.5 to 0.5). */
    fun cylinder(seg: Int = 32, caps: Boolean = true): FloatArray {
        val o = mutableListOf<Float>()
        for (i in 0 until seg) {
            val a0 = (i * 2 * Math.PI / seg).toFloat()
            val a1 = ((i + 1) * 2 * Math.PI / seg).toFloat()
            val x0 = 0.5f * cos(a0); val z0 = 0.5f * sin(a0)
            val x1 = 0.5f * cos(a1); val z1 = 0.5f * sin(a1)
            // side
            o.v(x0, -0.5f, z0, cos(a0), 0f, sin(a0)); o.v(x1, -0.5f, z1, cos(a1), 0f, sin(a1)); o.v(x1, 0.5f, z1, cos(a1), 0f, sin(a1))
            o.v(x0, -0.5f, z0, cos(a0), 0f, sin(a0)); o.v(x1, 0.5f, z1, cos(a1), 0f, sin(a1)); o.v(x0, 0.5f, z0, cos(a0), 0f, sin(a0))
            if (caps) {
                o.v(0f, 0.5f, 0f, 0f, 1f, 0f); o.v(x0, 0.5f, z0, 0f, 1f, 0f); o.v(x1, 0.5f, z1, 0f, 1f, 0f)
                o.v(0f, -0.5f, 0f, 0f, -1f, 0f); o.v(x1, -0.5f, z1, 0f, -1f, 0f); o.v(x0, -0.5f, z0, 0f, -1f, 0f)
            }
        }
        return o.toFloatArray()
    }
}
