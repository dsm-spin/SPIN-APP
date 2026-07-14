import 'package:flutter/material.dart';
import 'package:spin_app/models/history_model.dart';

/// 히스토리 한 건의 '여행 테마'. 대표 이미지가 없는 루트에도 그 여행에 어울리는
/// 썸네일을 보여주려고, 목적과 가게 이름에서 테마를 골라 색·아이콘을 정한다.
///
/// 서버가 실제 사진([HistoryModel.photoUrl])을 주면 사진이 우선이다.
/// 나중에 테마별 실사 이미지를 넣고 싶으면 여기 [asset]만 채우면 된다.
enum TripTheme {
  cafe(Icons.local_cafe_rounded, Color(0xFFB08968), Color(0xFF7F5539)),
  drink(Icons.wine_bar_rounded, Color(0xFF8E7CC3), Color(0xFF5B4B8A)),
  food(Icons.restaurant_rounded, Color(0xFFE07A5F), Color(0xFFB4503A)),
  walk(Icons.park_rounded, Color(0xFF7FA05A), Color(0xFF4A6B33)),
  shopping(Icons.shopping_bag_rounded, Color(0xFFE0708A), Color(0xFFB04A62)),
  culture(Icons.museum_rounded, Color(0xFF6096BA), Color(0xFF386480)),
  solo(Icons.backpack_rounded, Color(0xFF4FA3A5), Color(0xFF2C6E70)),
  explore(Icons.explore_rounded, Color(0xFF8FA37E), Color(0xFF56704A));

  final IconData icon;
  final Color from;
  final Color to;

  const TripTheme(this.icon, this.from, this.to);
}

/// 테마별로 찾을 낱말. 위에서부터 먼저 걸리는 테마를 쓴다 —
/// '카페에서 한잔'처럼 여러 개가 걸리면 앞선 테마(카페)로 정해진다.
///
/// 낱말이 낱말 안에 숨어 있는 걸 조심해야 한다: '미술관'에는 '술'이 들어 있어서
/// 문화를 술보다 먼저 본다. 같은 이유로 '책'(산책), '바'(바람), '차'(자동차)처럼
/// 다른 말에 흔히 섞여 드는 한 글자 낱말은 쓰지 않는다.
const _keywords = <TripTheme, List<String>>{
  TripTheme.cafe: ['카페', '커피', '디저트', '베이커리', '빵', '브런치'],
  TripTheme.culture: ['전시', '미술', '박물관', '영화', '공연', '서점', '책방', '문화'],
  TripTheme.drink: ['술', '맥주', '와인', '이자카야', '포차', '펍', '한잔', '칵테일', '하이볼'],
  TripTheme.food: ['맛집', '밥', '식사', '점심', '저녁', '먹', '버거', '국수', '고기', '분식'],
  TripTheme.walk: ['산책', '공원', '걷', '나들이', '피크닉', '숲', '데이트'],
  TripTheme.shopping: ['쇼핑', '구경', '소품', '옷', '시장', '편집숍'],
  // 무엇을 할지는 안 적고 '혼자'라는 것만 적은 여행. 뒤에 둬서 '혼자 커피 한 잔'처럼
  // 활동이 함께 적힌 목적은 그 활동(카페)으로 먼저 잡히게 한다.
  TripTheme.solo: ['혼자', '나홀로', '혼행', '혼놀', '홀로'],
};

/// 여행 테마를 고른다. 카드 제목이 곧 [purpose]라, 그림이 제목과 따로 놀지
/// 않도록 목적에서 먼저 찾고 — 거기서 안 걸릴 때만 가게 이름을 본다.
/// (합쳐서 찾으면 '갑천 산책'인데 가게에 '카페'가 있다고 커피잔이 뜬다.)
/// 둘 다 안 걸리면 [TripTheme.explore].
TripTheme tripThemeFor({required String purpose, required String storeNames}) {
  return _themeIn(purpose) ?? _themeIn(storeNames) ?? TripTheme.explore;
}

TripTheme? _themeIn(String text) {
  for (final entry in _keywords.entries) {
    for (final keyword in entry.value) {
      if (text.contains(keyword)) return entry.key;
    }
  }
  return null;
}

/// 히스토리 카드의 대표 이미지. 서버 사진이 있으면 사진을, 없으면 여행 테마에
/// 맞춘 썸네일을 그린다.
class HistoryThumbnail extends StatelessWidget {
  final HistoryModel history;
  final double size;

  const HistoryThumbnail({super.key, required this.history, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final theme = tripThemeFor(
      purpose: history.purpose,
      storeNames: history.storeNames,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.from, theme.to],
                ),
              ),
            ),
            Center(
              child: Icon(
                theme.icon,
                size: size * 0.42,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            // 서버가 사진을 주면 테마 썸네일 위에 덮어 그린다 —
            // 사진을 받아오는 동안에도 빈 칸이 보이지 않는다.
            if (history.photoUrl.isNotEmpty)
              Image.network(
                history.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
