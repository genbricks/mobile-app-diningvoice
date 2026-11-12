package io.genbricks.diningvoice.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import io.genbricks.diningvoice.ui.theme.*

@Composable
fun PublicFeedbackScreen() {
    var feedbackText by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var submitted by remember { mutableStateOf(false) }
    val maxChars = 350

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (submitted) {
            Spacer(Modifier.weight(1f))

            Icon(Icons.Filled.CheckCircle, null, modifier = Modifier.size(72.dp), tint = Positive)
            Spacer(Modifier.height(16.dp))
            Text("Thank You!", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(8.dp))
            Text(
                "Your feedback has been submitted successfully.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(24.dp))
            Button(onClick = {
                submitted = false
                feedbackText = ""
                email = ""
            }) {
                Text("Submit Another")
            }

            Spacer(Modifier.weight(1f))
        } else {
            Icon(Icons.Filled.Forum, null, modifier = Modifier.size(40.dp), tint = Purple)
            Spacer(Modifier.height(12.dp))
            Text(
                "Share Your Experience",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                "Your feedback helps us improve",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(24.dp))

            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email (optional)") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = { Icon(Icons.Filled.Email, null) }
            )

            Spacer(Modifier.height(12.dp))

            OutlinedTextField(
                value = feedbackText,
                onValueChange = { if (it.length <= maxChars) feedbackText = it },
                label = { Text("Your feedback") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(160.dp),
                placeholder = { Text("Tell us about your dining experience...") },
                supportingText = {
                    Text(
                        "${feedbackText.length}/$maxChars",
                        color = if (feedbackText.length > maxChars) Negative
                            else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            )

            Spacer(Modifier.height(16.dp))

            Button(
                onClick = { submitted = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                enabled = feedbackText.isNotBlank()
            ) {
                Icon(Icons.Filled.Send, null)
                Spacer(Modifier.width(8.dp))
                Text("Submit Feedback", fontWeight = FontWeight.SemiBold)
            }

            Spacer(Modifier.height(24.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Column(Modifier.padding(16.dp)) {
                    Text("Features", fontWeight = FontWeight.Medium, style = MaterialTheme.typography.bodyMedium)
                    Spacer(Modifier.height(8.dp))
                    FeatureRow(Icons.Filled.Language, "Multi-Language", "Speak in any language")
                    FeatureRow(Icons.Filled.Translate, "Auto-Translation", "Automatic translation")
                    FeatureRow(Icons.Filled.Psychology, "AI Analysis", "Sentiment classification")
                }
            }
        }
    }
}

@Composable
private fun FeatureRow(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, detail: String) {
    Row(Modifier.padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = Purple, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(12.dp))
        Column {
            Text(title, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Medium)
            Text(detail, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
