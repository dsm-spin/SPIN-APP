import 'package:dio/dio.dart';
import 'package:spin_app/log_in_model.dart';

final dio = Dio();

Future<Loginmodel?> signupapi(String id, String password) async {
  try {
    final response = await dio.post(
      'http://52.78.224.116:8080/',
      data: {
        'username': id,
        'password': password
      },
    );
    if(response.statusCode == 200 || response.statusCode == 201) {
      print('서버 통신 성공!');

      final signupResult = Loginmodel.fromJson(response.data);
      return signupResult;
    }
    return null;
  } on DioException catch(e){
    print('Dio 에러 발생: ${e.message}');
    if(e.response != null) {
      print('서버가 뱉은 에러 데이터: ${e.response?.data}');
    }
    return null;
  } catch(e){
    print('일반 에러 발생: $e');
    return null;
  }
}