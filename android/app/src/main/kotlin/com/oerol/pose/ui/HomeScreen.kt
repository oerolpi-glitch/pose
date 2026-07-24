package com.oerol.pose.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.oerol.pose.data.IntentCollection
import com.oerol.pose.data.PoseRepository
import com.oerol.pose.theme.Theme
import com.oerol.posekit.ReferencePose
import java.util.Calendar

@Composable
fun HomeScreen(
    onOpenCollection: (IntentCollection) -> Unit,
    onOpenLibrary: () -> Unit,
    onOpenCamera: () -> Unit,
    onOpenPose: (ReferencePose) -> Unit,
) {
    val context = LocalContext.current
    val repo = remember { PoseRepository(context) }
    val dailyPose = remember {
        repo.allPoses().let { poses ->
            if (poses.isEmpty()) null
            else poses[Calendar.getInstance().get(Calendar.DAY_OF_YEAR) % poses.size]
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.Colors.background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Theme.Spacing.l),
    ) {
        Text(
            "POSE",
            style = Theme.Typography.eyebrow,
            color = Theme.Colors.accent,
            modifier = Modifier.padding(top = Theme.Spacing.xl),
        )
        Text(
            "what are you shooting today?",
            style = Theme.Typography.screenTitle,
            color = Theme.Colors.foreground,
            modifier = Modifier.padding(top = Theme.Spacing.xs),
        )

        val photo = dailyPose?.let { repo.photo(it.id) }
        if (dailyPose != null && photo != null) {
            Box(
                Modifier
                    .padding(top = Theme.Spacing.l)
                    .fillMaxWidth()
                    .aspectRatio(4f / 5f)
                    .clip(Theme.Radius.cardShape)
                    .border(1.dp, Theme.Colors.hairline, Theme.Radius.cardShape)
                    .clickable { onOpenPose(dailyPose) },
            ) {
                Image(
                    bitmap = photo.asImageBitmap(),
                    contentDescription = dailyPose.title,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                )
                Column(
                    Modifier
                        .align(Alignment.BottomStart)
                        .fillMaxWidth()
                        .background(
                            Brush.verticalGradient(
                                listOf(
                                    Theme.Colors.background.copy(alpha = 0f),
                                    Theme.Colors.background.copy(alpha = 0.9f),
                                )
                            )
                        )
                        .padding(Theme.Spacing.m),
                ) {
                    Text(
                        "POSE OF THE DAY",
                        style = Theme.Typography.eyebrow,
                        color = Theme.Colors.accent,
                    )
                    Text(
                        dailyPose.title,
                        style = Theme.Typography.stepTitle,
                        color = Theme.Colors.foreground,
                    )
                }
            }
        }

        Spacer(Modifier.height(Theme.Spacing.l))
        IntentCollection.entries.toList().chunked(2).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(bottom = Theme.Spacing.m),
                horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
            ) {
                row.forEach { collection ->
                    CollectionCard(
                        collection = collection,
                        modifier = Modifier.weight(1f),
                        onClick = { if (!collection.comingSoon) onOpenCollection(collection) },
                    )
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }

        WideCard(
            title = "live coaching",
            subtitle = "real-time posture feedback",
            icon = Icons.Outlined.GraphicEq,
            onClick = onOpenCamera,
            modifier = Modifier.padding(bottom = Theme.Spacing.m),
        )

        WideCard(
            title = "all poses",
            subtitle = "search the full library",
            icon = Icons.Outlined.Search,
            onClick = onOpenLibrary,
            modifier = Modifier.padding(bottom = Theme.Spacing.xl),
        )
    }
}

@Composable
fun PillButton(title: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxWidth()
            .clip(CircleShape)
            .background(Theme.Colors.accent)
            .clickable(onClick = onClick)
            .padding(vertical = Theme.Spacing.m + 2.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(title, style = Theme.Typography.bodyEmphasis, color = Theme.Colors.onAccent)
    }
}

@Composable
private fun CollectionCard(
    collection: IntentCollection,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier
            .height(150.dp)
            .clip(Theme.Radius.cardShape)
            .background(Theme.Colors.surface)
            .border(1.dp, Theme.Colors.hairline, Theme.Radius.cardShape)
            .clickable(onClick = onClick)
            .padding(Theme.Spacing.m)
            .alpha(if (collection.comingSoon) 0.55f else 1f),
    ) {
        Icon(collection.icon, contentDescription = null, tint = Theme.Colors.accent,
            modifier = Modifier.size(24.dp))
        Spacer(Modifier.weight(1f))
        Text(collection.title, style = Theme.Typography.sectionTitle, color = Theme.Colors.foreground)
        Text(
            if (collection.comingSoon) "coming soon" else collection.subtitle,
            style = Theme.Typography.caption,
            color = Theme.Colors.secondary,
        )
    }
}

@Composable
private fun WideCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier
            .fillMaxWidth()
            .clip(Theme.Radius.cardShape)
            .background(Theme.Colors.surface)
            .border(1.dp, Theme.Colors.hairline, Theme.Radius.cardShape)
            .clickable(onClick = onClick)
            .padding(Theme.Spacing.m),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
    ) {
        Icon(icon, contentDescription = null, tint = Theme.Colors.accent,
            modifier = Modifier.size(24.dp))
        Column(Modifier.weight(1f)) {
            Text(title, style = Theme.Typography.sectionTitle, color = Theme.Colors.foreground)
            Text(subtitle, style = Theme.Typography.caption, color = Theme.Colors.secondary)
        }
        Icon(Icons.Outlined.ChevronRight, contentDescription = null,
            tint = Theme.Colors.secondary, modifier = Modifier.size(18.dp))
    }
}
