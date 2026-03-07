import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global language provider — shared across all features.
/// Defaults to Hindi ('hi'). Toggle between 'hi' and 'en'.
final languageProvider = StateProvider<String>((ref) => 'hi');
