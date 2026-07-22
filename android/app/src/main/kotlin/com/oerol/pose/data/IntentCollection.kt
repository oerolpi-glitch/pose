package com.oerol.pose.data

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material.icons.outlined.CropPortrait
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material.icons.outlined.WorkOutline
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * A shooting-intent collection — the top-level way users browse poses.
 * Mirrors iOS App/Models/IntentCollection.swift; ids/titles/subtitles must match exactly.
 */
enum class IntentCollection(
    val id: String,
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val comingSoon: Boolean = false,
) {
    DATING("dating", "dating & profile", "shots that spark a swipe right", Icons.Outlined.AutoAwesome),
    PROFESSIONAL("professional", "professional", "headshots that mean business", Icons.Outlined.WorkOutline),
    MIRROR("mirror", "mirror selfie", "the effortless mirror moment", Icons.Outlined.CropPortrait),
    FULLBODY("fullbody", "full body", "head-to-toe, framed right", Icons.Outlined.PersonOutline),
    COUPLE("couple", "couples", "two people, one great frame", Icons.Outlined.Groups, comingSoon = true),
    CANDID("candid", "candid", "caught-in-the-moment, on purpose", Icons.Outlined.CameraAlt),
}
