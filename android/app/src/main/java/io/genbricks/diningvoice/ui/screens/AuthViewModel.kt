package io.genbricks.diningvoice.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.genbricks.diningvoice.data.api.DiningVoiceApi
import io.genbricks.diningvoice.data.model.AuthState
import io.genbricks.diningvoice.data.model.LoginRequest
import io.genbricks.diningvoice.data.model.RegisterRequest
import io.genbricks.diningvoice.data.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val api: DiningVoiceApi,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _authState = MutableStateFlow(AuthState())
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    init {
        viewModelScope.launch {
            val token = authRepository.getToken()
            val user = authRepository.getUser()
            if (token != null && user != null) {
                _authState.value = AuthState(
                    user = user,
                    token = token,
                    isAuthenticated = true
                )
            }
        }
    }

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(isLoading = true, error = null)
            try {
                val response = api.login(LoginRequest(email, password))
                authRepository.saveToken(response.accessToken)
                authRepository.saveUser(response.user)
                _authState.value = AuthState(
                    user = response.user,
                    token = response.accessToken,
                    isAuthenticated = true
                )
            } catch (e: Exception) {
                _authState.value = _authState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Login failed"
                )
            }
        }
    }

    fun register(email: String, username: String, password: String) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(isLoading = true, error = null)
            try {
                val response = api.register(RegisterRequest(email, username, password))
                authRepository.saveToken(response.accessToken)
                authRepository.saveUser(response.user)
                _authState.value = AuthState(
                    user = response.user,
                    token = response.accessToken,
                    isAuthenticated = true
                )
            } catch (e: Exception) {
                _authState.value = _authState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Registration failed"
                )
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            try { api.logout() } catch (_: Exception) {}
            authRepository.clear()
            _authState.value = AuthState()
        }
    }

    fun clearError() {
        _authState.value = _authState.value.copy(error = null)
    }
}
