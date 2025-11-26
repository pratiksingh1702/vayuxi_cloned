import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import '../domain/rateModel.dart';

final rateNotifierProvider =
StateNotifierProvider<RateNotifier, RateState<List<Rate>>>((ref) {
  return RateNotifier();
});

class RateNotifier extends StateNotifier<RateState<List<Rate>>> {
  RateNotifier() : super(RateState(data: []));

  final RateApiClient _client = RateApiClient();

  Future<void> fetchRate(String type, String siteId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _client.fetchRate(type, siteId);

      if (response['success'] == true) {
        // Safely handle the rates data - it might be null or empty
        final ratesData = response['data']['rates'];
        List<Rate> rates = [];

        if (ratesData is List<dynamic>) {
          rates = ratesData.map((e) => Rate.fromJson(e)).toList();
        } else if (ratesData == null) {
          rates = []; // Handle null case
        }

        state = state.copyWith(loading: false, data: rates);
      } else {
        state = state.copyWith(
            loading: false,
            error: response['error']?.toString() ?? "Unknown error"
        );
      }
    } catch (e) {
      state = state.copyWith(
          loading: false,
          error: "Failed to fetch rates: $e"
      );
    }
  }
  Future<void> postRate(Map<String, dynamic> data, String type, String siteId) async {
    state = state.copyWith(loading: true, error: null);
    final response = await _client.postRate(data, type, siteId);

    if (response['success']) {
      await fetchRate(type, siteId);
    } else {
      state = state.copyWith(
          loading: false, error: response['error']?.toString() ?? "Unknown error");
    }
  }

  Future<void> updateRate(Map<String, dynamic> data, String siteId, String rateId) async {
    state = state.copyWith(loading: true, error: null);
    final response = await _client.updateRate(data, siteId, rateId);

    if (response['success']) {
      final ratesJson = response['data']['rates'] as List<dynamic>;
      final rates = ratesJson.map((e) => Rate.fromJson(e)).toList();
      state = state.copyWith(loading: false, data: rates);
    } else {
      state = state.copyWith(
          loading: false, error: response['error']?.toString() ?? "Unknown error");
    }
  }
}

class RateState<T> {
  final bool loading;
  final T? data;
  final String? error;

  RateState({this.loading = false, this.data, this.error});

  RateState<T> copyWith({bool? loading, T? data, String? error}) {
    return RateState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
