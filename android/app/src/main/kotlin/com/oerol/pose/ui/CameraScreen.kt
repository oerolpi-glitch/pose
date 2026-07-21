package com.oerol.pose.ui

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.provider.MediaStore
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.oerol.pose.camera.CameraViewModel
import com.oerol.pose.camera.CoordinateMapper
import com.oerol.pose.camera.PoseAnalyzer
import com.oerol.pose.theme.Theme
import com.oerol.posekit.Bone
import com.oerol.posekit.ReferencePose
import kotlin.math.min

/** The live coaching camera — Android port of the iOS CameraScreen. */
@Composable
fun CameraScreen(targetPose: ReferencePose?, onClose: () -> Unit) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED
        )
    }
    var permissionDenied by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasPermission = granted
        permissionDenied = !granted
    }
    LaunchedEffect(Unit) {
        if (!hasPermission) permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    val viewModel = remember { CameraViewModel(targetPose) }
    var isFront by remember { mutableStateOf(false) }
    var capturedBitmap by remember { mutableStateOf<Bitmap?>(null) }
    val imageCapture = remember { ImageCapture.Builder().build() }
    val analyzer = remember {
        PoseAnalyzer(isFront = { isFront }) { pose, w, h ->
            viewModel.onFrame(pose, w, h)
        }
    }

    fun capture() {
        if (viewModel.captureBlocked) return
        viewModel.captureBlocked = true
        imageCapture.takePicture(
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    capturedBitmap = image.toRotatedBitmap(mirror = isFront)
                    image.close()
                }
                override fun onError(exception: ImageCaptureException) {
                    viewModel.captureBlocked = false
                }
            }
        )
    }
    viewModel.onAutoCapture = { capture() }

    // Auto-dismiss the captured preview after 3s, like iOS.
    LaunchedEffect(capturedBitmap) {
        if (capturedBitmap != null) {
            kotlinx.coroutines.delay(3000)
            capturedBitmap = null
            viewModel.captureBlocked = false
        }
    }

    val previewView = remember {
        PreviewView(context).apply { scaleType = PreviewView.ScaleType.FILL_CENTER }
    }
    // Rebinds only when the lens flips — never on ordinary recomposition
    // (an `update` block would rebind the camera on every scored frame).
    LaunchedEffect(hasPermission, isFront) {
        if (!hasPermission) return@LaunchedEffect
        val providerFuture = ProcessCameraProvider.getInstance(context)
        providerFuture.addListener({
            val provider = providerFuture.get()
            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }
            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also { it.setAnalyzer(ContextCompat.getMainExecutor(context), analyzer) }
            val selector = if (isFront) CameraSelector.DEFAULT_FRONT_CAMERA
            else CameraSelector.DEFAULT_BACK_CAMERA
            provider.unbindAll()
            provider.bindToLifecycle(lifecycleOwner, selector, preview, analysis, imageCapture)
        }, ContextCompat.getMainExecutor(context))
    }

    Box(Modifier.fillMaxSize().background(Theme.Colors.background)) {
        if (hasPermission) {
            AndroidView(factory = { previewView }, modifier = Modifier.fillMaxSize())

            PoseOverlays(viewModel)

            if (!viewModel.bodyDetected && capturedBitmap == null) {
                SearchingCard(Modifier.align(Alignment.Center))
            }

            Column(
                Modifier
                    .fillMaxSize()
                    .padding(Theme.Spacing.l),
                verticalArrangement = Arrangement.SpaceBetween,
            ) {
                TopBar(
                    score = viewModel.score,
                    onClose = onClose,
                    onSwitch = { isFront = !isFront },
                )
                BottomHud(
                    hint = if (viewModel.bodyDetected) viewModel.hintText else null,
                    progress = viewModel.autoCaptureProgress,
                    onShutter = { capture() },
                )
            }

            capturedBitmap?.let { bitmap ->
                CapturedPreview(
                    bitmap = bitmap,
                    onSave = {
                        saveToGallery(context, bitmap)
                        capturedBitmap = null
                        viewModel.captureBlocked = false
                    },
                    onRetake = {
                        capturedBitmap = null
                        viewModel.captureBlocked = false
                    },
                )
            }
        } else if (permissionDenied) {
            PermissionDeniedView(Modifier.align(Alignment.Center))
        }
    }
}

/** Ghost (gold, Procrustes-aligned) + live skeleton (warm white, haloed).
 *  Before a body is tracked, the target pose draws as a centered preview so
 *  the user sees what they're about to match — iOS parity. */
@Composable
private fun PoseOverlays(viewModel: CameraViewModel) {
    Canvas(Modifier.fillMaxSize()) {
        val mapper = CoordinateMapper(
            bufferWidth = viewModel.bufferWidth.toFloat(),
            bufferHeight = viewModel.bufferHeight.toFloat(),
            viewWidth = size.width,
            viewHeight = size.height,
        )
        val target = viewModel.targetPose
        if (viewModel.ghostSegments.isEmpty() && target != null) {
            drawTargetFigure(target.poseVector.points)
        }
        for ((a, b) in viewModel.ghostSegments) {
            val pa = mapper.viewPoint(a)
            val pb = mapper.viewPoint(b)
            drawLine(Color.Black.copy(alpha = 0.30f), Offset(pa.x, pa.y), Offset(pb.x, pb.y),
                strokeWidth = 8.dp.toPx(), cap = StrokeCap.Round)
            drawLine(Theme.Colors.accent.copy(alpha = 0.75f), Offset(pa.x, pa.y), Offset(pb.x, pb.y),
                strokeWidth = 5.dp.toPx(), cap = StrokeCap.Round)
        }
        viewModel.livePose?.let { pose ->
            for (bone in Bone.entries) {
                val (ja, jb) = bone.endpoints
                val a = pose.points[ja] ?: continue
                val b = pose.points[jb] ?: continue
                val pa = mapper.viewPoint(a)
                val pb = mapper.viewPoint(b)
                drawLine(Color.Black.copy(alpha = 0.45f), Offset(pa.x, pa.y), Offset(pb.x, pb.y),
                    strokeWidth = 7.dp.toPx(), cap = StrokeCap.Round)
                drawLine(Theme.Colors.foreground.copy(alpha = 0.95f), Offset(pa.x, pa.y), Offset(pb.x, pb.y),
                    strokeWidth = 4.dp.toPx(), cap = StrokeCap.Round)
            }
        }
    }
}

/** Centered figure preview of the target pose — the Android port of the iOS
 *  MannequinView camera treatment: bones minus the nose-neck strand, plus
 *  shoulder/hip crossbars and an outlined head, in translucent gold. */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawTargetFigure(
    points: Map<com.oerol.posekit.Joint, com.oerol.posekit.Vec2>,
) {
    if (points.isEmpty()) return
    val minX = points.values.minOf { it.x }
    val maxX = points.values.maxOf { it.x }
    val minY = points.values.minOf { it.y }
    val maxY = points.values.maxOf { it.y }
    if (maxX <= minX || maxY <= minY) return

    val inset = 0.18f
    val fit = minOf(
        size.width * (1 - 2 * inset) / (maxX - minX),
        size.height * (1 - 2 * inset) / (maxY - minY),
    )
    val ox = (size.width - (maxX - minX) * fit) / 2
    val oy = (size.height - (maxY - minY) * fit) / 2
    fun place(p: com.oerol.posekit.Vec2) = Offset((p.x - minX) * fit + ox, (p.y - minY) * fit + oy)

    val color = Theme.Colors.accent.copy(alpha = 0.5f)
    val base = minOf(size.width, size.height) * 0.02f

    fun stroke(a: com.oerol.posekit.Joint, b: com.oerol.posekit.Joint, width: Float) {
        val pa = points[a] ?: return
        val pb = points[b] ?: return
        drawLine(color, place(pa), place(pb), strokeWidth = width, cap = StrokeCap.Round)
    }

    for (bone in Bone.entries) {
        if (bone == Bone.NECK) continue
        val width = if (bone == Bone.TORSO) base * 1.5f else base
        stroke(bone.endpoints.first, bone.endpoints.second, width)
    }
    stroke(com.oerol.posekit.Joint.leftHip, com.oerol.posekit.Joint.rightHip, base)
    stroke(com.oerol.posekit.Joint.leftShoulder, com.oerol.posekit.Joint.rightShoulder, base)

    val le = points[com.oerol.posekit.Joint.leftEar]
    val re = points[com.oerol.posekit.Joint.rightEar]
    if (le != null && re != null) {
        val pa = place(le)
        val pb = place(re)
        val center = Offset((pa.x + pb.x) / 2, (pa.y + pb.y) / 2)
        val dx = pa.x - pb.x
        val dy = pa.y - pb.y
        val radius = maxOf(kotlin.math.sqrt(dx * dx + dy * dy) * 0.8f, base)
        drawCircle(color, radius = radius, center = center, style = Stroke(width = base))
    }
}

@Composable
private fun TopBar(score: Float?, onClose: () -> Unit, onSwitch: () -> Unit) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        HudChip(onClick = onClose) { Text("✕", style = Theme.Typography.bodyEmphasis, color = Theme.Colors.foreground) }
        if (score != null) {
            Box(
                Modifier
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.38f))
                    .padding(horizontal = Theme.Spacing.m, vertical = Theme.Spacing.s),
            ) {
                Text("${(score * 100).toInt()}%", style = Theme.Typography.readout, color = Theme.Colors.foreground)
            }
        }
        HudChip(onClick = onSwitch) { Text("↺", style = Theme.Typography.bodyEmphasis, color = Theme.Colors.foreground) }
    }
}

@Composable
private fun HudChip(onClick: () -> Unit, content: @Composable () -> Unit) {
    Box(
        Modifier
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.38f))
            .clickable(onClick = onClick)
            .padding(Theme.Spacing.m),
        contentAlignment = Alignment.Center,
        content = { content() },
    )
}

@Composable
private fun BottomHud(hint: String?, progress: Float, onShutter: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
        if (hint != null) {
            Box(
                Modifier
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.38f))
                    .padding(horizontal = Theme.Spacing.m, vertical = Theme.Spacing.s),
            ) {
                Text(hint, style = Theme.Typography.bodyEmphasis, color = Theme.Colors.foreground)
            }
        }
        Box(Modifier.padding(top = Theme.Spacing.m).size(92.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                // Gold auto-capture progress ring, concentric outside the shutter.
                if (progress > 0f) {
                    drawArc(
                        color = Theme.Colors.accent,
                        startAngle = -90f,
                        sweepAngle = 360f * progress,
                        useCenter = false,
                        style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round),
                    )
                }
                // Two-ring shutter: fixed outer ring, gap, inner disc.
                val center = Offset(size.width / 2, size.height / 2)
                drawCircle(Theme.Colors.foreground, radius = min(size.width, size.height) / 2 - 7.dp.toPx(),
                    center = center, style = Stroke(width = 3.dp.toPx()))
                drawCircle(Theme.Colors.foreground, radius = min(size.width, size.height) / 2 - 14.dp.toPx(),
                    center = center)
            }
            Box(
                Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .clickable(onClick = onShutter),
            )
        }
    }
}

@Composable
private fun SearchingCard(modifier: Modifier = Modifier) {
    Column(
        modifier
            .clip(Theme.Radius.cardShape)
            .background(Color.Black.copy(alpha = 0.38f))
            .padding(Theme.Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("step into frame", style = Theme.Typography.stepTitle, color = Theme.Colors.foreground)
        Text(
            "stand back until your whole body fits",
            style = Theme.Typography.caption,
            color = Theme.Colors.foreground.copy(alpha = 0.75f),
        )
    }
}

@Composable
private fun CapturedPreview(bitmap: Bitmap, onSave: () -> Unit, onRetake: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .background(Theme.Colors.scrim)
            .padding(Theme.Spacing.l),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            bitmap = bitmap.asImageBitmap(),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxWidth()
                .clip(Theme.Radius.cardShape),
        )
        Row(
            Modifier
                .fillMaxWidth()
                .padding(top = Theme.Spacing.l),
            horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
        ) {
            Box(
                Modifier
                    .weight(1f)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.38f))
                    .clickable(onClick = onRetake)
                    .padding(vertical = Theme.Spacing.m),
                contentAlignment = Alignment.Center,
            ) {
                Text("retake", style = Theme.Typography.bodyEmphasis, color = Theme.Colors.foreground)
            }
            Box(
                Modifier
                    .weight(1f)
                    .clip(CircleShape)
                    .background(Theme.Colors.accent)
                    .clickable(onClick = onSave)
                    .padding(vertical = Theme.Spacing.m),
                contentAlignment = Alignment.Center,
            ) {
                Text("save", style = Theme.Typography.bodyEmphasis, color = Theme.Colors.onAccent)
            }
        }
    }
}

@Composable
private fun PermissionDeniedView(modifier: Modifier = Modifier) {
    Column(modifier.padding(Theme.Spacing.xl), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("camera access needed", style = Theme.Typography.readout, color = Theme.Colors.foreground)
        Text(
            "enable camera access in settings to get live pose coaching",
            style = Theme.Typography.body,
            color = Theme.Colors.secondary,
        )
    }
}

/** JPEG from ImageCapture arrives unrotated; apply rotation (and the front-
 *  camera mirror, so the saved photo matches the preview the user framed —
 *  the WYSIWYG rule from the iOS pipeline). */
private fun ImageProxy.toRotatedBitmap(mirror: Boolean): Bitmap {
    val buffer = planes[0].buffer
    val bytes = ByteArray(buffer.remaining()).also { buffer.get(it) }
    val raw = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    val matrix = android.graphics.Matrix().apply {
        postRotate(imageInfo.rotationDegrees.toFloat())
        if (mirror) postScale(-1f, 1f)
    }
    return Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, matrix, true)
}

private fun saveToGallery(context: android.content.Context, bitmap: Bitmap) {
    val values = ContentValues().apply {
        put(MediaStore.Images.Media.DISPLAY_NAME, "pose-${System.currentTimeMillis()}.jpg")
        put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
    }
    val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        ?: return
    context.contentResolver.openOutputStream(uri)?.use { stream ->
        bitmap.compress(Bitmap.CompressFormat.JPEG, 92, stream)
    }
}
