import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/language_provider.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    
    return GestureDetector(
      onTap: () {
        ref.read(languageProvider.notifier).state =
            lang == 'hi' ? 'en' : 'hi';
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (color ?? AppColors.primary).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          lang == 'hi' ? 'EN' : 'हि',
          style: TextStyle(
            color: color ?? AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
