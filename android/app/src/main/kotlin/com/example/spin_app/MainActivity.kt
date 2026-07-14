package com.example.spin_app

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

private const val INSTAGRAM_PACKAGE = "com.instagram.android"
private const val CHANNEL = "spin_app/instagram_share"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToStory" -> {
                    val filePath = call.argument<String>("filePath")
                    val contentUrl = call.argument<String>("contentUrl")
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath가 필요합니다", null)
                    } else {
                        result.success(shareToInstagramStory(filePath, contentUrl))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** 인스타그램 스토리 작성 화면으로 이미지(+ 링크)를 직접 전달한다. 성공적으로 인텐트를 실행하면 true를 반환한다. */
    private fun shareToInstagramStory(filePath: String, contentUrl: String?): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        val isInstagramInstalled = try {
            packageManager.getPackageInfo(INSTAGRAM_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
        if (!isInstagramInstalled) return false

        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)

        val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
            // 캡처한 카드를 스토리 배경 이미지로 전달
            setDataAndType(uri, "image/*")
            if (!contentUrl.isNullOrBlank()) {
                // 스토리에 링크 스티커로 붙는 URL
                putExtra("content_url", contentUrl)
            }
            setPackage(INSTAGRAM_PACKAGE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        if (intent.resolveActivity(packageManager) == null) return false

        startActivity(intent)
        return true
    }
}
