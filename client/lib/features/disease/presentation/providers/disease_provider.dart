import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/disease_report_model.dart';
import '../../data/repository/disease_repository.dart';

final diseaseRepositoryProvider = Provider<DiseaseRepository>(
  (_) => DiseaseRepository(),
);

// State for the analysis flow
class DiseaseAnalysisState {
  final File? selectedImage;
  final String selectedCrop;
  final DiseaseReportModel? result;
  final bool isLoading;
  final String? error;
  final bool resultSaved;

  const DiseaseAnalysisState({
    this.selectedImage,
    this.selectedCrop = '',
    this.result,
    this.isLoading = false,
    this.error,
    this.resultSaved = false,
  });

  DiseaseAnalysisState copyWith({
    File? selectedImage,
    String? selectedCrop,
    DiseaseReportModel? result,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearResult = false,
    bool? resultSaved,
  }) {
    return DiseaseAnalysisState(
      selectedImage: selectedImage ?? this.selectedImage,
      selectedCrop: selectedCrop ?? this.selectedCrop,
      result: clearResult ? null : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      resultSaved: resultSaved ?? this.resultSaved,
    );
  }
}

class DiseaseAnalysisNotifier extends StateNotifier<DiseaseAnalysisState> {
  DiseaseAnalysisNotifier(this._repository) : super(const DiseaseAnalysisState());

  final DiseaseRepository _repository;

  void setImage(File image) {
    state = state.copyWith(
      selectedImage: image,
      clearResult: true,
      clearError: true,
    );
  }

  void setCrop(String crop) {
    state = state.copyWith(selectedCrop: crop);
  }

  Future<void> analyze({String language = 'hi'}) async {
    final image = state.selectedImage;
    if (image == null) return;

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final result = await _repository.analyzeDisease(
        imageFile: image,
        cropType: state.selectedCrop,
        language: language,
      );
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearAll() {
    state = const DiseaseAnalysisState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final diseaseAnalysisProvider =
    StateNotifierProvider<DiseaseAnalysisNotifier, DiseaseAnalysisState>(
  (ref) => DiseaseAnalysisNotifier(ref.watch(diseaseRepositoryProvider)),
);

// Past reports provider
final pastReportsProvider = FutureProvider<List<DiseaseReportModel>>((ref) async {
  final repo = ref.watch(diseaseRepositoryProvider);
  return repo.getLocalReports();
});

// Language provider
final languageProvider = StateProvider<String>((ref) => 'hi');
