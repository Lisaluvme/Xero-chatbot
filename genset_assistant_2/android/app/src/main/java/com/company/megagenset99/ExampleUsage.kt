package com.company.megagenset99

import android.util.Log
import com.google.firebase.auth.FirebaseAuth

class ExampleUsage {

    private val apiService = ApiService()

    fun performPostLoginActions() {
        // Assuming user is already logged in with Firebase Google Login
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            Log.e("ExampleUsage", "User not logged in")
            return
        }

        // Get Firebase ID token
        currentUser.getIdToken(false).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val idToken = task.result?.token
                Log.d("ExampleUsage", "Firebase ID Token: $idToken")

                // Now call register API
                registerUser()
            } else {
                Log.e("ExampleUsage", "Failed to get ID token", task.exception)
            }
        }
    }

    private fun registerUser() {
        // Example: Register with role "customer" and utokens ["abc123"]
        val role = "customer"
        val utokens = listOf("abc123")

        apiService.registerUser(role, utokens) { response, error ->
            if (error != null) {
                Log.e("ExampleUsage", "Register failed: $error")
            } else {
                Log.d("ExampleUsage", "Register successful: Email=${response?.email}, Role=${response?.role}, Utokens=${response?.utokens}")

                // After register, call gensets API
                fetchGensets()
            }
        }
    }

    private fun fetchGensets() {
        apiService.getGensets { response, error ->
            if (error != null) {
                Log.e("ExampleUsage", "Gensets fetch failed: $error")
            } else {
                Log.d("ExampleUsage", "Gensets fetched: Email=${response?.email}, Role=${response?.role}")
                Log.d("ExampleUsage", "Gensets data: ${response?.gensets}")

                // Handle the gensets data as needed
                response?.gensets?.forEach { genset ->
                    Log.d("ExampleUsage", "Genset: $genset")
                }
            }
        }
    }
}
