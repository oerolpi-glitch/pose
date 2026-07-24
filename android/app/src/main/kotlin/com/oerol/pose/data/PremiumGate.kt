package com.oerol.pose.data

import com.oerol.posekit.ReferencePose

object PremiumGate {
    fun isLocked(pose: ReferencePose, subscribed: Boolean): Boolean = !pose.free && !subscribed
}
