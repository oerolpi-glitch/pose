package com.oerol.pose.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.oerol.pose.data.IntentCollection
import com.oerol.pose.data.PoseRepository
import com.oerol.pose.data.PremiumGate
import com.oerol.pose.theme.Theme
import com.oerol.posekit.ReferencePose

@Composable
fun CollectionScreen(
    collectionId: String,
    onSelect: (ReferencePose) -> Unit,
) {
    val context = LocalContext.current
    val repo = remember { PoseRepository(context) }
    val collection = IntentCollection.entries.first { it.id == collectionId }
    val poses = remember(collectionId) { repo.poses(collection) }
    // TODO(Task 9): route locked taps through the real Superwall paywall.
    val onLockedSelect: (ReferencePose) -> Unit = { onSelect(it) }

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.Colors.background)
            .padding(horizontal = Theme.Spacing.l),
    ) {
        Text(
            collection.title,
            style = Theme.Typography.stepTitle,
            color = Theme.Colors.foreground,
            modifier = Modifier.padding(top = Theme.Spacing.xl),
        )
        Text(
            collection.subtitle,
            style = Theme.Typography.body,
            color = Theme.Colors.secondary,
            modifier = Modifier.padding(top = Theme.Spacing.xs),
        )

        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
            verticalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
            contentPadding = PaddingValues(top = Theme.Spacing.l, bottom = Theme.Spacing.xl),
            modifier = Modifier.fillMaxSize(),
        ) {
            items(poses, key = { it.id }) { pose ->
                val locked = PremiumGate.isLocked(pose, subscribed = false)
                PoseCard(
                    pose = pose,
                    photo = repo.photo(pose.id),
                    locked = locked,
                    onClick = { if (locked) onLockedSelect(pose) else onSelect(pose) },
                )
            }
        }
    }
}
