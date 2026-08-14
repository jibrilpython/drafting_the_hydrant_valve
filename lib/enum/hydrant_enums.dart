enum FootValveGateStyle {
  flapGate('Flap-gate foot valve'),
  ballValve('Ball valve'),
  gateValve('Gate valve'),
  globeValve('Globe valve'),
  nonReturn('Non-return'),
  frostCase('Frost case'),
  leatherWedge('Leather-faced compression wedge'),
  rubberFlap('Rubber-seated flap gate'),
  reversePlug('Reverse-flow plug');

  const FootValveGateStyle(this.label);
  final String label;

  String get codeAbbrev {
    switch (this) {
      case FootValveGateStyle.flapGate:
        return 'FLAP';
      case FootValveGateStyle.ballValve:
        return 'BALL';
      case FootValveGateStyle.gateValve:
        return 'GATE';
      case FootValveGateStyle.globeValve:
        return 'GLOB';
      case FootValveGateStyle.nonReturn:
        return 'NRET';
      case FootValveGateStyle.frostCase:
        return 'FRST';
      case FootValveGateStyle.leatherWedge:
        return 'WDGE';
      case FootValveGateStyle.rubberFlap:
        return 'RFLP';
      case FootValveGateStyle.reversePlug:
        return 'RPLG';
    }
  }

  /// Base head-loss coefficient K for this foot valve style.
  double get baseLossCoefficient {
    switch (this) {
      case FootValveGateStyle.flapGate:
        return 2.8;
      case FootValveGateStyle.ballValve:
        return 1.4;
      case FootValveGateStyle.gateValve:
        return 0.9;
      case FootValveGateStyle.globeValve:
        return 4.2;
      case FootValveGateStyle.nonReturn:
        return 2.2;
      case FootValveGateStyle.frostCase:
        return 1.8;
      case FootValveGateStyle.leatherWedge:
        return 3.4;
      case FootValveGateStyle.rubberFlap:
        return 2.5;
      case FootValveGateStyle.reversePlug:
        return 3.0;
    }
  }

  /// Relative bore width for cross-section motif (0.35–0.75).
  double get motifBoreRatio {
    switch (this) {
      case FootValveGateStyle.gateValve:
        return 0.72;
      case FootValveGateStyle.ballValve:
        return 0.65;
      case FootValveGateStyle.flapGate:
      case FootValveGateStyle.rubberFlap:
        return 0.58;
      case FootValveGateStyle.nonReturn:
      case FootValveGateStyle.frostCase:
        return 0.52;
      case FootValveGateStyle.leatherWedge:
      case FootValveGateStyle.globeValve:
        return 0.45;
      case FootValveGateStyle.reversePlug:
        return 0.40;
    }
  }

  bool get usesLeather =>
      this == FootValveGateStyle.leatherWedge ||
      this == FootValveGateStyle.flapGate;
}

enum OperatingNutGeometry {
  squareDrive15('1.5" square drive nut'),
  squareDrive125('1.25" square drive nut'),
  pentagonDrive('1.5" pentagon-drive nut'),
  hexDrive('1.375" hex drive nut'),
  taperedSquare('Tapered square operating nut'),
  municipalSpecial('Municipal special square nut');

  const OperatingNutGeometry(this.label);
  final String label;

  String get driveRatio {
    switch (this) {
      case OperatingNutGeometry.squareDrive15:
        return '1:12';
      case OperatingNutGeometry.squareDrive125:
        return '1:10';
      case OperatingNutGeometry.pentagonDrive:
        return '1:14';
      case OperatingNutGeometry.hexDrive:
        return '1:8';
      case OperatingNutGeometry.taperedSquare:
        return '1:16';
      case OperatingNutGeometry.municipalSpecial:
        return '1:12';
    }
  }

  double get torqueFactor {
    switch (this) {
      case OperatingNutGeometry.squareDrive15:
        return 1.0;
      case OperatingNutGeometry.squareDrive125:
        return 0.92;
      case OperatingNutGeometry.pentagonDrive:
        return 1.15;
      case OperatingNutGeometry.hexDrive:
        return 0.85;
      case OperatingNutGeometry.taperedSquare:
        return 1.25;
      case OperatingNutGeometry.municipalSpecial:
        return 1.05;
    }
  }
}

enum NozzleThreadStandard {
  municipal325V('3.25" 4-TPI V-thread municipal special'),
  national25('2.5" national standard hose'),
  britishFire('2.5" British fire brigade thread'),
  parisian('80mm Paris Service des Eaux'),
  bostonBoard('3" Boston Water Board special'),
  whitworth('Historical Whitworth hose thread');

  const NozzleThreadStandard(this.label);
  final String label;
}

enum MainValveStemPitch {
  acmeDoubleLead6('Acme double-lead 6-TPI rod'),
  acmeSingle4('Acme single-lead 4-TPI rod'),
  squareThread8('Square thread 8-TPI stem'),
  buttress5('Buttress 5-TPI operating rod'),
  trapezoidal7('Trapezoidal 7-TPI stem');

  const MainValveStemPitch(this.label);
  final String label;

  String get codeAbbrev {
    switch (this) {
      case MainValveStemPitch.acmeDoubleLead6:
        return 'ACM6';
      case MainValveStemPitch.acmeSingle4:
        return 'ACM4';
      case MainValveStemPitch.squareThread8:
        return 'SQR8';
      case MainValveStemPitch.buttress5:
        return 'BUT5';
      case MainValveStemPitch.trapezoidal7:
        return 'TRP7';
    }
  }
}

enum HeadSimulationStatus {
  ready('HEAD: READY'),
  partialSpec('HEAD: PARTIAL SPEC'),
  requiresMeasurement('HEAD: REQUIRES MEASUREMENT');

  const HeadSimulationStatus(this.label);
  final String label;
}

enum LeatherCondition {
  newLeather('New'),
  serviceable('Serviceable'),
  worn('Worn'),
  cracked('Cracked');

  const LeatherCondition(this.label);
  final String label;

  double get lossMultiplier {
    switch (this) {
      case LeatherCondition.newLeather:
        return 1.0;
      case LeatherCondition.serviceable:
        return 1.35;
      case LeatherCondition.worn:
        return 1.85;
      case LeatherCondition.cracked:
        return 2.6;
    }
  }
}

enum PipeRoughness {
  castIronNew('Cast iron new'),
  castIronTuberculated('Cast iron tuberculated'),
  wroughtIron('Wrought iron');

  const PipeRoughness(this.label);
  final String label;

  double get frictionFactor {
    switch (this) {
      case PipeRoughness.castIronNew:
        return 0.018;
      case PipeRoughness.castIronTuberculated:
        return 0.032;
      case PipeRoughness.wroughtIron:
        return 0.022;
    }
  }
}
