import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/providers/user_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/widgets/hydrant_barrel_motif.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openLedger() {
    ref.read(userProvider).setFirstTimeUser(false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DraftingPaperPainter()),
          ),
          Positioned.fill(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      20.h,
                      24.w,
                      bottom + 16.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 24.h),
                        _buildTitleBlock(),
                        SizedBox(height: 20.h),
                        _buildDescriptionCard(),
                        SizedBox(height: 22.h),
                        _buildBarrelMotifCard(),
                        SizedBox(height: 28.h),
                        _buildQuoteCard(),
                        SizedBox(height: 32.h),
                        _buildOpenLedgerButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: kAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(kRadiusPill),
              border: Border.all(color: kAccent.withAlpha(50)),
            ),
            child: Text(
              'MUNICIPAL FITTING REGISTRY',
              style: GoogleFonts.ibmPlexMono(
                color: kAccent,
                fontSize: 9.sp,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '',
          style: GoogleFonts.ibmPlexMono(
            color: kSecondaryText.withAlpha(140),
            fontSize: 8.sp,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'DRAFTING THE',
            style: GoogleFonts.archivo(
              color: kPrimaryText,
              fontSize: 34.sp,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Container(width: 28.w, height: 2.h, color: kAccent),
            SizedBox(width: 10.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'HYDRANT VALVE',
                  style: GoogleFonts.archivo(
                    color: kAccent,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline, width: kStrokeWeight),
      ),
      child: Text(
        'A municipal engineering ledger for mid-19th-century cast-iron hydrant barrels — leather flap-gate foot valves, frost-case sleeves, and operating nut specifications filed by Victorian waterworks departments. Includes a hydraulic head-loss simulator for outlet pressure adequacy.',
        style: GoogleFonts.ibmPlexSans(
          color: kSecondaryText,
          fontSize: 13.sp,
          fontWeight: FontWeight.w300,
          height: 1.65,
        ),
      ),
    );
  }

  Widget _buildBarrelMotifCard() {
    return Container(
      height: 148.h,
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline, width: kStrokeWeight),
        boxShadow: const [kShadowSubtle],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => CustomPaint(
                painter: _HydraulicPulsePainter(
                  progress: _pulseController.value,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20.w,
            top: 28.h,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale =
                    1.0 + math.sin(_pulseController.value * 2 * math.pi) * 0.03;
                return Transform.scale(
                  scale: scale,
                  child: hydrantBarrelIcon(
                    valveStyle: FootValveGateStyle.flapGate,
                    status: HeadSimulationStatus.ready,
                    size: 56.w,
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 14.w,
            top: 12.h,
            child: Text(
              'Barrel cross-section',
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 7.5.sp,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Positioned(
            right: 16.w,
            top: 14.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: kAccentSurface,
                borderRadius: BorderRadius.circular(kRadiusPill),
                border: Border.all(color: kAccent.withAlpha(60)),
              ),
              child: Text(
                'FLAP-GATE',
                style: GoogleFonts.ibmPlexMono(
                  color: kAccent,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 10.h,
            child: Text(
              'Ø76mm / 1:12 sq / K=2.8',
              style: GoogleFonts.ibmPlexMono(
                color: kAccent,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline, width: kStrokeWeight),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => CustomPaint(
              size: Size(double.infinity, 28.h),
              painter: _GradeLinePainter(
                pulse: _pulseController.value,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '"The adequacy of a hydrant is judged at the outlet — not by the cast iron above ground, but by the pressure delivered when the leather seal must hold."',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              color: kPrimaryText.withAlpha(190),
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '— MUNICIPAL WATERWORKS STANDARD —',
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText.withAlpha(120),
              fontSize: 8.sp,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenLedgerButton() {
    return GestureDetector(
      onTap: _openLedger,
      child: Container(
        height: 54.h,
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(kRadiusPill),
          boxShadow: const [kShadowAccent],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'OPEN THE LEDGER',
                style: GoogleFonts.archivo(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftingPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final majorLine = Paint()
      ..color = kOutline.withAlpha(90)
      ..strokeWidth = 0.5;
    final minorLine = Paint()
      ..color = kOutline.withAlpha(45)
      ..strokeWidth = 0.35;

    const majorSpacing = 28.0;
    const minorSpacing = 7.0;

    for (double y = majorSpacing; y < size.height; y += majorSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorLine);
    }
    for (double y = minorSpacing; y < size.height; y += minorSpacing) {
      if ((y / majorSpacing).round() * majorSpacing == y) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorLine);
    }

    final marginPaint = Paint()
      ..color = kAccent.withAlpha(18)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(32, 0),
      Offset(32, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HydraulicPulsePainter extends CustomPainter {
  final double progress;

  _HydraulicPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.72;
    final cy = size.height * 0.5;
    final phase = progress * 2 * math.pi;
    final alpha = (30 + (math.sin(phase) * 0.5 + 0.5) * 25).round();

    final glow = Paint()
      ..color = kAccent.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.height * 0.55,
        height: size.height * 0.38,
      ),
      glow,
    );

    final gradePaint = Paint()
      ..color = kAccent.withAlpha((80 + (math.sin(phase) * 0.5 + 0.5) * 40).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final startX = size.width * 0.42;
    final endX = size.width * 0.92;
    final startY = size.height * 0.32;
    final drop = size.height * 0.08 + math.sin(phase) * 2;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX * 0.55, startY - drop * 0.3),
      gradePaint,
    );
    canvas.drawLine(
      Offset(endX * 0.55, startY - drop * 0.3),
      Offset(endX, startY + drop),
      gradePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HydraulicPulsePainter old) =>
      old.progress != progress;
}

class _GradeLinePainter extends CustomPainter {
  final double pulse;

  _GradeLinePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final phase = pulse * 2 * math.pi;
    final paint = Paint()
      ..color = kAccent.withAlpha(
        (50 + (math.sin(phase) * 0.5 + 0.5) * 35).round(),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final y = size.height * 0.5;
    final drop = 6.0 + math.sin(phase) * 2;
    canvas.drawLine(Offset(0, y), Offset(size.width * 0.45, y - drop), paint);
    canvas.drawLine(
      Offset(size.width * 0.45, y - drop),
      Offset(size.width, y + drop * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradeLinePainter old) => old.pulse != pulse;
}
