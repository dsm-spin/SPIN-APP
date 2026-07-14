import 'package:dio/dio.dart';
import 'package:spin_app/core/config/env.dart';
import 'package:spin_app/models/history_model.dart';

final _dio = Dio(BaseOptions(baseUrl: Env.baseUrl));

/// 완주 기록 목록을 서버에서 GET으로 가져온다.
///
/// 성공 시 [HistoryModel] 리스트를, 실패 시 null을 반환한다.
/// 사용 예:
/// ```dart
/// final histories = await fetchHistories();
/// ```
Future<List<HistoryModel>?> fetchHistories() async {
  try {
    final response = await _dio.get('/histories');

    if (response.statusCode == 200) {
      final data = response.data;

      // 서버 응답이 [ {...}, {...} ] 형태인 경우
      if (data is List) {
        return data
            .map((e) => HistoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 서버 응답이 { "histories": [ {...} ] } 형태로 감싸져 오는 경우
      if (data is Map<String, dynamic> && data['histories'] is List) {
        return (data['histories'] as List)
            .map((e) => HistoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return null;
  } on DioException catch (e) {
    print('Dio 에러 발생: ${e.message}');
    if (e.response != null) {
      print('서버가 뱉은 에러 데이터: ${e.response?.data}');
    }
    return null;
  } catch (e) {
    print('일반 에러 발생: $e');
    return null;
  }
}
