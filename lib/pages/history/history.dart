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

  /// 당겨서 새로고침. RefreshIndicator가 스피너를 유지하도록
  /// 새 요청이 끝날 때까지 기다린다.
  Future<void> _refresh() async {
    final future = fetchHistories();
    setState(() {
      _historiesFuture = future;
    });
    await future;
  }

  /// 히스토리 API는 가게 좌표/주소까지는 내려주지 않아, 방문 순서를 보여주는
  /// 루트맵을 그릴 수 있도록 이름만으로 순번별 좌표를 임의로 배치한다.
  static List<StoreModel> _storesFromHistory(HistoryModel history) {
    final names = history.storeNames
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    return [
      for (var i = 0; i < names.length; i++)
        StoreModel(
          name: names[i],
          address: '',
          latitude: -i.toDouble(),
          longitude: i.isEven ? 0 : 1,
        ),
    ];
  }

  void _openDetail(BuildContext context, HistoryModel history) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryDetail(
          history: history,
          stores: _storesFromHistory(history),
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
                    // 빈 화면에서도 당겨서 새로고침이 되도록 스크롤 영역으로 감싼다.
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: LayoutBuilder(
                        builder: (context, constraints) => ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight,
                              child: const Center(
                                child: Text('아직 완주 기록이 없어요'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                    ),
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
