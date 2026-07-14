import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env 파일의 값을 읽어오는 설정 클래스.
///
/// 사용 전 main()에서 [load]가 먼저 호출되어야 한다.
/// 사용 예: `Uri.parse('${Env.baseUrl}/challenges')`
class Env {
  Env._();

  static Future<void> load() => dotenv.load();

  /// 서버 주소 (예: https://api.example.com)
  static String get baseUrl {
    final value = dotenv.env['SERVER_BASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('.env에 SERVER_BASE_URL이 없습니다. .env.example을 참고해 설정하세요.');
    }
    return value;
  }
}
