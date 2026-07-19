package com.oerol.pose

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.oerol.pose.theme.Theme
import com.oerol.pose.ui.HomeScreen
import com.oerol.pose.ui.LibraryScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            Box(
                Modifier
                    .fillMaxSize()
                    .safeDrawingPadding(),
            ) {
                PoseNav()
            }
        }
    }
}

@Composable
private fun PoseNav() {
    val nav = rememberNavController()
    NavHost(navController = nav, startDestination = "home") {
        composable("home") {
            HomeScreen(
                onOpenLibrary = { nav.navigate("library") },
                onOpenCamera = { nav.navigate("camera") },
                onOpenPose = { pose -> nav.navigate("camera?pose=${pose.id}") },
            )
        }
        composable("library") {
            LibraryScreen(onSelect = { pose -> nav.navigate("camera?pose=${pose.id}") })
        }
        composable("camera?pose={pose}") { entry ->
            // Camera + ML Kit pose detection arrive in the next phase; the
            // route exists so every entry point already navigates correctly.
            CameraPlaceholder(poseID = entry.arguments?.getString("pose"))
        }
    }
}

@Composable
private fun CameraPlaceholder(poseID: String?) {
    Box(
        Modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            if (poseID != null) "camera — pose: $poseID (next phase)"
            else "camera (next phase)",
            style = Theme.Typography.body,
            color = Theme.Colors.secondary,
            modifier = Modifier.padding(Theme.Spacing.xl),
        )
    }
}
