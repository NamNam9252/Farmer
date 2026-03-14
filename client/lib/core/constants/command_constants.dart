import '../../router/route_names.dart';

class CommandConstants {
  static const Map<String, List<String>> commandMap = {
    RouteNames.home: [
      'home', 'main', 'dashboard', 'shuru', 'house', 'panna', 'mukhya', 'dashboard pe jao', 'ghar', 'शुरू', 'मुख्य', 'होम', 'घर'
    ],
    RouteNames.disease: [
      'disease', 'sick', 'illness', 'upchar', 'bimari', 'kida', 'plant health', 'detect', 'check plant', 'rog', 'ilaj', 'बीमारी', 'रोग', 'कीड़ा', 'इलाज', 'पौधे की जांच'
    ],
    RouteNames.market: [
      'mandi', 'crop price', 'mandi bhav', 'price', 'rate', 'bhaw', 'market price', 'mandi rate', 'मंडी', 'भाव', 'दाम', 'कीमत', 'मंडी भाव', 'फसल भाव'
    ],
    RouteNames.profile: [
      'profile', 'me', 'account', 'khata', 'settings', 'user', 'my details', 'meri profile', 'mera khata', 'प्रोफ़ाइल', 'खाता', 'मेरी जानकारी'
    ],
    RouteNames.advisory: [
      'advisory', 'help', 'advice', 'salah', 'expert', 'guide', 'farming tips', 'kheti ki salah', 'expert se pucho', 'सलाह', 'एक्सपर्ट', 'खेती की सलाह'
    ],
    RouteNames.cropRecommendation: [
      'crop', 'recommendation', 'fasal', 'kheti', 'production', 'suggestion', 'what to grow', 'konsi fasal ugaye', 'fasal sujhav', 'फसल', 'खेती', 'सुझाव', 'कौन सी फसल उगाएं'
    ],
    RouteNames.marketplaceNew: [
      'marketplace', 'bazar', 'market', 'buy', 'sell', 'vyapar', 'trade', 'listing', 'khareeda', 'bechna', 'saaman', 'item sell', 'market place', 'shop', 'बाज़ार', 'व्यापार', 'बेचना', 'खरीदना', 'सामान'
    ],
    RouteNames.community: [
      'community', 'group', 'samuh', 'charcha', 'forum', 'farmers group', 'kisan samuh', 'judna', 'समूह', 'समुदाय', 'चर्चा', 'किसान समूह'
    ],
    RouteNames.chatbot: [
      'chatbot', 'bot', 'assistant', 'sahayak', 'help me', 'madad', 'talk', 'aai sahayak', 'बॉट', 'सहायक', 'चैटबॉट', 'मदद'
    ],
    RouteNames.schemes: [
      'schemes', 'yojana', 'government', 'sarkari yojana', 'subsidy', 'help for farmers', 'kisan yojana', 'योजना', 'सरकारी योजना', 'सब्सिडी'
    ],
    RouteNames.postItem: [
      'sell item', 'post item', 'bechna hai', 'saaman bechna', 'सामान बेचना'
    ],
    RouteNames.postDemand: [
      'buy item', 'post demand', 'kharedna hai', 'demand dalna', 'खरीदने के लिए पोस्ट'
    ],
    RouteNames.weatherDetails: [
      'weather', 'mausam', 'barish', 'temperature', 'taapman', 'मौसम', 'बारिश', 'तापमान'
    ],
    RouteNames.laborListing: [
      'helper', 'labor', 'labour', 'mazdoor', 'madadgar', 'get helper', 'find helper',
      'kisan sahayak', 'helper chahiye', 'mazdoor dhundo', 'madadgar khojo', 'worker',
      'मददगार', 'मजदूर', 'हेल्पर', 'सहायक खोजें', 'मददगार खोजें'
    ],
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
