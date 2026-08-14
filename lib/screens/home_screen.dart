import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/models/hydrant_valve_model.dart';
import 'package:drafting_the_hydrant_valve/providers/image_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/input_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/project_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/search_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/utils/layout.dart';
import 'package:drafting_the_hydrant_valve/widgets/hydrant_barrel_motif.dart';

enum _FilterAxis { valve, drive, head }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  FootValveGateStyle? _selectedValveFilter;
  OperatingNutGeometry? _selectedNutFilter;
  HeadSimulationStatus? _selectedHeadFilter;
  _FilterAxis _filterAxis = _FilterAxis.valve;
  int? _selectedCardIndex;
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        ref.read(searchProvider).clearSearchQuery();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  List<HydrantValveModel> _applyFilters(List<HydrantValveModel> all) {
    var filtered = all;
    if (_selectedValveFilter != null) {
      filtered = filtered
          .where((e) => e.footValveGateStyle == _selectedValveFilter)
          .toList();
    }
    if (_selectedNutFilter != null) {
      filtered = filtered
          .where((e) => e.operatingNutGeometry == _selectedNutFilter)
          .toList();
    }
    if (_selectedHeadFilter != null) {
      filtered = filtered
          .where((e) => e.headSimulationStatus == _selectedHeadFilter)
          .toList();
    }
    return ref.watch(searchProvider).filteredList(filtered);
  }

  String _collectionLine(int count) {
    if (count == 0) return 'No fittings catalogued';
    if (count == 1) return '1 fitting in this ledger';
    return '$count fittings in this ledger';
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final allEntries = project.entries;
    final entries = _applyFilters(allEntries);
    final top = MediaQuery.of(context).padding.top;
    final fabBottom = homeFabBottomInset(context);
    final scrollBottom = homeScrollBottomInset(context);

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Column(
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
              _buildAppBar(top, allEntries.length),
              _buildFilterStrip(),
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyState()
                    : MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16.h,
                        crossAxisSpacing: 16.w,
                        padding: EdgeInsets.fromLTRB(
                          20.w,
                          12.h,
                          20.w,
                          scrollBottom,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final entry = entries[i];
                          final mainIdx = ref
                              .read(projectProvider)
                              .entries
                              .indexOf(entry);
                          return _buildCard(context, entry, mainIdx, i);
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            right: 20.w,
            bottom: fabBottom,
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        ref.read(inputProvider).clearAll();
        ref.read(imageProvider).clearImage();
        Navigator.pushNamed(context, '/add_screen');
      },
      child: Container(
        width: kHomeFabSize.w,
        height: kHomeFabSize.w,
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [kShadowAccent],
        ),
        child: Icon(Icons.add, color: kPanelBg, size: 26.sp),
      ),
    );
  }

  Widget _buildAppBar(double top, int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, top + 18.h, 20.w, 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEDGER',
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccent.withAlpha(180),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Drafting the\nHydrant Valve',
                  style: GoogleFonts.archivo(
                    color: kPrimaryText,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kAccent.withAlpha(55)),
                  ),
                  child: Text(
                    _collectionLine(count),
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _toggleSearch,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: _searchOpen ? kAccent : kPanelBg,
                borderRadius: BorderRadius.circular(kRadiusMedium),
                border: Border.all(
                  color: _searchOpen ? kAccent : kOutline,
                  width: kStrokeWeight,
                ),
              ),
              child: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _searchOpen ? kPanelBg : kAccent,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStrip() {
    final activeCount = [
      _selectedValveFilter,
      _selectedNutFilter,
      _selectedHeadFilter,
    ].where((e) => e != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: _searchOpen ? 70.h : 0,
          child: _searchOpen
              ? Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (v) =>
                        ref.read(searchProvider).setSearchQuery(v),
                    style: GoogleFonts.ibmPlexSans(
                      color: kPrimaryText,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search registry codes, districts, valve types…',
                      hintStyle: GoogleFonts.ibmPlexSans(
                        color: kSecondaryText.withAlpha(90),
                        fontSize: 13.sp,
                      ),
                      filled: true,
                      fillColor: kPanelBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kRadiusMedium),
                        borderSide: const BorderSide(color: kOutline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kRadiusMedium),
                        borderSide: const BorderSide(color: kOutline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kRadiusMedium),
                        borderSide:
                            const BorderSide(color: kAccent, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 13.h,
                      ),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search,
                        color: kSecondaryText,
                        size: 18.sp,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: kPanelBg,
              borderRadius: BorderRadius.circular(kRadiusPill),
              border: Border.all(color: kOutline),
            ),
            child: Row(
              children: [
                _axisTab(
                  axis: _FilterAxis.valve,
                  label: 'Valve',
                  active: _selectedValveFilter != null,
                ),
                _axisTab(
                  axis: _FilterAxis.drive,
                  label: 'Drive',
                  active: _selectedNutFilter != null,
                ),
                _axisTab(
                  axis: _FilterAxis.head,
                  label: 'Head',
                  active: _selectedHeadFilter != null,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 36.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            children: _chipsForAxis(),
          ),
        ),
        if (activeCount > 0)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _activeFilterSummary(),
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedValveFilter = null;
                    _selectedNutFilter = null;
                    _selectedHeadFilter = null;
                    _selectedCardIndex = null;
                  }),
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 12.h),
        Container(height: 1, color: kOutline),
      ],
    );
  }

  Widget _axisTab({
    required _FilterAxis axis,
    required String label,
    required bool active,
  }) {
    final selected = _filterAxis == axis;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterAxis = axis),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOut,
          height: 32.h,
          decoration: BoxDecoration(
            color: selected ? kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusPill),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.ibmPlexSans(
                  color: selected ? kPanelBg : kSecondaryText,
                  fontSize: 10.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              if (active) ...[
                SizedBox(width: 5.w),
                Container(
                  width: 5.w,
                  height: 5.w,
                  decoration: BoxDecoration(
                    color: selected ? kPanelBg : kAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _chipsForAxis() {
    switch (_filterAxis) {
      case _FilterAxis.valve:
        return [
          _filterChip(
            'All types',
            _selectedValveFilter == null,
            () => setState(() {
              _selectedValveFilter = null;
              _selectedCardIndex = null;
            }),
            filled: true,
          ),
          ...FootValveGateStyle.values.map(
            (t) => _filterChip(
              t.label,
              _selectedValveFilter == t,
              () => setState(() {
                _selectedValveFilter = t;
                _selectedCardIndex = null;
              }),
              filled: true,
            ),
          ),
        ];
      case _FilterAxis.drive:
        return [
          _filterChip(
            'All drives',
            _selectedNutFilter == null,
            () => setState(() {
              _selectedNutFilter = null;
              _selectedCardIndex = null;
            }),
          ),
          ...OperatingNutGeometry.values.map(
            (t) => _filterChip(
              t.driveRatio,
              _selectedNutFilter == t,
              () => setState(() {
                _selectedNutFilter = t;
                _selectedCardIndex = null;
              }),
              mono: true,
            ),
          ),
        ];
      case _FilterAxis.head:
        return [
          _filterChip(
            'All status',
            _selectedHeadFilter == null,
            () => setState(() {
              _selectedHeadFilter = null;
              _selectedCardIndex = null;
            }),
          ),
          ...HeadSimulationStatus.values.map(
            (t) => _filterChip(
              t.label,
              _selectedHeadFilter == t,
              () => setState(() {
                _selectedHeadFilter = t;
                _selectedCardIndex = null;
              }),
              mono: true,
            ),
          ),
        ];
    }
  }

  String _activeFilterSummary() {
    final parts = <String>[];
    if (_selectedValveFilter != null) {
      parts.add(_selectedValveFilter!.label);
    }
    if (_selectedNutFilter != null) {
      parts.add(_selectedNutFilter!.driveRatio);
    }
    if (_selectedHeadFilter != null) {
      parts.add(_selectedHeadFilter!.label);
    }
    return parts.join('  ·  ');
  }

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    bool filled = false,
    bool mono = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: selected
              ? (filled ? kAccent : kSelectedTint)
              : kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusPill),
          border: Border.all(
            color: selected ? kAccent : kOutline,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          filled ? label.toUpperCase() : label,
          style: (mono ? GoogleFonts.ibmPlexMono : GoogleFonts.ibmPlexSans)(
            color: selected
                ? (filled ? kPanelBg : kAccent)
                : kSecondaryText,
            fontSize: 9.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    HydrantValveModel entry,
    int idx,
    int listPos,
  ) {
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(entry.photoPath);
    final hasImage = entry.photoPath.isNotEmpty &&
        imagePath != null &&
        File(imagePath).existsSync();
    final isSelected = _selectedCardIndex == idx;
    final simColor = getSimColor(entry.headSimulationStatus);
    final valveColor = getValveColor(entry.footValveGateStyle);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCardIndex = idx);
        Navigator.pushNamed(
          context,
          '/info_screen',
          arguments: {'index': idx},
        ).then((_) {
          if (mounted) setState(() => _selectedCardIndex = null);
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected ? kSelectedTint : kPanelBg,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(
                color: isSelected ? kAccent : kOutline,
                width: kStrokeWeight,
              ),
              boxShadow: const [kShadowSubtle],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(kRadiusCard),
                      topRight: Radius.circular(kRadiusCard),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 180.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: Image.file(File(imagePath), fit: BoxFit.cover),
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(kRadiusCard),
                      topRight: Radius.circular(kRadiusCard),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 80.h,
                      color: kBackground,
                      child: Center(
                        child: hydrantBarrelIcon(
                          valveStyle: entry.footValveGateStyle,
                          status: entry.headSimulationStatus,
                          size: 48.w,
                        ),
                      ),
                    ),
                  ),
                _buildMotifStrip(entry, valveColor),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${(listPos + 1).toString().padLeft(2, '0')}',
                            style: GoogleFonts.ibmPlexMono(
                              color: kAccent,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: kPanelBg,
                                borderRadius:
                                    BorderRadius.circular(kRadiusPill),
                                border: Border.all(
                                  color: kOutline,
                                  width: kStrokeWeight,
                                ),
                              ),
                              child: Text(
                                entry.fittingSpecBadge,
                                style: GoogleFonts.ibmPlexMono(
                                  color: kAccent,
                                  fontSize: 7.5.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        entry.municipalDistrictBranch.isNotEmpty
                            ? entry.municipalDistrictBranch
                            : 'Unassigned district',
                        style: GoogleFonts.ibmPlexSans(
                          color: kPrimaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.hydrantBarrelRegistry.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          entry.hydrantBarrelRegistry,
                          style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Text(
                        entry.headStatusLine,
                        style: GoogleFonts.ibmPlexMono(
                          color: simColor,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entry.municipalDistrictBranch.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: kAccent.withAlpha(26),
                            borderRadius: BorderRadius.circular(kRadiusPill),
                          ),
                          child: Text(
                            entry.municipalDistrictBranch,
                            style: GoogleFonts.ibmPlexMono(
                              color: kAccent,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: kAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kRadiusCard),
                    bottomLeft: Radius.circular(kRadiusCard),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMotifStrip(HydrantValveModel entry, Color valveColor) {
    return Container(
      height: 36.h,
      width: double.infinity,
      color: kBackground.withAlpha(60),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          hydrantBarrelIcon(
            valveStyle: entry.footValveGateStyle,
            status: entry.headSimulationStatus,
            size: 28.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              entry.footValveGateStyle.label.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                color: valveColor.withAlpha(180),
                fontSize: 8.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Text(
          'NO FITTINGS IN THIS LEDGER.',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexMono(
            color: kSecondaryText,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
