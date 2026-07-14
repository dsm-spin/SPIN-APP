import 'package:dio/dio.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/models/challenge_model.dart';

/// 루트에 대한 스탬프 챌린지를 시작한다. (POST /routes/{routeId}/challenges)
///
/// 성공 시 [ChallengeModel]을, 실패 시 null을 반환한다.
Future<ChallengeModel?> startChallenge({required int routeId}) async {
  try {
    final response = await dio.post('/routes/$routeId/challenges');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChallengeModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  } on DioException catch (e) {
    print('챌린지 시작 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return null;
  } catch (e) {
    print('챌린지 시작 일반 에러: $e');
    return null;
  }
}

/// QR 체크인 실패 사유. 서버가 상태 코드로 구분해서 내려준다.
enum CheckInError {
  /// 404: QR 코드에 해당하는 가게가 서버에 없음 (잘못된/오래된 QR)
  unknownCode,

  /// 400: 로그인한 사용자의 진행 중인 도전에 이 가게가 포함되어 있지 않음
  storeNotInChallenge,

  /// 409: 이미 체크인을 마친 가게
  alreadyCheckedIn,

  /// 네트워크 등 그 외 오류
  other,
}

/// [checkIn]의 결과. 성공이면 [data], 실패면 [error]가 채워진다.
class CheckInOutcome {
  final CheckInResult? data;
  final CheckInError? error;

  const CheckInOutcome.success(this.data) : error = null;
  const CheckInOutcome.failure(this.error) : data = null;
}

/// 스캔한 QR 원문에서 서버에 보낼 코드값을 뽑아낸다.
///
/// 가게 QR(GET /stores/{storeId}/qrcode)에는 `spin://checkin?code=<UUID>`가
/// 인코딩되어 있지만, 서버는 code 파라미터의 값만 받는다. 원문을 그대로 보내면
/// 404가 난다. 코드값만 담긴 QR도 있을 수 있으므로 그 경우는 원문을 그대로 쓴다.
String normalizeQrCheckInCode(String raw) {
  final code = Uri.tryParse(raw.trim())?.queryParameters['code'];
  return (code == null || code.isEmpty) ? raw.trim() : code;
}

/// 가게 QR 코드값으로 체크인한다. (POST /challenges/checkins)
///
/// [qrCode]에는 스캐너가 읽은 원문을 그대로 넘기면 된다 —
/// [normalizeQrCheckInCode]가 서버가 받는 형태로 변환한다.
///
/// challengeId는 보낼 필요 없다 — 서버가 이 가게를 포함한, 로그인한 사용자의
/// '진행 중'인 도전을 찾아 체크인하고, 마지막 도장이면 자동으로
/// 완주(COMPLETED) 처리한다.
Future<CheckInOutcome> checkIn({required String qrCode}) async {
  try {
    final response = await dio.post(
      '/challenges/checkins',
      data: {'qrCode': normalizeQrCheckInCode(qrCode)},
    );

    if (response.statusCode == 200) {
      return CheckInOutcome.success(
        CheckInResult.fromJson(response.data as Map<String, dynamic>),
      );
    }
    return const CheckInOutcome.failure(CheckInError.other);
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    if (status == 404) {
      return const CheckInOutcome.failure(CheckInError.unknownCode);
    }
    if (status == 400) {
      return const CheckInOutcome.failure(CheckInError.storeNotInChallenge);
    }
    if (status == 409) {
      return const CheckInOutcome.failure(CheckInError.alreadyCheckedIn);
    }
    print('체크인 실패 (status: $status): ${e.message}');
    return const CheckInOutcome.failure(CheckInError.other);
  } catch (e) {
    print('체크인 일반 에러: $e');
    return const CheckInOutcome.failure(CheckInError.other);
  }
}

/// 현재 진행 중인 챌린지의 스탬프 현황을 가져온다. (GET /challenges/current)
///
/// 진행 중인 챌린지가 없으면(404) null을 반환한다.
Future<ChallengeProgressModel?> getCurrentChallenge() async {
  try {
    final response = await dio.get('/challenges/current');

    if (response.statusCode == 200) {
      return ChallengeProgressModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return null;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    print('진행 챌린지 조회 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return null;
  } catch (e) {
    print('진행 챌린지 조회 일반 에러: $e');
    return null;
  }
}
