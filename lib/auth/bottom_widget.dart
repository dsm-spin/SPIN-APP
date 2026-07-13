import 'package:flutter/material.dart';
import 'package:spin_app/log_in.dart';

class BottomWidget extends StatefulWidget {
  const BottomWidget({super.key});

  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                '로그인을 아직 안하셨나요?',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 20),
            TextButton(
                onPressed: () {},
                child: Text(
                    '로그인',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF445732),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            width: 400,
            height: 60,
            child: Text(
              '로그인',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
