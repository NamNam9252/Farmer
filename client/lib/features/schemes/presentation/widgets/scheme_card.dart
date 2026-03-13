import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/models/scheme_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'localized_card_text.dart';

class SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final bool isHindi;

  const SchemeCard({super.key, required this.scheme, required this.isHindi});

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  void _showDescription(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedCardText(
                          text: scheme.title,
                          isHindi: isHindi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: LocalizedCardText(
                        text: scheme.description,
                        isHindi: isHindi,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with image placeholder and badge
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE8F5E9),
                      const Color(0xFFC8E6C9).withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_rounded, 
                    size: 44, 
                    color: AppColors.primary.withValues(alpha: 0.4)
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _buildLocationBadge(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildQualifyBadge(),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryAndBenefit(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scheme.category?.toUpperCase() ??
                            (isHindi ? 'सामान्य' : 'GENERAL'),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            scheme.isNational
                                ? Colors.blue.withValues(alpha: 0.08)
                                : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scheme.isNational
                            ? (isHindi ? 'राष्ट्रीय' : 'NATIONAL')
                            : (isHindi ? 'राज्य' : 'STATE'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color:
                              scheme.isNational
                                  ? Colors.blue.shade700
                                  : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    if (scheme.maxBenefitAmount != null)
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: isHindi ? 'तक ' : 'UP TO ',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '₹${scheme.maxBenefitAmount!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (scheme.benefitUnit != null)
                              TextSpan(
                                text: ' ${scheme.benefitUnit}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LocalizedCardText(
                  text: scheme.title,
                  isHindi: isHindi,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scheme.description,
                  style: const TextStyle(
                LocalizedCardText(
                  text: scheme.description,
                  isHindi: isHindi,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (scheme.eligibility != null || scheme.deadline != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (scheme.eligibility != null) _buildEligibilityItem(),
                  if (scheme.deadline != null) ...[
                    const SizedBox(height: 8),
                    _buildDeadlineItem(),
                  ],
                ],

                const SizedBox(height: 24),
                _buildActionButtons(),
                  if (scheme.eligibility != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LocalizedCardText(
                            text:
                                '${isHindi ? 'पात्रता' : 'Eligibility'}: ${scheme.eligibility}',
                            isHindi: isHindi,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (scheme.deadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isHindi ? 'अंतिम तिथि' : 'Deadline'}: ${DateFormat('dd MMM yyyy').format(scheme.deadline!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _launchUrl(scheme.officialLink),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isHindi ? 'अभी आवेदन करें' : 'Apply Now',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _showDescription(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isHindi ? 'और जानें' : 'Learn More',
                        style: const TextStyle(
                          color: AppColors.primary,
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
    );
  }

  Widget _buildLocationBadge() {
    final isNational = scheme.isNational;
    final color = isNational ? const Color(0xFF1E88E5) : const Color(0xFFFB8C00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNational ? Icons.flag_rounded : Icons.location_on_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isNational ? 'NATIONAL' : 'STATE LEVEL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualifyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 12, color: Color(0xFF2E7D32)),
          SizedBox(width: 4),
          Text(
            'FOR YOU',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAndBenefit() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            scheme.category?.toUpperCase() ?? 'GENERAL',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (scheme.maxBenefitAmount != null)
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'UP TO ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: '₹${scheme.maxBenefitAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                if (scheme.benefitUnit != null)
                  TextSpan(
                    text: ' ${scheme.benefitUnit}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEligibilityItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Eligibility: ${scheme.eligibility}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineItem() {
    return Row(
      children: [
        const Icon(Icons.timer_outlined, size: 14, color: Colors.redAccent),
        const SizedBox(width: 8),
        Text(
          'Ends: ${DateFormat('dd MMM yyyy').format(scheme.deadline!)}',
          style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _launchUrl(scheme.officialLink),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: IconButton(
            onPressed: () => _launchUrl(scheme.officialLink),
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            tooltip: 'Learn More',
          ),
        ),
      ],
    );
  }
}
