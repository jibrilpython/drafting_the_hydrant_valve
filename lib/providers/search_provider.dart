import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';

class SearchNotifier extends ChangeNotifier {
  String searchQuery = '';

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    searchQuery = '';
    notifyListeners();
  }

  List<HydrantValveModel> filteredList(List<HydrantValveModel> list) {
    if (searchQuery.isEmpty) return list;

    final query = searchQuery.toLowerCase();
    return list
        .where(
          (item) =>
              item.hydrantBarrelRegistry.toLowerCase().contains(query) ||
              item.municipalDistrictBranch.toLowerCase().contains(query) ||
              item.footValveGateStyle.label.toLowerCase().contains(query) ||
              item.operatingNutGeometry.label.toLowerCase().contains(query) ||
              item.nozzleThreadStandard.label.toLowerCase().contains(query) ||
              item.staticHeadPressureRating.toLowerCase().contains(query) ||
              item.barrelBoreSpec.toLowerCase().contains(query) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query)),
        )
        .toList();
  }
}

final searchProvider = ChangeNotifierProvider((ref) => SearchNotifier());
