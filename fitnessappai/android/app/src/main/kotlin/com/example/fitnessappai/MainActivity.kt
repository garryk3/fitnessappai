package com.example.fitnessappai

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fitnessappai/file_saver"

    // Исключение из оптимизации батареи (задача 48.7).
    private val BATTERY_CHANNEL = "com.example.fitnessappai/battery"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSourcePath: String? = null
    private var pendingBatteryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveFile" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        if (sourcePath == null || fileName == null) {
                            result.error("INVALID_ARGS", "sourcePath and fileName required", null)
                            return@setMethodCallHandler
                        }
                        pendingSourcePath = sourcePath
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/octet-stream"
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, SAVE_FILE_REQUEST)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())

                    "requestIgnoreBatteryOptimizations" -> {
                        if (isIgnoringBatteryOptimizations()) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        // Диалог «исключить приложение из оптимизации батареи»
                        // закрывается сам: результат читаем в onActivityResult,
                        // иначе статус в приложении устарел бы до ответа.
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName"),
                        )
                        try {
                            pendingBatteryResult = result
                            startActivityForResult(intent, BATTERY_REQUEST)
                        } catch (e: Exception) {
                            pendingBatteryResult = null
                            result.error("UNAVAILABLE", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SAVE_FILE_REQUEST) {
            val result = pendingResult
            val sourcePath = pendingSourcePath
            pendingResult = null
            pendingSourcePath = null
            if (resultCode == RESULT_OK && data?.data != null && sourcePath != null) {
                try {
                    val uri: Uri = data.data!!
                    contentResolver.openOutputStream(uri)?.use { output ->
                        File(sourcePath).inputStream().use { input ->
                            input.copyTo(output)
                        }
                    }
                    result?.success(true)
                } catch (e: Exception) {
                    result?.success(false)
                }
            } else {
                result?.success(false)
            }
        }
        if (requestCode == BATTERY_REQUEST) {
            // Системный диалог закрыт — возвращаем актуальный статус: он
            // меняется только здесь, поэтому устаревать ему негде.
            val batteryResult = pendingBatteryResult
            pendingBatteryResult = null
            batteryResult?.success(isIgnoringBatteryOptimizations())
        }
    }

    companion object {
        private const val SAVE_FILE_REQUEST = 1001
        private const val BATTERY_REQUEST = 1002
    }
}
