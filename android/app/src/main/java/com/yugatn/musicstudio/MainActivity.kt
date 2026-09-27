package com.yugatn.musicstudio

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp

data class Note(var pitch: Int, var beat: Float, var length: Float = .5f, var velocity: Int = 96)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MusicStudioApp() }
    }
}

@Composable
private fun MusicStudioApp() {
    var tab by remember { mutableIntStateOf(0) }
    val titles = listOf("Compose", "Piano Roll", "Curve Lab", "Project")
    MaterialTheme {
        Scaffold(
            topBar = { TopAppBar(title = { Text("Music Studio") }) },
            bottomBar = {
                NavigationBar {
                    titles.forEachIndexed { i, title ->
                        NavigationBarItem(i == tab, { tab = i }, icon = {}, label = { Text(title) })
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

@Composable private fun ComposeScreen() {
    var prompt by remember { mutableStateOf("melodic electronic intro") }
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("AI Composer", style = MaterialTheme.typography.headlineSmall)
        OutlinedTextField(prompt, { prompt = it }, label = { Text("Describe the composition") })
        Button(onClick = {}) { Text("Generate") }
        Text("AI output remains editable in Piano Roll and Curve Lab.")
    }
}

@Composable private fun PianoRollScreen() {
    val notes = remember { mutableStateListOf(Note(60,0f), Note(64,1f), Note(67,2f), Note(72,3f)) }
    var zoom by remember { mutableFloatStateOf(1f) }
    var pan by remember { mutableStateOf(Offset.Zero) }
    var selected by remember { mutableIntStateOf(-1) }

    Canvas(
        Modifier.fillMaxSize().pointerInput(Unit) {
            detectTransformGestures { _, delta, scale, _ ->
                zoom = (zoom * scale).coerceIn(.6f, 3f)
                pan += delta
            }
        }
    ) {
        val beatWidth = 80f * zoom
        val rowHeight = 24f * zoom
        for (beat in 0..32) {
            val x = pan.x + beat * beatWidth
            drawLine(MaterialTheme.colorScheme.outline.copy(alpha = if (beat % 4 == 0) .5f else .18f), Offset(x,0f), Offset(x,size.height))
        }
        for (row in 0..36) {
            val y = pan.y + row * rowHeight
            drawLine(MaterialTheme.colorScheme.outline.copy(alpha=.16f), Offset(0f,y), Offset(size.width,y))
        }
        notes.forEachIndexed { index, note ->
            val x = pan.x + note.beat * beatWidth
            val y = pan.y + (84 - note.pitch) * rowHeight
            drawRect(MaterialTheme.colorScheme.primary.copy(alpha = if(index == selected) 1f else .7f),
                androidx.compose.ui.geometry.Rect(x,y,x+note.length*beatWidth-2,y+rowHeight-3))
        }
    }
}

@Composable private fun CurveLabScreen() {
    var points by remember { mutableStateOf(listOf(Offset(.05f,.65f), Offset(.5f,.35f), Offset(.95f,.75f))) }
    var dragging by remember { mutableIntStateOf(-1) }
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Curve Lab", style = MaterialTheme.typography.headlineSmall)
        Text("Drag control points to shape velocity, pitch or timing.")
        Canvas(Modifier.fillMaxWidth().height(300.dp).pointerInput(Unit) {
            detectDragGestures(
                onDragStart = { position ->
                    dragging = points.indices.minByOrNull { i ->
                        val p=points[i]
                        ((p.x*size.width-position.x)*(p.x*size.width-position.x)+(p.y*size.height-position.y)*(p.y*size.height-position.y)).toDouble()
                    } ?: -1
                },
                onDrag = { change, dragAmount ->
                    if (dragging >= 0) {
                        val p=points[dragging]
                        points=points.toMutableList().also {
                            it[dragging]=Offset(
                                (p.x+dragAmount.x/size.width).coerceIn(0f,1f),
                                (p.y+dragAmount.y/size.height).coerceIn(0f,1f)
                            )
                        }
                        change.consume()
                    }
                },
                onDragEnd = { dragging=-1 }
            )
        }) {
            val path=Path()
            points.sortedBy{it.x}.forEachIndexed { i,p ->
                val q=Offset(p.x*size.width,p.y*size.height)
                if(i==0) path.moveTo(q.x,q.y) else path.lineTo(q.x,q.y)
                drawCircle(MaterialTheme.colorScheme.primary,8f,q)
            }
            drawPath(path,MaterialTheme.colorScheme.primary,strokeWidth=4f)
        }
    }
}

@Composable private fun ProjectScreen() {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Project", style = MaterialTheme.typography.headlineSmall)
        Text("Versioned portable project format: .yms")
        Text("Offline-first storage and cross-device sync are next.")
    }
}
