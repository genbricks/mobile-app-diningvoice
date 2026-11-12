package io.genbricks.diningvoice.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import io.genbricks.diningvoice.ui.screens.*

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    data object Dashboard : Screen("dashboard", "Dashboard", Icons.Filled.BarChart)
    data object Record : Screen("record", "Record", Icons.Filled.Mic)
    data object Submissions : Screen("submissions", "Submissions", Icons.Filled.List)
    data object Incidents : Screen("incidents", "Incidents", Icons.Filled.Warning)
    data object NfcMonitoring : Screen("nfc-monitoring", "NFC", Icons.Filled.Sensors)
    data object Settings : Screen("settings", "Settings", Icons.Filled.Settings)
    data object Login : Screen("login", "Login", Icons.Filled.Lock)
    data object PublicFeedback : Screen("public-feedback", "Feedback", Icons.Filled.ChatBubble)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiningVoiceNavHost() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val authState by authViewModel.authState.collectAsState()

    val bottomNavItems = remember(authState) {
        buildList {
            add(Screen.Dashboard)
            add(Screen.Record)
            add(Screen.Submissions)
            if (authState.user?.role == "admin") {
                add(Screen.Incidents)
                add(Screen.NfcMonitoring)
            }
            add(Screen.Settings)
        }
    }

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    val showBottomBar = authState.isAuthenticated && currentRoute in bottomNavItems.map { it.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomNavItems.forEach { screen ->
                        NavigationBarItem(
                            icon = { Icon(screen.icon, contentDescription = screen.title) },
                            label = { Text(screen.title, style = MaterialTheme.typography.labelSmall) },
                            selected = navBackStackEntry?.destination?.hierarchy?.any {
                                it.route == screen.route
                            } == true,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = if (authState.isAuthenticated) Screen.Dashboard.route else Screen.Login.route,
            modifier = Modifier.padding(padding)
        ) {
            composable(Screen.Login.route) {
                LoginScreen(
                    onLoginSuccess = {
                        navController.navigate(Screen.Dashboard.route) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    }
                )
            }
            composable(Screen.Dashboard.route) {
                DashboardScreen()
            }
            composable(Screen.Record.route) {
                RecordScreen()
            }
            composable(Screen.Submissions.route) {
                SubmissionsScreen()
            }
            composable(Screen.Incidents.route) {
                IncidentsScreen()
            }
            composable(Screen.NfcMonitoring.route) {
                NfcMonitoringScreen()
            }
            composable(Screen.Settings.route) {
                SettingsScreen(
                    onLogout = {
                        navController.navigate(Screen.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }
            composable(Screen.PublicFeedback.route) {
                PublicFeedbackScreen()
            }
        }
    }
}
