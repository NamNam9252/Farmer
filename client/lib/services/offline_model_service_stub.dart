

class OfflineModelService {
  static final OfflineModelService _instance = OfflineModelService._internal();
  factory OfflineModelService() => _instance;
  OfflineModelService._internal();

  Future<void> loadModel({String cropType = 'general'}) async {
    print('Offline model inference is not supported on the Web platform. Skipping model loading.');
  }

  // We use dynamic for imageFile to avoid dart:io references if possible, 
  // but since we are stubbing, the caller might still pass a File.
  // Actually, if we import dart:io here, it will fail to compile on Web!
  // BUT dart:io is NOT available on Web. We must not import dart:io.
  // So we use dynamic for the File parameter.
  Future<Map<String, dynamic>> predict(dynamic imageFile, {String cropType = 'tomato'}) async {
    print('Web platform detected: Model prediction is not available offline.');
    return {
      'diseaseName': 'Not Available on Web',
      'diseaseNameHindi': 'वेब पर उपलब्ध नहीं है',
      'plant': cropType,
      'confidence': 0.0,
      'treatment': 'Please use the mobile app for offline image scanning.',
      'treatmentHindi': 'ऑफ़लाइन छवि स्कैनिंग के लिए कृपया मोबाइल ऐप का उपयोग करें।',
      'description': 'Offline AI model is not supported in the web browser due to platform limitations.',
      'descriptionHindi': 'प्लेटफ़ॉर्म सीमाओं के कारण वेब ब्राउज़र में ऑफ़लाइन एआई मॉडल समर्थित नहीं है।',
      'severity': 'info',
      'isHealthy': false,
      'isOffline': true,
    };
  }
}
