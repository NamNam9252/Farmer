import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:client/features/disease/domain/entities/disease_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class OfflineModelService {
  static final OfflineModelService _instance = OfflineModelService._internal();
  factory OfflineModelService() => _instance;
  OfflineModelService._internal();

  Interpreter? _interpreter;
  String? _loadedCrop;
  List<String> _labels = [];
  Map<String, dynamic> _diseaseDb = {};
  bool _isDbLoaded = false;

  /// Load the disease database from assets
  Future<void> _loadDatabase() async {
    if (_isDbLoaded) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/app_metadata.json');
      _diseaseDb = jsonDecode(jsonString) as Map<String, dynamic>;
      _isDbLoaded = true;
      print('OfflineModelService: Local disease database loaded successfully.');
    } catch (e) {
      print('OfflineModelService Error: Failed to load database: $e');
    }
  }

  Future<void> loadModel({String cropType = 'general'}) async {
    if (_loadedCrop == cropType && _interpreter != null) return;

    try {
      _interpreter?.close();
      
      String modelName = _getFileNameForCrop(cropType);
      
      print('Loading TFLite model from assets/models/${modelName}_model.tflite...');
      _interpreter = await Interpreter.fromAsset('assets/models/${modelName}_model.tflite');
      
      print('Loading labels from assets/models/${modelName}_labels.txt...');
      final labelData = await rootBundle.loadString('assets/models/${modelName}_labels.txt');
      _labels = labelData.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      
      _loadedCrop = cropType;
      await _loadDatabase();
      
      print('OfflineModelService: Model ($modelName) and labels loaded successfully (Classes: ${_labels.length})');
    } catch (e) {
      _loadedCrop = null;
      print('OfflineModelService ERROR: Failed to load model or labels for $cropType: $e');
      rethrow;
    }
  }

  String _getFileNameForCrop(String crop) {
    final c = crop.toLowerCase();
    if (c.contains('apple')) return 'apple';
    if (c.contains('cherry')) return 'cherry';
    if (c.contains('corn') || c.contains('maize')) return 'corn';
    if (c.contains('grape')) return 'grape';
    if (c.contains('peach')) return 'peach';
    if (c.contains('pepper')) return 'pepper';
    if (c.contains('potato')) return 'potato';
    if (c.contains('strawberry')) return 'strawberry';
    if (c.contains('tomato')) return 'tomato';
    return 'tomato'; // Default fallback
  }

  Future<Map<String, dynamic>> predict(File imageFile, {String cropType = 'tomato'}) async {
    await loadModel(cropType: cropType);

    if (_interpreter == null) {
      throw Exception('Failed to load local model');
    }

    // Determine actual output shape from model
    final outputShape = _interpreter!.getOutputTensors()[0].shape;
    final int expectedClassCount = outputShape[1];
    
    print('Model expected output shape: $outputShape (Classes: $expectedClassCount)');
    print('Loaded labels count: ${_labels.length}');

    print('Preprocessing image in background isolate...');
    final input = await compute(_preprocessImageIsolate, imageFile.path);
    print('Preprocessing completed.');

    // Output shape MUST match model exactly [1, expectedClassCount]
    var output = List<List<double>>.generate(1, (_) => List<double>.filled(expectedClassCount, 0.0));

    // Run inference
    print('Starting TFLite inference for $cropType...');
    _interpreter!.run(input, output);
    print('Inference completed.');

    // Process result
    double maxScore = -1.0;
    int maxIndex = -1;

    for (int i = 0; i < expectedClassCount; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        maxIndex = i;
      }
    }

    if (maxIndex != -1) {
      // Use label if available, otherwise fallback to generic
      String label = (maxIndex < _labels.length) ? _labels[maxIndex] : "Unknown Disease ($maxIndex)";
      
      print('Predicted Raw Label: $label (Confidence: $maxScore)');
      
      // Clean label
      if (label.contains(':')) {
        label = label.split(':').last.trim();
      } else if (RegExp(r'^\d+\s+').hasMatch(label)) {
        label = label.replaceFirst(RegExp(r'^\d+\s+'), '').trim();
      }
      // Also handle potential underscores from some tflite label formats
      label = label.replaceAll('_', ' ').toLowerCase();
      
      print('Cleaned Label: "$label"');
      
      // Lookup details from database
      await _loadDatabase(); // Ensure loaded
      print('Disease DB Keys (first 5): ${_diseaseDb.keys.take(5).toList()}');
      
      // Try exact match first
      var details = _diseaseDb[label.toLowerCase()];
      
      // If no exact match, try contains (partial) match
      if (details == null) {
        print('Exact match failed for "$label", trying fuzzy match...');
        final key = _diseaseDb.keys.firstWhere(
          (k) => k.toLowerCase().contains(label.toLowerCase()) || label.toLowerCase().contains(k.toLowerCase()),
          orElse: () => '',
        );
        if (key.isNotEmpty) {
          details = _diseaseDb[key];
          print('Fuzzy match found: "$key"');
        }
      }
      
      // If still null, fallback to 'not detected'
      if (details == null) {
        print('No match found for "$label", using fallback.');
        details = _diseaseDb['not detected'];
      }
      
      return {
        'diseaseName': label.split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' '),
        'diseaseNameHindi': details?['diseaseNameHindi'] ?? label,
        'plant': cropType,
        'confidence': maxScore,
        'treatment': details?['treatment'] ?? 'Consult an expert.',
        'treatmentHindi': details?['treatmentHindi'] ?? 'विशेषज्ञ से सलाह लें।',
        'description': details?['description'] ?? 'No details available offline.',
        'descriptionHindi': details?['descriptionHindi'] ?? 'विवरण ऑफलाइन उपलब्ध नहीं है।',
        'severity': details?['severity'] ?? 'medium',
        'isHealthy': details?['isHealthy'] ?? false,
        'isOffline': true,
      };
    }

    throw Exception('Local inference failed');
  }
}

/// Helper function for compute (Isolate)
Future<List<List<List<List<double>>>>> _preprocessImageIsolate(String imagePath) async {
  final bytes = File(imagePath).readAsBytesSync();
  final img.Image? inputImage = img.decodeImage(bytes);
  if (inputImage == null) throw Exception('Failed to decode image');

  final img.Image resizedImage = img.copyResize(inputImage, width: 224, height: 224);

  // Prepare input as [1, 224, 224, 3]
  var input = List.generate(
    1,
    (_) => List.generate(
      224,
      (_) => List.generate(
        224,
        (_) => List.filled(3, 0.0),
      ),
    ),
  );

  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = resizedImage.getPixel(x, y);
      input[0][y][x][0] = pixel.r / 255.0;
      input[0][y][x][1] = pixel.g / 255.0;
      input[0][y][x][2] = pixel.b / 255.0;
    }
  }
  return input;
}
