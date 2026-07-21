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
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathOperation
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.oerol.pose.camera.CameraViewModel
import com.oerol.pose.camera.CoordinateMapper
import com.oerol.pose.camera.PoseAnalyzer
import com.oerol.pose.data.PoseRepository
import com.oerol.pose.theme.Theme
import com.oerol.posekit.Joint
import com.oerol.posekit.ReferencePose
import com.oerol.posekit.Vec2
import kotlin.math.hypot
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

            val ghostBitmap = remember(viewModel.targetPose) {
                viewModel.targetPose?.let { PoseRepository(context).ghost(it.id) }
            }
            PoseOverlays(viewModel, ghostBitmap)

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

/** The pose ghost: a translucent, filled human silhouette (warm-white body,
 *  gold edge) the user aligns into — not a wireframe. When a body is tracked
 *  it is Procrustes-projected onto the user; before that it sits centered as a
 *  preview of the pose to match. Only shown in pose-me (a target exists). */
@Composable
private fun PoseOverlays(viewModel: CameraViewModel, ghost: Bitmap?) {
    Canvas(Modifier.fillMaxSize()) {
        val target = viewModel.targetPose ?: return@Canvas
        if (ghost != null) {
            // Photogenik-style guide: dim the live feed, then lay the ivory
            // mannequin (already brightness-keyed to alpha) over it so the
            // figure glows and the black falls away. Centered, aspect-fit.
            drawRect(Color.Black, alpha = 0.4f)
            val img = ghost.asImageBitmap()
            val scale = min(size.width / img.width, size.height / img.height) * 0.92f
            val w = (img.width * scale)
            val h = (img.height * scale)
            drawImage(
                image = img,
                srcOffset = IntOffset.Zero,
                srcSize = IntSize(img.width, img.height),
                dstOffset = IntOffset(((size.width - w) / 2).toInt(), ((size.height - h) / 2).toInt()),
                dstSize = IntSize(w.toInt(), h.toInt()),
            )
        } else {
            // Fallback until a mannequin ghost is bundled: a drawn silhouette.
            drawBodyGhost(centeredGhost(target.poseVector.points))
        }
    }
}

/** Aspect-fit the authored pose into the frame (centered, padded) as view-space
 *  joint offsets — used before a live body is tracked. */
private fun DrawScope.centeredGhost(points: Map<Joint, Vec2>): Map<Joint, Offset> {
    if (points.isEmpty()) return emptyMap()
    val minX = points.values.minOf { it.x }
    val maxX = points.values.maxOf { it.x }
    val minY = points.values.minOf { it.y }
    val maxY = points.values.maxOf { it.y }
    if (maxX <= minX || maxY <= minY) return emptyMap()
    val inset = 0.16f
    val fit = minOf(
        size.width * (1 - 2 * inset) / (maxX - minX),
        size.height * (1 - 2 * inset) / (maxY - minY),
    )
    val ox = (size.width - (maxX - minX) * fit) / 2
    val oy = (size.height - (maxY - minY) * fit) / 2
    return points.mapValues { Offset((it.value.x - minX) * fit + ox, (it.value.y - minY) * fit + oy) }
}

/** Builds one unioned silhouette from filled limb capsules, a torso polygon,
 *  and a head, then paints it as a ghost: translucent warm-white fill, a dark
 *  halo for legibility over any background, and a thin gold edge. */
private fun DrawScope.drawBodyGhost(p: Map<Joint, Offset>) {
    if (p.size < 6) return
    val minDim = min(size.width, size.height)
    val limbW = minDim * 0.06f
    val slimW = minDim * 0.045f

    val parts = mutableListOf<Path>()

    val ls = p[Joint.leftShoulder]; val rs = p[Joint.rightShoulder]
    val lh = p[Joint.leftHip]; val rh = p[Joint.rightHip]
    if (ls != null && rs != null && lh != null && rh != null) {
        parts += Path().apply {
            moveTo(ls.x, ls.y); lineTo(rs.x, rs.y); lineTo(rh.x, rh.y); lineTo(lh.x, lh.y); close()
        }
    }

    fun limb(a: Joint, b: Joint, w: Float) {
        val pa = p[a] ?: return
        val pb = p[b] ?: return
        parts += capsulePath(pa, pb, w / 2)
    }
    limb(Joint.leftShoulder, Joint.leftElbow, limbW)
    limb(Joint.leftElbow, Joint.leftWrist, slimW)
    limb(Joint.rightShoulder, Joint.rightElbow, limbW)
    limb(Joint.rightElbow, Joint.rightWrist, slimW)
    limb(Joint.leftHip, Joint.leftKnee, limbW)
    limb(Joint.leftKnee, Joint.leftAnkle, slimW)
    limb(Joint.rightHip, Joint.rightKnee, limbW)
    limb(Joint.rightKnee, Joint.rightAnkle, slimW)

    // Head: sized from ear span, else a default disc above the neck/shoulders.
    val le = p[Joint.leftEar]; val re = p[Joint.rightEar]
    val neck = p[Joint.neck] ?: if (ls != null && rs != null) Offset((ls.x + rs.x) / 2, (ls.y + rs.y) / 2) else null
    val headCenter: Offset?
    val headRadius: Float
    if (le != null && re != null) {
        headCenter = Offset((le.x + re.x) / 2, (le.y + re.y) / 2)
        headRadius = maxOf(hypot(le.x - re.x, le.y - re.y) * 0.85f, minDim * 0.05f)
    } else {
        val nose = p[Joint.nose]
        headCenter = nose ?: neck
        headRadius = minDim * 0.06f
    }
    if (headCenter != null) {
        parts += Path().apply {
            addOval(Rect(headCenter.x - headRadius, headCenter.y - headRadius,
                headCenter.x + headRadius, headCenter.y + headRadius))
        }
    }

    if (parts.isEmpty()) return
    val body = parts.reduce { acc, part -> Path().apply { op(acc, part, PathOperation.Union) } }

    drawPath(body, Theme.Colors.foreground.copy(alpha = 0.22f))
    drawPath(body, Color.Black.copy(alpha = 0.30f), style = Stroke(width = 5.dp.toPx()))
    drawPath(body, Theme.Colors.accent.copy(alpha = 0.9f), style = Stroke(width = 2.dp.toPx()))
}

/** A filled capsule (rounded thick segment) between two points. */
private fun capsulePath(a: Offset, b: Offset, r: Float): Path = Path().apply {
    addOval(Rect(a.x - r, a.y - r, a.x + r, a.y + r))
    addOval(Rect(b.x - r, b.y - r, b.x + r, b.y + r))
    val dx = b.x - a.x; val dy = b.y - a.y
    val len = hypot(dx, dy)
    if (len >= 1e-3f) {
        val px = -dy / len * r; val py = dx / len * r
        moveTo(a.x + px, a.y + py)
        lineTo(b.x + px, b.y + py)
        lineTo(b.x - px, b.y - py)
        lineTo(a.x - px, a.y - py)
        close()
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
