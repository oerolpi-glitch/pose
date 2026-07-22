package com.oerol.pose.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.oerol.posekit.ReferencePose

/**
 * Loads the bundled reference poses and their model photographs from assets.
 * The asset tree is the iOS bundle verbatim (App/Resources/Poses is wired in
 * as the assets source dir): pose JSONs at the root, photos in Photos/<id>.jpg.
 */
class PoseRepository(private val context: Context) {

    private val poses: List<ReferencePose> by lazy {
        val names = context.assets.list("")?.filter { it.endsWith(".json") }.orEmpty()
        names.mapNotNull { name ->
            runCatching {
                context.assets.open(name).bufferedReader().use { it.readText() }
                    .let(ReferencePose::fromJson)
            }.getOrNull()
        }.sortedBy { it.title }
    }

    private val photoCache = mutableMapOf<String, Bitmap?>()

    fun allPoses(): List<ReferencePose> = poses

    fun pose(id: String): ReferencePose? = poses.firstOrNull { it.id == id }

    /** Priority tags first, then the rest alphabetically — mirrors iOS. */
    fun allTags(): List<String> {
        val priority = listOf("mirror", "close-up", "selfie")
        val rest = poses.flatMap { it.tags }.distinct().filterNot { it in priority }.sorted()
        return priority.filter { p -> poses.any { p in it.tags } } + rest
    }

    fun poses(matching: String, tag: String?): List<ReferencePose> =
        poses.filter { pose ->
            (matching.isBlank() || pose.title.contains(matching.trim(), ignoreCase = true) ||
                pose.tags.any { it.contains(matching.trim(), ignoreCase = true) }) &&
                (tag == null || tag in pose.tags)
        }

    fun poses(collection: IntentCollection): List<ReferencePose> =
        poses.filter { collection.id in it.collections }

    /** Model photograph for a pose, or null when none is bundled. */
    fun photo(id: String): Bitmap? = photoCache.getOrPut(id) {
        runCatching {
            context.assets.open("Photos/$id.jpg").use(BitmapFactory::decodeStream)
        }.getOrNull()
    }

    /** Ivory 3D-mannequin pose guide, or null when none is bundled — the
     *  in-camera "ghost". Authored on a black background; brightness is keyed
     *  to alpha here (gamma 2) so the black falls away and the figure glows
     *  softly over the live feed, no hard cut-out edge. */
    fun ghost(id: String): Bitmap? = ghostCache.getOrPut(id) {
        runCatching {
            val src = context.assets.open("Ghosts/$id.jpg").use(BitmapFactory::decodeStream)
            val w = src.width
            val h = src.height
            val px = IntArray(w * h)
            src.getPixels(px, 0, w, 0, 0, w, h)
            for (i in px.indices) {
                val c = px[i]
                val r = (c shr 16) and 0xFF
                val g = (c shr 8) and 0xFF
                val b = c and 0xFF
                val lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
                val a = (lum * lum * 255.0).toInt().coerceIn(0, 255)
                px[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
            }
            Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).apply {
                setPixels(px, 0, w, 0, 0, w, h)
            }
        }.getOrNull()
    }

    private val ghostCache = mutableMapOf<String, Bitmap?>()
}
