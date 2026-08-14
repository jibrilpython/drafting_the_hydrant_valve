import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';
import 'package:drafting_the_hydrant_valve/providers/image_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/project_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/widgets/hydrant_barrel_motif.dart';

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

class InfoScreen extends ConsumerWidget {
  final int index;
  const InfoScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectProv = ref.watch(projectProvider);
    if (index < 0 || index >= projectProv.entries.length) {
      return Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Text(
            'FITTING NOT FOUND',
            style: GoogleFonts.ibmPlexMono(
              color: kAccent,
              fontSize: 12.sp,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    final entry = projectProv.entries[index];
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(entry.photoPath);
    final hasImage = entry.photoPath.isNotEmpty &&
        imagePath != null &&
        File(imagePath).existsSync();

    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final valveColor = getValveColor(entry.footValveGateStyle);
    final simColor = getSimColor(entry.headSimulationStatus);

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: hasImage
                ? Image.file(File(imagePath), fit: BoxFit.cover)
                : Container(
                    color: kPanelBg,
                    child: Center(
                      child: hydrantBarrelIcon(
                        valveStyle: entry.footValveGateStyle,
                        status: entry.headSimulationStatus,
                        size: 96.w,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kBackground.withAlpha(210),
                    Colors.transparent,
                    kBackground.withAlpha(120),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: size.height * 0.40),
                Container(
                  decoration: BoxDecoration(
                    color: kBackground,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: kAccent.withAlpha(150),
                        width: kStrokeWeightMedium,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28.w, 40.h, 28.w, 120.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: kAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'FITTING',
                                style: GoogleFonts.ibmPlexMono(
                                  color: kBackground,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                entry.hydrantBarrelRegistry.isNotEmpty
                                    ? entry.hydrantBarrelRegistry
                                    : 'UNREGISTERED',
                                style: GoogleFonts.ibmPlexMono(
                                  color: kAccent,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          entry.municipalDistrictBranch.isNotEmpty
                              ? entry.municipalDistrictBranch
                              : 'Unassigned District',
                          style: GoogleFonts.archivo(
                            color: kPrimaryText,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.fittingSpecBadge.isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: kAccent.withAlpha(26),
                              borderRadius:
                                  BorderRadius.circular(kRadiusPill),
                              border: Border.all(
                                color: kAccent.withAlpha(80),
                              ),
                            ),
                            child: Text(
                              entry.fittingSpecBadge,
                              style: GoogleFonts.ibmPlexMono(
                                color: kAccent,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 24.h),
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children: [
                            _tag(
                              entry.footValveGateStyle.label.toUpperCase(),
                              valveColor,
                              true,
                            ),
                            _tag(
                              entry.operatingNutGeometry.driveRatio,
                              kAccent,
                              false,
                            ),
                            _tag(
                              entry.headStatusLine,
                              simColor,
                              false,
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                        _sectionHeader('TECHNICAL DATA'),
                        _buildTable(entry),
                        if (entry.archivalNotes.isNotEmpty) ...[
                          SizedBox(height: 40.h),
                          _sectionHeader('ARCHIVAL NOTES'),
                          Text(
                            entry.archivalNotes,
                            style: GoogleFonts.ibmPlexSans(
                              color: kPrimaryText,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w300,
                              height: 1.8,
                            ),
                          ),
                        ],
                        if (entry.tags.isNotEmpty) ...[
                          SizedBox(height: 40.h),
                          _sectionHeader('INDEX TAGS'),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: entry.tags
                                .map(
                                  (t) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kPanelBg,
                                      borderRadius:
                                          BorderRadius.circular(kRadiusCard),
                                      border: Border.all(color: kOutline),
                                    ),
                                    child: Text(
                                      '#${t.toUpperCase()}',
                                      style: GoogleFonts.ibmPlexMono(
                                        color: kSecondaryText,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topPadding + 10.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _glassButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    _glassButton(
                      icon: Icons.edit_outlined,
                      onTap: () {
                        projectProv.fillInput(ref, index);
                        Navigator.pushNamed(
                          context,
                          '/add_screen',
                          arguments: {
                            'isEdit': true,
                            'currentIndex': index,
                          },
                        );
                      },
                    ),
                    SizedBox(width: 12.w),
                    _glassButton(
                      icon: Icons.delete_outline,
                      iconColor: kError,
                      onTap: () => _confirmDelete(context, projectProv, index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color, bool filled) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: kStrokeWeightMedium),
        borderRadius: BorderRadius.circular(kRadiusPill),
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          color: filled ? kBackground : color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          Container(width: 12.w, height: 12.w, color: kAccent),
          SizedBox(width: 10.w),
          Text(
            title,
            style: GoogleFonts.archivo(
              color: kPrimaryText,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(HydrantValveModel e) {
    final simColor = getSimColor(e.headSimulationStatus);
    final rows = <_SpecRow>[
      _SpecRow('Registry Code', e.hydrantBarrelRegistry, mono: true),
      _SpecRow('District Branch', e.municipalDistrictBranch),
      _SpecRow('Fitting Identity', e.fittingSpecBadge, mono: true),
      _SpecRow('Head Status', e.headStatusLine, mono: true, valueColor: simColor),
      _SpecRow('Foot Valve Style', e.footValveGateStyle.label),
      _SpecRow('Operating Nut', e.operatingNutGeometry.label),
      _SpecRow('Drive Ratio', e.operatingNutGeometry.driveRatio, mono: true),
      _SpecRow('Nozzle Thread', e.nozzleThreadStandard.label),
      _SpecRow('Stem Pitch', e.mainValveStemPitch.label),
      _SpecRow('Barrel Bore', e.barrelBoreSpec, mono: true),
      _SpecRow('Metal Thickness', e.barrelMetalThickness, mono: true),
      _SpecRow('Frost Sleeve Clearance', e.frostSleeveClearance, mono: true),
      _SpecRow('Static Head Rating', e.staticHeadPressureRating, mono: true),
      _SpecRow('Head Simulation', e.headSimulationStatus.label, valueColor: simColor),
      _SpecRow('Date Catalogued', _formatDate(e.dateAdded), mono: true),
    ];

    return Column(
      children: rows.map((row) {
        final isEmpty = row.value.trim().isEmpty;
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kOutline, width: kStrokeWeight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120.w,
                child: Text(
                  row.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isEmpty ? '—' : row.value,
                  style: row.mono
                      ? GoogleFonts.ibmPlexMono(
                          color: row.valueColor ?? kPrimaryText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        )
                      : GoogleFonts.ibmPlexSans(
                          color: row.valueColor ?? kPrimaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = kPrimaryText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: kGlassBg,
              borderRadius: BorderRadius.circular(kRadiusMedium),
              border: Border.all(color: kOutline.withAlpha(100)),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProjectNotifier projectProv,
    int idx,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20.w,
          20.h,
          20.w,
          MediaQuery.of(ctx).padding.bottom + 20.h,
        ),
        decoration: const BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusMedium),
          ),
          border: Border(top: BorderSide(color: kOutline, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 3.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: kOutline,
                  borderRadius: BorderRadius.circular(kRadiusPill),
                ),
              ),
            ),
            Text(
              'REMOVE THIS FITTING?',
              style: GoogleFonts.archivo(
                color: kError,
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This permanently removes the hydrant fitting record — barrel specifications, foot valve geometry, and head-loss simulation data will be lost from the municipal ledger.',
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 15.sp,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 52.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kRadiusMedium),
                        border: Border.all(color: kOutline),
                      ),
                      child: Text(
                        'Keep Fitting',
                        style: GoogleFonts.ibmPlexSans(
                          color: kPrimaryText,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      projectProv.deleteEntry(idx);
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 52.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kError,
                        borderRadius: BorderRadius.circular(kRadiusMedium),
                      ),
                      child: Text(
                        'Remove Record',
                        style: GoogleFonts.ibmPlexSans(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow {
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  _SpecRow(
    this.label,
    this.value, {
    this.mono = false,
    this.valueColor,
  });
}
