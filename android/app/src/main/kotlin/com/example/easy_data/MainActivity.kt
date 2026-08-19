package com.example.easy_data

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val channelName = "easy_data/chart_export"
    private val createPngRequest = 6201
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "savePng") {
            result.notImplemented()
            return
        }
        if (pendingResult != null) {
            result.error("export_in_progress", "Uma exportação já está em andamento.", null)
            return
        }

        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName")
        if (bytes == null || bytes.isEmpty() || fileName.isNullOrBlank()) {
            result.error("invalid_png", "O PNG ou o nome do arquivo é inválido.", null)
            return
        }

        pendingBytes = bytes
        pendingResult = result
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/png"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            startActivityForResult(intent, createPngRequest)
        } catch (error: Exception) {
            clearPending()
            result.error("destination_unavailable", "Não foi possível abrir o seletor de destino.", null)
        }
    }

    @Deprecated("Deprecated in Android, kept for compatibility with FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != createPngRequest) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingResult
        val bytes = pendingBytes
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPending()
            result?.success("cancelled")
            return
        }

        try {
            contentResolver.openOutputStream(data.data!!, "w")?.use { stream ->
                stream.write(bytes ?: throw IOException("PNG indisponível"))
                stream.flush()
            } ?: throw IOException("Destino indisponível")
            clearPending()
            result?.success("saved")
        } catch (error: Exception) {
            clearPending()
            result?.error("write_failed", "Não foi possível salvar o PNG.", null)
        }
    }

    private fun clearPending() {
        pendingBytes = null
        pendingResult = null
    }
}
