import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/rental_api.dart';
import '../../data/models/rental_models.dart';
import '../../data/repository/rental_repository.dart';
import '../../domain/repository_contract.dart';

final rentalApiProvider = Provider((ref) => RentalApi());

final rentalRepositoryProvider = Provider<IRentalRepository>((ref) {
  final api = ref.watch(rentalApiProvider);
  return RentalRepository(api);
});

// Assets State
class RentalAssetsState {
  final List<RentalAsset> assets;
  final bool isLoading;
  final String? error;

  RentalAssetsState({
    required this.assets,
    this.isLoading = false,
    this.error,
  });

  RentalAssetsState copyWith({
    List<RentalAsset>? assets,
    bool? isLoading,
    String? error,
  }) {
    return RentalAssetsState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RentalAssetsNotifier extends StateNotifier<RentalAssetsState> {
  final IRentalRepository _repository;

  RentalAssetsNotifier(this._repository) : super(RentalAssetsState(assets: []));

  Future<void> loadAssets() async {
    state = state.copyWith(isLoading: true);
    try {
      final assets = await _repository.getAssets();
      state = state.copyWith(assets: assets, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadMyAssets() async {
    state = state.copyWith(isLoading: true);
    try {
      final assets = await _repository.getMyAssets();
      state = state.copyWith(assets: assets, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createAsset(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createAsset(data);
      await loadMyAssets();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateAsset(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateAsset(id, data);
      await loadMyAssets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _repository.deleteAsset(id);
      await loadMyAssets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadAssets();
}

final rentalAssetsProvider = StateNotifierProvider<RentalAssetsNotifier, RentalAssetsState>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return RentalAssetsNotifier(repo);
});

final myAssetsProvider = StateNotifierProvider<RentalAssetsNotifier, RentalAssetsState>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return RentalAssetsNotifier(repo);
});

// Bids State
class RentalBidsState {
  final List<RentalBid> bids;
  final bool isLoading;
  final String? error;

  RentalBidsState({
    required this.bids,
    this.isLoading = false,
    this.error,
  });

  RentalBidsState copyWith({
    List<RentalBid>? bids,
    bool? isLoading,
    String? error,
  }) {
    return RentalBidsState(
      bids: bids ?? this.bids,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RentalBidsNotifier extends StateNotifier<RentalBidsState> {
  final IRentalRepository _repository;

  RentalBidsNotifier(this._repository) : super(RentalBidsState(bids: []));

  Future<void> loadAssetBids(String assetId) async {
    state = state.copyWith(isLoading: true);
    try {
      final bids = await _repository.getAssetBids(assetId);
      state = state.copyWith(bids: bids, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadMyBids() async {
    state = state.copyWith(isLoading: true);
    try {
      final bids = await _repository.getMyBids();
      state = state.copyWith(bids: bids, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> acceptBid(String assetId, String bidId) async {
    try {
      await _repository.acceptBid(assetId, bidId);
      await loadAssetBids(assetId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final myBidsProvider = StateNotifierProvider<RentalBidsNotifier, RentalBidsState>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return RentalBidsNotifier(repo);
});

final rentalBidsProvider = StateNotifierProvider.family<RentalBidsNotifier, RentalBidsState, String>((ref, assetId) {
  final repo = ref.watch(rentalRepositoryProvider);
  final notifier = RentalBidsNotifier(repo);
  notifier.loadAssetBids(assetId);
  return notifier;
});

final rentalAssetProvider = FutureProvider.family<RentalAsset?, String>((ref, id) {
  return ref.watch(rentalRepositoryProvider).getAsset(id);
});

// Rentals State
class MyRentalsState {
  final List<RentalOrder> rentals;
  final bool isLoading;
  final String? error;

  MyRentalsState({
    required this.rentals,
    this.isLoading = false,
    this.error,
  });

  MyRentalsState copyWith({
    List<RentalOrder>? rentals,
    bool? isLoading,
    String? error,
  }) {
    return MyRentalsState(
      rentals: rentals ?? this.rentals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MyRentalsNotifier extends StateNotifier<MyRentalsState> {
  final IRentalRepository _repository;

  MyRentalsNotifier(this._repository) : super(MyRentalsState(rentals: []));

  Future<void> loadRentals() async {
    state = state.copyWith(isLoading: true);
    try {
      final rentals = await _repository.getMyRentals();
      state = state.copyWith(rentals: rentals, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final myRentalsProvider = StateNotifierProvider<MyRentalsNotifier, MyRentalsState>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return MyRentalsNotifier(repo);
});
