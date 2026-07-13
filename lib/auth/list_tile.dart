import 'package:flutter/material.dart';
import 'package:spin_app/components/list_tile_component.dart';
class ListTileWidget extends StatefulWidget {
  const ListTileWidget({super.key});

  @override
  State<ListTileWidget> createState() => _ListTileWidgetState();
}

class _ListTileWidgetState extends State<ListTileWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            width: 1.0,
          color: Color(0xFFE2E6DC),
        ),
        color: Color(0xFFF5F7F2),
      ),
      child: Column(
        children: [
          CustomListTile(text: '볕들다', smalltext: '카페'),
          CustomListTile(text: '선술', smalltext: '이자카야'),
          CustomListTile(text: '궁동버거', smalltext: '수제버거'),
          CustomListTile(text: '달밤', smalltext: '디저트바'),
        ],
      ),
    );
  }
}
