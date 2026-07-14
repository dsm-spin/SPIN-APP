import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String icontext;
  final String text;
  final String smalltext;

  const CustomListTile({
    super.key,
    required this.text,
    required this.smalltext,
    required this.icontext,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF42542A),
        radius: 18,
        child: Text(
          icontext,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      title: Row(
        children: [
          Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Text(smalltext, style: TextStyle(color: Colors.grey.withAlpha(128))),
        ],
      ),
    );
  }
}
