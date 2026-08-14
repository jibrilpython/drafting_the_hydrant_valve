import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const double kBottomNavBarHeight = 72;
const double kBottomNavBarMargin = 12;
const double kFabSpacingAboveNav = 16;
const double kHomeFabSize = 58;

double bottomNavOccupiedHeight(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  return safeBottom + kBottomNavBarMargin.h + kBottomNavBarHeight.h;
}

double homeFabBottomInset(BuildContext context) {
  return bottomNavOccupiedHeight(context) + kFabSpacingAboveNav.h;
}

double homeScrollBottomInset(BuildContext context) {
  return bottomNavOccupiedHeight(context) +
      kHomeFabSize.h +
      kFabSpacingAboveNav.h +
      12.h;
}

double tabScrollBottomInset(BuildContext context) {
  return bottomNavOccupiedHeight(context) + 16.h;
}
