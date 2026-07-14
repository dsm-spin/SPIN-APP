import 'package:dio/dio.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/models/history_model.dart';

/// 완주 히스토리 목록을 서버에서 가져온다. (GET /challenges/history)
///
/// 로그인(세션) 상태여야 한다 — 세션 쿠키는 api_client가 자동으로 실어 보낸다.
/// 성공 시 [HistoryModel] 리스트를, 실패 시 null을 반환한다.
Future<List<HistoryModel>?> fetchHistories() async {
  try {
    final response = await dio.get('/challenges/history');

    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((e) => HistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  } on DioException catch (e) {
    // 403: 로그인(세션)이 없거나 만료된 상태
    print('히스토리 조회 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return null;
  } catch (e) {
    print('히스토리 조회 일반 에러: $e');
    return null;
  }
}
