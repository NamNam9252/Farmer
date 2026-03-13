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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Community avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(_typeEmoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _typeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (community.isPrivate) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock_rounded, size: 14, color: AppColors.textHint),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        '${community.memberCount} ${isHindi ? "सदस्य" : "members"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
