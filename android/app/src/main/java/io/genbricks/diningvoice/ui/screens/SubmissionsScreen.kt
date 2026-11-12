package io.genbricks.diningvoice.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.genbricks.diningvoice.data.api.DiningVoiceApi
import io.genbricks.diningvoice.data.model.Submission
import io.genbricks.diningvoice.ui.theme.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SubmissionsState(
    val submissions: List<Submission> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val totalCount: Int = 0,
    val currentPage: Int = 1,
    val hasMore: Boolean = true
)

@HiltViewModel
class SubmissionsViewModel @Inject constructor(
    private val api: DiningVoiceApi
) : ViewModel() {
    private val _state = MutableStateFlow(SubmissionsState())
    val state: StateFlow<SubmissionsState> = _state

    init { load() }

    fun load(reset: Boolean = true) {
        viewModelScope.launch {
            if (reset) {
                _state.value = _state.value.copy(
                    currentPage = 1,
                    hasMore = true,
                    submissions = emptyList()
                )
            }
            val page = _state.value.currentPage
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val response = api.getSubmissions(page = page)
                val items = if (reset) response.items
                    else _state.value.submissions + response.items
                _state.value = _state.value.copy(
                    submissions = items,
                    totalCount = response.total,
                    hasMore = page < response.totalPages,
                    currentPage = page + 1,
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load submissions"
                )
            }
        }
    }

    fun loadMore() = load(reset = false)

    fun delete(id: String) {
        viewModelScope.launch {
            try {
                api.deleteSubmission(id)
                _state.value = _state.value.copy(
                    submissions = _state.value.submissions.filter { it.id != id },
                    totalCount = _state.value.totalCount - 1
                )
            } catch (_: Exception) {}
        }
    }
}

@Composable
fun SubmissionsScreen(viewModel: SubmissionsViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Submissions",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    "${state.totalCount} total",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        if (state.submissions.isEmpty() && !state.isLoading) {
            item {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .padding(vertical = 64.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        Icons.Filled.MicOff, null,
                        modifier = Modifier.size(48.dp),
                        tint = Purple.copy(alpha = 0.6f)
                    )
                    Spacer(Modifier.height(16.dp))
                    Text("No Submissions", style = MaterialTheme.typography.titleMedium)
                    Text(
                        "Record or type feedback to see submissions here.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        items(state.submissions, key = { it.id }) { submission ->
            SubmissionCard(submission = submission, onDelete = { viewModel.delete(submission.id) })
        }

        if (state.isLoading) {
            item {
                Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
fun SubmissionCard(submission: Submission, onDelete: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                SentimentChip(submission.sentiment, submission.confidenceScore)
                submission.urgencyScore?.let { urgency ->
                    if (urgency > 0) {
                        Spacer(Modifier.width(6.dp))
                        UrgencyChip(urgency)
                    }
                }
                Spacer(Modifier.weight(1f))
                IconButton(onClick = { showDeleteDialog = true }, modifier = Modifier.size(24.dp)) {
                    Icon(Icons.Filled.Delete, null, tint = Negative.copy(alpha = 0.7f), modifier = Modifier.size(16.dp))
                }
            }

            Spacer(Modifier.height(8.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                submission.referenceNumber?.let {
                    Text(it, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Medium)
                }
                Text(submission.createdAt.take(10), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            submission.category?.let { cat ->
                Spacer(Modifier.height(6.dp))
                SuggestionChip(
                    onClick = {},
                    label = { Text(cat, style = MaterialTheme.typography.labelSmall) },
                    colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Purple.copy(alpha = 0.1f))
                )
            }

            Spacer(Modifier.height(8.dp))

            Text(
                submission.transcriptionText,
                style = MaterialTheme.typography.bodySmall,
                maxLines = if (expanded) Int.MAX_VALUE else 4,
                overflow = TextOverflow.Ellipsis
            )

            if (submission.transcriptionText.length > 200) {
                TextButton(onClick = { expanded = !expanded }) {
                    Text(if (expanded) "Show less" else "Show more")
                }
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Submission") },
            text = { Text("This action cannot be undone.") },
            confirmButton = {
                TextButton(onClick = { onDelete(); showDeleteDialog = false }) {
                    Text("Delete", color = Negative)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun SentimentChip(sentiment: String, confidence: Double) {
    val color = when (sentiment) {
        "positive" -> Positive
        "negative" -> Negative
        "mixed" -> Mixed
        else -> Neutral
    }
    SuggestionChip(
        onClick = {},
        label = {
            Text(
                "${sentiment.replaceFirstChar { it.uppercase() }} ${(confidence * 100).toInt()}%",
                style = MaterialTheme.typography.labelSmall
            )
        },
        colors = SuggestionChipDefaults.suggestionChipColors(containerColor = color.copy(alpha = 0.15f)),
        icon = {
            val icon = when (sentiment) {
                "positive" -> Icons.Filled.SentimentSatisfied
                "negative" -> Icons.Filled.Warning
                "mixed" -> Icons.Filled.SwapHoriz
                else -> Icons.Filled.SentimentNeutral
            }
            Icon(icon, null, tint = color, modifier = Modifier.size(16.dp))
        }
    )
}

@Composable
fun UrgencyChip(score: Double) {
    val (label, color) = when {
        score >= 0.7 -> "High" to Negative
        score >= 0.4 -> "Medium" to Mixed
        else -> "Low" to Positive
    }
    SuggestionChip(
        onClick = {},
        label = { Text(label, style = MaterialTheme.typography.labelSmall) },
        colors = SuggestionChipDefaults.suggestionChipColors(containerColor = color.copy(alpha = 0.15f)),
        icon = { Icon(Icons.Filled.Bolt, null, tint = color, modifier = Modifier.size(14.dp)) }
    )
}
