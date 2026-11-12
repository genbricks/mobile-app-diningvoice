package io.genbricks.diningvoice.ui.screens

import androidx.compose.foundation.layout.*
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
import io.genbricks.diningvoice.data.model.TenantFeatures
import io.genbricks.diningvoice.ui.theme.Purple
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FeatureStatusViewModel @Inject constructor(
    private val api: DiningVoiceApi
) : ViewModel() {
    private val _features = MutableStateFlow<TenantFeatures?>(null)
    val features = _features.asStateFlow()

    init { loadFeatures() }

    fun loadFeatures() {
        viewModelScope.launch {
            try {
                _features.value = api.getFeatures()
            } catch (_: Exception) {}
        }
    }
}

@Composable
fun SettingsScreen(
    onLogout: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val authState by viewModel.authState.collectAsState()
    val featureVM: FeatureStatusViewModel = hiltViewModel()
    val featuresData by featureVM.features.collectAsState()
    var showLogoutDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text("Settings", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)

        Spacer(Modifier.height(24.dp))

        featuresData?.let { tf ->
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    Text("Feature Modules", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.height(8.dp))
                    tf.modules.forEach { mod ->
                        Row(
                            Modifier.fillMaxWidth().padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(mod.label, style = MaterialTheme.typography.bodyMedium)
                            SuggestionChip(
                                onClick = {},
                                label = { Text(if (mod.enabled) "Enabled" else "Disabled", style = MaterialTheme.typography.labelSmall) },
                                colors = SuggestionChipDefaults.suggestionChipColors(
                                    containerColor = if (mod.enabled) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
                                )
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(16.dp))
        }

        authState.user?.let { user ->
            Card(Modifier.fillMaxWidth()) {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.AccountCircle, null, modifier = Modifier.size(48.dp), tint = Purple)
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(user.username, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        Text(user.email, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        user.role?.let { role ->
                            Spacer(Modifier.height(4.dp))
                            SuggestionChip(
                                onClick = {},
                                label = { Text(role.replaceFirstChar { it.uppercase() }, style = MaterialTheme.typography.labelSmall) },
                                colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Purple.copy(alpha = 0.1f))
                            )
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        Card(Modifier.fillMaxWidth()) {
            Column {
                ListItem(
                    headlineContent = { Text("Version") },
                    trailingContent = { Text("1.0.0", color = MaterialTheme.colorScheme.onSurfaceVariant) },
                    leadingContent = { Icon(Icons.Filled.Info, null) }
                )
                HorizontalDivider()
                ListItem(
                    headlineContent = { Text("DiningVoice Web") },
                    leadingContent = { Icon(Icons.Filled.Language, null) }
                )
                HorizontalDivider()
                ListItem(
                    headlineContent = { Text("GenBricks") },
                    leadingContent = { Icon(Icons.Filled.Link, null) }
                )
            }
        }

        Spacer(Modifier.height(24.dp))

        Button(
            onClick = { showLogoutDialog = true },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
        ) {
            Icon(Icons.Filled.Logout, null)
            Spacer(Modifier.width(8.dp))
            Text("Sign Out", fontWeight = FontWeight.Medium)
        }
    }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text("Sign Out") },
            text = { Text("Are you sure you want to sign out?") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.logout()
                    showLogoutDialog = false
                    onLogout()
                }) {
                    Text("Sign Out", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
