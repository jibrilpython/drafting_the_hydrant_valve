import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';
import 'package:drafting_the_hydrant_valve/providers/project_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/utils/layout.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _focusSimIndex = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final entries = project.entries;
    final top = MediaQuery.of(context).padding.top;

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
          _buildHeader(top, entries.length),
          Expanded(
            child: entries.isEmpty
                ? _buildEmpty()
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      8.h,
                      20.w,
                      tabScrollBottomInset(context),
                    ),
                    children: [
                      _buildHeroStrip(entries),
                      SizedBox(height: 22.h),
                      _buildHeadReadiness(entries),
                      SizedBox(height: 22.h),
                      _buildValveStyleSection(entries),
                      SizedBox(height: 22.h),
                      _buildNutSection(entries),
                      SizedBox(height: 22.h),
                      _buildDistrictSection(entries),
                      SizedBox(height: 12.h),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top, int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, top + 16.h, 20.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANALYSIS',
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccent.withAlpha(180),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Logbook',
                  style: GoogleFonts.archivo(
                    color: kPrimaryText,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Hydrant metrics & hydraulic distribution',
                  style: GoogleFonts.ibmPlexSans(
                    color: kSecondaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: kAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: kAccent.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Text(
                    count.toString().padLeft(2, '0'),
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  Text(
                    'FITTINGS',
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent.withAlpha(180),
                      fontSize: 8.sp,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) => CustomPaint(
                size: Size(96.w, 96.w),
                painter: _HydrantLogbookPainter(
                  progress: _pulseController.value,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'NO FITTINGS IN THIS LEDGER.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Catalogue hydrant fittings to unlock\nhead-loss readiness and valve distribution charts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w300,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStrip(List<HydrantValveModel> entries) {
    final total = entries.length;
    final ready = entries
        .where((e) => e.headSimulationStatus == HeadSimulationStatus.ready)
        .length;
    final leather = entries
        .where((e) => e.footValveGateStyle.usesLeather)
        .length;

    return Row(
      children: [
        Expanded(
          child: _metricTile('TOTAL', '$total', 'fittings', kPrimaryText),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _metricTile('READY', '$ready', 'head-loss', kAccent),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _metricTile('LEATHER', '$leather', 'valve gates', kLeather),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, String unit, Color accent) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: accent.withAlpha(90), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 8.sp,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.archivo(
              color: accent,
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            unit,
            style: GoogleFonts.ibmPlexSans(
              color: kSecondaryText,
              fontSize: 10.sp,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadReadiness(List<HydrantValveModel> entries) {
    final total = entries.length;
    final counts = <HeadSimulationStatus, int>{
      for (final s in HeadSimulationStatus.values) s: 0,
    };
    for (final e in entries) {
      counts[e.headSimulationStatus] =
          (counts[e.headSimulationStatus] ?? 0) + 1;
    }

    return _sectionShell(
      title: 'Head simulation readiness',
      subtitle: 'Hydraulic specification completeness across the registry',
      child: Column(
        children: [
          SizedBox(
            height: 140.h,
            child: Row(
              children: [
                SizedBox(
                  width: 130.w,
                  height: 130.w,
                  child: CustomPaint(
                    painter: _ReadinessRingPainter(
                      counts: counts,
                      total: total,
                      focusIndex: _focusSimIndex,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        List.generate(HeadSimulationStatus.values.length, (i) {
                      final s = HeadSimulationStatus.values[i];
                      final count = counts[s] ?? 0;
                      final pct =
                          total == 0 ? 0 : ((count / total) * 100).round();
                      final focused = _focusSimIndex == i;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _focusSimIndex = focused ? -1 : i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(bottom: 6.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: focused
                                ? getSimColor(s).withAlpha(22)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: focused
                                  ? getSimColor(s).withAlpha(120)
                                  : kOutline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  color: getSimColor(s),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  s.label.replaceFirst('HEAD: ', ''),
                                  style: GoogleFonts.ibmPlexSans(
                                    color: focused
                                        ? kPrimaryText
                                        : kSecondaryText,
                                    fontSize: 11.sp,
                                    fontWeight: focused
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: GoogleFonts.ibmPlexMono(
                                  color: getSimColor(s),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          ...HeadSimulationStatus.values.map((s) {
            final count = counts[s] ?? 0;
            final frac = total == 0 ? 0.0 : count / total;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.label,
                          style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: GoogleFonts.ibmPlexMono(
                          color: getSimColor(s),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: frac.clamp(0.04, 1.0),
                      minHeight: 5.h,
                      backgroundColor: kOutline,
                      color: getSimColor(s),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValveStyleSection(List<HydrantValveModel> entries) {
    final counts = <FootValveGateStyle, int>{};
    for (final e in entries) {
      counts[e.footValveGateStyle] =
          (counts[e.footValveGateStyle] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox.shrink();
    final maxVal = sorted.first.value;

    return _sectionShell(
      title: 'Foot valve style',
      subtitle: 'Gate configurations and loss-coefficient families',
      child: Column(
        children: sorted.map((entry) {
          final frac = entry.value / maxVal;
          final color = getValveColor(entry.key);
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.label,
                        style: GoogleFonts.ibmPlexSans(
                          color: kPrimaryText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'K=${entry.key.baseLossCoefficient.toStringAsFixed(1)}',
                      style: GoogleFonts.ibmPlexMono(
                        color: kSecondaryText,
                        fontSize: 9.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${entry.value}',
                      style: GoogleFonts.ibmPlexMono(
                        color: color,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Container(
                        height: 6.h,
                        width: double.infinity,
                        color: kOutline,
                      ),
                      FractionallySizedBox(
                        widthFactor: frac.clamp(0.04, 1.0),
                        child: Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNutSection(List<HydrantValveModel> entries) {
    final counts = <OperatingNutGeometry, int>{};
    for (final e in entries) {
      counts[e.operatingNutGeometry] =
          (counts[e.operatingNutGeometry] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _sectionShell(
      title: 'Operating nut geometry',
      subtitle: 'Drive ratios and torque factors across the ledger',
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: sorted.map((entry) {
          return Container(
            width: (MediaQuery.sizeOf(context).width - 48.w - 8.w) / 2,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: kBackground,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kAccent.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.key.driveRatio,
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '×${entry.value}',
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  entry.key.label,
                  style: GoogleFonts.ibmPlexSans(
                    color: kPrimaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Text(
                  'τ ${entry.key.torqueFactor.toStringAsFixed(2)}',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistrictSection(List<HydrantValveModel> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      final key = e.municipalDistrictBranch.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final others = sorted.skip(5).toList();
    final othersCount = others.fold<int>(0, (sum, e) => sum + e.value);

    return _sectionShell(
      title: 'Municipal district branches',
      subtitle: 'Originating waterworks authorities in the archive',
      child: Column(
        children: [
          ...List.generate(top.length, (i) {
            final entry = top[i];
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: kAccent.withAlpha(55)),
              ),
              child: Row(
                children: [
                  Text(
                    (i + 1).toString().padLeft(2, '0'),
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.ibmPlexSans(
                        color: kPrimaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: kLeather.withAlpha(35),
                      borderRadius: BorderRadius.circular(kRadiusPill),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: GoogleFonts.ibmPlexMono(
                        color: kLeather,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (others.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: kOutline.withAlpha(160)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Other districts…',
                      style: GoogleFonts.ibmPlexSans(
                        color: kSecondaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    '${others.length} branches · $othersCount',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionShell({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kAccent.withAlpha(70), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.archivo(
              color: kPrimaryText,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: GoogleFonts.ibmPlexSans(
              color: kSecondaryText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

class _RingSegment {
  final HeadSimulationStatus status;
  final int count;
  _RingSegment({required this.status, required this.count});
}

class _ReadinessRingPainter extends CustomPainter {
  final Map<HeadSimulationStatus, int> counts;
  final int total;
  final int focusIndex;

  _ReadinessRingPainter({
    required this.counts,
    required this.total,
    required this.focusIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    final activeSegments = <_RingSegment>[];
    for (final s in HeadSimulationStatus.values) {
      final count = counts[s] ?? 0;
      if (count > 0) {
        activeSegments.add(_RingSegment(status: s, count: count));
      }
    }

    if (activeSegments.length == 1) {
      final seg = activeSegments.first;
      final idx = HeadSimulationStatus.values.indexOf(seg.status);
      final paint = Paint()
        ..color = focusIndex == idx
            ? getSimColor(seg.status)
            : getSimColor(seg.status).withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = focusIndex == idx ? 14 : 10;
      canvas.drawCircle(center, radius, paint);
      _paintCenter(canvas, center, radius, total);
      return;
    }

    double start = -math.pi / 2;
    for (final seg in activeSegments) {
      final sweep = (seg.count / total) * 2 * math.pi;
      final i = HeadSimulationStatus.values.indexOf(seg.status);
      final focused = focusIndex == i;
      final paint = Paint()
        ..color = focused
            ? getSimColor(seg.status)
            : getSimColor(seg.status).withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 14 : 10
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
    _paintCenter(canvas, center, radius, total);
  }

  void _paintCenter(Canvas canvas, Offset center, double radius, int total) {
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()..color = kBackground,
    );
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$total\n',
            style: TextStyle(
              color: kPrimaryText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          TextSpan(
            text: 'total',
            style: TextStyle(
              color: kSecondaryText,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ReadinessRingPainter old) =>
      old.total != total || old.focusIndex != focusIndex;
}

class _HydrantLogbookPainter extends CustomPainter {
  final double progress;

  _HydrantLogbookPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerW = size.width * 0.28;
    final barrelH = size.height * 0.62;
    final top = c.dy - barrelH / 2;
    final bottom = c.dy + barrelH / 2;
    final left = c.dx - outerW / 2;
    final right = c.dx + outerW / 2;

    final paint = Paint()
      ..color = kAccent.withAlpha((60 + progress * 80).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Frost sleeve
    canvas.drawRect(
      Rect.fromLTRB(left - 6, top - 4, right + 6, bottom + 4),
      paint..strokeWidth = 1.0,
    );

    // Barrel
    canvas.drawRect(
      Rect.fromLTRB(left, top + 8, right, bottom),
      paint..strokeWidth = 1.5,
    );

    // Operating nut
    final nutSize = size.width * 0.14;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(c.dx, top + 2),
        width: nutSize,
        height: nutSize * 0.7,
      ),
      paint,
    );

    // Foot valve flap — pulsing leather indicator
    final flapY = bottom - 4;
    canvas.drawLine(
      Offset(left + 2, flapY),
      Offset(right - 2, flapY),
      Paint()
        ..color = kLeather.withAlpha((100 + progress * 100).round())
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Hydraulic grade line pulse
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: size.shortestSide * 0.38),
      -math.pi * 0.75,
      math.pi * (0.5 + progress * 0.4),
      false,
      Paint()
        ..color = kAccent.withAlpha((80 + progress * 70).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HydrantLogbookPainter old) =>
      old.progress != progress;
}
