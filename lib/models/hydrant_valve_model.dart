import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';

class HydrantValveModel {
  String id;
  String hydrantBarrelRegistry;
  OperatingNutGeometry operatingNutGeometry;
  FootValveGateStyle footValveGateStyle;
  String frostSleeveClearance;
  NozzleThreadStandard nozzleThreadStandard;
  MainValveStemPitch mainValveStemPitch;
  String barrelMetalThickness;
  String staticHeadPressureRating;
  String municipalDistrictBranch;
  HeadSimulationStatus headSimulationStatus;
  String barrelBoreSpec;
  String archivalNotes;
  String photoPath;
  List<String> tags;
  DateTime dateAdded;

  HydrantValveModel({
    required this.id,
    required this.hydrantBarrelRegistry,
    required this.operatingNutGeometry,
    required this.footValveGateStyle,
    required this.frostSleeveClearance,
    required this.nozzleThreadStandard,
    required this.mainValveStemPitch,
    required this.barrelMetalThickness,
    required this.staticHeadPressureRating,
    required this.municipalDistrictBranch,
    required this.headSimulationStatus,
    required this.barrelBoreSpec,
    required this.archivalNotes,
    required this.photoPath,
    required this.tags,
    required this.dateAdded,
  });

  /// Fitting identity badge: "Ø76mm / 1:12 sq / K=4.2"
  String get fittingSpecBadge {
    final bore = barrelBoreSpec.isNotEmpty ? barrelBoreSpec : 'Ø—';
    final ratio = operatingNutGeometry.driveRatio;
    final k = footValveGateStyle.baseLossCoefficient.toStringAsFixed(1);
    return '$bore / $ratio sq / K=$k';
  }

  String get headStatusLine {
    if (headSimulationStatus == HeadSimulationStatus.ready) {
      final k = footValveGateStyle.baseLossCoefficient.toStringAsFixed(1);
      final dh = (footValveGateStyle.baseLossCoefficient * 0.65)
          .toStringAsFixed(1);
      return 'HEAD: K=$k / ΔH=${dh}m';
    }
    return headSimulationStatus.label;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hydrantBarrelRegistry': hydrantBarrelRegistry,
        'operatingNutGeometry': operatingNutGeometry.name,
        'footValveGateStyle': footValveGateStyle.name,
        'frostSleeveClearance': frostSleeveClearance,
        'nozzleThreadStandard': nozzleThreadStandard.name,
        'mainValveStemPitch': mainValveStemPitch.name,
        'barrelMetalThickness': barrelMetalThickness,
        'staticHeadPressureRating': staticHeadPressureRating,
        'municipalDistrictBranch': municipalDistrictBranch,
        'headSimulationStatus': headSimulationStatus.name,
        'barrelBoreSpec': barrelBoreSpec,
        'archivalNotes': archivalNotes,
        'photoPath': photoPath,
        'tags': tags,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory HydrantValveModel.fromJson(Map<String, dynamic> json) =>
      HydrantValveModel(
        id: json['id'] ?? '',
        hydrantBarrelRegistry: json['hydrantBarrelRegistry'] ?? '',
        operatingNutGeometry: OperatingNutGeometry.values
                .asNameMap()[json['operatingNutGeometry']] ??
            OperatingNutGeometry.squareDrive15,
        footValveGateStyle: FootValveGateStyle.values
                .asNameMap()[json['footValveGateStyle']] ??
            FootValveGateStyle.flapGate,
        frostSleeveClearance: json['frostSleeveClearance'] ?? '',
        nozzleThreadStandard: NozzleThreadStandard.values
                .asNameMap()[json['nozzleThreadStandard']] ??
            NozzleThreadStandard.municipal325V,
        mainValveStemPitch: MainValveStemPitch.values
                .asNameMap()[json['mainValveStemPitch']] ??
            MainValveStemPitch.acmeDoubleLead6,
        barrelMetalThickness: json['barrelMetalThickness'] ?? '',
        staticHeadPressureRating: json['staticHeadPressureRating'] ?? '',
        municipalDistrictBranch: json['municipalDistrictBranch'] ?? '',
        headSimulationStatus: HeadSimulationStatus.values
                .asNameMap()[json['headSimulationStatus']] ??
            HeadSimulationStatus.requiresMeasurement,
        barrelBoreSpec: json['barrelBoreSpec'] ?? '',
        archivalNotes: json['archivalNotes'] ?? '',
        photoPath: json['photoPath'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        dateAdded:
            DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      );
}
