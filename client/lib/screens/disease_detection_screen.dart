import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/disease_api_service.dart';
import '../services/offline_model_service.dart';
import '../utils/connectivity_service.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  final DiseaseApiService _apiService = DiseaseApiService();
  final OfflineModelService _offlineService = OfflineModelService();
  final ConnectivityService _connectivityService = ConnectivityService();

  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _isOfflineResult = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        _selectedImage = File(file.path);
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _isOfflineResult = false;
    });

    try {
      final bool online = await _connectivityService.isConnected();
      
      if (online) {
        try {
          final result = await _apiService.analyzeImage(imageFile: _selectedImage!);
          if (mounted) {
            setState(() {
              _result = result;
              _isLoading = false;
            });
          }
          return; // Success, stop here
        } catch (e) {
          debugPrint('API analysis failed, falling back to offline: $e');
          // If API fails (e.g. server down, slow internet), we continue to offline prediction
        }
      }

      // Offline Prediction (Fallback or explicitly offline)
      debugPrint('Running offline prediction...');
      final result = await _offlineService.predict(_selectedImage!);
      
      if (mounted) {
        setState(() {
          _result = result;
          _isOfflineResult = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Detection failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Disease Detection'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePickerSection(),
            const SizedBox(height: 24),
            if (_selectedImage != null) _buildAnalyzeButton(),
            const SizedBox(height: 24),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_error != null) _buildErrorCard(),
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _selectedImage == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_search, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No image selected', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _analyzeImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Analyze Disease', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildResultCard() {
    final String diseaseName = _result!['diseaseName'] ?? 'Unknown';
    final double confidence = _result!['confidence'] ?? 0.0;
    final String treatment = _result!['treatment'] ?? 'No treatment info available';

    return Column(
      children: [
        if (_isOfflineResult)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "This result may not be accurate. Connect to internet for better analysis.",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Result',
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  diseaseName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Confidence Score: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${(confidence * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Recommended Treatment:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(treatment, style: const TextStyle(fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
