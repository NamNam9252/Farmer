import '../../router/route_names.dart';

class CommandConstants {
  static const Map<String, List<String>> commandMap = {
    RouteNames.home: ['home', 'main', 'dashboard', 'shuru', 'house'],
    RouteNames.disease: ['disease', 'sick', 'illness', 'upchar', 'bimari', 'kida', 'plant health'],
    RouteNames.market: ['market', 'mandi', 'shop', 'bazar', 'price'],
    RouteNames.profile: ['profile', 'me', 'account', 'khata', 'settings'],
    RouteNames.advisory: ['advisory', 'help', 'advice', 'salah', 'expert'],
    RouteNames.cropRecommendation: ['crop', 'recommendation', 'fasal', 'kheti', 'production'],
    RouteNames.marketplaceNew: ['marketplace', 'buy', 'sell', 'vyapar', 'trade', 'listing'],
    RouteNames.community: ['community', 'group', 'samuh', 'charcha', 'forum'],
  };

  static String? getRouteFromCommand(String input) {
    // Normalization: Lowercase, remove common punctuation, split into words
    final cleanInput = input.toLowerCase().replaceAll(RegExp(r'[?.,!/\\\-]'), ' ').trim();
    final words = cleanInput.split(RegExp(r'\s+'));

    // 1. Try exact matches first for single words
    for (final entry in commandMap.entries) {
      if (entry.value.contains(cleanInput)) {
        return entry.key;
      }
    }

    // 2. Keyword extraction: check if any word in the sentence matches a keyword
    // We iterate backwards through the map to preserve any specific order if needed
    for (final word in words) {
      if (word.isEmpty || word.length < 3) continue; // Skip very short words like 'to', 'me'
      
      for (final entry in commandMap.entries) {
        if (entry.value.contains(word)) {
          return entry.key;
        }
      }
    }

    return null;
  }
}
