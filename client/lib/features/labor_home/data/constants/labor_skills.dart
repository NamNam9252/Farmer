/// Predefined list of labor skills for fuzzy search selection.
/// Each skill has an English key and Hindi translation.
class LaborSkill {
  final String key;
  final String en;
  final String hi;

  const LaborSkill({
    required this.key,
    required this.en,
    required this.hi,
  });
}

const List<LaborSkill> predefinedSkills = [
  // Crop Operations
  LaborSkill(key: 'SOWING', en: 'Sowing', hi: 'बुवाई'),
  LaborSkill(key: 'HARVESTING', en: 'Harvesting', hi: 'कटाई'),
  LaborSkill(key: 'WEEDING', en: 'Weeding', hi: 'निराई'),
  LaborSkill(key: 'TRANSPLANTING', en: 'Transplanting', hi: 'रोपाई'),
  LaborSkill(key: 'THRESHING', en: 'Threshing', hi: 'गहाई'),
  LaborSkill(key: 'WINNOWING', en: 'Winnowing', hi: 'ओसाई'),
  LaborSkill(key: 'PLOUGHING', en: 'Ploughing', hi: 'जुताई'),

  // Irrigation
  LaborSkill(key: 'IRRIGATION', en: 'Irrigation', hi: 'सिंचाई'),
  LaborSkill(key: 'DRIP_SETUP', en: 'Drip Irrigation Setup', hi: 'ड्रिप सिंचाई'),
  LaborSkill(key: 'CANAL_WORK', en: 'Canal Maintenance', hi: 'नहर रखरखाव'),

  // Equipment
  LaborSkill(key: 'TRACTOR', en: 'Tractor Driving', hi: 'ट्रैक्टर चालन'),
  LaborSkill(key: 'COMBINE', en: 'Combine Harvester', hi: 'कंबाइन हार्वेस्टर'),
  LaborSkill(key: 'SPRAYING', en: 'Pesticide Spraying', hi: 'कीटनाशक छिड़काव'),
  LaborSkill(key: 'PUMP_REPAIR', en: 'Pump Repair', hi: 'पंप मरम्मत'),

  // Animal & Dairy
  LaborSkill(key: 'DAIRY', en: 'Dairy Farming', hi: 'दुग्ध उत्पादन'),
  LaborSkill(key: 'ANIMAL_CARE', en: 'Animal Husbandry', hi: 'पशुपालन'),
  LaborSkill(key: 'POULTRY', en: 'Poultry Farming', hi: 'मुर्गीपालन'),

  // General
  LaborSkill(key: 'LOADING', en: 'Loading/Unloading', hi: 'लोडिंग/अनलोडिंग'),
  LaborSkill(key: 'DIGGING', en: 'Digging', hi: 'खुदाई'),
  LaborSkill(key: 'FENCING', en: 'Fencing', hi: 'बाड़ लगाना'),
  LaborSkill(key: 'MULCHING', en: 'Mulching', hi: 'मल्चिंग'),
  LaborSkill(key: 'COMPOSTING', en: 'Composting', hi: 'खाद बनाना'),
  LaborSkill(key: 'GREENHOUSE', en: 'Greenhouse Work', hi: 'ग्रीनहाउस कार्य'),
  LaborSkill(key: 'NURSERY', en: 'Nursery Management', hi: 'नर्सरी प्रबंधन'),
  LaborSkill(key: 'PRUNING', en: 'Pruning', hi: 'छंटाई'),
  LaborSkill(key: 'GRADING', en: 'Grading & Sorting', hi: 'ग्रेडिंग एवं छंटाई'),
  LaborSkill(key: 'PACKAGING', en: 'Packaging', hi: 'पैकेजिंग'),
];
