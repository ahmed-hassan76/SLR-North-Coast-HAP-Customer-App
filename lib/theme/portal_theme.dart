import 'package:material_ui/material_ui.dart';

const navy = Color(0xFF15394B);
const sea = Color(0xFF286775);
const mist = Color(0xFFE6F2F4);
const inkMuted = Color(0xFF516875);
const line = Color(0xFFD5E0E3);
const canvas = Color(0xFFF7F9F9);

TextStyle heading(double size) => TextStyle(
  fontFamily: 'serif',
  fontSize: size,
  height: 1.12,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.7,
  color: navy,
);

ThemeData portalTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: navy)
        .copyWith(primary: navy, secondary: sea, surface: Colors.white),
    scaffoldBackgroundColor: canvas,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: sea, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconColor: inkMuted,
      suffixIconColor: inkMuted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
