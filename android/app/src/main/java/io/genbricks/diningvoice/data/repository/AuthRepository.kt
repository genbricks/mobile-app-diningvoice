package io.genbricks.diningvoice.data.repository

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import io.genbricks.diningvoice.data.model.User
import com.google.gson.Gson
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    private val gson = Gson()

    companion object {
        val TOKEN_KEY = stringPreferencesKey("auth_token")
        val USER_KEY = stringPreferencesKey("user_data")
    }

    suspend fun saveToken(token: String) {
        dataStore.edit { it[TOKEN_KEY] = token }
    }

    suspend fun getToken(): String? =
        dataStore.data.map { it[TOKEN_KEY] }.first()

    fun getTokenSync(): String? = runBlocking {
        dataStore.data.map { it[TOKEN_KEY] }.first()
    }

    suspend fun saveUser(user: User) {
        dataStore.edit { it[USER_KEY] = gson.toJson(user) }
    }

    suspend fun getUser(): User? {
        val json = dataStore.data.map { it[USER_KEY] }.first()
        return json?.let { gson.fromJson(it, User::class.java) }
    }

    suspend fun clear() {
        dataStore.edit {
            it.remove(TOKEN_KEY)
            it.remove(USER_KEY)
        }
    }
}
