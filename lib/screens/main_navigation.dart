import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/screens/home_screen.dart';
import 'package:drafting_the_hydrant_valve/screens/showcase_screen.dart';
import 'package:drafting_the_hydrant_valve/screens/simulator_screen.dart';
import 'package:drafting_the_hydrant_valve/screens/stats_screen.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';
import 'package:drafting_the_hydrant_valve/utils/layout.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ShowcaseScreen(),
    SimulatorScreen(),
    StatsScreen(),
  ];

  static const _tabs = [
    _NavTab(icon: Icons.inventory_2_outlined, label: 'Ledger'),
    _NavTab(icon: Icons.map_outlined, label: 'District Map'),
    _NavTab(icon: Icons.water_drop_outlined, label: 'Head-Loss'),
    _NavTab(icon: Icons.menu_book_outlined, label: 'Logbook'),
  ];

  void _setIndex(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  Alignment _indicatorAlignment(int index) {
    final t = _tabs.length <= 1 ? 0.0 : index / (_tabs.length - 1);
    return Alignment(-1.0 + 2.0 * t, 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBackground,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: List.generate(_screens.length, (i) {
              return TickerMode(
                enabled: _currentIndex == i,
                child: _screens[i],
              );
            }),
          ),
          Positioned(
            left: kBottomNavBarMargin.w,
            right: kBottomNavBarMargin.w,
            bottom: bottom + kBottomNavBarMargin.h,
            child: _buildNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: kBottomNavBarHeight.h,
          decoration: BoxDecoration(
            color: const Color(0x59FFFFFF),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withAlpha(90),
              width: kStrokeWeight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(6.h),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: _indicatorAlignment(_currentIndex),
                  child: FractionallySizedBox(
                    widthFactor: 1 / _tabs.length,
                    heightFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kAccent.withAlpha(28),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: kAccent.withAlpha(40),
                          width: kStrokeWeight,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_tabs.length, (index) {
                    return Expanded(
                      child: _NavBarItem(
                        tab: _tabs[index],
                        isActive: _currentIndex == index,
                        onTap: () => _setIndex(index),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        splashColor: kAccent.withAlpha(25),
        highlightColor: kAccent.withAlpha(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Icon(
                  tab.icon,
                  color: isActive ? kAccent : kSecondaryText.withAlpha(200),
                  size: 20.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                tab.label,
                style: GoogleFonts.ibmPlexSans(
                  color: isActive ? kAccent : kSecondaryText,
                  fontSize: 9.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: isActive ? 0.1 : 0,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;

  const _NavTab({required this.icon, required this.label});
}
