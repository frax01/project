import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFBF0022),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFFDAD7),
  onPrimaryContainer: Color(0xFF410005),
  secondary: Color(0xFF775654),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFDAD7),
  onSecondaryContainer: Color(0xFF2C1514),
  tertiary: Color(0xFF735B2E),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFDEA9),
  onTertiaryContainer: Color(0xFF271900),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  background: Color(0xFFF8FDFF),
  onBackground: Color(0xFF001F25),
  surface: Color(0xFFF8FDFF),
  onSurface: Color(0xFF001F25),
  surfaceVariant: Color(0xFFF4DDDB),
  onSurfaceVariant: Color(0xFF534342),
  outline: Color(0xFF857372),
  onInverseSurface: Color(0xFFD6F6FF),
  inverseSurface: Color(0xFF00363F),
  inversePrimary: Color(0xFFFFB3AF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFBF0022),
  outlineVariant: Color(0xFFD8C1C0),
  scrim: Color(0xFF000000),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFB3AF),
  onPrimary: Color(0xFF68000E),
  primaryContainer: Color(0xFF930018),
  onPrimaryContainer: Color(0xFFFFDAD7),
  secondary: Color(0xFFE7BDBA),
  onSecondary: Color(0xFF442928),
  secondaryContainer: Color(0xFF5D3F3D),
  onSecondaryContainer: Color(0xFFFFDAD7),
  tertiary: Color(0xFFE2C28C),
  onTertiary: Color(0xFF402D05),
  tertiaryContainer: Color(0xFF594319),
  onTertiaryContainer: Color(0xFFFFDEA9),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  background: Color(0xFF001F25),
  onBackground: Color(0xFFA6EEFF),
  surface: Color(0xFF001F25),
  onSurface: Color(0xFFA6EEFF),
  surfaceVariant: Color(0xFF534342),
  onSurfaceVariant: Color(0xFFD8C1C0),
  outline: Color(0xFFA08C8B),
  onInverseSurface: Color(0xFF001F25),
  inverseSurface: Color(0xFFA6EEFF),
  inversePrimary: Color(0xFFBF0022),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFFFB3AF),
  outlineVariant: Color(0xFF534342),
  scrim: Color(0xFF000000),
);

final textTheme = TextTheme(
  displayLarge: GoogleFonts.cabin(
      fontSize: 96, fontWeight: FontWeight.w300, color: Colors.black
  ),
  displayMedium: GoogleFonts.cabin(
      fontSize: 60, fontWeight: FontWeight.w300, color: Colors.black
  ),
  displaySmall: GoogleFonts.cabin(
      fontSize: 48, fontWeight: FontWeight.w300, color: Colors.black
  ),
  headlineLarge: GoogleFonts.sniglet(
      fontSize: 34, fontWeight: FontWeight.w400, color: Colors.black
  ),
  headlineMedium: GoogleFonts.sniglet(
      fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black
  ),
  headlineSmall: GoogleFonts.sniglet(
      fontSize: 20, fontWeight: FontWeight.w400, color: Colors.black
  ),
 bodyLarge: GoogleFonts.cabin(
      fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black
  ),
  bodyMedium: GoogleFonts.cabin(
      fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black
  ),
  bodySmall: GoogleFonts.cabin(
      fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black
  ),
  button: GoogleFonts.cabin(
      fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white
  ),
);
