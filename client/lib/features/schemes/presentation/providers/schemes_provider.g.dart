// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$schemesRepositoryHash() => r'77069c8b4f8141377eab062705430ccb1609b350';

/// See also [schemesRepository].
@ProviderFor(schemesRepository)
final schemesRepositoryProvider =
    AutoDisposeProvider<SchemesRepository>.internal(
      schemesRepository,
      name: r'schemesRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$schemesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SchemesRepositoryRef = AutoDisposeProviderRef<SchemesRepository>;
String _$schemesControllerHash() => r'42fdfcae20d768cb9fe0f7f025af707036c02300';

/// See also [SchemesController].
@ProviderFor(SchemesController)
final schemesControllerProvider = AutoDisposeAsyncNotifierProvider<
  SchemesController,
  List<SchemeModel>
>.internal(
  SchemesController.new,
  name: r'schemesControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$schemesControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SchemesController = AutoDisposeAsyncNotifier<List<SchemeModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
