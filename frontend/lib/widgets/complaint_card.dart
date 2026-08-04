import 'package:flutter/material.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
    this.showReactions = false,
  });

  final ComplaintModel complaint;
  final VoidCallback? onTap;
  final bool showReactions;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.fill04,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.fill08,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(complaint.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          complaint.displayTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _displayStatus(complaint.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    complaint.shortDescription,
                    style: TextStyle(
                      color: context.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  if (complaint.location?.address != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '📍 ${complaint.location!.address}',
                      style: TextStyle(
                        color: context.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (showReactions) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _reactionChip(
                          icon: '✅',
                          label: '${complaint.verificationCount} Fixed',
                          color: const Color(0xFF4ADE80),
                        ),
                        const SizedBox(width: 8),
                        _reactionChip(
                          icon: '😐',
                          label: '${complaint.notFixedCount} Still there',
                          color: const Color(0xFFFBBF24),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reactionChip({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _displayStatus(String status) {
    final map = {
      'created': 'Created',
      'verified': 'Verified',
      'assigned': 'Assigned',
      'in_progress': 'In Progress',
      'fixed': 'Fixed ✅',
      'closed': 'Closed',
      'rejected': 'Rejected',
      'pending': 'Pending',
    };
    return map[status.toLowerCase()] ?? status;
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'fixed' || normalized == 'closed' || normalized == 'resolved') {
      return const Color(0xFF4ADE80);
    }
    if (normalized == 'in_progress' || normalized == 'assigned') {
      return const Color(0xFF60A5FA);
    }
    return const Color(0xFFFBBF24);
  }
}
