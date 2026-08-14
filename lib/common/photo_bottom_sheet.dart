import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drafting_the_hydrant_valve/providers/image_provider.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';

void photoBottomSheet(
  BuildContext context,
  ImageNotifier imageProv,
  int index,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).padding.bottom;
      return Container(
        padding: EdgeInsets.fromLTRB(0, 24.h, 0, bottom + 16.h),
        decoration: const BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusCard)),
          border: Border(top: BorderSide(color: kOutline, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: kOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Text(
                    'BARREL\nDOCUMENTATION',
                    style: GoogleFonts.archivo(
                      color: kPrimaryText,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        border: Border.all(color: kOutline),
                        borderRadius: BorderRadius.circular(kRadiusCard),
                      ),
                      child: Icon(Icons.close, size: 14.sp, color: kPrimaryText),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(height: 1, color: kOutline),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: _photoPlate(
                      ctx: ctx,
                      imageProv: imageProv,
                      icon: Icons.camera_alt_outlined,
                      label: 'CAMERA',
                      sublabel: 'Photograph the\nbarrel section',
                      source: ImageSource.camera,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _photoPlate(
                      ctx: ctx,
                      imageProv: imageProv,
                      icon: Icons.photo_library_outlined,
                      label: 'LIBRARY',
                      sublabel: 'Select from\nexisting images',
                      source: ImageSource.gallery,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _photoPlate({
  required BuildContext ctx,
  required ImageNotifier imageProv,
  required IconData icon,
  required String label,
  required String sublabel,
  required ImageSource source,
}) {
  return GestureDetector(
    onTap: () async {
      Navigator.pop(ctx);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await imageProv.pickImage(source: source);
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: kPanelBg,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: kOutline),
            ),
            child: Icon(icon, color: kAccent, size: 22.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kPrimaryText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              sublabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w300,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
