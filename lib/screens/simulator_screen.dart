import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';
import 'package:drafting_the_hydrant_valve/providers/project_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/code_generator.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/utils/layout.dart';

class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final ValueNotifier<int> _hglTick = ValueNotifier<int>(0);

  int? _selectedHydrantIndex;
  double _supplyPressurePsi = 85;
  double _spindleCorrosion = 0.25;
  double _flowDemandGpm = 500;
  LeatherCondition _leatherCondition = LeatherCondition.serviceable;
  PipeRoughness _roughness = PipeRoughness.castIronNew;

  // Animated display values (spring toward computed targets each tick)
  double _animValveLoss = 0;
  double _animFrictionLoss = 0;
  double _animSleeveLoss = 0;
  double _animTotalLoss = 0;
  double _animOutletKpa = 0;
  double _animSupplyHeadM = 85 * 0.703;
  double _animGradePhase = 0;

  static const _manualDefaultsLabel = 'Manual defaults';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hglTick.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    final r = _computeResult();
    const k = 0.14;
    final supplyHeadM = _supplyPressurePsi * 0.703;
    _animValveLoss += (r.valveLossM - _animValveLoss) * k;
    _animFrictionLoss += (r.frictionLossM - _animFrictionLoss) * k;
    _animSleeveLoss += (r.sleeveLossM - _animSleeveLoss) * k;
    _animTotalLoss += (r.totalLossM - _animTotalLoss) * k;
    _animOutletKpa += (r.outletPressureKpa - _animOutletKpa) * k;
    _animSupplyHeadM += (supplyHeadM - _animSupplyHeadM) * k;
    _animGradePhase += 0.018;
    _hglTick.value++;
  }

  HydrantValveModel? get _selectedHydrant {
    final entries = ref.read(projectProvider).entries;
    if (_selectedHydrantIndex == null ||
        _selectedHydrantIndex! < 0 ||
        _selectedHydrantIndex! >= entries.length) {
      return null;
    }
    return entries[_selectedHydrantIndex!];
  }

  FootValveGateStyle get _valveStyle =>
      _selectedHydrant?.footValveGateStyle ?? FootValveGateStyle.flapGate;

  OperatingNutGeometry get _nutGeometry =>
      _selectedHydrant?.operatingNutGeometry ??
      OperatingNutGeometry.squareDrive15;

  double get _boreMm => _selectedHydrant != null
      ? parseBoreMm(_selectedHydrant!.barrelBoreSpec)
      : 76;

  double get _clearanceMm => _selectedHydrant != null
      ? parseClearanceMm(_selectedHydrant!.frostSleeveClearance)
      : 12.7;

  double get _barrelLengthMm {
    final h = _selectedHydrant;
    if (h == null) return 900;
    final t = h.barrelMetalThickness.toLowerCase();
    final match = RegExp(r'([\d.]+)\s*(mm|m\b)').firstMatch(t);
    if (match != null) {
      final v = double.tryParse(match.group(1)!) ?? 900;
      if (match.group(2) == 'm') return v * 1000;
      return v;
    }
    return (_boreMm * 11.8).clamp(760.0, 1200.0);
  }

  String get _districtLabel =>
      _selectedHydrant?.municipalDistrictBranch ?? 'Generic municipal district';

  HeadLossResult _computeResult() {
    return calculateHeadLoss(
      supplyPressurePsi: _supplyPressurePsi,
      boreMm: _boreMm,
      barrelLengthMm: _barrelLengthMm,
      valveStyle: _valveStyle,
      leatherCondition: _leatherCondition,
      frostClearanceMm: _clearanceMm,
      nutGeometry: _nutGeometry,
      roughness: _roughness,
      flowDemandGpm: _flowDemandGpm,
      spindleCorrosion: _spindleCorrosion,
    );
  }

  double _districtSurveyKpa(String district) {
    if (district.isEmpty) return 168.0;
    final hash = district.codeUnits.fold<int>(0, (a, b) => a + b);
    return 118.0 + (hash % 72).toDouble();
  }

  void _selectHydrant(int? index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHydrantIndex = index;
      if (index != null) {
        final h = ref.read(projectProvider).entries[index];
        _supplyPressurePsi = parsePressurePsi(
          h.staticHeadPressureRating.isNotEmpty
              ? h.staticHeadPressureRating
              : '85 PSI',
        );
      }
    });
  }

  TextStyle _mono({
    double? size,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.3,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: size ?? 11.sp,
      fontWeight: weight,
      color: color ?? kPrimaryText,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _sectionLabel() => _mono(
        size: 9.sp,
        weight: FontWeight.w600,
        color: kSecondaryText,
        letterSpacing: 0.8,
      );

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final entries = project.entries;
    final result = _computeResult();
    final minLeather = minimumLeatherForAdequacy(
      supplyPressurePsi: _supplyPressurePsi,
      boreMm: _boreMm,
      barrelLengthMm: _barrelLengthMm,
      valveStyle: _valveStyle,
      frostClearanceMm: _clearanceMm,
      nutGeometry: _nutGeometry,
      roughness: _roughness,
      flowDemandGpm: _flowDemandGpm,
    );
    final surveyKpa = _districtSurveyKpa(_districtLabel);
    final surveyDelta = result.outletPressureKpa - surveyKpa;
    final top = MediaQuery.paddingOf(context).top;
    final bottomPad = tabScrollBottomInset(context);

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (project.isLoading)
            SizedBox(
              height: 2.h,
              child: const LinearProgressIndicator(
                backgroundColor: kOutline,
                color: kAccent,
                minHeight: 2,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, top + 12.h, 20.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HEAD-LOSS',
                  style: _mono(
                    size: 8.sp,
                    weight: FontWeight.w600,
                    color: kAccent.withAlpha(160),
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Hydraulic Simulator',
                  style: GoogleFonts.archivo(
                    color: kPrimaryText,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Pressure head loss through cast-iron barrel & leather foot valve',
                  style: GoogleFonts.ibmPlexSans(
                    color: kSecondaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, bottomPad),
              children: [
                _buildHydrantSelector(entries),
                SizedBox(height: 14.h),
                _buildSimPanel(result),
                SizedBox(height: 14.h),
                _buildVerdictBanner(result),
                SizedBox(height: 14.h),
                _buildReadouts(result),
                SizedBox(height: 14.h),
                _buildLeatherPanel(result, minLeather),
                SizedBox(height: 14.h),
                _buildSurveyPanel(result, surveyKpa, surveyDelta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrantSelector(List<HydrantValveModel> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATALOGUED FITTING', style: _sectionLabel()),
        SizedBox(height: 8.h),
        SizedBox(
          height: 78.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: entries.length + 1,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, i) {
              if (i == 0) {
                final sel = _selectedHydrantIndex == null;
                return _hydrantChip(
                  title: _manualDefaultsLabel,
                  subtitle: 'Ø76mm / FLAP / K=2.8',
                  selected: sel,
                  onTap: () => _selectHydrant(null),
                );
              }
              final idx = i - 1;
              final h = entries[idx];
              final sel = _selectedHydrantIndex == idx;
              return _hydrantChip(
                title: h.hydrantBarrelRegistry,
                subtitle: h.fittingSpecBadge,
                selected: sel,
                statusColor: getSimColor(h.headSimulationStatus),
                onTap: () => _selectHydrant(idx),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hydrantChip({
    required String title,
    required String subtitle,
    required bool selected,
    Color? statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOut,
        width: 148.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: selected ? kSelectedTint : kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(
            color: selected ? kAccent : kOutline,
            width: selected ? kStrokeWeightMedium : kStrokeWeight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Container(
                width: 3.w,
                height: 14.h,
                margin: EdgeInsets.only(bottom: 4.h),
                decoration: BoxDecoration(
                  color: kAccent,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            Text(
              title,
              style: GoogleFonts.ibmPlexSans(
                color: kPrimaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: _mono(
                size: 8.sp,
                color: statusColor ?? kAccent,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimPanel(HeadLossResult result) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kSimPanel,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.22,
            child: RepaintBoundary(
              child: ValueListenableBuilder<int>(
                valueListenable: _hglTick,
                builder: (context, _, _) {
                  return CustomPaint(
                    painter: _HydraulicGradientPainter(
                      valveLossM: _animValveLoss.clamp(0.0, 1e6),
                      frictionLossM: _animFrictionLoss.clamp(0.0, 1e6),
                      sleeveLossM: _animSleeveLoss.clamp(0.0, 1e6),
                      totalLossM: _animTotalLoss.clamp(0.0, 1e6),
                      supplyHeadM: math.max(_animSupplyHeadM, 0.5),
                      valveStyle: _valveStyle,
                      boreMm: _boreMm,
                      phase: _animGradePhase,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _sliderBlock(
            label: 'WATER MAIN STATIC PRESSURE',
            valueLabel: '${_supplyPressurePsi.toStringAsFixed(0)} PSI',
            value: _supplyPressurePsi,
            min: 30,
            max: 200,
            onChanged: (v) => setState(() => _supplyPressurePsi = v),
          ),
          SizedBox(height: 10.h),
          _sliderBlock(
            label: 'SPINDLE CORROSION (SEIZED FACTOR)',
            valueLabel: _spindleCorrosion.toStringAsFixed(2),
            value: _spindleCorrosion,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (v) => setState(() => _spindleCorrosion = v),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _sliderBlock(
                  label: 'FLOW DEMAND',
                  valueLabel: '${_flowDemandGpm.toStringAsFixed(0)} GPM',
                  value: _flowDemandGpm,
                  min: 100,
                  max: 1500,
                  onChanged: (v) => setState(() => _flowDemandGpm = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text('LEATHER CONDITION', style: _sectionLabel()),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: LeatherCondition.values.map((c) {
              final sel = c == _leatherCondition;
              return _compactChip(
                label: c.label.toUpperCase(),
                selected: sel,
                accent: c == LeatherCondition.cracked ? kLeather : kAccent,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _leatherCondition = c);
                },
              );
            }).toList(),
          ),
          SizedBox(height: 10.h),
          Text('PIPE ROUGHNESS', style: _sectionLabel()),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: PipeRoughness.values.map((r) {
              final sel = r == _roughness;
              return _compactChip(
                label: r.label,
                selected: sel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _roughness = r);
                },
              );
            }).toList(),
          ),
          if (_selectedHydrant != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: kPanelBg,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: kOutline),
              ),
              child: Text(
                '${_selectedHydrant!.fittingSpecBadge} · ${_selectedHydrant!.headStatusLine}',
                style: _mono(size: 9.sp, color: kSecondaryText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _sectionLabel())),
            Text(
              valueLabel,
              style: _mono(size: 11.sp, weight: FontWeight.w700, color: kAccent),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: kAccent,
            inactiveTrackColor: kOutline,
            thumbColor: kAccent,
            overlayColor: kAccent.withAlpha(40),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _compactChip({
    required String label,
    required bool selected,
    Color accent = kAccent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(28) : kPanelBg,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: selected ? accent : kOutline),
        ),
        child: Text(
          label,
          style: _mono(
            size: 9.sp,
            weight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accent : kSecondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildVerdictBanner(HeadLossResult result) {
    final color = getAdequacyColor(result.adequacyVerdict);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: color, width: kStrokeWeightMedium),
      ),
      child: Column(
        children: [
          Text(
            'MUNICIPAL ADEQUACY VERDICT',
            style: _mono(
              size: 9.sp,
              weight: FontWeight.w600,
              color: kSecondaryText,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            result.adequacyVerdict,
            textAlign: TextAlign.center,
            style: GoogleFonts.archivo(
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadouts(HeadLossResult result) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HYDRAULIC OUTPUTS', style: _sectionLabel()),
          SizedBox(height: 10.h),
          Row(
            children: [
              _readout('ΔH_valve', '${result.valveLossM.toStringAsFixed(2)} m'),
              _readout(
                'ΔH_friction',
                '${result.frictionLossM.toStringAsFixed(2)} m',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _readout('ΔH_sleeve', '${result.sleeveLossM.toStringAsFixed(2)} m'),
              _readout('ΔH_total', '${result.totalLossM.toStringAsFixed(2)} m'),
            ],
          ),
          Divider(height: 20.h, color: kOutline),
          Row(
            children: [
              _readout(
                'P_outlet',
                '${result.outletPressureKpa.toStringAsFixed(0)} kPa',
              ),
              _readout('v', '${result.flowVelocityMs.toStringAsFixed(2)} m/s'),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _readout('Re', result.reynolds.toStringAsFixed(0)),
              _readout('REGIME', result.flowRegime),
            ],
          ),
          Divider(height: 20.h, color: kOutline),
          Row(
            children: [
              _readout(
                'TORQUE',
                '${result.torqueNm.toStringAsFixed(1)} N·m',
              ),
              _readout(
                'DISCHARGE',
                '${result.dischargeGpm.toStringAsFixed(0)} GPM',
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'K=${result.headLossK.toStringAsFixed(1)} · Ø${_boreMm.toStringAsFixed(0)}mm · ${_nutGeometry.driveRatio} sq',
            style: _mono(size: 9.sp, color: kSecondaryText),
          ),
        ],
      ),
    );
  }

  Widget _readout(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _mono(size: 8.sp, color: kSecondaryText)),
          SizedBox(height: 2.h),
          Text(
            value,
            style: _mono(size: 14.sp, weight: FontWeight.w700, color: kAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildLeatherPanel(HeadLossResult result, LeatherCondition minLeather) {
    final rows = LeatherCondition.values.map((cond) {
      final r = calculateHeadLoss(
        supplyPressurePsi: _supplyPressurePsi,
        boreMm: _boreMm,
        barrelLengthMm: _barrelLengthMm,
        valveStyle: _valveStyle,
        leatherCondition: cond,
        frostClearanceMm: _clearanceMm,
        nutGeometry: _nutGeometry,
        roughness: _roughness,
        flowDemandGpm: _flowDemandGpm,
        spindleCorrosion: _spindleCorrosion,
      );
      return _LeatherRow(
        condition: cond,
        valveLoss: r.valveLossM,
        outletKpa: r.outletPressureKpa,
        verdict: r.adequacyVerdict,
        isCurrent: cond == _leatherCondition,
      );
    }).toList();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, color: kLeather, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'LEATHER VALVE DEGRADATION',
                style: _sectionLabel().copyWith(color: kLeather),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Foot valve loss increase from new leather through cracked condition',
            style: GoogleFonts.ibmPlexSans(
              color: kSecondaryText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 12.h),
          ...rows.map(_leatherRowTile),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: kLeather.withAlpha(18),
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kLeather.withAlpha(90)),
            ),
            child: Text(
              'Minimum leather for adequacy: ${minLeather.label.toUpperCase()} '
              '(current: ${_leatherCondition.label.toUpperCase()}, '
              'ΔH_valve=${result.valveLossM.toStringAsFixed(2)}m)',
              style: _mono(size: 10.sp, color: kLeather, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leatherRowTile(_LeatherRow row) {
    final verdictColor = getAdequacyColor(row.verdict);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 88.w,
            child: Text(
              row.condition.label.toUpperCase(),
              style: _mono(
                size: 10.sp,
                weight: row.isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: row.isCurrent ? kLeather : kSecondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'ΔH=${row.valveLoss.toStringAsFixed(2)}m · '
              'P=${row.outletKpa.toStringAsFixed(0)} kPa',
              style: _mono(size: 9.sp),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: verdictColor.withAlpha(24),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: verdictColor.withAlpha(120)),
            ),
            child: Text(
              row.verdict.split(' ').first,
              style: _mono(size: 8.sp, color: verdictColor, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyPanel(
    HeadLossResult result,
    double surveyKpa,
    double delta,
  ) {
    final converged = delta.abs() <= 12;
    final flagColor = converged ? kAccent : kLeather;
    final message = converged
        ? 'Convergence validates specification record against district survey.'
        : delta > 0
            ? 'Computed exceeds survey — possible main pressure rise or improved leather.'
            : 'Computed below survey — condition change or specification error flagged.';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kSimPanel.withAlpha(180),
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORICAL PRESSURE SURVEY',
            style: _sectionLabel(),
          ),
          SizedBox(height: 4.h),
          Text(
            _districtLabel,
            style: GoogleFonts.ibmPlexSans(
              color: kPrimaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _readout(
                'COMPUTED',
                '${result.outletPressureKpa.toStringAsFixed(0)} kPa',
              ),
              _readout(
                'SURVEY 1889',
                '${surveyKpa.toStringAsFixed(0)} kPa',
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _readout(
                'Δ',
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kPa',
              ),
              _readout(
                'STATUS',
                converged ? 'CONVERGENT' : 'DIVERGENT',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: flagColor.withAlpha(20),
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: flagColor.withAlpha(100)),
            ),
            child: Text(
              message,
              style: GoogleFonts.ibmPlexSans(
                color: flagColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeatherRow {
  final LeatherCondition condition;
  final double valveLoss;
  final double outletKpa;
  final String verdict;
  final bool isCurrent;

  const _LeatherRow({
    required this.condition,
    required this.valveLoss,
    required this.outletKpa,
    required this.verdict,
    required this.isCurrent,
  });
}

class _HydraulicGradientPainter extends CustomPainter {
  final double valveLossM;
  final double frictionLossM;
  final double sleeveLossM;
  final double totalLossM;
  final double supplyHeadM;
  final FootValveGateStyle valveStyle;
  final double boreMm;
  final double phase;

  _HydraulicGradientPainter({
    required this.valveLossM,
    required this.frictionLossM,
    required this.sleeveLossM,
    required this.totalLossM,
    required this.supplyHeadM,
    required this.valveStyle,
    required this.boreMm,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const titleH = 18.0;
    const captionH = 44.0;
    final splitX = size.width * 0.24;
    final plotLeft = splitX + 6;
    final plotRight = size.width - 8;
    final plotTop = titleH + 6;
    final plotBottom = size.height - captionH - 6;

    final titleTp = _monoText(
      'HYDRAULIC GRADE LINE',
      kSecondaryText.withAlpha(200),
      9,
      letterSpacing: 1.1,
      weight: FontWeight.w500,
    );
    titleTp.paint(canvas, Offset(8, (titleH - titleTp.height) / 2));

    _drawHydrant(
      canvas,
      Rect.fromLTRB(4, plotTop, splitX, plotBottom),
    );

    final supply = math.max(supplyHeadM, 0.5);
    final hAfterValve = math.max(0.0, supply - valveLossM);
    final hAfterFriction = math.max(0.0, hAfterValve - frictionLossM);
    final hOutlet = math.max(0.0, hAfterFriction - sleeveLossM);

    double yFor(double head) {
      final t = (head / supply).clamp(0.0, 1.0);
      return plotBottom - t * (plotBottom - plotTop);
    }

    final x0 = plotLeft;
    final xValve = plotLeft + (plotRight - plotLeft) * 0.20;
    final xFricEnd = plotLeft + (plotRight - plotLeft) * 0.58;
    final xSleeve = plotLeft + (plotRight - plotLeft) * 0.74;
    final xOut = plotRight - 2;

    final yInlet = yFor(supply);
    final yValve = yFor(hAfterValve);
    final yFric = yFor(hAfterFriction);
    final yOut = yFor(hOutlet);

    canvas.drawLine(
      Offset(plotLeft, plotBottom),
      Offset(xOut, plotBottom),
      Paint()
        ..color = kOutline
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(plotLeft, plotTop),
      Offset(xOut, plotTop),
      Paint()
        ..color = kAccent.withAlpha(28)
        ..strokeWidth = 1.0,
    );

    final pulse = (math.sin(phase) * 0.5 + 0.5);
    final hglPaint = Paint()
      ..color = kAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + pulse * 0.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(x0, yInlet)
      ..lineTo(xValve, yInlet)
      ..lineTo(xValve, yValve)
      ..lineTo(xFricEnd, yFric)
      ..lineTo(xSleeve, yFric)
      ..lineTo(xSleeve, yOut)
      ..lineTo(xOut, yOut);
    canvas.drawPath(path, hglPaint);

    final node = Paint()..color = kAccent;
    final stations = [
      Offset(x0, yInlet),
      Offset(xValve, yInlet),
      Offset(xValve, yValve),
      Offset(xFricEnd, yFric),
      Offset(xSleeve, yFric),
      Offset(xSleeve, yOut),
      Offset(xOut, yOut),
    ];
    for (final p in stations) {
      canvas.drawCircle(p, 2.2, node);
    }

    final shimmer = _pointOnPolyline(stations, (phase * 0.07) % 1.0);
    canvas.drawCircle(
      shimmer,
      3.0 + pulse,
      Paint()..color = kAccent.withAlpha(190),
    );

    final captions = [
      _HglCaption(
        station: Offset(xValve, math.max(yInlet, yValve)),
        key: 'ΔH_valve',
        value: '${valveLossM.toStringAsFixed(1)}m',
        color: kLeather,
      ),
      _HglCaption(
        station: Offset((xValve + xFricEnd) / 2, math.max(yValve, yFric)),
        key: 'ΔH_fric',
        value: '${frictionLossM.toStringAsFixed(1)}m',
        color: kAccent,
      ),
      _HglCaption(
        station: Offset(xSleeve, math.max(yFric, yOut)),
        key: 'ΔH_sleeve',
        value: '${sleeveLossM.toStringAsFixed(1)}m',
        color: kSecondaryText,
      ),
      _HglCaption(
        station: Offset(xOut, yOut),
        key: 'P_out',
        value: '${hOutlet.toStringAsFixed(1)}m',
        color: kAccent,
      ),
    ];
    _drawCaptionStrip(
      canvas,
      captions,
      plotLeft: plotLeft,
      plotRight: xOut,
      plotBottom: plotBottom,
      stripTop: plotBottom + 8,
    );

    canvas.restore();
  }

  void _drawHydrant(Canvas canvas, Rect bounds) {
    final cx = bounds.center.dx;
    final barrelW = (bounds.width * 0.42 * (boreMm / 76).clamp(0.75, 1.3))
        .clamp(10.0, bounds.width * 0.7);
    final frostW = barrelW * 1.32;
    final top = bounds.top + 10;
    final bottom = bounds.bottom - 4;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, (top + bottom) / 2),
        width: frostW,
        height: bottom - top,
      ),
      Paint()
        ..color = kSecondaryText.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, (top + bottom) / 2),
        width: barrelW,
        height: bottom - top,
      ),
      Paint()
        ..color = kPrimaryText.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final nut = barrelW * 0.55;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, top - 1),
        width: nut,
        height: nut * 0.55,
      ),
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final flap = Paint()
      ..color = valveStyle.usesLeather ? kLeather : kAccent
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - barrelW * 0.38, bottom - 3),
      Offset(cx + barrelW * 0.38, bottom - 7),
      flap,
    );

    canvas.drawLine(
      Offset(cx + barrelW / 2, top + (bottom - top) * 0.32),
      Offset(bounds.right - 2, top + (bottom - top) * 0.32),
      Paint()
        ..color = kAccent.withAlpha(140)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  Offset _pointOnPolyline(List<Offset> pts, double t) {
    double total = 0;
    final segs = <double>[];
    for (int i = 1; i < pts.length; i++) {
      final d = (pts[i] - pts[i - 1]).distance;
      segs.add(d);
      total += d;
    }
    if (total <= 0) return pts.first;
    var remain = t.clamp(0.0, 1.0) * total;
    for (int i = 1; i < pts.length; i++) {
      final d = segs[i - 1];
      if (remain <= d) {
        final u = d == 0 ? 0.0 : remain / d;
        return Offset.lerp(pts[i - 1], pts[i], u)!;
      }
      remain -= d;
    }
    return pts.last;
  }

  TextPainter _monoText(
    String text,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0.2,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: 'monospace',
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  void _drawCaptionStrip(
    Canvas canvas,
    List<_HglCaption> captions, {
    required double plotLeft,
    required double plotRight,
    required double plotBottom,
    required double stripTop,
  }) {
    final count = captions.length;
    if (count == 0) return;
    final width = plotRight - plotLeft;
    final colW = width / count;
    final leader = Paint()
      ..color = kSecondaryText.withAlpha(70)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final cap = captions[i];
      final colLeft = plotLeft + colW * i;
      final cx = colLeft + colW / 2;

      _dashedLine(
        canvas,
        Offset(cap.station.dx, cap.station.dy),
        Offset(cap.station.dx, plotBottom),
        leader,
      );
      _dashedLine(
        canvas,
        Offset(cap.station.dx, plotBottom),
        Offset(cx, stripTop - 2),
        leader,
      );

      final keyTp = _monoText(cap.key, cap.color.withAlpha(180), 7);
      final valTp = _monoText(
        cap.value,
        cap.color,
        9,
        weight: FontWeight.w700,
      );
      keyTp.paint(canvas, Offset(cx - keyTp.width / 2, stripTop));
      valTp.paint(
        canvas,
        Offset(cx - valTp.width / 2, stripTop + keyTp.height + 1),
      );
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = (b - a).distance;
    if (d < 1) return;
    const dash = 3.0;
    const gap = 3.0;
    final dir = (b - a) / d;
    var drawn = 0.0;
    while (drawn < d) {
      final start = a + dir * drawn;
      final end = a + dir * math.min(drawn + dash, d);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HydraulicGradientPainter old) =>
      old.valveLossM != valveLossM ||
      old.frictionLossM != frictionLossM ||
      old.sleeveLossM != sleeveLossM ||
      old.totalLossM != totalLossM ||
      old.supplyHeadM != supplyHeadM ||
      old.valveStyle != valveStyle ||
      old.boreMm != boreMm ||
      old.phase != phase;
}

class _HglCaption {
  final Offset station;
  final String key;
  final String value;
  final Color color;

  const _HglCaption({
    required this.station,
    required this.key,
    required this.value,
    required this.color,
  });
}
