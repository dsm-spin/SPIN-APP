import 'package:flutter/material.dart';
import 'package:spin_app/api/history_api.dart';
import 'package:spin_app/core/components/history_card.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/pages/history/history_detail.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

/// 히스토리 탭 루트. 탭 전용 Navigator를 둬서
/// 상세페이지로 이동해도 바텀바가 유지된다.
class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (context) => const HistoryList(),
      ),
    );
  }
}

class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  late Future<List<HistoryModel>?> _historiesFuture;

  @override
  void initState() {
    super.initState();
    _historiesFuture = fetchHistories();
  }

  void _reload() {
    setState(() {
      _historiesFuture = fetchHistories();
    });
  }

  // TODO: 상세 API 연동 후 서버 데이터로 교체
  static const List<StoreModel> _mockStores = [
    StoreModel(
      name: '성심당 본점',
      address: '대전광역시 00구 000로 00번길 00 1층',
      latitude: 36.3220,
      longitude: 127.4180,
    ),
    StoreModel(
      name: '리유즈',
      address: '대전광역시 00구 000로 00번길 00 1층',
      latitude: 36.3305,
      longitude: 127.4262,
    ),
    StoreModel(
      name: '몽심',
      address: '대전광역시 00구 000로 00번길 00 1층',
      latitude: 36.3252,
      longitude: 127.4335,
    ),
    StoreModel(
      name: '한빛탑',
      address: '대전광역시 00구 000로 00번길 00',
      latitude: 36.3330,
      longitude: 127.4405,
    ),
  ];

  void _openDetail(BuildContext context, HistoryModel history) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryDetail(
          history: history,
          stores: _mockStores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 30, 25, 20),
              child: Text(
                '지금까지 다녔던\n루트를 확인해보세요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<HistoryModel>?>(
                future: _historiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data;
                  if (items == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('완주 기록을 불러오지 못했어요'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return const Center(child: Text('아직 완주 기록이 없어요'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return HistoryCard(
                        history: item,
                        onTap: () => _openDetail(context, item),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
