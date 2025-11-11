package com.example.halo_feedback

import android.content.Context
import android.content.res.Configuration
import android.app.UiModeManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.net.toUri
import androidx.enterprise.feedback.KeyedAppState
import androidx.enterprise.feedback.KeyedAppStatesReporter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sqrt

/** HaloFeedbackPlugin - Handles all Android native feedback operations */
class HaloFeedbackPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var applicationContext: Context? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "halo_feedback")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getAndroidData" -> {
        try {
          val context = applicationContext
            ?: return result.error("CONTEXT_ERROR", "Application context not available", null)
          
          val deviceType = getDeviceType(context)
          var randomId = ""
          var intentData = mapOf<String, String?>()
          var contentProviderData = ContentProviderData(null, null, null, null, null)
          
          // Get Android ID
          val androidId = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
          ) ?: ""

          if (deviceType != "Mobile") {
            contentProviderData = handleContentProvider(context)
          } else {
            // Generate randomId (Android ID) and send KeyedAppState feedback
            randomId = androidId
            Log.i("HaloFeedbackPlugin", "Generated randomId for plugin: $randomId")
            KeyedAppStatesUtil.appFeedback(context, "TTEMM_APP", randomId)
          }

          val data = mapOf(
            "randomId" to randomId,
            "androidId" to androidId,
            "deviceType" to deviceType,
            "intentData" to mapOf(
              "message" to intentData["message"],
              "deviceId" to intentData["deviceId"],
              "tenant" to intentData["tenant"],
              "baseUrl" to null // Will be set by app's BuildConfig if needed
            ),
            "contentProviderData" to mapOf(
              "token" to contentProviderData.token,
              "refreshToken" to contentProviderData.refreshToken,
              "deviceId" to contentProviderData.deviceId,
              "baseUrl" to contentProviderData.baseUrl,
              "tenant" to contentProviderData.tenant
            )
          )
          result.success(data)
        } catch (e: Exception) {
          Log.e("HaloFeedbackPlugin", "Error in getAndroidData: ${e.message}", e)
          result.error("GET_ANDROID_DATA_ERROR", "Failed to get Android data: ${e.message}", null)
        }
      }
      "sendKeyedAppStateFeedback" -> {
        try {
          val context = applicationContext
            ?: return result.error("CONTEXT_ERROR", "Application context not available", null)
          val key = call.argument<String>("key") ?: "TTEMM_APP"
          val message = call.argument<String>("message") ?: ""
          KeyedAppStatesUtil.appFeedback(context, key, message)
          result.success(null)
        } catch (e: Exception) {
          Log.e("HaloFeedbackPlugin", "Error in sendKeyedAppStateFeedback: ${e.message}", e)
          result.error("KEYED_APP_STATE_ERROR", "Failed to send feedback: ${e.message}", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    applicationContext = null
  }

  // Device type detection
  private fun getDeviceType(context: Context): String {
    val configuration = context.resources.configuration
    val uiModeManager = context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
    val isTv = uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    val hasTouch = configuration.touchscreen != Configuration.TOUCHSCREEN_NOTOUCH

    return when {
      isIfpBasedOnManufacturer() -> "IFP"
      isTv && hasTouch && isIfpBasedOnManufacturer() && isLargeScreen(context) -> "IFP"
      isTv && !hasTouch -> "Smart TV"
      else -> "Mobile"
    }
  }

  private fun isIfpBasedOnManufacturer(): Boolean {
    val model = Build.MODEL.lowercase()
    val manufacturer = Build.MANUFACTURER.lowercase()
    val brand = Build.BRAND.lowercase()

    return model.contains("ifp") ||
        model.contains("65") ||
        manufacturer.contains("ifp") ||
        manufacturer.contains("65") ||
        brand.contains("ifp") ||
        brand.contains("65") ||
        model.contains("CONEKT") ||
        model.contains("conekt")
  }

  private fun isLargeScreen(context: Context): Boolean {
    val displayMetrics = context.resources.displayMetrics
    val widthInInches = displayMetrics.widthPixels / displayMetrics.xdpi
    val heightInInches = displayMetrics.heightPixels / displayMetrics.ydpi
    val diagonalInInches = sqrt(widthInInches * widthInInches + heightInInches * heightInInches)
    return diagonalInInches >= 24
  }

  // Content Provider data class
  private data class ContentProviderData(
    val token: String?,
    val refreshToken: String?,
    val deviceId: String?,
    val baseUrl: String?,
    val tenant: String?,
  )

  // Handle Content Provider for TV/IFP devices
  private fun handleContentProvider(context: Context): ContentProviderData {
    var token: String? = null
    var refreshToken: String? = null
    var deviceId: String? = null
    var tenant: String? = null
    var baseUrl: String? = null

    try {
      val uri = "content://com.example.providerapp.provider/data".toUri()
      val cursor = context.contentResolver.query(uri, null, null, null, null)

      Log.i("HaloFeedbackPlugin", "Cursor value :: $cursor")

      cursor?.use {
        if (it.moveToFirst()) {
          val columnCount = it.columnCount
          val columnNames = mutableListOf<String>()
          for (i in 0 until columnCount) {
            columnNames.add(it.getColumnName(i))
          }
          
          Log.d("HaloFeedbackPlugin", "Content Provider columns: $columnNames")
          
          try {
            val tokenIndex = it.getColumnIndex("token")
            if (tokenIndex >= 0) {
              token = it.getString(tokenIndex)
            }
          } catch (e: Exception) {
            Log.e("HaloFeedbackPlugin", "Error reading token column: ${e.message}")
          }

          try {
            val refreshTokenIndex = it.getColumnIndex("refreshToken")
            if (refreshTokenIndex >= 0) {
              refreshToken = it.getString(refreshTokenIndex)
            }
          } catch (e: Exception) {
            Log.e("HaloFeedbackPlugin", "Error reading refreshToken column: ${e.message}")
          }

          try {
            val deviceIdIndex = it.getColumnIndex("deviceId")
            if (deviceIdIndex >= 0) {
              deviceId = it.getString(deviceIdIndex)
            }
          } catch (e: Exception) {
            Log.e("HaloFeedbackPlugin", "Error reading deviceId column: ${e.message}")
          }

          try {
            val tenantIndex = it.getColumnIndex("tenant")
            if (tenantIndex >= 0) {
              tenant = it.getString(tenantIndex)
            }
          } catch (e: Exception) {
            Log.e("HaloFeedbackPlugin", "Error reading tenant column: ${e.message}")
          }

          Log.d("HaloFeedbackPlugin", "Fetched token: $token")
          Log.d("HaloFeedbackPlugin", "Fetched refreshToken: $refreshToken")
          Log.d("HaloFeedbackPlugin", "Fetched deviceId: $deviceId")
          Log.d("HaloFeedbackPlugin", "Fetched baseUrl: $baseUrl")
          Log.d("HaloFeedbackPlugin", "Fetched tenant: $tenant")
        } else {
          Log.w("HaloFeedbackPlugin", "Content Provider cursor is empty")
        }
      } ?: run {
        Log.e("HaloFeedbackPlugin", "Content Provider cursor is null")
      }
    } catch (e: Exception) {
      Log.e("HaloFeedbackPlugin", "Error in handleContentProvider: ${e.message}", e)
    }

    return ContentProviderData(token, refreshToken, deviceId, baseUrl, tenant)
  }
}
