import 'dart:math' as math;

import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';
import 'package:drafting_the_hydrant_valve/providers/project_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/code_generator.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/utils/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class _SectionNode {
  final String id;
  String label;
  String value;
  Offset anchor;
  Offset home;
  Color color;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  bool dragging = false;
  double lift = 0;

  _SectionNode({
    required this.id,
    required this.label,
    required this.value,
    required this.anchor,
    required this.home,
    required this.color,
  })  : x = home.dx,
        y = home.dy;

  Offset get offset => Offset(x, y);

  bool contains(Offset p) {
    final r = Rect.fromCenter(center: offset, width: 132, height: 54);
    return r.inflate(8).contains(p);
  }

  void retarget({
    required String label,
    required String value,
    required Offset anchor,
    required Offset home,
    required Color color,
  }) {
    this.label = label;
    this.value = value;
    this.anchor = anchor;
    this.home = home;
    this.color = color;
  }
}

class _GaugeResult {
  final HeadLossResult result;
  final double boreMm;
  final double clearanceMm;
  final double ratingPsi;

  const _GaugeResult({
    required this.result,
    required this.boreMm,
    required this.clearanceMm,
    required this.ratingPsi,
  });
}

class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_SectionNode> _nodes = [];
  final ValueNotifier<int> _benchTick = ValueNotifier<int>(0);

  int _selectedRecord = 0;
  String? _activeNodeId;
  _SectionNode? _dragging;
  String _lastLayoutKey = '';
  double _time = 0;
  double _pressurePsi = 85;
  double _spindleCorrosion = 0.24;
  double _keyTurns = 0;
  Offset? _lastPan;
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _benchTick.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;
    const dt = 0.016;
    _time += dt;

    for (final node in _nodes) {
      if (node.dragging) {
        node.lift = (node.lift + dt * 8).clamp(0.0, 1.0);
        continue;
      }
      final float = Offset(
        math.sin(_time * 0.9 + node.id.hashCode) * 1.8,
        math.cos(_time * 0.7 + node.id.hashCode) * 1.2,
      );
      final target = node.home + float;
      node.vx += (target.dx - node.x) * 0.06;
      node.vy += (target.dy - node.y) * 0.06;
      node.vx *= 0.76;
      node.vy *= 0.76;
      node.x += node.vx;
      node.y += node.vy;
      node.lift = (node.lift - dt * 4.5).clamp(0.0, 1.0);
    }

    _benchTick.value++;
  }

  HydrantValveModel? _selectedItem(List<HydrantValveModel> entries) {
    if (entries.isEmpty) return null;
    if (_selectedRecord >= entries.length) _selectedRecord = entries.length - 1;
    return entries[_selectedRecord];
  }

  _GaugeResult _resultFor(HydrantValveModel item) {
    final boreMm = parseBoreMm(item.barrelBoreSpec);
    final clearanceMm = parseClearanceMm(item.frostSleeveClearance);
    final ratingPsi = parsePressurePsi(item.staticHeadPressureRating);
    final lengthMm = (boreMm * 11.8).clamp(760.0, 1280.0);
    return _GaugeResult(
      boreMm: boreMm,
      clearanceMm: clearanceMm,
      ratingPsi: ratingPsi,
      result: calculateHeadLoss(
        supplyPressurePsi: _pressurePsi,
        boreMm: boreMm,
        barrelLengthMm: lengthMm,
        valveStyle: item.footValveGateStyle,
        leatherCondition: item.footValveGateStyle.usesLeather
            ? LeatherCondition.serviceable
            : LeatherCondition.newLeather,
        frostClearanceMm: clearanceMm,
        nutGeometry: item.operatingNutGeometry,
        roughness: PipeRoughness.castIronNew,
        flowDemandGpm: 520,
        spindleCorrosion: _spindleCorrosion,
      ),
    );
  }

  String _recorded(String value, {required String fallback}) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  void _syncNodes(HydrantValveModel item, _GaugeResult gauge, Size size) {
    final layoutKey =
        '${item.id}:${ref.read(projectProvider).stateVersion}:${size.width.toInt()}x${size.height.toInt()}';
    final layoutChanged = _lastLayoutKey != layoutKey;
    _lastLayoutKey = layoutKey;

    final assembly = _assemblyRect(size);
    final leftX = 22.0;
    final rightX = size.width - 22.0;
    final topY = assembly.top + 12;
    final midY = assembly.center.dy;
    final bottomY = assembly.bottom - 10;
    final color = getValveColor(item.footValveGateStyle);
    final boreLabel = _recorded(item.barrelBoreSpec, fallback: 'Ø unrecorded');
    final wallLabel = _recorded(
      item.barrelMetalThickness,
      fallback: 'wall unrecorded',
    );
    final sleeveLabel = _recorded(
      item.frostSleeveClearance,
      fallback: 'clearance unrecorded',
    );

    final specs = <_NodeSpec>[
      _NodeSpec(
        id: 'nut',
        label: 'OPERATING NUT',
        value:
            '${item.operatingNutGeometry.driveRatio} sq / ${item.operatingNutGeometry.label}',
        anchor: Offset(assembly.center.dx, assembly.top + 18),
        home: Offset(leftX + 62, topY),
        color: kAccent,
      ),
      _NodeSpec(
        id: 'nozzle',
        label: 'NOZZLE THREAD',
        value: item.nozzleThreadStandard.label,
        anchor: Offset(assembly.right - 4, assembly.top + assembly.height * 0.34),
        home: Offset(rightX - 62, topY + 32),
        color: kAccent,
      ),
      _NodeSpec(
        id: 'sleeve',
        label: 'FROST SLEEVE',
        value: sleeveLabel,
        anchor: Offset(assembly.left + 8, midY - 18),
        home: Offset(leftX + 66, midY - 8),
        color: kSecondaryText,
      ),
      _NodeSpec(
        id: 'barrel',
        label: 'BARREL SECTION',
        value: '$boreLabel / $wallLabel',
        anchor: Offset(assembly.center.dx, midY + 4),
        home: Offset(rightX - 62, midY + 24),
        color: kPrimaryText,
      ),
      _NodeSpec(
        id: 'stem',
        label: 'STEM PITCH',
        value: item.mainValveStemPitch.label,
        anchor: Offset(assembly.center.dx, assembly.top + assembly.height * 0.58),
        home: Offset(leftX + 62, bottomY - 30),
        color: kAccent,
      ),
      _NodeSpec(
        id: 'valve',
        label: 'FOOT VALVE',
        value:
            '${item.footValveGateStyle.label} / K=${item.footValveGateStyle.baseLossCoefficient.toStringAsFixed(1)}',
        anchor: Offset(assembly.center.dx, assembly.bottom - 28),
        home: Offset(rightX - 62, bottomY),
        color: color,
      ),
    ];

    for (final spec in specs) {
      final existing = _nodes.where((n) => n.id == spec.id).firstOrNull;
      if (existing == null) {
        _nodes.add(
          _SectionNode(
            id: spec.id,
            label: spec.label,
            value: spec.value,
            anchor: spec.anchor,
            home: spec.home,
            color: spec.color,
          ),
        );
      } else {
        existing.retarget(
          label: spec.label,
          value: spec.value,
          anchor: spec.anchor,
          home: layoutChanged ? spec.home : existing.home,
          color: spec.color,
        );
      }
    }
  }

  Rect _assemblyRect(Size size) {
    final nav = bottomNavOccupiedHeight(context);
    final top = 54.0;
    final bottom = size.height - nav - 150;
    final height = math.max(270.0, bottom - top);
    final width = math.min(154.0, size.width * 0.42);
    return Rect.fromCenter(
      center: Offset(size.width / 2, top + height / 2),
      width: width,
      height: height,
    );
  }

  _SectionNode? _hitNode(Offset p) {
    for (final node in _nodes.reversed) {
      if (node.contains(p)) return node;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    _lastPan = details.localPosition;
    _moved = false;
    final hit = _hitNode(details.localPosition);
    if (hit != null) {
      HapticFeedback.selectionClick();
      hit.dragging = true;
      _dragging = hit;
      setState(() => _activeNodeId = hit.id);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _moved = true;
    final previous = _lastPan ?? details.localPosition;
    _lastPan = details.localPosition;
    final node = _dragging;
    if (node != null) {
      node.x += details.delta.dx;
      node.y += details.delta.dy;
      node.vx = details.delta.dx;
      node.vy = details.delta.dy;
      setState(() {});
      return;
    }

    final delta = details.localPosition - previous;
    setState(() {
      _pressurePsi = (_pressurePsi - delta.dy * 0.22).clamp(25.0, 180.0);
      _spindleCorrosion = (_spindleCorrosion + delta.dx * 0.0016).clamp(0.0, 1.0);
      _keyTurns += delta.dx * 0.01;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragging != null) {
      _dragging!.dragging = false;
      _dragging = null;
    }
    _lastPan = null;
  }

  void _onTapUp(TapUpDetails details) {
    if (_moved) {
      _moved = false;
      return;
    }
    final hit = _hitNode(details.localPosition);
    setState(() => _activeNodeId = hit?.id);
  }

  void _openRecord() {
    Navigator.pushNamed(
      context,
      '/info_screen',
      arguments: {'index': _selectedRecord},
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;
    final item = _selectedItem(entries);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildHeader(top),
          if (entries.isNotEmpty) _buildRecordRail(entries),
          Expanded(
            child: item == null
                ? _buildEmpty()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final gauge = _resultFor(item);
                      _syncNodes(item, gauge, size);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapUp: _onTapUp,
                        onDoubleTap: _openRecord,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _benchTick,
                                  builder: (context, _, _) {
                                    return CustomPaint(
                                      painter: _SectionBenchPainter(
                                        item: item,
                                        gauge: gauge,
                                        nodes: _nodes,
                                        activeNodeId: _activeNodeId,
                                        assembly: _assemblyRect(size),
                                        pressurePsi: _pressurePsi,
                                        corrosion: _spindleCorrosion,
                                        keyTurns: _keyTurns,
                                        time: _time,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16.w,
                              right: 16.w,
                              bottom: bottomNavOccupiedHeight(context) + 8.h,
                              child: _buildBenchReadout(item, gauge),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, top + 14.h, 20.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECTION BENCH',
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccent.withAlpha(180),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Hydrant Valve Cutaway',
                  style: GoogleFonts.archivo(
                    color: kPrimaryText,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Drag labels, swipe up for head pressure, swipe sideways to turn the stem.',
                  style: GoogleFonts.ibmPlexSans(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: kAccent.withAlpha(22),
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kAccent.withAlpha(90)),
            ),
            child: Text(
              '${_pressurePsi.toStringAsFixed(0)} PSI',
              style: GoogleFonts.ibmPlexMono(
                color: kAccent,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRail(List<HydrantValveModel> entries) {
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: entries.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final selected = i == _selectedRecord;
          final entry = entries[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedRecord = i;
                _activeNodeId = null;
                _pressurePsi = parsePressurePsi(entry.staticHeadPressureRating);
                _lastLayoutKey = '';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? kAccent : kPanelBg,
                borderRadius: BorderRadius.circular(kRadiusPill),
                border: Border.all(color: selected ? kAccent : kOutline),
              ),
              child: Text(
                entry.hydrantBarrelRegistry.isEmpty
                    ? 'FITTING ${i + 1}'
                    : entry.hydrantBarrelRegistry,
                style: GoogleFonts.ibmPlexMono(
                  color: selected ? kPanelBg : kSecondaryText,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenchReadout(HydrantValveModel item, _GaugeResult gauge) {
    final result = gauge.result;
    final active = _nodes.where((n) => n.id == _activeNodeId).firstOrNull;
    final verdictColor = getAdequacyColor(result.adequacyVerdict);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: kPanelBg.withAlpha(238),
        borderRadius: BorderRadius.circular(kRadiusMedium),
        border: Border.all(color: kOutline),
        boxShadow: const [kShadowFloat],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.municipalDistrictBranch.isEmpty
                      ? 'Unassigned municipal district'
                      : item.municipalDistrictBranch,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  active?.label ?? 'FITTING SPEC',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexMono(
                    color: active?.color ?? kAccent,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  active?.value ?? item.fittingSpecBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    color: kPrimaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'P_out ${result.outletPressureKpa.toStringAsFixed(0)} kPa · torque ${result.torqueNm.toStringAsFixed(1)} N·m',
                  style: GoogleFonts.ibmPlexMono(
                    color: verdictColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: _openRecord,
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(kRadiusCard),
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                color: kPanelBg,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 40.h, 28.w, tabScrollBottomInset(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture_rounded, color: kAccent, size: 58.sp),
          SizedBox(height: 18.h),
          Text(
            'NO FITTINGS IN THIS LEDGER.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Add a hydrant record to assemble the interactive municipal cutaway.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              color: kSecondaryText,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeSpec {
  final String id;
  final String label;
  final String value;
  final Offset anchor;
  final Offset home;
  final Color color;

  const _NodeSpec({
    required this.id,
    required this.label,
    required this.value,
    required this.anchor,
    required this.home,
    required this.color,
  });
}

class _SectionBenchPainter extends CustomPainter {
  final HydrantValveModel item;
  final _GaugeResult gauge;
  final List<_SectionNode> nodes;
  final String? activeNodeId;
  final Rect assembly;
  final double pressurePsi;
  final double corrosion;
  final double keyTurns;
  final double time;

  _SectionBenchPainter({
    required this.item,
    required this.gauge,
    required this.nodes,
    required this.activeNodeId,
    required this.assembly,
    required this.pressurePsi,
    required this.corrosion,
    required this.keyTurns,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paper(canvas, size);
    _titleBlock(canvas, size);
    _assembly(canvas);
    _waterColumn(canvas);
    _operatingKey(canvas);
    _leaders(canvas);
    for (final node in nodes) {
      _node(canvas, node);
    }
  }

  void _paper(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = kOutline.withAlpha(90)
      ..strokeWidth = 0.6;
    for (double x = 28; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), rule);
    }
    for (double y = 18; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
  }

  void _titleBlock(Canvas canvas, Size size) {
    _text('BOARD OF WORKS FITTING SECTION', 9, kSecondaryText.withAlpha(170),
            weight: FontWeight.w700, letterSpacing: 1.0)
        .paint(canvas, const Offset(32, 12));
    _text('WATER COLUMN: ${pressurePsi.toStringAsFixed(0)} PSI', 8, kAccent,
            weight: FontWeight.w700)
        .paint(canvas, Offset(size.width - 160, 12));
  }

  void _assembly(Canvas canvas) {
    final center = assembly.center;
    final boreScale = (gauge.boreMm / 76).clamp(0.62, 1.32);
    final sleeveScale = (gauge.clearanceMm / 12.7).clamp(0.55, 2.0);
    final barrelW = assembly.width * 0.36 * boreScale.clamp(0.85, 1.15);
    final sleeveW = (barrelW + 16 * sleeveScale).clamp(barrelW + 8, assembly.width * 0.92);
    final boreW = barrelW * (0.42 + 0.28 * boreScale);
    final top = assembly.top + 24;
    final bottom = assembly.bottom - 24;

    final sleeve = Rect.fromCenter(
      center: Offset(center.dx, (top + bottom) / 2),
      width: sleeveW,
      height: bottom - top,
    );
    final barrel = Rect.fromCenter(
      center: sleeve.center,
      width: barrelW,
      height: sleeve.height * 0.96,
    );
    final bore = Rect.fromCenter(
      center: sleeve.center,
      width: boreW,
      height: sleeve.height * 0.89,
    );

    canvas.drawRect(
      sleeve,
      Paint()
        ..color = kSecondaryText.withAlpha(55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRect(
      barrel,
      Paint()
        ..color = kPrimaryText.withAlpha(190)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawRect(
      bore,
      Paint()
        ..color = kAccent.withAlpha(30)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(bore.left, bore.top),
      Offset(bore.left, bore.bottom),
      Paint()
        ..color = kAccent.withAlpha(120)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(bore.right, bore.top),
      Offset(bore.right, bore.bottom),
      Paint()
        ..color = kAccent.withAlpha(120)
        ..strokeWidth = 1,
    );

    final nut = Rect.fromCenter(
      center: Offset(center.dx, top - 16),
      width: barrelW * (0.58 + 0.14 * item.operatingNutGeometry.torqueFactor),
      height: barrelW * 0.36,
    );
    canvas.drawRect(
      nut,
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final nozzleY = top + (bottom - top) * 0.32;
    canvas.drawLine(
      Offset(barrel.right, nozzleY),
      Offset(assembly.right + 28, nozzleY),
      Paint()
        ..color = kAccent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(assembly.right + 32, nozzleY),
      10,
      Paint()
        ..color = kAccent.withAlpha(45)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(assembly.right + 32, nozzleY),
      10,
      Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final valveColor = getValveColor(item.footValveGateStyle);
    canvas.drawLine(
      Offset(barrel.left + 4, bottom - 10),
      Offset(barrel.right - 4, bottom - 18),
      Paint()
        ..color = valveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(center.dx, bottom - 14),
      7,
      Paint()..color = valveColor.withAlpha(65),
    );

    canvas.drawLine(
      Offset(center.dx, top - 2),
      Offset(center.dx, bottom - 20),
      Paint()
        ..color = kPrimaryText.withAlpha(155)
        ..strokeWidth = 1.2,
    );
  }

  void _waterColumn(Canvas canvas) {
    final center = assembly.center;
    final top = assembly.top + 50;
    final bottom = assembly.bottom - 50;
    final pressureT = (pressurePsi / 180).clamp(0.0, 1.0);
    final dotPaint = Paint()..color = kAccent.withAlpha(170);
    for (int i = 0; i < 18; i++) {
      final phase = (time * (0.28 + pressureT * 1.2) + i / 18) % 1.0;
      final y = bottom - (bottom - top) * phase;
      final x = center.dx + math.sin(i * 1.7 + time * 2.4) * assembly.width * 0.08;
      canvas.drawCircle(Offset(x, y), 1.6 + pressureT * 1.5, dotPaint);
    }
  }

  void _operatingKey(Canvas canvas) {
    final c = Offset(assembly.center.dx, assembly.top + 8);
    final r = assembly.width * 0.28;
    final a = keyTurns;
    final p = Paint()
      ..color = kLeather.withAlpha((120 + corrosion * 100).round())
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r * 0.16, p..style = PaintingStyle.stroke);
    canvas.drawLine(
      c + Offset(math.cos(a), math.sin(a)) * r,
      c - Offset(math.cos(a), math.sin(a)) * r,
      p,
    );
  }

  void _leaders(Canvas canvas) {
    for (final node in nodes) {
      final active = node.id == activeNodeId;
      final paint = Paint()
        ..color = (active ? node.color : kSecondaryText).withAlpha(active ? 210 : 105)
        ..strokeWidth = active ? 1.4 : 0.9
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(node.anchor.dx, node.anchor.dy)
        ..lineTo((node.anchor.dx + node.x) / 2, node.anchor.dy)
        ..lineTo(node.x, node.y);
      canvas.drawPath(path, paint);
      canvas.drawCircle(node.anchor, active ? 3.2 : 2.2, Paint()..color = node.color);
    }
  }

  void _node(Canvas canvas, _SectionNode node) {
    final active = node.id == activeNodeId;
    final rect = Rect.fromCenter(
      center: node.offset,
      width: 122 + node.lift * 8,
      height: 46 + node.lift * 4,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = active ? kSelectedTint.withAlpha(245) : kPanelBg.withAlpha(238)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = active ? node.color : kOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.5 : 1.0,
    );
    final label = _text(node.label, 7.4, node.color,
        weight: FontWeight.w800, letterSpacing: 0.7);
    label.paint(canvas, Offset(rect.left + 8, rect.top + 7));
    final value = _text(
      node.value,
      7.2,
      kPrimaryText.withAlpha(215),
      weight: FontWeight.w500,
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(rect.left + 8, rect.top + 21, rect.width - 16, 16));
    value.paint(canvas, Offset(rect.left + 8, rect.top + 23));
    canvas.restore();
  }

  TextPainter _text(
    String text,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w500,
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

  @override
  bool shouldRepaint(covariant _SectionBenchPainter oldDelegate) => true;
}
