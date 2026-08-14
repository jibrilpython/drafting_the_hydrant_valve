import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/common/photo_bottom_sheet.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/providers/image_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/input_provider.dart';
import 'package:drafting_the_hydrant_valve/providers/project_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/code_generator.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';

class AddScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  final int currentIndex;

  const AddScreen({super.key, this.isEdit = false, this.currentIndex = 0});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen>
    with SingleTickerProviderStateMixin {
  static const _stepCount = 4;
  static const _stepTitles = [
    'Identification',
    'Valve Geometry',
    'Barrel & Pressure',
    'Archive',
  ];

  late PageController _pageController;
  late AnimationController _errorShakeController;

  int _currentStep = 0;
  bool _showErrorBanner = false;
  bool _districtError = false;

  late TextEditingController _districtCtrl;
  late TextEditingController _frostCtrl;
  late TextEditingController _boreCtrl;
  late TextEditingController _thicknessCtrl;
  late TextEditingController _pressureCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagsCtrl;
  late TextEditingController _codeCtrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _errorShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final p = ref.read(inputProvider);
    _districtCtrl = TextEditingController(text: p.municipalDistrictBranch);
    _frostCtrl = TextEditingController(text: p.frostSleeveClearance);
    _boreCtrl = TextEditingController(text: p.barrelBoreSpec);
    _thicknessCtrl = TextEditingController(text: p.barrelMetalThickness);
    _pressureCtrl = TextEditingController(text: p.staticHeadPressureRating);
    _notesCtrl = TextEditingController(text: p.archivalNotes);
    _tagsCtrl = TextEditingController(text: p.tags.join(', '));
    _codeCtrl = TextEditingController(text: p.hydrantBarrelRegistry);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _errorShakeController.dispose();
    _districtCtrl.dispose();
    _frostCtrl.dispose();
    _boreCtrl.dispose();
    _thicknessCtrl.dispose();
    _pressureCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    final clamped = step.clamp(0, _stepCount - 1);
    setState(() => _currentStep = clamped);
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _triggerValidation() {
    final empty = _districtCtrl.text.trim().isEmpty;
    setState(() {
      _districtError = empty;
      _showErrorBanner = empty;
    });
    if (empty) {
      _errorShakeController.forward(from: 0);
      _goToStep(0);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showErrorBanner = false);
      });
    }
  }

  Future<void> _save() async {
    _triggerValidation();
    if (_districtError) return;

    final input = ref.read(inputProvider);
    input.municipalDistrictBranch = _districtCtrl.text.trim();
    input.frostSleeveClearance = _frostCtrl.text.trim();
    input.barrelBoreSpec = _boreCtrl.text.trim();
    input.barrelMetalThickness = _thicknessCtrl.text.trim();
    input.staticHeadPressureRating = _pressureCtrl.text.trim();
    input.archivalNotes = _notesCtrl.text.trim();
    input.tags = _tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    input.hydrantBarrelRegistry = _codeCtrl.text.trim();
    if (input.hydrantBarrelRegistry.isEmpty) {
      input.hydrantBarrelRegistry = generateHydrantBarrelRegistry(
        valve: input.footValveGateStyle,
        stem: input.mainValveStemPitch,
      );
    }

    if (widget.isEdit) {
      ref.read(projectProvider).editEntry(ref, widget.currentIndex);
    } else {
      ref.read(projectProvider).addEntry(ref);
    }

    if (mounted) {
      Navigator.pop(context);
      ref.read(inputProvider).clearAll();
      ref.read(imageProvider).clearImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final input = ref.watch(inputProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20.w, top + 12.h, 20.w, 8.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: kPanelBg,
                      border: Border.all(color: kOutline),
                      borderRadius: BorderRadius.circular(kRadiusCard),
                    ),
                    child: Icon(Icons.close, color: kPrimaryText, size: 16.sp),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit ? 'EDIT FITTING' : 'NEW FITTING',
                        style: GoogleFonts.archivo(
                          color: kPrimaryText,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _stepTitles[_currentStep],
                        style: GoogleFonts.ibmPlexSans(
                          color: kSecondaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currentStep + 1}/$_stepCount',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stepCount, (i) {
                final isActive = i == _currentStep;
                return GestureDetector(
                  onTap: () => _goToStep(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: isActive ? 20.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: isActive ? kAccent : kOutline,
                      borderRadius: BorderRadius.circular(kRadiusPill),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _errorShakeController,
              builder: (context, _) {
                final shake = _errorShakeController.isAnimating
                    ? math.sin(_errorShakeController.value * math.pi * 4) * 4
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _buildStepIdentification(input),
                      _buildStepValveGeometry(input),
                      _buildStepBarrelPressure(input),
                      _buildStepArchive(),
                    ],
                  ),
                );
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: _showErrorBanner
                ? Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: kError.withAlpha(28),
                        borderRadius: BorderRadius.circular(kRadiusCard),
                        border: Border.all(color: kError.withAlpha(160)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: kError,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Municipal district branch is required before committing.',
                              style: GoogleFonts.ibmPlexSans(
                                color: kError,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, bottom + 8.h),
            decoration: const BoxDecoration(
              color: kBackground,
              border: Border(top: BorderSide(color: kOutline, width: 1)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  GestureDetector(
                    onTap: () => _goToStep(_currentStep - 1),
                    child: Container(
                      height: 50.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: kPanelBg,
                        border: Border.all(color: kOutline),
                        borderRadius: BorderRadius.circular(kRadiusCard),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'BACK',
                        style: GoogleFonts.ibmPlexMono(
                          color: kSecondaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: _currentStep < _stepCount - 1
                        ? () => _goToStep(_currentStep + 1)
                        : _save,
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(kRadiusCard),
                        boxShadow: const [kShadowAccent],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentStep < _stepCount - 1
                            ? 'CONTINUE'
                            : widget.isEdit
                                ? 'UPDATE RECORD'
                                : 'COMMIT TO LEDGER',
                        style: GoogleFonts.ibmPlexMono(
                          color: kPanelBg,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIdentification(InputNotifier input) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        _stepCard(
          tabLabel: 'ID',
          tabColor: kAccent,
          children: [
            _codeField(),
            _field(
              'Municipal District Branch',
              _districtCtrl,
              hint: 'Birmingham Waterworks, Metropolitan Board of Works…',
              hasError: _districtError,
              onChanged: (v) {
                ref.read(inputProvider).municipalDistrictBranch = v;
                if (_districtError && v.trim().isNotEmpty) {
                  setState(() {
                    _districtError = false;
                    _showErrorBanner = false;
                  });
                }
              },
            ),
            _chips<FootValveGateStyle>(
              label: 'Foot Valve Gate Style',
              values: FootValveGateStyle.values,
              current: input.footValveGateStyle,
              labelFn: (v) => v.label,
              onSelect: (v) => ref.read(inputProvider).footValveGateStyle = v,
              colorFn: getValveColor,
            ),
            _chips<OperatingNutGeometry>(
              label: 'Operating Nut Geometry',
              values: OperatingNutGeometry.values,
              current: input.operatingNutGeometry,
              labelFn: (v) => v.label,
              onSelect: (v) =>
                  ref.read(inputProvider).operatingNutGeometry = v,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepValveGeometry(InputNotifier input) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        _stepCard(
          tabLabel: 'GEO',
          tabColor: kAccent,
          children: [
            _chips<NozzleThreadStandard>(
              label: 'Nozzle Thread Standard',
              values: NozzleThreadStandard.values,
              current: input.nozzleThreadStandard,
              labelFn: (v) => v.label,
              onSelect: (v) =>
                  ref.read(inputProvider).nozzleThreadStandard = v,
            ),
            _chips<MainValveStemPitch>(
              label: 'Main Valve Stem Pitch',
              values: MainValveStemPitch.values,
              current: input.mainValveStemPitch,
              labelFn: (v) => v.label,
              onSelect: (v) =>
                  ref.read(inputProvider).mainValveStemPitch = v,
            ),
            _field(
              'Frost Sleeve Clearance',
              _frostCtrl,
              hint: '12.7 mm, 0.5 inch…',
              mono: true,
              onChanged: (v) =>
                  ref.read(inputProvider).frostSleeveClearance = v,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepBarrelPressure(InputNotifier input) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        _stepCard(
          tabLabel: 'BAR',
          tabColor: kLeather,
          children: [
            _field(
              'Barrel Bore Specification',
              _boreCtrl,
              hint: 'Ø76mm, 3 inch bore…',
              mono: true,
              onChanged: (v) => ref.read(inputProvider).barrelBoreSpec = v,
            ),
            _field(
              'Barrel Metal Thickness',
              _thicknessCtrl,
              hint: '9.5 mm wall, 3/8 inch…',
              mono: true,
              onChanged: (v) =>
                  ref.read(inputProvider).barrelMetalThickness = v,
            ),
            _field(
              'Static Head Pressure Rating',
              _pressureCtrl,
              hint: '85 PSI, 200 kPa, 18m head…',
              mono: true,
              onChanged: (v) =>
                  ref.read(inputProvider).staticHeadPressureRating = v,
            ),
            _chips<HeadSimulationStatus>(
              label: 'Head Simulation Status',
              values: HeadSimulationStatus.values,
              current: input.headSimulationStatus,
              labelFn: (v) => v.label,
              onSelect: (v) =>
                  ref.read(inputProvider).headSimulationStatus = v,
              colorFn: getSimColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepArchive() {
    final imageProv = ref.watch(imageProvider);
    final imgPath = imageProv.getImagePath(imageProv.resultImage);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        _stepCard(
          tabLabel: 'AR',
          tabColor: kSecondaryText,
          children: [
            _field(
              'Archival Notes',
              _notesCtrl,
              hint: 'Leather flap condition, frost case notes…',
              maxLines: 4,
              onChanged: (v) => ref.read(inputProvider).archivalNotes = v,
            ),
            _field(
              'Tags',
              _tagsCtrl,
              hint: 'cast-iron, birmingham, leather-flap…',
              onChanged: (v) => ref.read(inputProvider).tags = v
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
            SizedBox(height: 8.h),
            _buildPhotoPlate(imgPath),
          ],
        ),
      ],
    );
  }

  Widget _codeField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              'HYDRANT BARREL REGISTRY',
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          TextField(
            controller: _codeCtrl,
            onChanged: (v) =>
                ref.read(inputProvider).hydrantBarrelRegistry = v,
            cursorColor: kAccent,
            style: GoogleFonts.ibmPlexMono(
              color: _codeCtrl.text.isEmpty ? kSecondaryText : kAccent,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'DHV-HYD-512-VALVE',
              hintStyle: GoogleFonts.ibmPlexMono(
                color: kSecondaryText.withAlpha(100),
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: kBackground,
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 12.w, right: 8.w),
                child: Icon(Icons.qr_code_2_outlined, color: kAccent, size: 18.sp),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
                borderSide: const BorderSide(color: kOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
                borderSide: const BorderSide(color: kOutline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
                borderSide:
                    const BorderSide(color: kAccent, width: kStrokeWeightMedium),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'Auto-assigned on commit if left blank',
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 10.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlate(String? imgPath) {
    final hasImage = imgPath != null && File(imgPath).existsSync();

    return GestureDetector(
      onTap: () => photoBottomSheet(context, ref.read(imageProvider), 0, ref),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: kOutline),
        ),
        child: Column(
          children: [
            Text(
              'BARREL PHOTO PLATE',
              style: GoogleFonts.ibmPlexMono(
                color: kAccent,
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 10.h),
            hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    child: SizedBox(
                      height: 200.h,
                      width: double.infinity,
                      child: Image.file(File(imgPath), fit: BoxFit.cover),
                    ),
                  )
                : Container(
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: kPanelBg,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(color: kOutline),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: kAccent.withAlpha(160),
                            size: 28.sp,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'TAP TO DOCUMENT',
                            style: GoogleFonts.ibmPlexMono(
                              color: kSecondaryText,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({
    required String tabLabel,
    required Color tabColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline, width: kStrokeWeight),
        boxShadow: const [kShadowSubtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: tabColor.withAlpha(26),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                tabLabel,
                style: GoogleFonts.ibmPlexMono(
                  color: tabColor,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips<T>({
    required String label,
    required List<T> values,
    T? current,
    required String Function(T) labelFn,
    required Function(T) onSelect,
    Color Function(T)? colorFn,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Wrap(
            spacing: 6.w,
            runSpacing: 8.h,
            children: values.map((v) {
              final isSel = current != null && v == current;
              final color = colorFn != null ? colorFn(v) : kAccent;
              return GestureDetector(
                onTap: () => onSelect(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSel ? kSelectedTint : kBackground,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: isSel ? color : kOutline,
                      width: isSel ? 1.2 : 1,
                    ),
                  ),
                  child: Text(
                    labelFn(v),
                    style: GoogleFonts.ibmPlexSans(
                      color: isSel ? color : kPrimaryText,
                      fontSize: 11.sp,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    bool hasError = false,
    bool mono = false,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                color: hasError ? kError : kSecondaryText,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            maxLines: maxLines,
            cursorColor: kAccent,
            style: mono
                ? GoogleFonts.ibmPlexMono(
                    color: kPrimaryText,
                    fontSize: 12.sp,
                  )
                : GoogleFonts.ibmPlexSans(
                    color: kPrimaryText,
                    fontSize: 13.sp,
                  ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.ibmPlexSans(
                color: kSecondaryText.withAlpha(115),
                fontSize: 12.sp,
                fontWeight: FontWeight.w300,
              ),
              filled: true,
              fillColor: kBackground,
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
                borderSide: BorderSide(
                  color: hasError ? kError : kOutline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
                borderSide: BorderSide(
                  color: hasError ? kError : kOutline,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusCard),
                borderSide: BorderSide(
                  color: hasError ? kError : kAccent,
                  width: kStrokeWeightMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
