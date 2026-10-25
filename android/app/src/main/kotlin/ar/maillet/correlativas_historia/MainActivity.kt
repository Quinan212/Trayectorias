package ar.maillet.correlativas_historia

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.webkit.WebView
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterPlugin
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : FlutterFragmentActivity() {
    private val deviceIdentityChannel =
        "ar.maillet.correlativas_historia/device_identity"
    private val bibliotecaFilesChannel =
        "ar.maillet.correlativas_historia/biblioteca_files"

    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveSourcePath: String? = null

    private val createDocumentLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { activityResult ->
        val callback = pendingSaveResult
        val sourcePath = pendingSaveSourcePath
        pendingSaveResult = null
        pendingSaveSourcePath = null

        if (callback == null) return@registerForActivityResult
        val destinationUri = activityResult.data?.data
        if (activityResult.resultCode != Activity.RESULT_OK || destinationUri == null) {
            callback.success(false)
            return@registerForActivityResult
        }
        if (sourcePath.isNullOrBlank()) {
            callback.error(
                "SAVE_SOURCE_MISSING",
                "No se encontró la copia local del archivo.",
                null,
            )
            return@registerForActivityResult
        }

        val source = File(sourcePath)
        if (!source.isFile || source.length() <= 0L) {
            callback.error(
                "SAVE_SOURCE_INVALID",
                "La copia local del archivo no está disponible.",
                null,
            )
            return@registerForActivityResult
        }

        Thread {
            try {
                val output = contentResolver.openOutputStream(destinationUri, "w")
                    ?: throw IllegalStateException(
                        "Android no permitió escribir en la ubicación elegida.",
                    )
                source.inputStream().use { input ->
                    output.use { destination -> input.copyTo(destination) }
                }
                runOnUiThread { callback.success(true) }
            } catch (error: Exception) {
                runOnUiThread {
                    callback.error(
                        "SAVE_FAILED",
                        error.message
                            ?: "No se pudo guardar el archivo en el dispositivo.",
                        null,
                    )
                }
            }
        }.start()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ar.maillet.correlativas_historia/sage_webview_activity",
        ).setMethodCallHandler { call, result ->
            if (call.method != "setActive" && call.method != "release") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val identifier = call.argument<Number>("identifier")?.toLong()
            val plugin = flutterEngine.plugins.get(WebViewFlutterPlugin::class.java)
                as? WebViewFlutterPlugin
            val webView = identifier?.let {
                plugin?.instanceManager?.getInstance<WebView>(it)
            }
            if (webView == null) {
                result.success(false)
                return@setMethodCallHandler
            }
            try {
                when (call.method) {
                    "setActive" -> {
                        if (call.argument<Boolean>("active") == true) {
                            webView.onResume()
                        } else {
                            webView.onPause()
                        }
                    }
                    "release" -> {
                        // Flutter conserva la propiedad y disposición de la vista.
                        // Descargar el DOM detiene sus tareas sin borrar las cookies.
                        webView.stopLoading()
                        webView.onPause()
                        webView.loadUrl("about:blank")
                    }
                }
                result.success(true)
            } catch (error: Exception) {
                result.error("SAGE_WEBVIEW_ACTIVITY", error.message, null)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            deviceIdentityChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidDeviceId" -> {
                    val avdName = readSystemProperty("ro.boot.qemu.avd_name")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                    if (avdName != null) {
                        result.success("emu_$avdName")
                        return@setMethodCallHandler
                    }

                    val androidId = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ANDROID_ID,
                    )
                    result.success(androidId)
                }

                "getAndroidDeviceLabel" -> {
                    val avdName = readSystemProperty("ro.boot.qemu.avd_name")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                    if (avdName != null) {
                        result.success("Android Emulator ${friendlyAvdName(avdName)}")
                        return@setMethodCallHandler
                    }

                    result.success(buildDeviceLabel())
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            bibliotecaFilesChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveFileToDevice" -> saveFileToDevice(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun saveFileToDevice(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        if (pendingSaveResult != null) {
            result.error(
                "SAVE_IN_PROGRESS",
                "Ya hay un archivo esperando una ubicación de destino.",
                null,
            )
            return
        }

        val sourcePath = call.argument<String>("sourcePath")?.trim().orEmpty()
        val source = File(sourcePath)
        if (sourcePath.isEmpty() || !source.isFile || source.length() <= 0L) {
            result.error(
                "SAVE_SOURCE_INVALID",
                "La copia local del archivo no está disponible.",
                null,
            )
            return
        }

        val requestedName = call.argument<String>("fileName")?.trim().orEmpty()
        val fileName = requestedName.ifEmpty { source.name }
        val requestedMime = call.argument<String>("mimeType")?.trim().orEmpty()
        val mimeType = requestedMime.ifEmpty { "application/octet-stream" }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
        }

        pendingSaveResult = result
        pendingSaveSourcePath = sourcePath
        try {
            createDocumentLauncher.launch(intent)
        } catch (error: Exception) {
            pendingSaveResult = null
            pendingSaveSourcePath = null
            result.error(
                "SAVE_PICKER_FAILED",
                error.message ?: "No se pudo abrir el selector de archivos.",
                null,
            )
        }
    }

    private fun buildDeviceLabel(): String {
        val manufacturer = Build.MANUFACTURER?.trim().orEmpty()
        val model = Build.MODEL?.trim().orEmpty()
        if (manufacturer.equals("samsung", ignoreCase = true) &&
            model.startsWith("SM-A35", ignoreCase = true)
        ) {
            return "Samsung A35"
        }

        val prettyManufacturer = manufacturer
            .replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
        return when {
            model.isEmpty() && prettyManufacturer.isEmpty() -> "Dispositivo Android"
            prettyManufacturer.isEmpty() -> model
            model.isEmpty() -> prettyManufacturer
            model.startsWith(prettyManufacturer, ignoreCase = true) -> model
            else -> "$prettyManufacturer $model"
        }
    }

    private fun friendlyAvdName(raw: String): String {
        return raw.replace('_', ' ').trim()
    }

    private fun readSystemProperty(key: String): String? {
        return try {
            val process = ProcessBuilder("getprop", key).start()
            BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                reader.readLine()
            }
        } catch (_: Exception) {
            null
        }
    }
}
