import 'package:flutter/material.dart';

import '../../data/api/translation_api.dart';

class LocalizedCardText extends StatelessWidget {
  final String text;
  final bool isHindi;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedCardText({
    super.key,
    required this.text,
    required this.isHindi,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHindi) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    return FutureBuilder<String>(
      future: TranslationApi.toHindi(text),
      builder: (context, snapshot) {
        final value = snapshot.data ?? text;
        return Text(
          value,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
