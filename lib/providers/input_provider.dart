import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';

class InputNotifier extends ChangeNotifier {
  String _hydrantBarrelRegistry = '';
  OperatingNutGeometry _operatingNutGeometry =
      OperatingNutGeometry.squareDrive15;
  FootValveGateStyle _footValveGateStyle = FootValveGateStyle.flapGate;
  String _frostSleeveClearance = '';
  NozzleThreadStandard _nozzleThreadStandard =
      NozzleThreadStandard.municipal325V;
  MainValveStemPitch _mainValveStemPitch = MainValveStemPitch.acmeDoubleLead6;
  String _barrelMetalThickness = '';
  String _staticHeadPressureRating = '';
  String _municipalDistrictBranch = '';
  HeadSimulationStatus _headSimulationStatus =
      HeadSimulationStatus.requiresMeasurement;
  String _barrelBoreSpec = '';
  String _archivalNotes = '';
  String _photoPath = '';
  List<String> _tags = [];
  DateTime _dateAdded = DateTime.now();

  String get hydrantBarrelRegistry => _hydrantBarrelRegistry;
  OperatingNutGeometry get operatingNutGeometry => _operatingNutGeometry;
  FootValveGateStyle get footValveGateStyle => _footValveGateStyle;
  String get frostSleeveClearance => _frostSleeveClearance;
  NozzleThreadStandard get nozzleThreadStandard => _nozzleThreadStandard;
  MainValveStemPitch get mainValveStemPitch => _mainValveStemPitch;
  String get barrelMetalThickness => _barrelMetalThickness;
  String get staticHeadPressureRating => _staticHeadPressureRating;
  String get municipalDistrictBranch => _municipalDistrictBranch;
  HeadSimulationStatus get headSimulationStatus => _headSimulationStatus;
  String get barrelBoreSpec => _barrelBoreSpec;
  String get archivalNotes => _archivalNotes;
  String get photoPath => _photoPath;
  List<String> get tags => _tags;
  DateTime get dateAdded => _dateAdded;

  set hydrantBarrelRegistry(String v) {
    _hydrantBarrelRegistry = v;
    notifyListeners();
  }

  set operatingNutGeometry(OperatingNutGeometry v) {
    _operatingNutGeometry = v;
    notifyListeners();
  }

  set footValveGateStyle(FootValveGateStyle v) {
    _footValveGateStyle = v;
    notifyListeners();
  }

  set frostSleeveClearance(String v) {
    _frostSleeveClearance = v;
    notifyListeners();
  }

  set nozzleThreadStandard(NozzleThreadStandard v) {
    _nozzleThreadStandard = v;
    notifyListeners();
  }

  set mainValveStemPitch(MainValveStemPitch v) {
    _mainValveStemPitch = v;
    notifyListeners();
  }

  set barrelMetalThickness(String v) {
    _barrelMetalThickness = v;
    notifyListeners();
  }

  set staticHeadPressureRating(String v) {
    _staticHeadPressureRating = v;
    notifyListeners();
  }

  set municipalDistrictBranch(String v) {
    _municipalDistrictBranch = v;
    notifyListeners();
  }

  set headSimulationStatus(HeadSimulationStatus v) {
    _headSimulationStatus = v;
    notifyListeners();
  }

  set barrelBoreSpec(String v) {
    _barrelBoreSpec = v;
    notifyListeners();
  }

  set archivalNotes(String v) {
    _archivalNotes = v;
    notifyListeners();
  }

  set photoPath(String v) {
    _photoPath = v;
    notifyListeners();
  }

  set tags(List<String> v) {
    _tags = v;
    notifyListeners();
  }

  set dateAdded(DateTime v) {
    _dateAdded = v;
    notifyListeners();
  }

  void clearAll() {
    _hydrantBarrelRegistry = '';
    _operatingNutGeometry = OperatingNutGeometry.squareDrive15;
    _footValveGateStyle = FootValveGateStyle.flapGate;
    _frostSleeveClearance = '';
    _nozzleThreadStandard = NozzleThreadStandard.municipal325V;
    _mainValveStemPitch = MainValveStemPitch.acmeDoubleLead6;
    _barrelMetalThickness = '';
    _staticHeadPressureRating = '';
    _municipalDistrictBranch = '';
    _headSimulationStatus = HeadSimulationStatus.requiresMeasurement;
    _barrelBoreSpec = '';
    _archivalNotes = '';
    _photoPath = '';
    _tags = [];
    _dateAdded = DateTime.now();
    notifyListeners();
  }
}

final inputProvider = ChangeNotifierProvider<InputNotifier>(
  (ref) => InputNotifier(),
);
