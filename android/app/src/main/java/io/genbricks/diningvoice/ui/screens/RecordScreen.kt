package io.genbricks.diningvoice.ui.screens

import android.Manifest
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import io.genbricks.diningvoice.ui.theme.*

enum class RecordMode { SELECTION, VOICE, TEXT }

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun RecordScreen() {
    var mode by remember { mutableStateOf(RecordMode.SELECTION) }
    var textInput by remember { mutableStateOf("") }
    val micPermission = rememberPermissionState(Manifest.permission.RECORD_AUDIO)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            "Record Feedback",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(8.dp))

        when (mode) {
            RecordMode.SELECTION -> {
                Spacer(Modifier.weight(1f))

                Text(
                    "How would you like to submit feedback?",
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(24.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Card(
                        onClick = {
                            if (micPermission.status.isGranted) {
                                mode = RecordMode.VOICE
                            } else {
                                micPermission.launchPermissionRequest()
                            }
                        },
                        modifier = Modifier
                            .weight(1f)
                            .height(160.dp),
                        colors = CardDefaults.cardColors(containerColor = Purple)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(Icons.Filled.Mic, null, tint = Color.White, modifier = Modifier.size(36.dp))
                            Spacer(Modifier.height(12.dp))
                            Text("Talk", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                            Text("Record voice", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
                        }
                    }

                    Card(
                        onClick = { mode = RecordMode.TEXT },
                        modifier = Modifier
                            .weight(1f)
                            .height(160.dp),
                        colors = CardDefaults.cardColors(containerColor = Blue)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(Icons.Filled.Keyboard, null, tint = Color.White, modifier = Modifier.size(36.dp))
                            Spacer(Modifier.height(12.dp))
                            Text("Type", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                            Text("Write text", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
                        }
                    }
                }

                Spacer(Modifier.height(24.dp))

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Psychology, null, tint = Purple, modifier = Modifier.size(32.dp))
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text("AI-Powered Analysis", fontWeight = FontWeight.Medium, style = MaterialTheme.typography.bodyMedium)
                            Text(
                                "Feedback is transcribed, translated, and analyzed automatically.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                Spacer(Modifier.weight(1f))
            }

            RecordMode.VOICE -> {
                TextButton(onClick = { mode = RecordMode.SELECTION }) {
                    Icon(Icons.Filled.ArrowBack, null)
                    Spacer(Modifier.width(4.dp))
                    Text("Back")
                }

                Spacer(Modifier.weight(1f))

                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        Icons.Filled.Mic,
                        null,
                        modifier = Modifier.size(72.dp),
                        tint = Purple
                    )
                    Spacer(Modifier.height(16.dp))
                    Text(
                        "Voice recording",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "Tap the button below to start recording your feedback",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                    Spacer(Modifier.height(32.dp))

                    Button(
                        onClick = { /* TODO: implement Android audio recording */ },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        shape = RoundedCornerShape(26.dp)
                    ) {
                        Icon(Icons.Filled.Mic, null)
                        Spacer(Modifier.width(8.dp))
                        Text("Start Recording", fontWeight = FontWeight.SemiBold)
                    }
                }

                Spacer(Modifier.weight(1f))
            }

            RecordMode.TEXT -> {
                TextButton(onClick = { mode = RecordMode.SELECTION }) {
                    Icon(Icons.Filled.ArrowBack, null)
                    Spacer(Modifier.width(4.dp))
                    Text("Back")
                }

                Spacer(Modifier.height(16.dp))

                Text("Write your feedback", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))

                OutlinedTextField(
                    value = textInput,
                    onValueChange = { if (it.length <= 10000) textInput = it },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp),
                    placeholder = { Text("Describe your experience...") },
                    supportingText = { Text("${textInput.length} / 10,000") }
                )

                Spacer(Modifier.height(16.dp))

                Button(
                    onClick = { /* TODO: submit text */ },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    enabled = textInput.isNotBlank()
                ) {
                    Icon(Icons.Filled.Send, null)
                    Spacer(Modifier.width(8.dp))
                    Text("Submit Feedback", fontWeight = FontWeight.SemiBold)
                }

                Spacer(Modifier.weight(1f))
            }
        }
    }
}
