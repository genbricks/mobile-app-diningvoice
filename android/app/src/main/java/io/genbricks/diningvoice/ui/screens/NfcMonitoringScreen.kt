package io.genbricks.diningvoice.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.genbricks.diningvoice.data.api.DiningVoiceApi
import io.genbricks.diningvoice.data.model.*
import io.genbricks.diningvoice.ui.theme.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

// ----------------------------------------------------------------- State

data class NfcMonitoringState(
    val devices: List<NfcDevice> = emptyList(),
    val tables: List<DiningTable> = emptyList(),
    val sessions: List<TableSession> = emptyList(),
    val overdueAlerts: List<OverdueSession> = emptyList(),
    val checkins: Map<String, List<ServerCheckin>> = emptyMap(),
    val settings: NfcSettings = NfcSettings(),
    val features: TenantFeatures? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

// ----------------------------------------------------------- ViewModel

@HiltViewModel
class NfcMonitoringViewModel @Inject constructor(
    private val api: DiningVoiceApi
) : ViewModel() {
    private val _state = MutableStateFlow(NfcMonitoringState())
    val state: StateFlow<NfcMonitoringState> = _state

    init { loadAll() }

    fun loadAll() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val devices = try { api.listNfcDevices() } catch (_: Exception) { emptyList() }
                val tables = try { api.listDiningTables() } catch (_: Exception) { emptyList() }
                val sessions = try { api.listTableSessions() } catch (_: Exception) { emptyList() }
                val overdue = try { api.getOverdueCheckins() } catch (_: Exception) { emptyList() }
                val settings = try { api.getNfcSettings() } catch (_: Exception) { NfcSettings() }
                val features = try { api.getFeatures() } catch (_: Exception) { null }
                _state.value = _state.value.copy(
                    devices = devices,
                    tables = tables,
                    sessions = sessions,
                    overdueAlerts = overdue,
                    settings = settings,
                    features = features,
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load NFC data"
                )
            }
        }
    }

    fun registerDevice(uid: String, type: String, label: String) {
        viewModelScope.launch {
            try {
                api.registerNfcDevice(NfcDeviceRequest(deviceUid = uid, deviceType = type, label = label))
                loadAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun createTable(number: String, section: String?, seatCount: Int, nfcDeviceId: String?) {
        viewModelScope.launch {
            try {
                api.createDiningTable(DiningTableRequest(
                    tableNumber = number,
                    section = section?.takeIf { it.isNotBlank() },
                    seatCount = seatCount,
                    nfcDeviceId = nfcDeviceId
                ))
                loadAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun openSession(tableId: String, guestCount: Int, preference: String) {
        viewModelScope.launch {
            try {
                api.openTableSession(TableSessionRequest(
                    tableId = tableId,
                    guestCount = guestCount,
                    checkinPreference = preference
                ))
                loadAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun updateSessionStatus(sessionId: String, status: String) {
        viewModelScope.launch {
            try {
                api.updateTableSession(sessionId, TableSessionUpdateRequest(status = status))
                loadAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun recordCheckin(nfcDeviceUid: String, serverMemberId: String, notes: String?) {
        viewModelScope.launch {
            try {
                api.recordNfcCheckin(CheckinRequest(
                    nfcDeviceUid = nfcDeviceUid,
                    serverMemberId = serverMemberId,
                    notes = notes?.takeIf { it.isNotBlank() }
                ))
                loadAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun loadCheckins(sessionId: String) {
        viewModelScope.launch {
            try {
                val checkins = api.getSessionCheckins(sessionId)
                _state.value = _state.value.copy(
                    checkins = _state.value.checkins + (sessionId to checkins)
                )
            } catch (_: Exception) {}
        }
    }

    fun updateNfcSettings(enabled: Boolean?, interval: Int?, grace: Int?, alertOnMissed: Boolean?) {
        viewModelScope.launch {
            try {
                api.updateNfcSettings(NfcSettingsUpdateRequest(
                    enabled = enabled,
                    checkinIntervalMinutes = interval,
                    gracePeriodMinutes = grace,
                    alertOnMissedCheckin = alertOnMissed
                ))
                loadAll()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}

// ----------------------------------------------------------- Main Screen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NfcMonitoringScreen(viewModel: NfcMonitoringViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Devices", "Tables", "Sessions", "Settings")

    Column(Modifier.fillMaxSize()) {
        // Header
        Column(Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp)) {
            Text("NFC Monitoring", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(4.dp))
        }

        // Overdue alert banner
        if (state.overdueAlerts.isNotEmpty()) {
            ElevatedCard(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                colors = CardDefaults.elevatedCardColors(containerColor = Negative.copy(alpha = 0.1f))
            ) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.NotificationsActive, null, tint = Negative, modifier = Modifier.size(24.dp))
                    Spacer(Modifier.width(8.dp))
                    Column {
                        Text(
                            "${state.overdueAlerts.size} table${if (state.overdueAlerts.size > 1) "s" else ""} need check-in",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = Negative
                        )
                        state.overdueAlerts.take(3).forEach { alert ->
                            Text(
                                "${alert.tableNumber} — ${alert.minutesOverdue} min overdue" +
                                    (alert.serverName?.let { " ($it)" } ?: ""),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }

        // Error banner
        state.error?.let { error ->
            Card(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
            ) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Warning, null, tint = MaterialTheme.colorScheme.error)
                    Spacer(Modifier.width(8.dp))
                    Text(error, style = MaterialTheme.typography.bodySmall, modifier = Modifier.weight(1f))
                    IconButton(onClick = { viewModel.clearError() }, modifier = Modifier.size(24.dp)) {
                        Icon(Icons.Filled.Close, null, modifier = Modifier.size(16.dp))
                    }
                }
            }
        }

        // Tab row
        PrimaryTabRow(selectedTabIndex = selectedTab) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text(title, style = MaterialTheme.typography.labelMedium) }
                )
            }
        }

        // Tab content
        when (selectedTab) {
            0 -> DevicesTab(state, viewModel)
            1 -> TablesTab(state, viewModel)
            2 -> SessionsTab(state, viewModel)
            3 -> NfcSettingsTab(state, viewModel)
        }

        if (state.isLoading) {
            Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        }
    }
}

// ----------------------------------------------------------- Devices Tab

@Composable
private fun DevicesTab(state: NfcMonitoringState, viewModel: NfcMonitoringViewModel) {
    var showAddDialog by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize()) {
        if (state.devices.isEmpty() && !state.isLoading) {
            Column(
                Modifier.fillMaxWidth().padding(vertical = 48.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(Icons.Filled.Nfc, null, modifier = Modifier.size(48.dp), tint = Neutral)
                Spacer(Modifier.height(12.dp))
                Text("No NFC Devices", style = MaterialTheme.typography.titleMedium)
                Text("Register your first NFC tag", style = MaterialTheme.typography.bodySmall, color = Neutral)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.devices, key = { it.deviceId }) { device ->
                    NfcDeviceCard(device)
                }
            }
        }

        FloatingActionButton(
            onClick = { showAddDialog = true },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
            containerColor = Purple
        ) {
            Icon(Icons.Filled.Add, "Register device", tint = Color.White)
        }
    }

    if (showAddDialog) {
        AddDeviceDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { uid, type, label ->
                viewModel.registerDevice(uid, type, label)
                showAddDialog = false
            }
        )
    }
}

@Composable
private fun NfcDeviceCard(device: NfcDevice) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    if (device.deviceType == "server_badge") Icons.Filled.Badge else Icons.Filled.Nfc,
                    null,
                    tint = Purple,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(Modifier.width(10.dp))
                Column(Modifier.weight(1f)) {
                    Text(device.label, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Text(device.deviceUid, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                SuggestionChip(
                    onClick = {},
                    label = {
                        Text(
                            device.deviceType.replace("_", " ").replaceFirstChar { it.uppercase() },
                            style = MaterialTheme.typography.labelSmall
                        )
                    },
                    colors = SuggestionChipDefaults.suggestionChipColors(
                        containerColor = Blue.copy(alpha = 0.1f)
                    )
                )
            }
            Spacer(Modifier.height(4.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Registered ${device.registeredAt.take(10)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.weight(1f))
                SuggestionChip(
                    onClick = {},
                    label = { Text(if (device.isActive) "Active" else "Inactive", style = MaterialTheme.typography.labelSmall) },
                    colors = SuggestionChipDefaults.suggestionChipColors(
                        containerColor = if (device.isActive) Positive.copy(alpha = 0.15f) else Neutral.copy(alpha = 0.15f)
                    )
                )
            }
        }
    }
}

@Composable
private fun AddDeviceDialog(onDismiss: () -> Unit, onConfirm: (String, String, String) -> Unit) {
    var uid by remember { mutableStateOf("") }
    var label by remember { mutableStateOf("") }
    var deviceType by remember { mutableStateOf("table_tag") }
    var typeExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Register NFC Device") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = uid,
                    onValueChange = { uid = it },
                    label = { Text("Device UID") },
                    placeholder = { Text("Scan or enter tag UID") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Filled.Nfc, null) }
                )
                OutlinedTextField(
                    value = label,
                    onValueChange = { label = it },
                    label = { Text("Label") },
                    placeholder = { Text("e.g. Table 5 Tag") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                ExposedDropdownMenuBox(
                    expanded = typeExpanded,
                    onExpandedChange = { typeExpanded = it }
                ) {
                    OutlinedTextField(
                        value = if (deviceType == "table_tag") "Table Tag" else "Server Badge",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Type") },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(typeExpanded) }
                    )
                    ExposedDropdownMenu(expanded = typeExpanded, onDismissRequest = { typeExpanded = false }) {
                        DropdownMenuItem(
                            text = { Text("Table Tag") },
                            onClick = { deviceType = "table_tag"; typeExpanded = false }
                        )
                        DropdownMenuItem(
                            text = { Text("Server Badge") },
                            onClick = { deviceType = "server_badge"; typeExpanded = false }
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(uid.trim(), deviceType, label.trim()) },
                enabled = uid.isNotBlank() && label.isNotBlank()
            ) { Text("Register") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

// ----------------------------------------------------------- Tables Tab

@Composable
private fun TablesTab(state: NfcMonitoringState, viewModel: NfcMonitoringViewModel) {
    var showAddDialog by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize()) {
        if (state.tables.isEmpty() && !state.isLoading) {
            Column(
                Modifier.fillMaxWidth().padding(vertical = 48.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(Icons.Filled.TableRestaurant, null, modifier = Modifier.size(48.dp), tint = Neutral)
                Spacer(Modifier.height(12.dp))
                Text("No Tables", style = MaterialTheme.typography.titleMedium)
                Text("Add your first dining table", style = MaterialTheme.typography.bodySmall, color = Neutral)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.tables, key = { it.tableId }) { table ->
                    DiningTableCard(table, state.devices)
                }
            }
        }

        FloatingActionButton(
            onClick = { showAddDialog = true },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
            containerColor = Purple
        ) {
            Icon(Icons.Filled.Add, "Add table", tint = Color.White)
        }
    }

    if (showAddDialog) {
        AddTableDialog(
            devices = state.devices.filter { d -> d.isActive && state.tables.none { it.nfcDeviceId == d.deviceId } },
            onDismiss = { showAddDialog = false },
            onConfirm = { number, section, seats, deviceId ->
                viewModel.createTable(number, section, seats, deviceId)
                showAddDialog = false
            }
        )
    }
}

@Composable
private fun DiningTableCard(table: DiningTable, devices: List<NfcDevice>) {
    val linkedDevice = devices.find { it.deviceId == table.nfcDeviceId }

    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.TableRestaurant, null, tint = Purple, modifier = Modifier.size(24.dp))
                Spacer(Modifier.width(10.dp))
                Text(table.tableNumber, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                table.section?.let {
                    SuggestionChip(
                        onClick = {},
                        label = { Text(it, style = MaterialTheme.typography.labelSmall) },
                        colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Purple.copy(alpha = 0.1f))
                    )
                }
            }
            Spacer(Modifier.height(6.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.People, null, Modifier.size(14.dp), MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(4.dp))
                    Text("${table.seatCount} seats", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (linkedDevice != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Nfc, null, Modifier.size(14.dp), Positive)
                        Spacer(Modifier.width(4.dp))
                        Text(linkedDevice.label, style = MaterialTheme.typography.labelSmall, color = Positive)
                    }
                } else {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.LinkOff, null, Modifier.size(14.dp), Mixed)
                        Spacer(Modifier.width(4.dp))
                        Text("No NFC tag", style = MaterialTheme.typography.labelSmall, color = Mixed)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddTableDialog(
    devices: List<NfcDevice>,
    onDismiss: () -> Unit,
    onConfirm: (String, String?, Int, String?) -> Unit
) {
    var number by remember { mutableStateOf("") }
    var section by remember { mutableStateOf("") }
    var seatCount by remember { mutableStateOf("4") }
    var selectedDeviceId by remember { mutableStateOf<String?>(null) }
    var deviceExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Dining Table") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = number,
                    onValueChange = { number = it },
                    label = { Text("Table Number") },
                    placeholder = { Text("e.g. T5, Patio-3") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                OutlinedTextField(
                    value = section,
                    onValueChange = { section = it },
                    label = { Text("Section (optional)") },
                    placeholder = { Text("e.g. Main, Patio, Bar") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                OutlinedTextField(
                    value = seatCount,
                    onValueChange = { seatCount = it.filter { c -> c.isDigit() } },
                    label = { Text("Seat Count") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                if (devices.isNotEmpty()) {
                    ExposedDropdownMenuBox(
                        expanded = deviceExpanded,
                        onExpandedChange = { deviceExpanded = it }
                    ) {
                        OutlinedTextField(
                            value = devices.find { it.deviceId == selectedDeviceId }?.label ?: "None",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("NFC Tag") },
                            modifier = Modifier.fillMaxWidth().menuAnchor(),
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(deviceExpanded) },
                            leadingIcon = { Icon(Icons.Filled.Nfc, null) }
                        )
                        ExposedDropdownMenu(expanded = deviceExpanded, onDismissRequest = { deviceExpanded = false }) {
                            DropdownMenuItem(text = { Text("None") }, onClick = { selectedDeviceId = null; deviceExpanded = false })
                            devices.forEach { d ->
                                DropdownMenuItem(
                                    text = { Text("${d.label} (${d.deviceUid.takeLast(8)})") },
                                    onClick = { selectedDeviceId = d.deviceId; deviceExpanded = false }
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(number.trim(), section.takeIf { it.isNotBlank() }, seatCount.toIntOrNull() ?: 4, selectedDeviceId) },
                enabled = number.isNotBlank()
            ) { Text("Add") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

// ----------------------------------------------------------- Sessions Tab

@Composable
private fun SessionsTab(state: NfcMonitoringState, viewModel: NfcMonitoringViewModel) {
    var showOpenDialog by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize()) {
        if (state.sessions.isEmpty() && !state.isLoading) {
            Column(
                Modifier.fillMaxWidth().padding(vertical = 48.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(Icons.Filled.DinnerDining, null, modifier = Modifier.size(48.dp), tint = Neutral)
                Spacer(Modifier.height(12.dp))
                Text("No Active Sessions", style = MaterialTheme.typography.titleMedium)
                Text("Open a session when guests are seated", style = MaterialTheme.typography.bodySmall, color = Neutral)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.sessions, key = { it.sessionId }) { session ->
                    val tableName = state.tables.find { it.tableId == session.tableId }?.tableNumber ?: "?"
                    SessionCard(
                        session = session,
                        tableNumber = tableName,
                        checkins = state.checkins[session.sessionId] ?: emptyList(),
                        onStatusChange = { status -> viewModel.updateSessionStatus(session.sessionId, status) },
                        onExpand = { viewModel.loadCheckins(session.sessionId) }
                    )
                }
            }
        }

        FloatingActionButton(
            onClick = { showOpenDialog = true },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
            containerColor = Purple
        ) {
            Icon(Icons.Filled.Add, "Open session", tint = Color.White)
        }
    }

    if (showOpenDialog) {
        OpenSessionDialog(
            tables = state.tables.filter { t ->
                t.isActive && state.sessions.none { s -> s.tableId == t.tableId && s.status != "closed" }
            },
            onDismiss = { showOpenDialog = false },
            onConfirm = { tableId, guests, pref ->
                viewModel.openSession(tableId, guests, pref)
                showOpenDialog = false
            }
        )
    }
}

@Composable
private fun SessionCard(
    session: TableSession,
    tableNumber: String,
    checkins: List<ServerCheckin>,
    onStatusChange: (String) -> Unit,
    onExpand: () -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Card(
        onClick = {
            expanded = !expanded
            if (expanded) onExpand()
        },
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.TableRestaurant, null, tint = Purple, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                Text(tableNumber, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                SessionStatusChip(session.status)
            }

            Spacer(Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.People, null, Modifier.size(14.dp), MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(4.dp))
                    Text("${session.guestCount} guests", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Timer, null, Modifier.size(14.dp), MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.width(4.dp))
                    Text(
                        session.checkinPreference.replace("_", " ").replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (session.nextCheckinDueAt != null && session.status == "food_delivered") {
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Schedule, null, Modifier.size(14.dp), Mixed)
                    Spacer(Modifier.width(4.dp))
                    Text(
                        "Next check-in: ${session.nextCheckinDueAt.substring(11, 16)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = Mixed
                    )
                }
            }

            // Action buttons
            if (session.status != "closed") {
                Spacer(Modifier.height(10.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    when (session.status) {
                        "seated" -> {
                            OutlinedButton(
                                onClick = { onStatusChange("order_placed") },
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) { Text("Order Placed", style = MaterialTheme.typography.labelSmall) }
                        }
                        "order_placed" -> {
                            OutlinedButton(
                                onClick = { onStatusChange("food_delivered") },
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) { Text("Food Delivered", style = MaterialTheme.typography.labelSmall) }
                        }
                        "food_delivered" -> {}
                    }
                    OutlinedButton(
                        onClick = { onStatusChange("closed") },
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Neutral)
                    ) { Text("Close", style = MaterialTheme.typography.labelSmall) }
                }
            }

            // Expandable check-in history
            AnimatedVisibility(visible = expanded) {
                Column {
                    Spacer(Modifier.height(8.dp))
                    HorizontalDivider()
                    Spacer(Modifier.height(8.dp))
                    Text("Check-in History", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Medium)
                    Spacer(Modifier.height(4.dp))
                    if (checkins.isEmpty()) {
                        Text("No check-ins yet", style = MaterialTheme.typography.labelSmall, color = Neutral)
                    } else {
                        checkins.forEach { ci ->
                            Row(
                                Modifier.fillMaxWidth().padding(vertical = 3.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    if (ci.wasOnTime) Icons.Filled.CheckCircle else Icons.Filled.Warning,
                                    null,
                                    modifier = Modifier.size(16.dp),
                                    tint = if (ci.wasOnTime) Positive else Negative
                                )
                                Spacer(Modifier.width(6.dp))
                                Text(ci.checkinAt.substring(11, 16), style = MaterialTheme.typography.labelSmall)
                                Spacer(Modifier.width(8.dp))
                                SuggestionChip(
                                    onClick = {},
                                    label = {
                                        Text(
                                            if (ci.wasOnTime) "On time" else "Late",
                                            style = MaterialTheme.typography.labelSmall
                                        )
                                    },
                                    colors = SuggestionChipDefaults.suggestionChipColors(
                                        containerColor = (if (ci.wasOnTime) Positive else Negative).copy(alpha = 0.1f)
                                    )
                                )
                                ci.notes?.let {
                                    Spacer(Modifier.width(6.dp))
                                    Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(4.dp))
            Row {
                Spacer(Modifier.weight(1f))
                Icon(
                    if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                    null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun SessionStatusChip(status: String) {
    val (label, color) = when (status) {
        "seated" -> "Seated" to Blue
        "order_placed" -> "Order Placed" to Mixed
        "food_delivered" -> "Food Delivered" to Positive
        "closed" -> "Closed" to Neutral
        else -> status to Neutral
    }
    SuggestionChip(
        onClick = {},
        label = { Text(label, style = MaterialTheme.typography.labelSmall) },
        colors = SuggestionChipDefaults.suggestionChipColors(containerColor = color.copy(alpha = 0.15f))
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OpenSessionDialog(
    tables: List<DiningTable>,
    onDismiss: () -> Unit,
    onConfirm: (String, Int, String) -> Unit
) {
    var selectedTableId by remember { mutableStateOf(tables.firstOrNull()?.tableId ?: "") }
    var guestCount by remember { mutableStateOf("2") }
    var preference by remember { mutableStateOf("all") }
    var tableExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Open Session") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (tables.isEmpty()) {
                    Text("No available tables", style = MaterialTheme.typography.bodySmall, color = Negative)
                } else {
                    ExposedDropdownMenuBox(
                        expanded = tableExpanded,
                        onExpandedChange = { tableExpanded = it }
                    ) {
                        OutlinedTextField(
                            value = tables.find { it.tableId == selectedTableId }?.tableNumber ?: "Select table",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Table") },
                            modifier = Modifier.fillMaxWidth().menuAnchor(),
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(tableExpanded) }
                        )
                        ExposedDropdownMenu(expanded = tableExpanded, onDismissRequest = { tableExpanded = false }) {
                            tables.forEach { t ->
                                DropdownMenuItem(
                                    text = { Text("${t.tableNumber}${t.section?.let { " ($it)" } ?: ""}") },
                                    onClick = { selectedTableId = t.tableId; tableExpanded = false }
                                )
                            }
                        }
                    }
                }

                OutlinedTextField(
                    value = guestCount,
                    onValueChange = { guestCount = it.filter { c -> c.isDigit() } },
                    label = { Text("Guest Count") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                Text("Check-in preference", style = MaterialTheme.typography.labelMedium)
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    listOf("all" to "All", "peak_only" to "Peak", "declined" to "None").forEachIndexed { i, (value, label) ->
                        SegmentedButton(
                            selected = preference == value,
                            onClick = { preference = value },
                            shape = SegmentedButtonDefaults.itemShape(i, 3)
                        ) { Text(label, style = MaterialTheme.typography.labelSmall) }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(selectedTableId, guestCount.toIntOrNull() ?: 2, preference) },
                enabled = selectedTableId.isNotBlank() && tables.isNotEmpty()
            ) { Text("Open") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

// ----------------------------------------------------------- Settings Tab

@Composable
private fun NfcSettingsTab(state: NfcMonitoringState, viewModel: NfcMonitoringViewModel) {
    var enabled by remember(state.settings) { mutableStateOf(state.settings.enabled) }
    var interval by remember(state.settings) { mutableFloatStateOf(state.settings.checkinIntervalMinutes.toFloat()) }
    var grace by remember(state.settings) { mutableFloatStateOf(state.settings.gracePeriodMinutes.toFloat()) }
    var alertOnMissed by remember(state.settings) { mutableStateOf(state.settings.alertOnMissedCheckin) }
    var hasChanges by remember { mutableStateOf(false) }

    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text("NFC Monitoring", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text("Enable server check-in tracking", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = enabled,
                            onCheckedChange = { enabled = it; hasChanges = true },
                            colors = SwitchDefaults.colors(checkedTrackColor = Purple)
                        )
                    }
                }
            }
        }

        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    Text("Check-in Interval", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        "Servers should check tables every ${interval.toInt()} minutes after food delivery",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("5", style = MaterialTheme.typography.labelSmall, color = Neutral)
                        Slider(
                            value = interval,
                            onValueChange = { interval = it; hasChanges = true },
                            valueRange = 5f..60f,
                            steps = 10,
                            modifier = Modifier.weight(1f).padding(horizontal = 8.dp),
                            colors = SliderDefaults.colors(thumbColor = Purple, activeTrackColor = Purple)
                        )
                        Text("60", style = MaterialTheme.typography.labelSmall, color = Neutral)
                    }
                    Text("${interval.toInt()} min", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Medium, modifier = Modifier.align(Alignment.CenterHorizontally))
                }
            }
        }

        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    Text("Grace Period", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        "Allow ${grace.toInt()} extra minutes before marking late",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("0", style = MaterialTheme.typography.labelSmall, color = Neutral)
                        Slider(
                            value = grace,
                            onValueChange = { grace = it; hasChanges = true },
                            valueRange = 0f..30f,
                            steps = 5,
                            modifier = Modifier.weight(1f).padding(horizontal = 8.dp),
                            colors = SliderDefaults.colors(thumbColor = Purple, activeTrackColor = Purple)
                        )
                        Text("30", style = MaterialTheme.typography.labelSmall, color = Neutral)
                    }
                    Text("${grace.toInt()} min", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Medium, modifier = Modifier.align(Alignment.CenterHorizontally))
                }
            }
        }

        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text("Alert on Missed Check-in", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text("Notify when a server misses a scheduled check-in", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = alertOnMissed,
                            onCheckedChange = { alertOnMissed = it; hasChanges = true },
                            colors = SwitchDefaults.colors(checkedTrackColor = Purple)
                        )
                    }
                }
            }
        }

        // Feature modules status
        state.features?.let { features ->
            item {
                Text("Feature Modules", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            items(features.modules) { mod ->
                Card(Modifier.fillMaxWidth()) {
                    Row(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(mod.label, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                        SuggestionChip(
                            onClick = {},
                            label = { Text(if (mod.enabled) "Enabled" else "Disabled", style = MaterialTheme.typography.labelSmall) },
                            colors = SuggestionChipDefaults.suggestionChipColors(
                                containerColor = if (mod.enabled) Positive.copy(alpha = 0.15f) else Neutral.copy(alpha = 0.15f)
                            )
                        )
                    }
                }
            }
        }

        if (hasChanges) {
            item {
                Button(
                    onClick = {
                        viewModel.updateNfcSettings(enabled, interval.toInt(), grace.toInt(), alertOnMissed)
                        hasChanges = false
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Purple)
                ) {
                    Icon(Icons.Filled.Save, null)
                    Spacer(Modifier.width(8.dp))
                    Text("Save Settings", fontWeight = FontWeight.Medium)
                }
            }
        }
    }
}
