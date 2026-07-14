import 'package:flutter/material.dart';
import 'package:spin_app/pages/history/history.dart';
import 'package:spin_app/pages/home/home.dart';
import 'package:spin_app/pages/route/route_page.dart';


class BottomNavigationbar extends StatefulWidget {
  final int initialIndex;

  const BottomNavigationbar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigationbar> createState() => _BottomNavigationbarState();
}

class _BottomNavigationbarState extends State<BottomNavigationbar> {
  late int _currentIndex = widget.initialIndex;

  static const List<Widget> _pages = [
    Home(),
    RoutePage(),
    History(),
  ];

  void onSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
            iconSize: 30,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedItemColor: Colors.green,
            backgroundColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.route), label: '루트'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: '히스토리'),
            ],
            onTap: onSelected,
          ),
        ),
      ),
    );
  }
}
