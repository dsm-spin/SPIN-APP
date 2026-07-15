import 'package:dio/dio.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/models/route_model.dart';

/// 지역/목적 기반 루트를 생성한다. (POST /routes)
///
/// 서버가 한 번의 호출로 Claude가 추천한 서로 다른 루트 대안을 여러 개
/// (현재 3개) 배열로 내려준다 — 사용자가 그중 하나를 골라 시작하라는 뜻이다.
/// 성공 시 [RouteGenerateResult] 목록을, 실패 시 null을 반환한다.
Future<List<RouteGenerateResult>?> generateRoute({
  required String region,
  required String purpose,
  double? latitude,
  double? longitude,
}) async {
  try {
    final response = await dio.post(
      '/routes',
      data: {
        'region': region,
        'purpose': purpose,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );

    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((e) => RouteGenerateResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  } on DioException catch (e) {
    print('루트 생성 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return null;
  } catch (e) {
    print('루트 생성 일반 에러: $e');
    return null;
  }
}

/// 루트 상세를 조회한다. (GET /routes/{routeId})
///
/// 성공 시 [RouteGenerateResult]를, 실패 시 null을 반환한다.
Future<RouteGenerateResult?> getRouteDetail(int routeId) async {
  try {
    final response = await dio.get('/routes/$routeId');

    if (response.statusCode == 200) {
      return RouteGenerateResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return null;
  } on DioException catch (e) {
    print('루트 상세 조회 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return null;
  } catch (e) {
    print('루트 상세 조회 일반 에러: $e');
    return null;
  }
}
