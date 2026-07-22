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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.oerol.pose.data.PoseRepository
import com.oerol.pose.theme.Theme
import com.oerol.posekit.ReferencePose

@Composable
fun LibraryScreen(onSelect: (ReferencePose) -> Unit) {
    val context = LocalContext.current
    val repo = remember { PoseRepository(context) }
    var query by remember { mutableStateOf("") }
    var selectedTag by remember { mutableStateOf<String?>(null) }

    val results = repo.poses(matching = query, tag = selectedTag)

    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.Colors.background)
            .padding(horizontal = Theme.Spacing.l)
    ) {
        Text(
            "all poses",
            style = Theme.Typography.stepTitle,
            color = Theme.Colors.foreground,
            modifier = Modifier.padding(top = Theme.Spacing.xl),
        )

        SearchField(
            value = query,
            onValueChange = { query = it },
            placeholder = "search poses",
            modifier = Modifier.padding(top = Theme.Spacing.m),
        )

        Row(
            Modifier
                .padding(top = Theme.Spacing.m)
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.s),
        ) {
            repo.allTags().forEach { tag ->
                TagChip(
                    label = tag,
                    isSelected = selectedTag == tag,
                    onClick = { selectedTag = if (selectedTag == tag) null else tag },
                )
            }
        }

        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
            verticalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                top = Theme.Spacing.l, bottom = Theme.Spacing.xl,
            ),
            modifier = Modifier.fillMaxSize(),
        ) {
            items(results, key = { it.id }) { pose ->
                PoseCard(pose = pose, photo = repo.photo(pose.id), onClick = { onSelect(pose) })
            }
        }
    }
}

@Composable
fun PoseCard(
    pose: ReferencePose,
    photo: android.graphics.Bitmap?,
    onClick: () -> Unit,
    locked: Boolean = false,
) {
    Box(
        Modifier
            .fillMaxWidth()
            .aspectRatio(2f / 3f)
            .clip(Theme.Radius.cardShape)
            .background(Theme.Colors.surface)
            .border(1.dp, Theme.Colors.hairline, Theme.Radius.cardShape)
            .clickable(onClick = onClick),
    ) {
        if (photo != null) {
            Image(
                bitmap = photo.asImageBitmap(),
                contentDescription = pose.title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
        Box(
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
                pose.title,
                style = Theme.Typography.sectionTitle,
                color = Theme.Colors.foreground,
            )
        }
        if (locked) {
            Box(
                Modifier
                    .align(Alignment.TopStart)
                    .padding(Theme.Spacing.xs)
                    .clip(CircleShape)
                    .background(Theme.Colors.background.copy(alpha = 0.6f))
                    .padding(Theme.Spacing.s),
            ) {
                Icon(
                    Icons.Outlined.Lock,
                    contentDescription = null,
                    tint = Theme.Colors.accent,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
    }
}

@Composable
fun SearchField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier
            .fillMaxWidth()
            .clip(Theme.Radius.cardShape)
            .background(Theme.Colors.surface)
            .border(1.dp, Theme.Colors.hairline, Theme.Radius.cardShape)
            .padding(Theme.Spacing.m),
    ) {
        if (value.isEmpty()) {
            Text(placeholder, style = Theme.Typography.body, color = Theme.Colors.secondary)
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            textStyle = Theme.Typography.body.copy(color = Theme.Colors.foreground),
            cursorBrush = SolidColor(Theme.Colors.accent),
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
fun TagChip(label: String, isSelected: Boolean, onClick: () -> Unit) {
    Text(
        label,
        style = Theme.Typography.caption,
        color = if (isSelected) Theme.Colors.onAccent else Theme.Colors.foreground,
        modifier = Modifier
            .clip(CircleShape)
            .background(if (isSelected) Theme.Colors.accent else Theme.Colors.surface)
            .border(1.dp, if (isSelected) Theme.Colors.accent else Theme.Colors.hairline, CircleShape)
            .clickable(onClick = onClick)
            .padding(horizontal = Theme.Spacing.m, vertical = Theme.Spacing.s),
    )
}
