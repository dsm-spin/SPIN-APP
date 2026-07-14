import 'package:flutter/material.dart';
import 'package:spin_app/core/theme/colors.dart';
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.impact,
                borderRadius: BorderRadius.circular(10),
                image: history.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(history.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Color(0xFFE0708A),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          history.storeNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
                      Text(
                        history.completedAtLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6A6A6A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    history.purpose,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9A9A),
                    ),
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
