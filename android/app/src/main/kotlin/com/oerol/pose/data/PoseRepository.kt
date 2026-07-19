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

    /** Model photograph for a pose, or null when none is bundled. */
    fun photo(id: String): Bitmap? = photoCache.getOrPut(id) {
        runCatching {
            context.assets.open("Photos/$id.jpg").use(BitmapFactory::decodeStream)
        }.getOrNull()
    }
}
