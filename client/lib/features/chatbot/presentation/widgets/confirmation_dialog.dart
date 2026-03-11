import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_models.dart';

class ConfirmationDialog extends StatelessWidget {
  final AgentAction action;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationDialog({
    super.key,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final payload = action.confirmPayload;
    final actionName = action.confirmAction ?? 'unknown';

    String title;
    IconData icon;
    Color iconColor;
    List<Widget> details = [];

    switch (actionName) {
      case 'create_marketplace_listing':
        title = 'Create Listing?';
        icon = Icons.sell_rounded;
        iconColor = AppColors.primary;
        if (payload is Map) {
          details = [
            _detailRow('Item', payload['itemName'] ?? '—'),
            _detailRow('Price', '₹${payload['pricePerUnit'] ?? '—'}/${payload['unit'] ?? ''}'),
            _detailRow('Quantity', '${payload['quantityAvailable'] ?? '—'}'),
            _detailRow('Category', '${payload['category'] ?? '—'}'),
            if (payload['description'] != null) _detailRow('Description', payload['description']),
          ];
        }
        break;
      case 'create_demand_post':
        title = 'Post Demand?';
        icon = Icons.shopping_cart_rounded;
        iconColor = const Color(0xFF1565C0);
        if (payload is Map) {
          details = [
            _detailRow('Item', payload['itemName'] ?? '—'),
            _detailRow('Budget', '₹${payload['budgetPerUnit'] ?? '—'}/${payload['unit'] ?? ''}'),
            _detailRow('Quantity', '${payload['quantityNeeded'] ?? '—'}'),
            _detailRow('Category', '${payload['category'] ?? '—'}'),
          ];
        }
        break;
      case 'join_community':
        title = 'Join Community?';
        icon = Icons.groups_rounded;
        iconColor = const Color(0xFF8E24AA);
        if (payload is Map) {
          details = [
            _detailRow('Community', payload['communityName'] ?? payload['communityId'] ?? '—'),
          ];
        }
        break;
      default:
        title = 'Confirm Action?';
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.primary;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: AppTextStyles.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              action.message ?? 'Would you like to proceed?',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Details
            if (details.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: details,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
