import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/community.dart';

/// Card widget for displaying a community in the list.
class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.community,
    required this.isHindi,
    required this.onTap,
  });

  final CommunityEntity community;
  final bool isHindi;
  final VoidCallback onTap;

  String get _typeLabel {
    switch (community.type) {
      case 'CROP_BASED':
        return isHindi ? 'फसल आधारित' : 'Crop Based';
      case 'ROUND':
        return isHindi ? 'राउंड' : 'Round';
      case 'RADIUS_BASED':
        return isHindi ? 'क्षेत्र आधारित' : 'Area Based';
      default:
        return isHindi ? 'सामान्य' : 'General';
    }
  }

  String get _typeEmoji {
    switch (community.type) {
      case 'CROP_BASED':
        return '🌾';
      case 'ROUND':
        return '🔄';
      case 'RADIUS_BASED':
        return '📍';
      default:
        return '👥';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Community avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(_typeEmoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (community.isPrivate) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_rounded,
                            size: 13, color: AppColors.textHint),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.group_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${community.memberCount} ${isHindi ? "सदस्य" : "members"}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 24),
          ],
        ),
      ),
    );
  }
}
