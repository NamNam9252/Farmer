import 'dart:io';
import '../entities/disease_report.dart';
import '../disease_repository_contract.dart';

class AnalyzeDiseaseUseCase {
  final IDiseaseRepository _repository;

  AnalyzeDiseaseUseCase(this._repository);

  Future<DiseaseReport> execute({
    required File imageFile,
    required String cropType,
    String language = 'hi',
  }) async {
    // Here we can place any business rules, like checking if the image size is reasonable
    // before attempting the network call (which might save user bandwidth),
    // or validating the cropType isn't empty.

    if (cropType.isEmpty) {
      throw Exception('Crop type must be selected');
    }

    return await _repository.analyzeDisease(
      imageFile: imageFile,
      cropType: cropType,
      language: language,
    );
  }
}
