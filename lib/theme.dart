import 'package:flutter/material.dart';

/// Colors from the Health Buddy design (green = primary, purple = stress,
/// blue = carbs/activity, orange = fat/food).
class AppColors {
  static const bg = Color(0xFFF6F7F9);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFECEEF1);
  static const borderStrong = Color(0xFFE5E8EC);
  static const track = Color(0xFFEEF0F3);
  static const divider = Color(0xFFF0F2F4);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF5B6472);

  static const green = Color(0xFF16A34A);
  static const greenDark = Color(0xFF15803D);
  static const greenSoft = Color(0xFFE8F7EC);
  static const greenTint = Color(0xFFDCF3E2);
  static const greenBubble = Color(0xFFE3F6E8);
  static const greenBubbleBorder = Color(0xFFC9EDD3);
  static const greenGlow = Color(0xFF4ADE80);

  static const purple = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF6D28D9);
  static const purpleDeep = Color(0xFF5B21B6);
  static const purpleSoft = Color(0xFFF3EEFF);
  static const purpleCard = Color(0xFFF4F0FF);
  static const purpleBorder = Color(0xFFE6DDFE);
  static const purpleLight = Color(0xFFDDD0FD);

  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const blueSoft = Color(0xFFE7EEFF);
  static const sky = Color(0xFF0369A1);
  static const skySoft = Color(0xFFE0F2FE);

  static const orange = Color(0xFFF59E0B);
  static const orangeDark = Color(0xFFD97706);
  static const orangeText = Color(0xFFB45309);
  static const orangeSoft = Color(0xFFFFF4E5);
  static const orangeCard = Color(0xFFFFF8EC);
  static const orangeBorder = Color(0xFFFBE3BC);
  static const orangeTrack = Color(0xFFFFF1DC);

  static const red = Color(0xFFB91C1C);
  static const dark = Color(0xFF1F2430);
  static const darkSoft = Color(0xFF2B3240);
}

/// Motion curves from the "Animation Flow" board.
class Motion {
  static const standard = Cubic(0.2, 0.8, 0.2, 1);
  static const spring = Cubic(0.2, 0.9, 0.25, 1.1);
  static const fast = Duration(milliseconds: 100);
  static const tab = Duration(milliseconds: 220);
  static const enter = Duration(milliseconds: 320);
  static const push = Duration(milliseconds: 300);
  static const chart = Duration(milliseconds: 900);
}

/// Text style shorthand: ts(16, FontWeight.w700, AppColors.muted)
TextStyle ts(
  double size, [
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.text,
]) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.35,
  );
}

ThemeData buildTheme() {
  // FONT_START
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Figtree',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  final textTheme = base.textTheme;
  // FONT_END
  return base.copyWith(
    textTheme: textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
