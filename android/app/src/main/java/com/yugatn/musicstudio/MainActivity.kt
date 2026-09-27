package com.yugatn.musicstudio

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MusicStudioApp() }
    }
}

@Composable
private fun MusicStudioApp() {
    var tab by remember { mutableStateOf(0) }
    val titles = listOf("Compose", "Piano Roll", "Curve Lab", "Project")

    MaterialTheme {
        Scaffold(
            topBar = { TopAppBar(title = { Text("Music Studio") }) },
            bottomBar = {
                NavigationBar {
                    titles.forEachIndexed { index, title ->
                        NavigationBarItem(
                            selected = tab == index,
                            onClick = { tab = index },
                            icon = {},
                            label = { Text(title) }
                        )
                    }
                }
            }
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                when (tab) {
                    0 -> ComposeScreen()
                    1 -> PianoRollScreen()
                    2 -> CurveLabScreen()
                    else -> ProjectScreen()
                }
            }
        }
    }
}

@Composable
private fun ComposeScreen() {
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("AI Composer", style = MaterialTheme.typography.headlineSmall)
        Text("Generate a melody, then edit every musical result manually.")
        OutlinedTextField(value = "", onValueChange = {}, label = { Text("Describe the composition") })
        Button(onClick = {}) { Text("Generate") }
    }
}

@Composable
private fun PianoRollScreen() {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }

    Canvas(
        Modifier.fillMaxSize()
            .pointerInput(Unit) {
                detectTransformGestures { _, pan, zoom, _ ->
                    scale = (scale * zoom).coerceIn(0.6f, 3f)
                    offset += pan
                }
            }
            .pointerInput(Unit) {
                detectTapGestures { }
            }
    ) {
        val beatWidth = 80f * scale
        val rowHeight = 24f * scale
        for (beat in 0..32) {
            val x = offset.x + beat * beatWidth
            drawLine(
                MaterialTheme.colorScheme.outline.copy(alpha = if (beat % 4 == 0) .5f else .18f),
                Offset(x, 0f), Offset(x, size.height)
            )
        }
        for (row in 0..36) {
            val y = offset.y + row * rowHeight
            drawLine(MaterialTheme.colorScheme.outline.copy(alpha = .16f), Offset(0f, y), Offset(size.width, y))
        }
    }
}

@Composable
private fun CurveLabScreen() {
    var points by remember {
        mutableStateOf(listOf(Offset(0.05f, .65f), Offset(.5f, .35f), Offset(.95f, .75f)))
    }

    Canvas(
        Modifier.fillMaxSize().padding(16.dp)
            .pointerInput(Unit) {
                detectTapGestures { }
            }
    ) {
        val path = Path()
        points.sortedBy { it.x }.forEachIndexed { i, point ->
            val p = Offset(point.x * size.width, point.y * size.height)
            if (i == 0) path.moveTo(p.x, p.y) else path.lineTo(p.x, p.y)
            drawCircle(MaterialTheme.colorScheme.primary, 8f, p)
        }
        drawPath(path, MaterialTheme.colorScheme.primary, strokeWidth = 4f)
    }
}

@Composable
private fun ProjectScreen() {
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Project", style = MaterialTheme.typography.headlineSmall)
        Text("Offline project workspace")
        Text("Portable .yms project contract will be connected here.")
    }
}
