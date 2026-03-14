import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../widgets/marketplace_rental_toggle.dart';

class MarketplaceSelectionScreen extends ConsumerWidget {
  const MarketplaceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SharedHeader(
            title: isHindi ? 'मार्केटप्लेस' : 'Marketplace',
            subtitle: isHindi
                ? 'अपनी जरूरत चुनें: खरीदें/बेचें या किराए पर लें'
                : 'Choose your need: Buy/Sell or Rentals',
            onLeadingPressed: () => context.go('/'),
          ),
          MarketplaceRentalToggle(
            isHindi: isHindi,
            marketplaceSelected: true,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SelectionCard(
                    title: isHindi ? 'खरीदें और बेचें' : 'Buy & Sell',
                    subtitle: isHindi 
                        ? 'फसलें और कृषि उत्पाद सीधे खरीदें या बेचें'
                        : 'Buy or sell crops and agri-products directly',
                    icon: Icons.shopping_bag_rounded,
                    color: const Color(0xFFE8F5E9),
                    iconColor: Colors.green[800]!,
                    onTap: () => context.push(RouteNames.marketplaceShop),
                  ),
                  const SizedBox(height: 24),
                  _SelectionCard(
                    title: isHindi ? 'किराए (रेंटल)' : 'Rentals',
                    subtitle: isHindi 
                        ? 'खेती के उपकरण, वाहन या जमीन किराए पर लें/दें'
                        : 'Rent or list equipment, vehicles, or land',
                    icon: Icons.vignette_rounded,
                    color: const Color(0xFFE3F2FD),
                    iconColor: Colors.blue[800]!,
                    onTap: () => context.push(RouteNames.rentalHome),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconColor.darken(20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: iconColor.darken(10).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 20, color: iconColor),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(
      a.toInt(), 
      (r * f).toInt(), 
      (g * f).toInt(), 
      (b * f).toInt()
    );
  }
}
