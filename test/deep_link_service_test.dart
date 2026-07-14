import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/core/services/deep_link_service.dart';

void main() {
  test('https 공유 링크에서 routeId를 뽑는다', () {
    expect(
      DeepLinkService.extractRouteId(
        Uri.parse('https://dsm-spin.github.io/SPIN-BE/share/?routeId=5'),
      ),
      5,
    );
    // 끝 슬래시가 없어도 동작해야 한다
    expect(
      DeepLinkService.extractRouteId(
        Uri.parse('https://dsm-spin.github.io/SPIN-BE/share?routeId=12'),
      ),
      12,
    );
  });

  test('커스텀 스킴(spinapp://)에서 routeId를 뽑는다', () {
    expect(
      DeepLinkService.extractRouteId(Uri.parse('spinapp://share?routeId=7')),
      7,
    );
  });

  test('관계없는 링크는 무시한다', () {
    expect(
      DeepLinkService.extractRouteId(Uri.parse('https://example.com/?routeId=5')),
      isNull,
    );
    expect(
      DeepLinkService.extractRouteId(
        Uri.parse('https://dsm-spin.github.io/other/?routeId=5'),
      ),
      isNull,
    );
    // routeId가 없거나 숫자가 아니면 무시
    expect(
      DeepLinkService.extractRouteId(
        Uri.parse('https://dsm-spin.github.io/SPIN-BE/share/'),
      ),
      isNull,
    );
    expect(
      DeepLinkService.extractRouteId(Uri.parse('spinapp://share?routeId=abc')),
      isNull,
    );
  });
}
