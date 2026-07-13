import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String text;
  final String smalltext;
  const CustomListTile({super.key, required this.text, required this.smalltext});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 10.0,
      ),
      title: Text(
          text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

    );
  }
}
