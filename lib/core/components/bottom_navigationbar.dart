import 'package:flutter/material.dart';
import 'package:spin_app/pages/history/history.dart';
import 'package:spin_app/pages/home/home.dart';
import 'package:spin_app/pages/point/point_page.dart';
import 'package:spin_app/route/route.dart';

class BottomNavigationbar extends StatefulWidget {
  final int initialIndex;

  const BottomNavigationbar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigationbar> createState() => _BottomNavigationbarState();
}

class _BottomNavigationbarState extends State<BottomNavigationbar> {
  late int _currentIndex = widget.initialIndex;

  /// 포인트/루트 탭은 IndexedStack에 살아있어 한 번 읽은 데이터를 계속 들고 있다.
  /// 탭을 다시 누를 때마다 키를 바꿔 새로 만들어서 최신 상태를 읽게 한다.
  /// (예: 루트 시작 후 뒤로 가서 루트 탭을 보면, 새로 시작한 도전이 반영돼야 한다.)
  int _pointTick = 0;
  int _routeTick = 0;

  static const int _routeIndex = 1;
  static const int _pointIndex = 2;

  void onSelected(int index) {
    setState(() {
      if (index == _routeIndex) _routeTick++;
      if (index == _pointIndex) _pointTick++;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const Home(),
          RoutePage(key: ValueKey('route-$_routeTick')),
          PointPage(key: ValueKey('point-$_pointTick')),
          const History(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF6A6A6A), width: 1.0)),
        ),
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            // 탭이 4개가 되면 기본이 shifting이라, 라벨이 항상 보이도록 고정한다.
            type: BottomNavigationBarType.fixed,
            iconSize: 30,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedItemColor: Colors.green,
            backgroundColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: '홈',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.route), label: '루트'),
              BottomNavigationBarItem(
                icon: Icon(Icons.paid_rounded),
                label: '포인트',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: '히스토리'),
            ],
            onTap: onSelected,
          ),
        ),
      ),
    );
  }
}
