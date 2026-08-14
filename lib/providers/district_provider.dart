import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// District water-main pressure field for the District Map showcase.
class DistrictNotifier extends ChangeNotifier {
  double mainPressurePsi = 55;
  double displayPressurePsi = 55;
  bool frozen = false;
  bool surge = false;
  double shake = 0;
  double flowPhase = 0;

  static const double maxSafePsi = 120;
  static const double surgeTripPsi = 140;
  static const double absoluteMaxPsi = 160;

  final Set<int> isolatedIndices = {};

  bool isIsolated(int index) => isolatedIndices.contains(index);

  void toggleIsolation(int index) {
    if (isolatedIndices.contains(index)) {
      isolatedIndices.remove(index);
    } else {
      isolatedIndices.add(index);
      HapticFeedback.heavyImpact();
    }
    notifyListeners();
  }

  void clearIsolation() {
    isolatedIndices.clear();
    notifyListeners();
  }

  void setFrozen(bool value) {
    frozen = value;
    notifyListeners();
  }

  void injectPressure(double deltaPsi) {
    if (frozen || surge) return;
    mainPressurePsi = (mainPressurePsi + deltaPsi).clamp(0.0, absoluteMaxPsi);
    if (mainPressurePsi >= surgeTripPsi) {
      _tripSurge();
    } else {
      notifyListeners();
    }
  }

  void _tripSurge() {
    surge = true;
    shake = 1.0;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 40), () {
      HapticFeedback.vibrate();
    });
    notifyListeners();
  }

  void tick(double dt) {
    flowPhase += dt * (0.6 + displayPressurePsi / 100);

    if (surge) {
      mainPressurePsi =
          (mainPressurePsi - dt * 90).clamp(0.0, absoluteMaxPsi);
      shake = (shake - dt * 1.8).clamp(0.0, 1.0);
      if (mainPressurePsi <= 30) {
        surge = false;
        mainPressurePsi = 30.0;
        shake = 0.0;
      }
    } else if (!frozen) {
      if (mainPressurePsi > 10) {
        mainPressurePsi =
            (mainPressurePsi - dt * 0.8).clamp(0.0, absoluteMaxPsi);
      }
    }

    final diff = mainPressurePsi - displayPressurePsi;
    displayPressurePsi += diff * (surge ? 0.35 : 0.14);

    if (shake > 0 && !surge) {
      shake = (shake - dt * 2.5).clamp(0.0, 1.0);
    }

    notifyListeners();
  }
}

final districtProvider = ChangeNotifierProvider<DistrictNotifier>(
  (ref) => DistrictNotifier(),
);
