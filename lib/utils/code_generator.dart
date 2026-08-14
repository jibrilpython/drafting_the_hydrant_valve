import 'dart:math' as math;

import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';

String generateHydrantBarrelRegistry({
  required FootValveGateStyle valve,
  required MainValveStemPitch stem,
}) {
  final random = math.Random();
  final serial = (100 + random.nextInt(900)).toString();
  return 'DHV-${valve.codeAbbrev}-$serial-${stem.codeAbbrev}';
}

double parsePressurePsi(String rating) {
  final lower = rating.toLowerCase();
  final match = RegExp(r'([\d.]+)').firstMatch(lower);
  if (match == null) return 85;
  final value = double.tryParse(match.group(1)!) ?? 85;
  if (lower.contains('bar')) return value * 14.5038;
  if (lower.contains('kpa')) return value * 0.145038;
  if (lower.contains('m') && !lower.contains('mm') && !lower.contains('psi')) {
    return value * 1.422; // metres head ≈ PSI
  }
  return value;
}

double parseBoreMm(String boreSpec) {
  final lower = boreSpec.toLowerCase();
  final match = RegExp(r'([\d.]+)').firstMatch(lower);
  if (match == null) return 76;
  final value = double.tryParse(match.group(1)!) ?? 76;
  if (lower.contains('inch') || lower.contains('"') || lower.contains('in')) {
    return value * 25.4;
  }
  return value;
}

double parseClearanceMm(String clearance) {
  final lower = clearance.toLowerCase();
  final match = RegExp(r'([\d.]+)').firstMatch(lower);
  if (match == null) return 12.7;
  final value = double.tryParse(match.group(1)!) ?? 12.7;
  if (lower.contains('inch') || lower.contains('"') || lower.contains('in')) {
    return value * 25.4;
  }
  return value;
}

class HeadLossResult {
  final double valveLossM;
  final double frictionLossM;
  final double sleeveLossM;
  final double totalLossM;
  final double outletPressureKpa;
  final double flowVelocityMs;
  final double reynolds;
  final String flowRegime;
  final String adequacyVerdict;
  final double torqueNm;
  final double dischargeGpm;
  final double headLossK;

  const HeadLossResult({
    required this.valveLossM,
    required this.frictionLossM,
    required this.sleeveLossM,
    required this.totalLossM,
    required this.outletPressureKpa,
    required this.flowVelocityMs,
    required this.reynolds,
    required this.flowRegime,
    required this.adequacyVerdict,
    required this.torqueNm,
    required this.dischargeGpm,
    required this.headLossK,
  });
}

/// Hydraulic head-loss & valve torque for a municipal hydrant assembly.
HeadLossResult calculateHeadLoss({
  required double supplyPressurePsi,
  required double boreMm,
  required double barrelLengthMm,
  required FootValveGateStyle valveStyle,
  required LeatherCondition leatherCondition,
  required double frostClearanceMm,
  required OperatingNutGeometry nutGeometry,
  required PipeRoughness roughness,
  required double flowDemandGpm,
  required double spindleCorrosion,
}) {
  final g = 9.81;
  final supplyHeadM = supplyPressurePsi * 0.703; // PSI → metres head approx
  final boreM = boreMm / 1000;
  final area = math.pi * boreM * boreM / 4;
  final demandLs = flowDemandGpm * 0.06309; // GPM → L/s
  final demandM3s = demandLs / 1000;
  final velocity = area > 0 ? demandM3s / area : 0.0;

  final kValve =
      valveStyle.baseLossCoefficient * leatherCondition.lossMultiplier;
  final valveLoss = kValve * velocity * velocity / (2 * g);

  final f = roughness.frictionFactor;
  final lengthM = barrelLengthMm / 1000;
  final frictionLoss = area > 0
      ? f * (lengthM / boreM) * velocity * velocity / (2 * g)
      : 0.0;

  final sleeveFactor = (12.7 / frostClearanceMm.clamp(2.0, 40.0)).clamp(0.4, 3.0);
  final sleeveLoss = 0.35 * sleeveFactor * velocity * velocity / (2 * g);

  final totalLoss = valveLoss + frictionLoss + sleeveLoss;
  final outletHeadM = (supplyHeadM - totalLoss).clamp(0.0, supplyHeadM);
  final outletKpa = outletHeadM * 9.81;

  final nu = 1.0e-6; // water kinematic viscosity
  final re = boreM > 0 ? velocity * boreM / nu : 0.0;
  final regime = re > 4000
      ? 'TURBULENT'
      : re > 2300
          ? 'TRANSITIONAL'
          : 'LAMINAR';

  String verdict;
  if (outletKpa >= 140) {
    verdict = 'ADEQUATE FOR FIRE SERVICE';
  } else if (outletKpa >= 90) {
    verdict = 'MARGINAL';
  } else {
    verdict = 'INSUFFICIENT';
  }

  // Spindle torque to unseat seized lower plug (N·m)
  final baseTorque = 18.0 * nutGeometry.torqueFactor;
  final corrosion = spindleCorrosion.clamp(0.0, 1.0);
  final pressureLoad = supplyPressurePsi / 85.0;
  final torqueNm =
      baseTorque * (1.0 + corrosion * 3.8) * (0.6 + 0.4 * pressureLoad);

  // Free discharge estimate at outlet
  final dischargeGpm = outletHeadM > 0
      ? 29.83 * math.pow(boreMm / 25.4, 2) * math.sqrt(outletHeadM / 0.703)
      : 0.0;

  return HeadLossResult(
    valveLossM: valveLoss,
    frictionLossM: frictionLoss,
    sleeveLossM: sleeveLoss,
    totalLossM: totalLoss,
    outletPressureKpa: outletKpa,
    flowVelocityMs: velocity,
    reynolds: re,
    flowRegime: regime,
    adequacyVerdict: verdict,
    torqueNm: torqueNm,
    dischargeGpm: dischargeGpm.toDouble(),
    headLossK: kValve,
  );
}

LeatherCondition minimumLeatherForAdequacy({
  required double supplyPressurePsi,
  required double boreMm,
  required double barrelLengthMm,
  required FootValveGateStyle valveStyle,
  required double frostClearanceMm,
  required OperatingNutGeometry nutGeometry,
  required PipeRoughness roughness,
  required double flowDemandGpm,
}) {
  for (final cond in LeatherCondition.values) {
    final r = calculateHeadLoss(
      supplyPressurePsi: supplyPressurePsi,
      boreMm: boreMm,
      barrelLengthMm: barrelLengthMm,
      valveStyle: valveStyle,
      leatherCondition: cond,
      frostClearanceMm: frostClearanceMm,
      nutGeometry: nutGeometry,
      roughness: roughness,
      flowDemandGpm: flowDemandGpm,
      spindleCorrosion: 0.2,
    );
    if (r.adequacyVerdict.contains('ADEQUATE')) return cond;
  }
  return LeatherCondition.cracked;
}
