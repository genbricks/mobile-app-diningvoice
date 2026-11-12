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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.genbricks.diningvoice.data.api.DiningVoiceApi
import io.genbricks.diningvoice.data.model.AnalyticsData
import io.genbricks.diningvoice.data.model.IncidentStats
import io.genbricks.diningvoice.ui.theme.*
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardState(
    val analytics: AnalyticsData? = null,
    val incidentStats: IncidentStats? = null,
    val departments: List<String> = emptyList(),
    val selectedDepartment: String? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val api: DiningVoiceApi
) : ViewModel() {
    private val _state = MutableStateFlow(DashboardState())
    val state: StateFlow<DashboardState> = _state

    init { load() }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val dept = _state.value.selectedDepartment
                val analyticsDeferred = async { api.getAnalytics(category = dept) }
                val statsDeferred = async {
                    try { api.getIncidentStats() } catch (_: Exception) { null }
                }
                val deptDeferred = async {
                    try { api.getCategories() } catch (_: Exception) { emptyList() }
                }

                _state.value = _state.value.copy(
                    analytics = analyticsDeferred.await(),
                    incidentStats = statsDeferred.await(),
                    departments = deptDeferred.await(),
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load dashboard"
                )
            }
        }
    }

    fun selectDepartment(dept: String?) {
        _state.value = _state.value.copy(selectedDepartment = dept)
        load()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(viewModel: DashboardViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text(
                "Dashboard",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(4.dp))
        }

        if (state.departments.isNotEmpty()) {
            item {
                var expanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = it }
                ) {
                    OutlinedTextField(
                        value = state.selectedDepartment ?: "All Departments",
                        onValueChange = {},
                        readOnly = true,
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(),
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded) },
                        leadingIcon = { Icon(Icons.Filled.FilterList, null) }
                    )
                    ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                        DropdownMenuItem(
                            text = { Text("All Departments") },
                            onClick = {
                                viewModel.selectDepartment(null)
                                expanded = false
                            }
                        )
                        state.departments.forEach { dept ->
                            DropdownMenuItem(
                                text = { Text(dept) },
                                onClick = {
                                    viewModel.selectDepartment(dept)
                                    expanded = false
                                }
                            )
                        }
                    }
                }
            }
        }

        state.error?.let { error ->
            item {
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Warning, null, tint = MaterialTheme.colorScheme.error)
                        Spacer(Modifier.width(8.dp))
                        Text(error, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }

        state.analytics?.let { data ->
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    StatCard(
                        modifier = Modifier.weight(1f),
                        title = "Total",
                        value = "${data.sentimentStats.total}",
                        icon = Icons.Filled.Description,
                        iconTint = Purple
                    )
                    StatCard(
                        modifier = Modifier.weight(1f),
                        title = "Positive",
                        value = "${data.sentimentStats.positive}",
                        icon = Icons.Filled.SentimentSatisfied,
                        iconTint = Positive
                    )
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    StatCard(
                        modifier = Modifier.weight(1f),
                        title = "Negative",
                        value = "${data.sentimentStats.negative}",
                        icon = Icons.Filled.Warning,
                        iconTint = Negative
                    )
                    StatCard(
                        modifier = Modifier.weight(1f),
                        title = "Neutral",
                        value = "${data.sentimentStats.neutral}",
                        icon = Icons.Filled.SentimentNeutral,
                        iconTint = Neutral
                    )
                }
            }

            state.incidentStats?.let { stats ->
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        StatCard(
                            modifier = Modifier.weight(1f),
                            title = "Open Incidents",
                            value = "${stats.openCount}",
                            icon = Icons.Filled.NotificationImportant,
                            iconTint = Mixed
                        )
                        StatCard(
                            modifier = Modifier.weight(1f),
                            title = "Closed",
                            value = "${stats.closedCount}",
                            icon = Icons.Filled.CheckCircle,
                            iconTint = Positive
                        )
                    }
                }
            }

            if (data.departmentStats.isNotEmpty()) {
                item {
                    Text(
                        "Department Breakdown",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }

                items(data.departmentStats) { dept ->
                    DepartmentCard(dept)
                }
            }
        }

        if (state.isLoading) {
            item {
                Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
fun StatCard(
    modifier: Modifier = Modifier,
    title: String,
    value: String,
    icon: ImageVector,
    iconTint: androidx.compose.ui.graphics.Color
) {
    Card(modifier = modifier) {
        Column(Modifier.padding(16.dp)) {
            Icon(
                icon, null,
                tint = iconTint,
                modifier = Modifier.size(28.dp)
            )
            Spacer(Modifier.height(8.dp))
            Text(value, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text(title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun DepartmentCard(dept: io.genbricks.diningvoice.data.model.DepartmentStats) {
    var expanded by remember { mutableStateOf(false) }

    Card(
        onClick = { expanded = !expanded },
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(dept.category, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    Spacer(Modifier.height(4.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("${dept.complaints} complaints", style = MaterialTheme.typography.labelSmall, color = Negative)
                        Text("${dept.compliments} compliments", style = MaterialTheme.typography.labelSmall, color = Positive)
                        Text("${dept.total} total", style = MaterialTheme.typography.labelSmall, color = Neutral)
                    }
                }
                Icon(
                    if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                    null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            if (expanded && dept.subcategories.isNotEmpty()) {
                Spacer(Modifier.height(8.dp))
                HorizontalDivider()
                Spacer(Modifier.height(8.dp))
                dept.subcategories.forEach { sub ->
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(sub.subcategory, style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(1f))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            SuggestionChip(
                                onClick = {},
                                label = { Text("${sub.complaints}", style = MaterialTheme.typography.labelSmall) },
                                colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Negative.copy(alpha = 0.1f))
                            )
                            SuggestionChip(
                                onClick = {},
                                label = { Text("${sub.compliments}", style = MaterialTheme.typography.labelSmall) },
                                colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Positive.copy(alpha = 0.1f))
                            )
                        }
                    }
                }
            }
        }
    }
}
