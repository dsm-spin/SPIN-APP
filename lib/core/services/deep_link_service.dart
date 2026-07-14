import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spin_app/pages/route/route_share_preview_page.dart';

/// 공유 링크(https://dsm-spin.github.io/SPIN-BE/share/?routeId=N)로 앱이
/// 열렸을 때, 루트 미리보기 화면으로 이동시킨다.
///
/// - Android: App Links (AndroidManifest.xml의 intent-filter)
/// - iOS: Universal Links (Runner.entitlements의 Associated Domains)
/// 두 플랫폼 모두 dsm-spin.github.io 도메인에 검증 파일
/// (assetlinks.json / apple-app-site-association)이 올라가 있어야 실제
/// 링크 탭으로 앱이 열린다. 검증 파일 없이도 adb/simctl로 URI를 직접 흘려
/// 넣어 이 라우팅 로직 자체는 테스트할 수 있다.
class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // 앱이 완전히 종료된 상태에서 링크로 처음 열린 경우
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handle(navigatorKey, initialUri);
    }

    // 앱이 이미 떠 있는 상태(백그라운드 포함)에서 링크로 들어온 경우
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handle(navigatorKey, uri),
    );
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _handle(GlobalKey<NavigatorState> navigatorKey, Uri uri) {
    final routeId = extractRouteId(uri);
    if (routeId == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RouteSharePreviewPage(routeId: routeId),
      ),
    );
  }

  /// 두 가지 형태의 공유 링크에서 routeId를 뽑는다.
  /// - App Links:   https://dsm-spin.github.io/SPIN-BE/share/?routeId=5
  /// - 커스텀 스킴:  spinapp://share?routeId=5
  ///   (인스타그램 인앱 브라우저에서는 https 링크가 앱으로 안 열려서,
  ///    공유 웹페이지의 "앱에서 열기" 버튼이 이 스킴을 대신 쓴다)
  @visibleForTesting
  static int? extractRouteId(Uri uri) {
    if (uri.scheme == 'spinapp') {
      return int.tryParse(uri.queryParameters['routeId'] ?? '');
    }
    if (uri.host != 'dsm-spin.github.io') return null;
    if (!uri.path.startsWith('/SPIN-BE/share')) return null;
    return int.tryParse(uri.queryParameters['routeId'] ?? '');
  }
}
