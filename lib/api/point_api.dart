import 'package:dio/dio.dart';
import 'package:spin_app/api/api_client.dart';

/// 로그인한 사용자의 포인트 잔액을 가져온다. (GET /points)
///
/// 체크인 한 번마다 서버가 포인트를 적립한다.
/// 로그인(세션) 상태여야 한다 — 세션이 없으면 서버가 403을 준다.
/// 성공 시 잔액을, 실패 시 null을 반환한다.
Future<int?> fetchPointBalance() async {
  try {
    final response = await dio.get('/points');

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return (data['balance'] as num?)?.toInt() ?? 0;
    }
    return null;
  } on DioException catch (e) {
    // 403: 로그인(세션)이 없거나 만료된 상태
    print('포인트 조회 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return null;
  } catch (e) {
    print('포인트 조회 일반 에러: $e');
    return null;
  }
}
