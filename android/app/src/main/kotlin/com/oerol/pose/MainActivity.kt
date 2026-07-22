package com.oerol.pose

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.oerol.pose.data.PoseRepository
import com.oerol.pose.ui.CameraScreen
import com.oerol.pose.ui.CollectionScreen
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
                onOpenCollection = { c -> nav.navigate("collection/${c.id}") },
                onOpenLibrary = { nav.navigate("library") },
                onOpenCamera = { nav.navigate("camera") },
                onOpenPose = { pose -> nav.navigate("camera?pose=${pose.id}") },
            )
        }
        composable("collection/{id}") { entry ->
            val id = entry.arguments?.getString("id").orEmpty()
            CollectionScreen(
                collectionId = id,
                onSelect = { pose -> nav.navigate("camera?pose=${pose.id}") },
            )
        }
        composable("library") {
            LibraryScreen(onSelect = { pose -> nav.navigate("camera?pose=${pose.id}") })
        }
        composable("camera?pose={pose}") { entry ->
            val context = androidx.compose.ui.platform.LocalContext.current
            val poseID = entry.arguments?.getString("pose")
            val target = androidx.compose.runtime.remember(poseID) {
                poseID?.let { PoseRepository(context).pose(it) }
            }
            CameraScreen(targetPose = target, onClose = { nav.popBackStack() })
        }
    }
}
