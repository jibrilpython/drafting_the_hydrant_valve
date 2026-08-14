import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';
import 'package:drafting_the_hydrant_valve/providers/image_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/input_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/code_generator.dart';

class ProjectNotifier extends ChangeNotifier {
  ProjectNotifier() {
    loadEntries();
  }

  List<HydrantValveModel> entries = [];
  bool isLoading = true;
  int stateVersion = 0;
  static const String _storageKey = 'dhv_hydrants_v1';
  final _uuid = const Uuid();

  Future<void> loadEntries() async {
    isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        entries = decodedList
            .map((item) => HydrantValveModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading entries: $e');
      entries = [];
    } finally {
      isLoading = false;
      stateVersion++;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(
      entries.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encodedList);
  }

  HydrantValveModel _buildFromInput(WidgetRef ref, {String? existingId}) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    final code = p.hydrantBarrelRegistry.isNotEmpty
        ? p.hydrantBarrelRegistry
        : generateHydrantBarrelRegistry(
            valve: p.footValveGateStyle,
            stem: p.mainValveStemPitch,
          );

    return HydrantValveModel(
      id: existingId ?? _uuid.v4(),
      hydrantBarrelRegistry: code,
      operatingNutGeometry: p.operatingNutGeometry,
      footValveGateStyle: p.footValveGateStyle,
      frostSleeveClearance: p.frostSleeveClearance,
      nozzleThreadStandard: p.nozzleThreadStandard,
      mainValveStemPitch: p.mainValveStemPitch,
      barrelMetalThickness: p.barrelMetalThickness,
      staticHeadPressureRating: p.staticHeadPressureRating,
      municipalDistrictBranch: p.municipalDistrictBranch,
      headSimulationStatus: p.headSimulationStatus,
      barrelBoreSpec: p.barrelBoreSpec,
      archivalNotes: p.archivalNotes,
      photoPath:
          imgProv.resultImage.isNotEmpty ? imgProv.resultImage : p.photoPath,
      tags: List<String>.from(p.tags),
      dateAdded: p.dateAdded,
    );
  }

  void addEntry(WidgetRef ref) {
    entries.add(_buildFromInput(ref));
    _save();
    stateVersion++;
    notifyListeners();
  }

  void editEntry(WidgetRef ref, int index) {
    final existing = entries[index];
    entries[index] = _buildFromInput(ref, existingId: existing.id)
      ..dateAdded = existing.dateAdded
      ..photoPath = ref.read(imageProvider).resultImage.isNotEmpty
          ? ref.read(imageProvider).resultImage
          : existing.photoPath;
    _save();
    stateVersion++;
    notifyListeners();
  }

  void deleteEntry(int index) {
    entries.removeAt(index);
    _save();
    stateVersion++;
    notifyListeners();
  }

  void fillInput(WidgetRef ref, int index) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    final entry = entries[index];

    p.hydrantBarrelRegistry = entry.hydrantBarrelRegistry;
    p.operatingNutGeometry = entry.operatingNutGeometry;
    p.footValveGateStyle = entry.footValveGateStyle;
    p.frostSleeveClearance = entry.frostSleeveClearance;
    p.nozzleThreadStandard = entry.nozzleThreadStandard;
    p.mainValveStemPitch = entry.mainValveStemPitch;
    p.barrelMetalThickness = entry.barrelMetalThickness;
    p.staticHeadPressureRating = entry.staticHeadPressureRating;
    p.municipalDistrictBranch = entry.municipalDistrictBranch;
    p.headSimulationStatus = entry.headSimulationStatus;
    p.barrelBoreSpec = entry.barrelBoreSpec;
    p.archivalNotes = entry.archivalNotes;
    p.photoPath = entry.photoPath;
    p.tags = List<String>.from(entry.tags);
    p.dateAdded = entry.dateAdded;

    imgProv.resultImage = entry.photoPath;
    notifyListeners();
  }
}

final projectProvider = ChangeNotifierProvider<ProjectNotifier>(
  (ref) => ProjectNotifier(),
);
