import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationItem extends StatelessWidget {
  final String message;
  final String type;
  final bool isRead;
  final String timeAgo;

  const NotificationItem({
    super.key,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 20),
        ),
        title: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(timeAgo, style: theme.textTheme.bodySmall),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case 'formation':
        return AppColors.primary;
      case 'challenge':
        return AppColors.secondary;
      case 'facture':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case 'formation':
        return Icons.school_outlined;
      case 'challenge':
        return Icons.emoji_events_outlined;
      case 'facture':
        return Icons.receipt_long_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
