package com.company.megagenset99

import com.google.firebase.auth.FirebaseAuth
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.Call
import retrofit2.Response
import android.util.Log

// Data classes
data class RegisterRequest(
    val role: String,
    val utokens: List<String>
)

data class RegisterResponse(
    val email: String,
    val role: String,
    val utokens: List<String>
)

data class GensetsResponse(
    val email: String,
    val role: String,
    val gensets: List<Map<String, Any>>
)

// Retrofit interface
interface ApiInterface {
    @POST("api/register")
    fun register(@Body request: RegisterRequest): Call<RegisterResponse>

    @GET("api/gensets")
    fun getGensets(): Call<GensetsResponse>
}

// ApiService class
class ApiService {
    private val baseUrl = "https://mirrorapi.netlify.app"

    private val retrofit: Retrofit

    init {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        val authInterceptor = Interceptor { chain ->
            val original = chain.request()
            val token = getFirebaseIdToken()
            val request = if (token != null) {
                original.newBuilder()
                    .header("Authorization", "Bearer $token")
                    .build()
            } else {
                original
            }
            chain.proceed(request)
        }

        val client = OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .build()

        retrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    private val api: ApiInterface = retrofit.create(ApiInterface::class.java)

    private fun getFirebaseIdToken(): String? {
        return try {
            FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.result?.token
        } catch (e: Exception) {
            Log.e("ApiService", "Error getting Firebase ID token", e)
            null
        }
    }

    fun registerUser(role: String, utokens: List<String>, callback: (RegisterResponse?, String?) -> Unit) {
        val request = RegisterRequest(role, utokens)
        api.register(request).enqueue(object : retrofit2.Callback<RegisterResponse> {
            override fun onResponse(call: Call<RegisterResponse>, response: Response<RegisterResponse>) {
                if (response.isSuccessful) {
                    val registerResponse = response.body()
                    Log.d("ApiService", "Register successful: $registerResponse")
                    callback(registerResponse, null)
                } else {
                    val error = "Register failed: ${response.code()} ${response.message()}"
                    Log.e("ApiService", error)
                    callback(null, error)
                }
            }

            override fun onFailure(call: Call<RegisterResponse>, t: Throwable) {
                val error = "Register error: ${t.message}"
                Log.e("ApiService", error, t)
                callback(null, error)
            }
        })
    }

    fun getGensets(callback: (GensetsResponse?, String?) -> Unit) {
        api.getGensets().enqueue(object : retrofit2.Callback<GensetsResponse> {
            override fun onResponse(call: Call<GensetsResponse>, response: Response<GensetsResponse>) {
                if (response.isSuccessful) {
                    val gensetsResponse = response.body()
                    Log.d("ApiService", "Gensets fetched: $gensetsResponse")
                    callback(gensetsResponse, null)
                } else {
                    val error = "Gensets fetch failed: ${response.code()} ${response.message()}"
                    Log.e("ApiService", error)
                    callback(null, error)
                }
            }

            override fun onFailure(call: Call<GensetsResponse>, t: Throwable) {
                val error = "Gensets error: ${t.message}"
                Log.e("ApiService", error, t)
                callback(null, error)
            }
        })
    }
}
