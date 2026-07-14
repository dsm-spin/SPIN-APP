import 'package:flutter/material.dart';
import 'package:spin_app/core/components/history_thumbnail.dart';
import 'package:spin_app/models/history_model.dart';

class HistoryCard extends StatelessWidget {
  final HistoryModel history;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.history, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HistoryThumbnail(history: history),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 무엇을 하러 간 여행이었는지가 제목이다.
                  Text(
                    history.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFFE0708A),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          history.storeNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A6A6A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: Color(0xFF6A6A6A),
                      ),
                      const SizedBox(width: 4),
                      // 글꼴을 키운 기기에서 날짜가 카드 밖으로 밀리지 않도록.
                      Expanded(
                        child: Text(
                          history.completedAtLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A6A6A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
