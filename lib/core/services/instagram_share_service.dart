import 'package:flutter/services.dart';

/// 안드로이드에서 인스타그램 스토리 작성 화면으로 이미지를 직접 전달하는 네이티브 채널 래퍼.
class InstagramShareService {
  static const _channel = MethodChannel('spin_app/instagram_share');

  /// 성공적으로 인스타그램 스토리 화면을 띄우면 true, 인스타그램 미설치 등으로 실패하면 false.
  /// [contentUrl]을 주면 스토리에 링크 스티커로 첨부된다.
  static Future<bool> shareToStory(String filePath, {String? contentUrl}) async {
    try {
      final handled = await _channel.invokeMethod<bool>('shareToStory', {
        'filePath': filePath,
        'contentUrl': contentUrl,
      });
      return handled ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
