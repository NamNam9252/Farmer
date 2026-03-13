import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onConfirmAction;
  final VoidCallback? onNavigateAction;

  const MessageBubble({
    super.key,
    required this.message,
    this.onConfirmAction,
    this.onNavigateAction,
  });

  bool get isUser => message.role == 'user';

  String _normalizeMarkdown(String input) {
    if (!input.contains('|')) return input;
    final lines = input.split('\n');
    final hasTable = lines.any((line) => line.contains('|')) &&
        lines.any((line) => line.contains('|') && line.contains('---'));

    if (!hasTable) return input;

    final List<String> normalized = [];
    for (final line in lines) {
      if (line.trim().startsWith('|') && line.contains('|')) {
        final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
        if (cells.isEmpty) continue;
        if (cells.every((c) => c.replaceAll('-', '').isEmpty)) continue;
        normalized.add('- ' + cells.join(' | '));
      } else {
        normalized.add(line);
      }
    }

    return normalized.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return _buildTypingIndicator();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🌾', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF388E3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser ? AppColors.primary : Colors.black).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.imagePath != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: message.isLocalImage
                                ? Image.file(
                                    File(message.imagePath!),
                                    width: 200,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    message.imagePath!,
                                    width: 200,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],
                      MarkdownBody(
                        data: _normalizeMarkdown(message.content),
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 14.5,
                            height: 1.45,
                            color: isUser ? Colors.white : AppColors.textPrimary,
                          ),
                          strong: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUser ? Colors.white : AppColors.textPrimary,
                          ),
                          em: const TextStyle(fontStyle: FontStyle.italic),
                          listBullet: TextStyle(
                            color: isUser ? Colors.white70 : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                if (message.action != null) ...[
                  const SizedBox(height: 8),
                  _buildActionWidget(message.action!),
                ],

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildActionWidget(AgentAction action) {
    switch (action.type) {
      case 'navigate':
        return _buildNavigateButton(action);
      case 'confirm':
        return _buildConfirmButton(action);
      case 'display_data':
        return _buildDataCard(action);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigateButton(AgentAction action) {
    return GestureDetector(
      onTap: onNavigateAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action.message ?? 'Opening page...',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(AgentAction action) {
    return GestureDetector(
      onTap: onConfirmAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF57C00).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              action.message ?? 'Tap to confirm',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(AgentAction action) {
    final dataType = action.dataType;
    if (dataType == 'weather' && action.data != null) {
      return _buildWeatherMini(action.data);
    }
    if (dataType == 'market_prices' && action.data is List) {
      return _buildMarketPricesMini(action.data as List);
    }
    if (dataType == 'marketplace_items' && action.data is List) {
      return _buildItemsList(action.data as List);
    }
    if (dataType == 'communities' && action.data is List) {
      return _buildCommunitiesList(action.data as List);
    }
    if (dataType == 'crop_recommendation' && action.data != null) {
      return _buildCropRecommendation(action.data);
    }
    if (dataType == 'advisory' && action.data is List) {
      return _buildAdvisoryList(action.data as List);
    }
    if (dataType == 'user_profile' && action.data != null) {
      return _buildUserProfileCard(action.data);
    }
    if (dataType == 'crop_disease_analysis' && action.data != null) {
      return _buildDiseaseAnalysisCard(action.data);
    }
    return const SizedBox.shrink();
  }

  Widget _buildWeatherMini(dynamic data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            '${data['temp']}°C • ${data['condition']}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPricesMini(List data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Live Market Prices', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ...data.take(3).map((item) {
            final name = item['commodity'] ?? 'Unknown';
            final price = item['modalPrice'] ?? '?';
            final market = item['market'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $name: ₹$price ${market.isNotEmpty ? "($market)" : ""}', style: const TextStyle(fontSize: 12)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemsList(List data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_basket_rounded, size: 16, color: Color(0xFFF57C00)),
              SizedBox(width: 6),
              Text('Marketplace Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF57C00))),
            ],
          ),
          const SizedBox(height: 8),
          ...data.take(3).map((item) {
            final name = item['name'] ?? 'Unknown';
            final price = item['price'] ?? '?';
            final unit = item['unit'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $name — ₹$price/$unit', style: const TextStyle(fontSize: 12)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommunitiesList(List data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, size: 16, color: Color(0xFF8E24AA)),
              SizedBox(width: 6),
              Text('Communities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8E24AA))),
            ],
          ),
          const SizedBox(height: 8),
          ...data.take(3).map((item) {
            final name = item['name'] ?? 'Unknown';
            final members = item['_count']?['members'] ?? item['memberCount'] ?? '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $name ($members members)', style: const TextStyle(fontSize: 12)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCropRecommendation(dynamic data) {
    final recommendations = data['recommendations'] as List? ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Top Recommended Crops',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.take(3).map((crop) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🌱', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Estimated Profit: ₹${crop['profitEstimate'] ?? '—'}/acre',
                        style: TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                      if (crop['marketPrice'] != null)
                        Text(
                          'Market Price: ${crop['marketPrice']}',
                          style: TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdvisoryList(List data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Advisory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ...data.take(3).map((item) {
            final action = item['action'] ?? '—';
            final reason = item['reason'] ?? '';
            final risk = item['riskLevel'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $action (${risk}) — $reason', style: const TextStyle(fontSize: 12)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(dynamic data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Your Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          if (data['name'] != null) Text('Name: ${data['name']}', style: const TextStyle(fontSize: 12)),
          if (data['phone'] != null) Text('Phone: ${data['phone']}', style: const TextStyle(fontSize: 12)),
          if (data['email'] != null) Text('Email: ${data['email']}', style: const TextStyle(fontSize: 12)),
          if (data['role'] != null) Text('Role: ${data['role']}', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDiseaseAnalysisCard(dynamic data) {
    final disease = data['diseaseName'] ?? 'Unknown';
    final crop = data['cropName'] ?? 'Unknown';
    final severity = data['severity'] ?? 'low';
    final isHealthy = data['isHealthy'] ?? false;
    final treatments = data['treatments'] as List? ?? [];
    
    Color severityColor;
    switch (severity.toString().toLowerCase()) {
      case 'high': severityColor = AppColors.error; break;
      case 'medium': severityColor = AppColors.warning; break;
      default: severityColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle_outline : Icons.coronavirus_outlined,
                color: severityColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHealthy ? 'Healthy Plant Detected!' : 'Disease Detected: $disease',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Crop: $crop • Severity: ${severity.toString().toUpperCase()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (treatments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recommended Treatments:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...treatments.take(2).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $t', style: const TextStyle(fontSize: 12, height: 1.3)),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🌾', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 600 + (i * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: value * 0.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
