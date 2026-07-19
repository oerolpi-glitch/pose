package com.oerol.pose.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

/**
 * Noir Editorial — the same design system as the iOS app's Theme.swift.
 * One source of truth per platform; values must stay in lockstep.
 */
object Theme {

    object Colors {
        /** Near-black page canvas. #0E0E11 */
        val background = Color(0xFF0E0E11)
        /** Slightly lifted surface for cards and controls. #1C1C21 */
        val surface = Color(0xFF1C1C21)
        /** Warm white — primary text, icons, strokes. #F6F4EF */
        val foreground = Color(0xFFF6F4EF)
        /** Muted warm grey — secondary text. #A7A29B */
        val secondary = Color(0xFFA7A29B)
        /** Champagne gold — the one accent. #C9A96A */
        val accent = Color(0xFFC9A96A)
        /** Deep espresso for content on gold. #1A1509 */
        val onAccent = Color(0xFF1A1509)
        /** Dimming layer behind overlays. */
        val scrim = Color.Black.copy(alpha = 0.62f)
        /** Hairline edge separating surfaces on the dark ground. */
        val hairline = foreground.copy(alpha = 0.10f)
    }

    object Typography {
        /** Serif large title — the one big editorial statement per screen. */
        val screenTitle = TextStyle(
            fontFamily = FontFamily.Serif, fontSize = 34.sp,
            fontWeight = FontWeight.Medium, letterSpacing = (-0.02).em,
        )
        /** Serif title — secondary screen headers. */
        val stepTitle = TextStyle(
            fontFamily = FontFamily.Serif, fontSize = 28.sp,
            fontWeight = FontWeight.Medium, letterSpacing = (-0.02).em,
        )
        /** Serif — numeric readouts over the camera. */
        val readout = TextStyle(
            fontFamily = FontFamily.Serif, fontSize = 28.sp,
            fontWeight = FontWeight.SemiBold,
        )
        /** Serif — section headers and card titles. */
        val sectionTitle = TextStyle(
            fontFamily = FontFamily.Serif, fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
        )
        /** Sans — body copy and button labels. */
        val body = TextStyle(fontSize = 16.sp)
        /** Sans medium — emphasized body. */
        val bodyEmphasis = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Medium)
        /** Sans — captions and metadata. */
        val caption = TextStyle(fontSize = 13.sp)
        /** Tiny wide-tracked uppercase eyebrow labels. */
        val eyebrow = TextStyle(
            fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
            letterSpacing = 2.2.sp,
        )
    }

    object Spacing {
        val xs = 4.dp
        val s = 8.dp
        val m = 16.dp
        val l = 24.dp
        val xl = 32.dp
    }

    object Radius {
        val card = 24.dp
        val cardShape = RoundedCornerShape(24.dp)
    }
}
