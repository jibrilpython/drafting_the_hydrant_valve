import 'package:flutter/material.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';

// Municipal Works Record — council paper / waterworks green
const Color kBackground = Color(0xFFF3F4F1);
const Color kPrimaryText = Color(0xFF131814);
const Color kPanelBg = Color(0xFFFFFFFF);
const Color kSecondaryText = Color(0xFF687268);
const Color kAccent = Color(0xFF1A5C3A);
const Color kOutline = Color(0xFFE4E6E2);
const Color kLeather = Color(0xFF8B4A18);
const Color kError = Color(0xFFC0392B);

const Color kSimPanel = Color(0xFFEDF0EC);
const Color kSelectedTint = Color(0xFFEAF4EE);
const Color kAccentSurface = Color(0xFFEAF4EE);
const Color kGlassBg = Color(0xCCFFFFFF);

const double kSpacingXXS = 4.0;
const double kSpacingXS = 8.0;
const double kSpacingS = 12.0;
const double kSpacingM = 16.0;
const double kSpacingL = 20.0;
const double kSpacingXL = 24.0;
const double kSpacingXXL = 32.0;
const double kSpacingXXXL = 48.0;

const double kRadiusCard = 10.0;
const double kRadiusMedium = 14.0;
const double kRadiusLarge = 20.0;
const double kRadiusPill = 999.0;

const BoxShadow kShadowSubtle = BoxShadow(
  offset: Offset(0, 2),
  blurRadius: 8,
  spreadRadius: -1,
  color: Color(0x14000000),
);

const BoxShadow kShadowFloat = BoxShadow(
  offset: Offset(0, 8),
  blurRadius: 24,
  spreadRadius: -4,
  color: Color(0x18000000),
);

const BoxShadow kShadowAccent = BoxShadow(
  offset: Offset(0, 4),
  blurRadius: 16,
  spreadRadius: -2,
  color: Color(0x331A5C3A),
);

const double kStrokeWeight = 1.0;
const double kStrokeWeightMedium = 1.5;

Color getValveColor(FootValveGateStyle style) {
  if (style.usesLeather) return kLeather;
  switch (style) {
    case FootValveGateStyle.flapGate:
    case FootValveGateStyle.rubberFlap:
      return kAccent;
    case FootValveGateStyle.ballValve:
      return const Color(0xFF2A7048);
    case FootValveGateStyle.gateValve:
      return const Color(0xFF1A5C3A);
    case FootValveGateStyle.globeValve:
      return kLeather;
    case FootValveGateStyle.nonReturn:
      return const Color(0xFF3D6B52);
    case FootValveGateStyle.frostCase:
      return const Color(0xFF4A6B5A);
    case FootValveGateStyle.leatherWedge:
      return kLeather;
    case FootValveGateStyle.reversePlug:
      return const Color(0xFF6B5038);
  }
}

Color getSimColor(HeadSimulationStatus status) {
  switch (status) {
    case HeadSimulationStatus.ready:
      return kAccent;
    case HeadSimulationStatus.partialSpec:
      return kLeather;
    case HeadSimulationStatus.requiresMeasurement:
      return kSecondaryText;
  }
}

Color getAdequacyColor(String verdict) {
  final v = verdict.toUpperCase();
  if (v.contains('ADEQUATE')) return kAccent;
  if (v.contains('MARGINAL')) return kLeather;
  return kError;
}

bool isHydraulicallyIntact(HeadSimulationStatus status) =>
    status == HeadSimulationStatus.ready;
