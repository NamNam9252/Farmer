/// Inline SVG icon strings for the Kisan Saathi app.
/// Rendered via flutter_svg's SvgPicture.string().
/// All icons are 100×100 viewBox, colorful illustrated style.
class AppIcons {
  AppIcons._();

  // ─────────────────────────────────────────────
  //  SERVICE ICONS
  // ─────────────────────────────────────────────

  /// Market / Mandi — orange price tag + stall awning
  static const String market = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Awning -->
  <path d="M10 42 Q50 22 90 42 L82 52 Q50 38 18 52Z" fill="#FF8F00"/>
  <!-- Stall body -->
  <rect x="18" y="52" width="64" height="30" rx="4" fill="#FFF3E0"/>
  <rect x="18" y="52" width="64" height="8" fill="#FFB300"/>
  <!-- Counter -->
  <rect x="22" y="70" width="56" height="10" rx="3" fill="#FF8F00"/>
  <!-- Price tag -->
  <circle cx="70" cy="35" r="10" fill="#FFFFFF" stroke="#FF8F00" stroke-width="2.5"/>
  <text x="70" y="39" text-anchor="middle" font-size="9" font-weight="bold" fill="#FF8F00">₹</text>
  <!-- Side poles -->
  <rect x="22" y="52" width="4" height="30" rx="2" fill="#E65100"/>
  <rect x="74" y="52" width="4" height="30" rx="2" fill="#E65100"/>
  <!-- Products -->
  <circle cx="38" cy="66" r="5" fill="#66BB6A"/>
  <circle cx="50" cy="64" r="6" fill="#FF7043"/>
  <circle cx="63" cy="66" r="5" fill="#FDD835"/>
</svg>
''';

  /// Marketplace — green shopping basket with leaf
  static const String marketplace = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Basket handles -->
  <path d="M30 45 Q30 28 50 28 Q70 28 70 45" fill="none" stroke="#2E7D32" stroke-width="5" stroke-linecap="round"/>
  <!-- Basket body -->
  <rect x="20" y="44" width="60" height="36" rx="8" fill="#E8F5E9"/>
  <rect x="20" y="44" width="60" height="10" rx="8" fill="#4CAF50"/>
  <!-- Basket weave lines -->
  <line x1="33" y1="54" x2="33" y2="80" stroke="#A5D6A7" stroke-width="1.5"/>
  <line x1="46" y1="54" x2="46" y2="80" stroke="#A5D6A7" stroke-width="1.5"/>
  <line x1="59" y1="54" x2="59" y2="80" stroke="#A5D6A7" stroke-width="1.5"/>
  <line x1="72" y1="54" x2="72" y2="80" stroke="#A5D6A7" stroke-width="1.5"/>
  <!-- Leaf badge -->
  <circle cx="72" cy="28" r="12" fill="#2E7D32"/>
  <path d="M72 22 Q78 28 72 34 Q66 28 72 22Z" fill="#A5D6A7"/>
  <line x1="72" y1="22" x2="72" y2="34" stroke="#A5D6A7" stroke-width="1"/>
  <!-- Products in basket -->
  <circle cx="38" cy="65" r="7" fill="#FF7043"/>
  <circle cx="52" cy="63" r="8" fill="#66BB6A"/>
  <circle cx="65" cy="65" r="6" fill="#FDD835"/>
</svg>
''';

  /// Crop Advisory — hands holding a plant sprout
  static const String advisory = cropAdvisory;
  static const String cropAdvisory = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Hands cupped -->
  <path d="M15 65 Q15 55 25 52 L40 50 Q45 50 45 55 L45 75 Q35 82 25 80Z" fill="#FFCC80"/>
  <path d="M85 65 Q85 55 75 52 L60 50 Q55 50 55 55 L55 75 Q65 82 75 80Z" fill="#FFCC80"/>
  <path d="M20 72 Q50 85 80 72" fill="#FFB74D" stroke="none"/>
  <!-- Soil -->
  <ellipse cx="50" cy="58" rx="18" ry="7" fill="#8D6E63"/>
  <!-- Stem -->
  <line x1="50" y1="58" x2="50" y2="30" stroke="#4CAF50" stroke-width="4" stroke-linecap="round"/>
  <!-- Leaves -->
  <path d="M50 40 Q38 32 35 22 Q46 24 50 34Z" fill="#66BB6A"/>
  <path d="M50 40 Q62 32 65 22 Q54 24 50 34Z" fill="#2E7D32"/>
  <!-- Sprout top -->
  <circle cx="50" cy="28" r="5" fill="#A5D6A7"/>
  <path d="M50 24 Q54 20 50 18 Q46 20 50 24Z" fill="#4CAF50"/>
</svg>
''';

  /// Disease Detection — leaf with magnifying glass and bug
  static const String disease = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Leaf -->
  <path d="M20 80 Q20 35 65 18 Q72 55 45 75Z" fill="#A5D6A7" stroke="#2E7D32" stroke-width="2"/>
  <path d="M20 80 Q42 65 65 18" fill="none" stroke="#2E7D32" stroke-width="2"/>
  <path d="M20 80 Q30 55 50 45" fill="none" stroke="#A5D6A7" stroke-width="1.5"/>
  <!-- Bug spots -->
  <circle cx="38" cy="58" r="5" fill="#E53935" opacity="0.8"/>
  <circle cx="48" cy="45" r="4" fill="#E53935" opacity="0.7"/>
  <circle cx="32" cy="68" r="3" fill="#E53935" opacity="0.6"/>
  <!-- Magnifying glass -->
  <circle cx="70" cy="65" r="18" fill="white" stroke="#1E88E5" stroke-width="4"/>
  <circle cx="70" cy="65" r="12" fill="#E3F2FD" opacity="0.8"/>
  <line x1="83" y1="78" x2="93" y2="88" stroke="#1565C0" stroke-width="5" stroke-linecap="round"/>
  <!-- Bug in lens -->
  <ellipse cx="70" cy="64" rx="5" ry="3" fill="#E53935"/>
  <circle cx="70" cy="60" r="3" fill="#B71C1C"/>
  <line x1="66" y1="62" x2="62" y2="58" stroke="#B71C1C" stroke-width="1.5"/>
  <line x1="66" y1="65" x2="61" y2="65" stroke="#B71C1C" stroke-width="1.5"/>
  <line x1="74" y1="62" x2="78" y2="58" stroke="#B71C1C" stroke-width="1.5"/>
  <line x1="74" y1="65" x2="79" y2="65" stroke="#B71C1C" stroke-width="1.5"/>
</svg>
''';

  /// Govt Schemes — scroll/document with star badge
  static const String schemes = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Scroll body -->
  <rect x="22" y="18" width="56" height="65" rx="6" fill="#E3F2FD"/>
  <rect x="22" y="18" width="56" height="65" rx="6" fill="none" stroke="#1565C0" stroke-width="2.5"/>
  <!-- Scroll ends -->
  <ellipse cx="50" cy="18" rx="28" ry="7" fill="#BBDEFB" stroke="#1565C0" stroke-width="2"/>
  <ellipse cx="50" cy="83" rx="28" ry="7" fill="#BBDEFB" stroke="#1565C0" stroke-width="2"/>
  <!-- Text lines -->
  <rect x="32" y="30" width="36" height="4" rx="2" fill="#90CAF9"/>
  <rect x="32" y="40" width="28" height="4" rx="2" fill="#90CAF9"/>
  <rect x="32" y="50" width="32" height="4" rx="2" fill="#90CAF9"/>
  <!-- Star badge -->
  <circle cx="72" cy="25" r="14" fill="#FFF9C4" stroke="#F9A825" stroke-width="2.5"/>
  <path d="M72 14 L74.5 21 L82 21 L76 25.5 L78.5 32.5 L72 28 L65.5 32.5 L68 25.5 L62 21 L69.5 21Z" fill="#F9A825"/>
  <!-- Ashoka-like element -->
  <circle cx="50" cy="62" r="8" fill="none" stroke="#1565C0" stroke-width="2"/>
  <circle cx="50" cy="62" r="2" fill="#1565C0"/>
</svg>
''';

  /// Community Fund — three people with coins/hands
  static const String community = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Center person -->
  <circle cx="50" cy="30" r="12" fill="#CE93D8"/>
  <path d="M30 72 Q30 55 50 55 Q70 55 70 72" fill="#8E24AA"/>
  <!-- Left person -->
  <circle cx="22" cy="35" r="9" fill="#F48FB1"/>
  <path d="M8 72 Q8 58 22 58 Q36 58 36 72" fill="#E91E63" opacity="0.7"/>
  <!-- Right person -->
  <circle cx="78" cy="35" r="9" fill="#80DEEA"/>
  <path d="M64 72 Q64 58 78 58 Q92 58 92 72" fill="#00ACC1" opacity="0.7"/>
  <!-- Coin/handshake in center -->
  <circle cx="50" cy="82" r="10" fill="#FDD835" stroke="#F9A825" stroke-width="2"/>
  <text x="50" y="86" text-anchor="middle" font-size="10" font-weight="bold" fill="#FF8F00">₹</text>
  <!-- Connection lines -->
  <line x1="28" y1="72" x2="40" y2="78" stroke="#9C27B0" stroke-width="2" stroke-dasharray="3"/>
  <line x1="72" y1="72" x2="60" y2="78" stroke="#9C27B0" stroke-width="2" stroke-dasharray="3"/>
</svg>
''';

  /// Smart Farming — analytics graph + plant
  static const String smartFarming = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Chart background -->
  <rect x="12" y="20" width="76" height="55" rx="8" fill="#E0F2F1"/>
  <rect x="12" y="20" width="76" height="55" rx="8" fill="none" stroke="#00897B" stroke-width="2.5"/>
  <!-- Grid lines -->
  <line x1="22" y1="55" x2="78" y2="55" stroke="#B2DFDB" stroke-width="1"/>
  <line x1="22" y1="43" x2="78" y2="43" stroke="#B2DFDB" stroke-width="1"/>
  <line x1="22" y1="31" x2="78" y2="31" stroke="#B2DFDB" stroke-width="1"/>
  <!-- Bar chart -->
  <rect x="26" y="48" width="10" height="17" rx="2" fill="#4DB6AC"/>
  <rect x="42" y="38" width="10" height="27" rx="2" fill="#00897B"/>
  <rect x="58" y="30" width="10" height="35" rx="2" fill="#00695C"/>
  <!-- Trend line -->
  <polyline points="31,48 47,38 63,30" fill="none" stroke="#F9A825" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="31" cy="48" r="3" fill="#F9A825"/>
  <circle cx="47" cy="38" r="3" fill="#F9A825"/>
  <circle cx="63" cy="30" r="3" fill="#F9A825"/>
  <!-- Plant icon -->
  <circle cx="78" cy="28" r="12" fill="#4CAF50"/>
  <path d="M78 22 Q83 27 78 32 Q73 27 78 22Z" fill="white"/>
  <line x1="78" y1="22" x2="78" y2="32" stroke="white" stroke-width="1"/>
  <!-- Axis -->
  <line x1="22" y1="65" x2="78" y2="65" stroke="#00897B" stroke-width="2"/>
  <line x1="22" y1="29" x2="22" y2="65" stroke="#00897B" stroke-width="2"/>
  <!-- Label -->
  <text x="50" y="85" text-anchor="middle" font-size="9" font-weight="bold" fill="#00695C">SMART</text>
</svg>
''';

  /// Warehouse — barn building with grain
  static const String warehouse = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Roof -->
  <path d="M10 45 L50 15 L90 45Z" fill="#8D6E63"/>
  <path d="M10 45 L50 15 L90 45Z" fill="none" stroke="#5D4037" stroke-width="2"/>
  <!-- Building body -->
  <rect x="15" y="44" width="70" height="42" rx="3" fill="#EFEBE9"/>
  <rect x="15" y="44" width="70" height="42" rx="3" fill="none" stroke="#8D6E63" stroke-width="2"/>
  <!-- Door -->
  <rect x="38" y="65" width="24" height="21" rx="4" fill="#8D6E63"/>
  <path d="M50 65 L50 86" stroke="#5D4037" stroke-width="1.5"/>
  <circle cx="44" cy="76" r="2" fill="#FDD835"/>
  <circle cx="56" cy="76" r="2" fill="#FDD835"/>
  <!-- Windows -->
  <rect x="20" y="52" width="14" height="12" rx="3" fill="#B3E5FC"/>
  <rect x="66" y="52" width="14" height="12" rx="3" fill="#B3E5FC"/>
  <line x1="27" y1="52" x2="27" y2="64" stroke="#81D4FA" stroke-width="1"/>
  <line x1="20" y1="58" x2="34" y2="58" stroke="#81D4FA" stroke-width="1"/>
  <line x1="73" y1="52" x2="73" y2="64" stroke="#81D4FA" stroke-width="1"/>
  <line x1="66" y1="58" x2="80" y2="58" stroke="#81D4FA" stroke-width="1"/>
  <!-- Grain sack badge -->
  <circle cx="78" cy="28" r="13" fill="#FFF9C4" stroke="#F9A825" stroke-width="2"/>
  <ellipse cx="78" cy="30" rx="7" ry="8" fill="#FFB300"/>
  <ellipse cx="78" cy="25" rx="4" ry="2" fill="#F9A825"/>
  <line x1="74" y1="27" x2="82" y2="27" stroke="#FF8F00" stroke-width="1"/>
</svg>
''';

  /// Weather Alerts — sun behind cloud with lightning
  static const String weatherAlert = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Sun rays -->
  <circle cx="38" cy="35" r="15" fill="#FDD835" opacity="0.5"/>
  <line x1="38" y1="12" x2="38" y2="18" stroke="#F9A825" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="38" y1="52" x2="38" y2="58" stroke="#F9A825" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="15" y1="35" x2="21" y2="35" stroke="#F9A825" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="55" y1="35" x2="61" y2="35" stroke="#F9A825" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="21" y1="19" x2="25" y2="23" stroke="#F9A825" stroke-width="2" stroke-linecap="round"/>
  <line x1="51" y1="47" x2="55" y2="51" stroke="#F9A825" stroke-width="2" stroke-linecap="round"/>
  <!-- Sun core -->
  <circle cx="38" cy="35" r="10" fill="#FDD835"/>
  <!-- Cloud -->
  <circle cx="62" cy="58" r="18" fill="white"/>
  <circle cx="46" cy="62" r="14" fill="white"/>
  <circle cx="70" cy="62" r="12" fill="white"/>
  <rect x="32" y="62" width="50" height="14" rx="7" fill="white"/>
  <circle cx="62" cy="58" r="18" fill="#B3E5FC" opacity="0.7"/>
  <circle cx="46" cy="62" r="14" fill="#B3E5FC" opacity="0.7"/>
  <circle cx="70" cy="62" r="12" fill="#B3E5FC" opacity="0.5"/>
  <rect x="32" y="62" width="50" height="14" rx="7" fill="#E1F5FE"/>
  <!-- Lightning -->
  <path d="M55 76 L62 60 L57 60 L64 44 L50 64 L56 64Z" fill="#F9A825" stroke="#FF8F00" stroke-width="1"/>
</svg>
''';

  /// Camera illustrated for capture actions
  static const String cameraAction = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Camera body -->
  <rect x="15" y="30" width="70" height="50" rx="10" fill="#42A5F5"/>
  <rect x="40" y="20" width="20" height="10" rx="3" fill="#1E88E5"/>
  <!-- Lens -->
  <circle cx="50" cy="55" r="22" fill="white" stroke="#1E88E5" stroke-width="4"/>
  <circle cx="50" cy="55" r="15" fill="#1E88E5"/>
  <circle cx="45" cy="50" r="4" fill="white" opacity="0.4"/>
  <!-- Flash -->
  <circle cx="75" cy="40" r="5" fill="#FFF59D"/>
  <!-- Shutter button -->
  <rect x="25" y="38" width="10" height="4" rx="2" fill="#1565C0"/>
</svg>
''';

  /// Gallery illustrated for upload actions
  static const String galleryAction = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Stacked photos -->
  <rect x="25" y="20" width="50" height="50" rx="6" fill="#F06292" transform="rotate(-5 50 45)"/>
  <rect x="20" y="25" width="60" height="60" rx="6" fill="#EC407A"/>
  <!-- Photo content -->
  <rect x="28" y="33" width="44" height="44" rx="2" fill="white"/>
  <!-- Landscape inside -->
  <circle cx="38" cy="45" r="5" fill="#FDD835"/>
  <path d="M28 77 L45 55 L60 70 L65 65 L72 77 Z" fill="#4CAF50"/>
</svg>
''';

  /// Location / Market pin illustrated
  static const String locationAction = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M50 15 C35 15 25 27 25 42 C25 62 50 85 50 85 C50 85 75 62 75 42 C75 27 65 15 50 15 Z" fill="#EF5350" stroke="#C62828" stroke-width="4"/>
  <circle cx="50" cy="42" r="10" fill="white"/>
</svg>
''';

  /// Calendar illustrated for date selection
  static const String calendarAction = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect x="20" y="25" width="60" height="55" rx="8" fill="#5C6BC0"/>
  <rect x="20" y="25" width="60" height="15" rx="8" fill="#3949AB"/>
  <rect x="30" y="15" width="6" height="15" rx="3" fill="#9FA8DA"/>
  <rect x="64" y="15" width="6" height="15" rx="3" fill="#9FA8DA"/>
  <rect x="28" y="48" width="8" height="8" rx="2" fill="white"/>
  <rect x="46" y="48" width="8" height="8" rx="2" fill="white"/>
  <rect x="64" y="48" width="8" height="8" rx="2" fill="white"/>
  <rect x="28" y="62" width="8" height="8" rx="2" fill="white" opacity="0.6"/>
</svg>
''';

  // ─────────────────────────────────────────────
  //  LABOR ROLE ICONS
  // ─────────────────────────────────────────────

  /// Find Work — briefcase with magnifying glass, amber tones
  static const String findWork = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Briefcase body -->
  <rect x="15" y="38" width="55" height="38" rx="8" fill="#FFF8E1"/>
  <rect x="15" y="38" width="55" height="38" rx="8" fill="none" stroke="#F9A825" stroke-width="3"/>
  <!-- Handle -->
  <path d="M32 38 L32 28 Q32 22 38 22 L47 22 Q53 22 53 28 L53 38" fill="none" stroke="#F57F17" stroke-width="3.5" stroke-linecap="round"/>
  <!-- Center clasp -->
  <rect x="38" y="50" width="10" height="10" rx="3" fill="#F9A825"/>
  <circle cx="43" cy="55" r="2" fill="#F57F17"/>
  <!-- Briefcase stripe -->
  <rect x="15" y="46" width="55" height="7" fill="#FFD54F" opacity="0.6"/>
  <!-- Magnifying glass overlay -->
  <circle cx="72" cy="65" r="16" fill="white" stroke="#FF8F00" stroke-width="3.5"/>
  <circle cx="72" cy="65" r="10" fill="#FFF8E1" opacity="0.8"/>
  <line x1="83" y1="76" x2="92" y2="85" stroke="#E65100" stroke-width="5" stroke-linecap="round"/>
  <!-- Search sparkle -->
  <circle cx="68" cy="61" r="2.5" fill="#F9A825" opacity="0.8"/>
</svg>
''';

  /// My Jobs — clipboard with checkmark, teal tones
  static const String myJobs = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Clipboard body -->
  <rect x="20" y="22" width="50" height="62" rx="7" fill="#E0F2F1"/>
  <rect x="20" y="22" width="50" height="62" rx="7" fill="none" stroke="#00897B" stroke-width="3"/>
  <!-- Clipboard clip -->
  <rect x="33" y="14" width="24" height="14" rx="4" fill="#00897B"/>
  <rect x="37" y="18" width="16" height="6" rx="3" fill="#B2DFDB"/>
  <!-- Check items -->
  <rect x="28" y="38" width="34" height="4" rx="2" fill="#80CBC4"/>
  <rect x="28" y="50" width="28" height="4" rx="2" fill="#80CBC4"/>
  <rect x="28" y="62" width="30" height="4" rx="2" fill="#80CBC4"/>
  <!-- Checkmark badge -->
  <circle cx="72" cy="70" r="16" fill="#00897B"/>
  <path d="M64 70 L69 75 L80 64" fill="none" stroke="white" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
  <!-- Progress dots -->
  <circle cx="62" cy="40" r="3" fill="#00695C"/>
  <circle cx="62" cy="52" r="3" fill="#4DB6AC"/>
  <circle cx="62" cy="64" r="3" fill="#B2DFDB"/>
</svg>
''';

  // ─────────────────────────────────────────────
  //  BOTTOM NAVIGATION ICONS  (active / inactive)
  // ─────────────────────────────────────────────

  static String navHome({bool active = false}) {
    const c = '#2E7D32';
    final b = active ? '#E8F5E9' : '#F5F5F5';
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <path d="M4 16 L16 5 L28 16 L28 28 L20 28 L20 21 Q20 19 18 19 L14 19 Q12 19 12 21 L12 28 L4 28Z"
    fill="$b" stroke="$c" stroke-width="2" stroke-linejoin="round"/>
  <path d="M11 5.5 L11 2 L16 2" fill="none" stroke="$c" stroke-width="2" stroke-linecap="round"/>
  <circle cx="16" cy="18" r="2" fill="$c"/>
</svg>
''';
  }

  static String navDisease({bool active = false}) {
    const c = '#D32F2F';
    final b = active ? '#FFEBEE' : '#F5F5F5';
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <path d="M6 26 Q6 10 22 4 Q25 17 14 24Z" fill="$b" stroke="$c" stroke-width="2"/>
  <path d="M6 26 Q16 19 22 4" fill="none" stroke="$c" stroke-width="1.5"/>
  <circle cx="13" cy="17" r="2" fill="#FF5252"/>
  <circle cx="17" cy="12" r="1.5" fill="#FF5252"/>
  <circle cx="22" cy="20" r="6" fill="none" stroke="$c" stroke-width="2"/>
  <line x1="26.2" y1="24.2" x2="30" y2="28" stroke="$c" stroke-width="2.5" stroke-linecap="round"/>
</svg>
''';
  }

  static String navMarket({bool active = false}) {
    const c = '#2E7D32';
    final b = active ? '#E8F5E9' : '#F5F5F5';
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <path d="M3 13 Q16 6 29 13 L26 17 Q16 11 6 17Z" fill="#FFB300"/>
  <rect x="6" y="16" width="20" height="12" rx="2" fill="$b" stroke="$c" stroke-width="1.5"/>
  <rect x="6" y="16" width="20" height="4" fill="#FFB300"/>
  <rect x="8" y="23" width="7" height="5" rx="1" fill="$c"/>
  <rect x="17" y="23" width="7" height="5" rx="1" fill="$c"/>
</svg>
''';
  }

  static String navSchemes({bool active = false}) {
    const c = '#1976D2';
    final b = active ? '#E3F2FD' : '#F5F5F5';
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect x="6" y="6" width="20" height="22" rx="3" fill="$b" stroke="$c" stroke-width="2"/>
  <rect x="10" y="12" width="12" height="2" rx="1" fill="$c" opacity="0.6"/>
  <rect x="10" y="17" width="8" height="2" rx="1" fill="$c" opacity="0.6"/>
  <rect x="10" y="22" width="10" height="2" rx="1" fill="$c" opacity="0.6"/>
  <circle cx="24" cy="8" r="5" fill="#FFA000" stroke="white" stroke-width="1.5"/>
</svg>
''';
  }

  static String navProfile({bool active = false}) {
    const c = '#7B1FA2';
    final b = active ? '#F3E5F5' : '#F5F5F5';
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle cx="16" cy="11" r="7" fill="$b" stroke="$c" stroke-width="2"/>
  <path d="M4 30 Q4 20 16 20 Q28 20 28 30" fill="$b" stroke="$c" stroke-width="2" stroke-linecap="round"/>
</svg>
''';
  }

  static String navChatbot({bool active = false}) {
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <!-- Robot Head -->
  <rect x="30" y="48" width="40" height="30" rx="8" fill="white"/>
  <!-- Eyes -->
  <circle cx="40" cy="58" r="3" fill="#2E7D32"/>
  <circle cx="60" cy="58" r="3" fill="#2E7D32"/>
  <!-- Antenna -->
  <line x1="50" y1="48" x2="50" y2="38" stroke="white" stroke-width="3" stroke-linecap="round"/>
  <circle cx="50" cy="38" r="4" fill="white"/>
  <!-- Smile -->
  <path d="M42 68 Q50 73 58 68" fill="none" stroke="#2E7D32" stroke-width="2" stroke-linecap="round"/>
  <!-- Speech Bubble -->
  <path d="M55 20 L80 20 L80 40 L67 40 L60 47 L60 40 L55 40 Z" fill="white"/>
  <rect x="60" y="27" width="12" height="2" rx="1" fill="#2E7D32"/>
  <rect x="60" y="33" width="8" height="2" rx="1" fill="#2E7D32"/>
</svg>
''';
  }

  // ─────────────────────────────────────────────
  //  WEATHER CONDITION ICONS
  // ─────────────────────────────────────────────

  static const String weatherSunny = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80">
  <circle cx="40" cy="40" r="18" fill="#FDD835"/>
  <circle cx="40" cy="40" r="13" fill="#F9A825"/>
  <line x1="40" y1="8" x2="40" y2="16" stroke="#FDD835" stroke-width="3.5" stroke-linecap="round"/>
  <line x1="40" y1="64" x2="40" y2="72" stroke="#FDD835" stroke-width="3.5" stroke-linecap="round"/>
  <line x1="8" y1="40" x2="16" y2="40" stroke="#FDD835" stroke-width="3.5" stroke-linecap="round"/>
  <line x1="64" y1="40" x2="72" y2="40" stroke="#FDD835" stroke-width="3.5" stroke-linecap="round"/>
  <line x1="17" y1="17" x2="23" y2="23" stroke="#FDD835" stroke-width="3" stroke-linecap="round"/>
  <line x1="57" y1="57" x2="63" y2="63" stroke="#FDD835" stroke-width="3" stroke-linecap="round"/>
  <line x1="63" y1="17" x2="57" y2="23" stroke="#FDD835" stroke-width="3" stroke-linecap="round"/>
  <line x1="17" y1="63" x2="23" y2="57" stroke="#FDD835" stroke-width="3" stroke-linecap="round"/>
</svg>
''';

  static const String weatherRainy = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80">
  <circle cx="45" cy="30" r="16" fill="#90CAF9"/>
  <circle cx="30" cy="35" r="12" fill="#90CAF9"/>
  <circle cx="55" cy="36" r="10" fill="#90CAF9"/>
  <rect x="18" y="35" width="44" height="12" rx="6" fill="#BBDEFB"/>
  <line x1="26" y1="55" x2="22" y2="68" stroke="#42A5F5" stroke-width="3" stroke-linecap="round"/>
  <line x1="36" y1="55" x2="32" y2="68" stroke="#42A5F5" stroke-width="3" stroke-linecap="round"/>
  <line x1="46" y1="55" x2="42" y2="68" stroke="#42A5F5" stroke-width="3" stroke-linecap="round"/>
  <line x1="56" y1="55" x2="52" y2="68" stroke="#42A5F5" stroke-width="3" stroke-linecap="round"/>
</svg>
''';

  static const String weatherCloud = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80">
  <circle cx="42" cy="38" r="18" fill="#CFD8DC"/>
  <circle cx="28" cy="44" r="13" fill="#ECEFF1"/>
  <circle cx="55" cy="44" r="11" fill="#ECEFF1"/>
  <rect x="15" y="44" width="50" height="14" rx="7" fill="#ECEFF1"/>
  <circle cx="42" cy="38" r="18" fill="#B0BEC5" opacity="0.4"/>
</svg>
''';
}
