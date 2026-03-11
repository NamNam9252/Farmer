import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/scheme_model.dart';
import '../../data/repository/schemes_repository.dart';

part 'schemes_provider.g.dart';

@riverpod
class SchemesController extends _$SchemesController {
  @override
  FutureOr<List<SchemeModel>> build() async {
    return ref.read(schemesRepositoryProvider).getSchemes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(schemesRepositoryProvider).getSchemes());
  }
}

@riverpod
SchemesRepository schemesRepository(Ref ref) {
  return SchemesRepository();
}
