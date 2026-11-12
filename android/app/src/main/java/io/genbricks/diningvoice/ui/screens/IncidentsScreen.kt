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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.genbricks.diningvoice.data.api.DiningVoiceApi
import io.genbricks.diningvoice.data.model.Incident
import io.genbricks.diningvoice.data.model.IncidentStats
import io.genbricks.diningvoice.ui.theme.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class IncidentsState(
    val incidents: List<Incident> = emptyList(),
    val stats: IncidentStats? = null,
    val selectedSentiment: String = "negative",
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class IncidentsViewModel @Inject constructor(
    private val api: DiningVoiceApi
) : ViewModel() {
    private val _state = MutableStateFlow(IncidentsState())
    val state: StateFlow<IncidentsState> = _state

    init { load() }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val sentiment = _state.value.selectedSentiment
                val incidents = api.getIncidents(sentiment = sentiment)
                val stats = try { api.getIncidentStats() } catch (_: Exception) { null }
                _state.value = _state.value.copy(
                    incidents = incidents,
                    stats = stats,
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load incidents"
                )
            }
        }
    }

    fun selectSentiment(sentiment: String) {
        _state.value = _state.value.copy(selectedSentiment = sentiment)
        load()
    }

    fun closeIncident(id: String, notes: String) {
        viewModelScope.launch {
            try {
                api.closeIncident(id, mapOf("resolution_notes" to notes))
                load()
            } catch (_: Exception) {}
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IncidentsScreen(viewModel: IncidentsViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()
    var showCloseDialog by remember { mutableStateOf<String?>(null) }
    var resolutionNotes by remember { mutableStateOf("") }

    val sentiments = listOf("negative", "positive", "neutral")
    val selectedIndex = sentiments.indexOf(state.selectedSentiment)

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Incidents", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        }

        state.stats?.let { stats ->
            item {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    MiniStatCard(Modifier.weight(1f), "Open", stats.openCount, Mixed)
                    MiniStatCard(Modifier.weight(1f), "Closed", stats.closedCount, Positive)
                    MiniStatCard(Modifier.weight(1f), "Total", stats.openCount + stats.closedCount, Purple)
                }
            }
        }

        item {
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                sentiments.forEachIndexed { index, sentiment ->
                    SegmentedButton(
                        selected = index == selectedIndex,
                        onClick = { viewModel.selectSentiment(sentiment) },
                        shape = SegmentedButtonDefaults.itemShape(index, sentiments.size)
                    ) {
                        Text(sentiment.replaceFirstChar { it.uppercase() })
                    }
                }
            }
        }

        if (state.incidents.isEmpty() && !state.isLoading) {
            item {
                Column(
                    Modifier.fillMaxWidth().padding(vertical = 48.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(Icons.Filled.VerifiedUser, null, modifier = Modifier.size(48.dp), tint = Positive)
                    Spacer(Modifier.height(12.dp))
                    Text("No Incidents", style = MaterialTheme.typography.titleMedium)
                }
            }
        }

        items(state.incidents, key = { it.id }) { incident ->
            IncidentCard(
                incident = incident,
                onClose = {
                    showCloseDialog = incident.id
                    resolutionNotes = ""
                }
            )
        }

        if (state.isLoading) {
            item {
                Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }

    showCloseDialog?.let { incidentId ->
        AlertDialog(
            onDismissRequest = { showCloseDialog = null },
            title = { Text("Close Incident") },
            text = {
                Column {
                    Text("Enter resolution notes:")
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = resolutionNotes,
                        onValueChange = { resolutionNotes = it },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 3,
                        placeholder = { Text("What was done to resolve this?") }
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.closeIncident(incidentId, resolutionNotes)
                        showCloseDialog = null
                    },
                    enabled = resolutionNotes.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(containerColor = Positive)
                ) {
                    Text("Close")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCloseDialog = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun IncidentCard(incident: Incident, onClose: () -> Unit) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    incident.incidentNumber,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(Modifier.weight(1f))
                val (label, color) = if (incident.isOpen) "Open" to Mixed else "Closed" to Positive
                SuggestionChip(
                    onClick = {},
                    label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                    colors = SuggestionChipDefaults.suggestionChipColors(containerColor = color.copy(alpha = 0.15f))
                )
            }

            incident.departmentName?.let {
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Business, null, Modifier.size(14.dp), MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(4.dp))
                    Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            incident.category?.let {
                Spacer(Modifier.height(4.dp))
                SuggestionChip(
                    onClick = {},
                    label = { Text(it, style = MaterialTheme.typography.labelSmall) },
                    colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Purple.copy(alpha = 0.1f))
                )
            }

            incident.submissionText?.let {
                Spacer(Modifier.height(6.dp))
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 2)
            }

            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(incident.createdAt.take(10), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.weight(1f))
                if (incident.isOpen) {
                    OutlinedButton(onClick = onClose, contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)) {
                        Text("Close", style = MaterialTheme.typography.labelSmall)
                    }
                }
            }

            incident.resolutionNotes?.let { notes ->
                if (notes.isNotBlank()) {
                    Spacer(Modifier.height(8.dp))
                    Card(colors = CardDefaults.cardColors(containerColor = Positive.copy(alpha = 0.05f))) {
                        Column(Modifier.padding(8.dp)) {
                            Text("Resolution", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Medium)
                            Text(notes, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MiniStatCard(modifier: Modifier, title: String, value: Int, color: androidx.compose.ui.graphics.Color) {
    Card(modifier = modifier, colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.08f))) {
        Column(Modifier.padding(12.dp).fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("$value", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = color)
            Text(title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
