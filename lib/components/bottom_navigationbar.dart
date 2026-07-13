import 'package:flutter/material.dart';
import 'package:spin_app/theme/colors.dart';

class BottomNavigationbar extends StatefulWidget {
  BottomNavigationbar({super.key});

  @override
  State<BottomNavigationbar> createState() => _BottomNavigationbarState();
}

class _BottomNavigationbarState extends State<BottomNavigationbar> {
  int _currentIndex = 0;

  void onSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          selectedItemColor: AppColors.button,
          backgroundColor: AppColors.background,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.route), label: '루트'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: '히스토리'),
          ],
          onTap: onSelected,
        ),
      ),
    );
  }
}
