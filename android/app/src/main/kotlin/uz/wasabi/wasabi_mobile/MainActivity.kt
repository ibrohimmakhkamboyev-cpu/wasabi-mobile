package uz.wasabi.wasabi_mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "uz.wasabi.mobile/native"
    private val locationRequestCode = 8024
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingLocationProviders: MutableList<String> = mutableListOf()
    private var activeLocationListener: LocationListener? = null
    private val locationHandler = Handler(Looper.getMainLooper())
    private val locationTimeout = Runnable {
        finishLocationFromCacheOrError("LOCATION_TIMEOUT", "location request timed out")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler {
            call,
            result ->
            val prefs = getSharedPreferences("wasabi_mobile", MODE_PRIVATE)
            when (call.method) {
                "getString" -> {
                    val key = call.argument<String>("key")
                    result.success(if (key == null) null else prefs.getString(key, null))
                }
                "setString" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key == null || value == null) {
                        result.error("INVALID_ARGS", "key and value are required", null)
                    } else {
                        prefs.edit().putString(key, value).apply()
                        result.success(null)
                    }
                }
                "remove" -> {
                    val key = call.argument<String>("key")
                    if (key != null) prefs.edit().remove(key).apply()
                    result.success(null)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("INVALID_URL", "url is required", null)
                    } else {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("OPEN_URL_FAILED", error.message, null)
                        }
                    }
                }
                "getCurrentLocation" -> {
                    if (pendingLocationResult != null) {
                        result.error("LOCATION_BUSY", "location request already running", null)
                    } else {
                        pendingLocationResult = result
                        ensureLocation()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != locationRequestCode) return
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
            sendCurrentLocation()
        } else {
            finishLocationError("LOCATION_DENIED", "location permission denied")
        }
    }

    private fun ensureLocation() {
        val fineGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (!fineGranted && !coarseGranted) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                locationRequestCode
            )
            return
        }
        sendCurrentLocation()
    }

    private fun sendCurrentLocation() {
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        bestLastKnownLocation()?.takeIf { location ->
            System.currentTimeMillis() - location.time <= 5 * 60 * 1000
        }?.let { location ->
            finishLocation(location)
            return
        }
        pendingLocationProviders = mutableListOf<String>().apply {
            if (manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                add(LocationManager.GPS_PROVIDER)
            }
            if (manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                add(LocationManager.NETWORK_PROVIDER)
            }
        }
        if (pendingLocationProviders.isEmpty()) {
            finishLocationFromCacheOrError("LOCATION_FAILED", "location provider disabled")
            return
        }

        locationHandler.removeCallbacks(locationTimeout)
        locationHandler.postDelayed(locationTimeout, 15_000)
        requestNextLocation(manager)
    }

    private fun requestNextLocation(manager: LocationManager) {
        val provider = pendingLocationProviders.removeFirstOrNull()
        if (provider == null) {
            finishLocationFromCacheOrError("LOCATION_FAILED", "location unavailable")
            return
        }
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                manager.getCurrentLocation(provider, null, mainExecutor) { location ->
                    if (location != null) finishLocation(location)
                    else requestNextLocation(manager)
                }
            } else {
                activeLocationListener?.let { manager.removeUpdates(it) }
                activeLocationListener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        finishLocation(location)
                    }

                    override fun onProviderDisabled(provider: String) {
                        requestNextLocation(manager)
                    }

                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                }
                manager.requestSingleUpdate(
                    provider,
                    activeLocationListener!!,
                    null
                )
            }
        } catch (error: Exception) {
            requestNextLocation(manager)
        }
    }

    private fun finishLocation(location: Location) {
        locationHandler.removeCallbacks(locationTimeout)
        activeLocationListener?.let {
            val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            manager.removeUpdates(it)
        }
        activeLocationListener = null
        pendingLocationProviders.clear()
        val result = pendingLocationResult
        pendingLocationResult = null
        result?.success(mapOf("lat" to location.latitude, "lng" to location.longitude))
    }

    private fun finishLocationFromCacheOrError(code: String, message: String) {
        val cached = bestLastKnownLocation()
        if (cached != null) {
            finishLocation(cached)
        } else {
            finishLocationError(code, message)
        }
    }

    private fun bestLastKnownLocation(): Location? {
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        return providers.mapNotNull { provider ->
            try {
                if (manager.isProviderEnabled(provider)) manager.getLastKnownLocation(provider) else null
            } catch (_: Exception) {
                null
            }
        }.maxByOrNull { it.time }
    }

    private fun finishLocationError(code: String, message: String) {
        locationHandler.removeCallbacks(locationTimeout)
        activeLocationListener?.let {
            val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            manager.removeUpdates(it)
        }
        activeLocationListener = null
        pendingLocationProviders.clear()
        val result = pendingLocationResult
        pendingLocationResult = null
        result?.error(code, message, null)
    }
}
