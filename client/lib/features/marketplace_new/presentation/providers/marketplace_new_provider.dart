import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/marketplace_new_api.dart';
import '../../data/models/marketplace_new_models.dart';

final marketplaceApiProvider = Provider((ref) => MarketplaceNewApi());

// Items State
class MarketplaceItemsState {
  final List<MarketplaceItem> items;
  final bool isLoading;
  final String? error;

  MarketplaceItemsState({
    required this.items,
    this.isLoading = false,
    this.error,
  });

  MarketplaceItemsState copyWith({
    List<MarketplaceItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return MarketplaceItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MarketplaceItemsNotifier extends StateNotifier<MarketplaceItemsState> {
  final MarketplaceNewApi _api;

  MarketplaceItemsNotifier(this._api) : super(MarketplaceItemsState(items: []));

  Future<void> loadItems({
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _api.getItems(
        category: category,
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadUserItems(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _api.getUserItems(userId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    try {
      await _api.createItem(data);
      refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      await _api.updateItem(itemId, data);
      refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _api.deleteItem(itemId);
      refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reportItem(String itemId, String reason, String description) async {
    try {
      await _api.reportItem(itemId, reason, description);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadItems();
}

final marketplaceItemsProvider = StateNotifierProvider<MarketplaceItemsNotifier, MarketplaceItemsState>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  return MarketplaceItemsNotifier(api);
});

// Providers for the current user's listings
final marketplaceMyItemsProvider = StateNotifierProvider<MarketplaceItemsNotifier, MarketplaceItemsState>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  return MarketplaceItemsNotifier(api);
});

final marketplaceMyDemandsProvider = StateNotifierProvider<MarketplaceDemandsNotifier, MarketplaceDemandsState>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  return MarketplaceDemandsNotifier(api);
});

// Deprecated or redirect if needed, but better to use specific ones above
final marketplaceMyListingsProvider = marketplaceMyItemsProvider;

// Demands State
class MarketplaceDemandsState {
  final List<MarketplaceDemand> demands;
  final bool isLoading;
  final String? error;

  MarketplaceDemandsState({
    required this.demands,
    this.isLoading = false,
    this.error,
  });

  MarketplaceDemandsState copyWith({
    List<MarketplaceDemand>? demands,
    bool? isLoading,
    String? error,
  }) {
    return MarketplaceDemandsState(
      demands: demands ?? this.demands,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MarketplaceDemandsNotifier extends StateNotifier<MarketplaceDemandsState> {
  final MarketplaceNewApi _api;

  MarketplaceDemandsNotifier(this._api) : super(MarketplaceDemandsState(demands: []));

  Future<void> loadDemands({String? category}) async {
    state = state.copyWith(isLoading: true);
    try {
      final demands = await _api.getDemands(category: category);
      state = state.copyWith(demands: demands, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadUserDemands(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final demands = await _api.getUserDemands(userId);
      state = state.copyWith(demands: demands, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createDemand(Map<String, dynamic> data) async {
    try {
      await _api.createDemand(data);
      loadDemands();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateDemand(String demandId, Map<String, dynamic> data) async {
    try {
      await _api.updateDemand(demandId, data);
      loadDemands();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteDemand(String demandId) async {
    try {
      await _api.deleteDemand(demandId);
      loadDemands();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reportDemand(String demandId, String reason, String description) async {
    try {
      await _api.reportDemand(demandId, reason, description);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadDemands();
}

final marketplaceDemandsProvider = StateNotifierProvider<MarketplaceDemandsNotifier, MarketplaceDemandsState>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  return MarketplaceDemandsNotifier(api);
});

// Purchase Requests State
class PurchaseRequestsState {
  final List<PurchaseRequest> incomingRequests;
  final List<PurchaseRequest> sentRequests;
  final bool isLoading;
  final String? error;

  PurchaseRequestsState({
    required this.incomingRequests,
    required this.sentRequests,
    this.isLoading = false,
    this.error,
  });

  PurchaseRequestsState copyWith({
    List<PurchaseRequest>? incomingRequests,
    List<PurchaseRequest>? sentRequests,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseRequestsState(
      incomingRequests: incomingRequests ?? this.incomingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PurchaseRequestsNotifier extends StateNotifier<PurchaseRequestsState> {
  final MarketplaceNewApi _api;

  PurchaseRequestsNotifier(this._api) : super(PurchaseRequestsState(incomingRequests: [], sentRequests: []));

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true);
    try {
      final incoming = await _api.getSellerRequests();
      final sent = await _api.getBuyerRequests();
      state = state.copyWith(incomingRequests: incoming, sentRequests: sent, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _api.acceptPurchaseRequest(requestId);
      await loadRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _api.rejectPurchaseRequest(requestId);
      await loadRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final purchaseRequestsProvider = StateNotifierProvider<PurchaseRequestsNotifier, PurchaseRequestsState>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  return PurchaseRequestsNotifier(api);
});

// Demand Offers State
class DemandOffersState {
  final List<DemandOffer> incomingOffers;
  final List<DemandOffer> sentOffers;
  final bool isLoading;
  final String? error;

  DemandOffersState({
    required this.incomingOffers,
    required this.sentOffers,
    this.isLoading = false,
    this.error,
  });

  DemandOffersState copyWith({
    List<DemandOffer>? incomingOffers,
    List<DemandOffer>? sentOffers,
    bool? isLoading,
    String? error,
  }) {
    return DemandOffersState(
      incomingOffers: incomingOffers ?? this.incomingOffers,
      sentOffers: sentOffers ?? this.sentOffers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DemandOffersNotifier extends StateNotifier<DemandOffersState> {
  final MarketplaceNewApi _api;

  DemandOffersNotifier(this._api) : super(DemandOffersState(incomingOffers: [], sentOffers: []));

  Future<void> loadOffers() async {
    state = state.copyWith(isLoading: true);
    try {
      final incoming = await _api.getBuyerOffers();
      final sent = await _api.getSellerOffers();
      state = state.copyWith(incomingOffers: incoming, sentOffers: sent, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> acceptOffer(String offerId) async {
    try {
      await _api.acceptDemandOffer(offerId);
      await loadOffers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectOffer(String offerId) async {
    try {
      await _api.rejectDemandOffer(offerId);
      await loadOffers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final demandOffersProvider = StateNotifierProvider<DemandOffersNotifier, DemandOffersState>((ref) {
  final api = ref.watch(marketplaceApiProvider);
  return DemandOffersNotifier(api);
});
