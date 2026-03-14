import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/rental_models.dart';

class RentalAssetCard extends StatelessWidget {
  final RentalAsset asset;
  final VoidCallback onTap;
  final bool isHindi;

  const RentalAssetCard({
    super.key,
    required this.asset,
    required this.onTap,
    required this.isHindi,
    this.currentUserId,
    this.onQuickAction,
    this.quickActionLabel,
  });

  final String? currentUserId;
  final VoidCallback? onQuickAction;
  final String? quickActionLabel;

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && asset.ownerId == currentUserId;
    final ownerName = asset.owner?['name'] ?? asset.owner?['email'] ?? (isHindi ? 'अज्ञात' : 'Unknown');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: asset.imageUrl != null ? Colors.grey[100] : _getTypeColor(asset.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: asset.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(asset.imageUrl!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                debugPrint('Image Load Error: $exception');
                              },
                            )
                          : null,
                    ),
                    child: asset.imageUrl == null
                        ? Icon(
                            _getTypeIcon(asset.type),
                            color: _getTypeColor(asset.type),
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isHindi ? _getTypeNameHindi(asset.type) : asset.type.name,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '₹${asset.basePrice}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          asset.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          asset.description,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!isOwner) ...[
                              const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ownerName,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else
                              const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(asset.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isHindi ? _getStatusNameHindi(asset.status) : asset.status.name,
                                style: TextStyle(
                                  color: _getStatusColor(asset.status),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
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
            if (!isOwner && onQuickAction != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onQuickAction,
                  icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                  label: Text(
                    quickActionLabel ?? (isHindi ? 'अभी किराए पर लें' : 'Rent Now'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(AssetType type) {
    switch (type) {
      case AssetType.PROPERTY: return Icons.landscape_rounded;
      case AssetType.VEHICLE: return Icons.agriculture_rounded;
      case AssetType.EQUIPMENT: return Icons.build_rounded;
      case AssetType.OTHER: return Icons.category_rounded;
    }
  }

  Color _getTypeColor(AssetType type) {
    switch (type) {
      case AssetType.PROPERTY: return Colors.brown;
      case AssetType.VEHICLE: return Colors.blue;
      case AssetType.EQUIPMENT: return Colors.orange;
      case AssetType.OTHER: return Colors.grey;
    }
  }

  String _getTypeNameHindi(AssetType type) {
    switch (type) {
      case AssetType.PROPERTY: return 'जमीन/संपत्ति';
      case AssetType.VEHICLE: return 'वाहन';
      case AssetType.EQUIPMENT: return 'उपकरण';
      case AssetType.OTHER: return 'अन्य';
    }
  }

  Color _getStatusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.AVAILABLE: return Colors.green;
      case AssetStatus.LOCKED: return Colors.orange;
      case AssetStatus.INACTIVE: return Colors.red;
    }
  }

  String _getStatusNameHindi(AssetStatus status) {
    switch (status) {
      case AssetStatus.AVAILABLE: return 'उपलब्ध';
      case AssetStatus.LOCKED: return 'बुक है';
      case AssetStatus.INACTIVE: return 'निष्क्रिय';
    }
  }
}
