package com.example.fitnessappai

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fitnessappai/file_saver"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSourcePath: String? = null

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
    }

    companion object {
        private const val SAVE_FILE_REQUEST = 1001
    }
}
