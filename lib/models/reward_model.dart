/// 포인트로 교환할 수 있는 혜택 한 종류.
///
/// 서버에 혜택/교환 API가 아직 없어서, 데모용으로 기기에 고정된 목록을 둔다.
class RewardModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int cost;

  const RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.cost,
  });
}

/// 데모용 혜택 카탈로그.
const rewardCatalog = <RewardModel>[
  RewardModel(
    id: 'americano',
    title: '아메리카노 1잔 무료',
    description: '제휴 카페에서 아메리카노 1잔과 교환할 수 있어요',
    emoji: '☕',
    cost: 1500,
  ),
  RewardModel(
    id: 'dessert_discount',
    title: '디저트 20% 할인권',
    description: '제휴 디저트 매장에서 결제 시 20% 할인돼요',
    emoji: '🍰',
    cost: 800,
  ),
  RewardModel(
    id: 'juice_upgrade',
    title: '생과일주스 사이즈 업',
    description: '레귤러 주문 시 라지 사이즈로 무료 업그레이드',
    emoji: '🥤',
    cost: 600,
  ),
  RewardModel(
    id: 'burger_discount',
    title: '수제버거 세트 500원 할인',
    description: '제휴 버거 매장 세트 메뉴 결제 시 즉시 할인',
    emoji: '🍔',
    cost: 1000,
  ),
  RewardModel(
    id: 'izakaya_snack',
    title: '이자카야 기본안주 서비스',
    description: '제휴 이자카야 방문 시 기본안주를 무료로 제공',
    emoji: '🍶',
    cost: 700,
  ),
  RewardModel(
    id: 'route_discount',
    title: '다음 루트 시작 1,000P 할인',
    description: '새 루트를 시작할 때 1,000P를 즉시 할인해줘요',
    emoji: '🎟️',
    cost: 2000,
  ),
];
