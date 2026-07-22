package com.oerol.posekit

import org.json.JSONObject

/**
 * An authored target pose bundled with the app as JSON. Parsed with org.json
 * (part of the Android framework; a plain jar on the JVM) so the library adds
 * no serialization dependency.
 */
data class ReferencePose(
    val id: String,
    val title: String,
    val tags: List<String>,
    val collections: List<String>,
    val free: Boolean,
    val joints: Map<String, List<Float>>,
) {
    /** Typed pose. Unknown joint names and arrays without exactly 2 values are skipped. */
    val poseVector: PoseVector
        get() {
            val pts = mutableMapOf<Joint, Vec2>()
            for ((key, arr) in joints) {
                val joint = Joint.fromKey(key) ?: continue
                if (arr.size != 2) continue
                pts[joint] = Vec2(arr[0], arr[1])
            }
            return PoseVector(pts)
        }

    companion object {
        /** Decodes the same JSON schema the iOS app bundles. */
        fun fromJson(json: String): ReferencePose {
            val obj = JSONObject(json)
            val tagsArr = obj.getJSONArray("tags")
            val tags = (0 until tagsArr.length()).map { tagsArr.getString(it) }
            val jointsObj = obj.getJSONObject("joints")
            val joints = mutableMapOf<String, List<Float>>()
            for (key in jointsObj.keys()) {
                val arr = jointsObj.getJSONArray(key)
                joints[key] = (0 until arr.length()).map { arr.getDouble(it).toFloat() }
            }
            val collectionsArr = obj.optJSONArray("collections")
            val collections = if (collectionsArr == null) emptyList()
                else (0 until collectionsArr.length()).map { collectionsArr.getString(it) }
            val free = obj.optBoolean("free", false)
            return ReferencePose(
                id = obj.getString("id"),
                title = obj.getString("title"),
                tags = tags,
                collections = collections,
                free = free,
                joints = joints,
            )
        }
    }
}
