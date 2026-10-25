import 'package:flutter/material.dart';

import '../../../compartido/navegacion/transiciones_paginas_app.dart';
import '../../trayectoria_sage_laboratorio/sage/estilo_visual_sage.dart';

abstract final class PaletaAtlassian {
  static const brand = Color(0xFF0C66E4);
  static const brandPressed = Color(0xFF0055CC);
  static const brandSubtle = Color(0xFFE9F2FF);
  static const brandSubtleDark = Color(0xFF123263);

  static const canvasLight = Color(0xFFF7F8F9);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedLight = Color(0xFFFFFFFF);
  static const surfaceSunkenLight = Color(0xFFF1F2F4);
  static const borderLight = Color(0xFFDCDFE4);
  static const borderStrongLight = Color(0xFFB7B9BE);
  static const textLight = Color(0xFF172B4D);
  static const textSubtleLight = Color(0xFF44546F);
  static const textSubtlestLight = Color(0xFF626F86);

  static const canvasDark = Color(0xFF000000);
  static const surfaceDark = Color(0xFF121214);
  static const surfaceRaisedDark = Color(0xFF1C1C1E);
  static const surfaceSunkenDark = Color(0xFF0B0B0C);
  static const borderDark = Color(0xFF242428);
  static const borderStrongDark = Color(0xFF3A3A40);
  static const textDark = Color(0xFFF2F4F7);
  static const textSubtleDark = Color(0xFFB6C2CF);
  static const textSubtlestDark = Color(0xFF8A99A8);

  static const success = Color(0xFF1F845A);
  static const successSubtle = Color(0xFFDCFFF1);
  static const successSubtleDark = Color(0xFF164B35);
  static const warning = Color(0xFFB65C02);
  static const warningSubtle = Color(0xFFFFF7D6);
  static const warningSubtleDark = Color(0xFF533F04);
  static const danger = Color(0xFFC9372C);
  static const dangerSubtle = Color(0xFFFFEDEB);
  static const dangerSubtleDark = Color(0xFF5D1F1A);
  static const discovery = Color(0xFF6E5DC6);
  static const discoverySubtle = Color(0xFFF3F0FF);
  static const discoverySubtleDark = Color(0xFF352C63);
  static const neutralBold = Color(0xFF44546F);
}

abstract final class EspacioAtlassian {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class RadioAtlassian {
  static const small = 6.0;
  static const medium = 10.0;
  static const large = 14.0;
  static const pill = 999.0;
}

ThemeData temaLaboratorioAtlassian(
  BuildContext context, {
  bool forceDark = false,
}) {
  final parent = Theme.of(context);
  final dark = forceDark || parent.brightness == Brightness.dark;
  final canvas = dark
      ? PaletaAtlassian.canvasDark
      : PaletaAtlassian.canvasLight;
  final surface = dark
      ? PaletaAtlassian.surfaceDark
      : PaletaAtlassian.surfaceLight;
  final surfaceRaised = dark
      ? PaletaAtlassian.surfaceRaisedDark
      : PaletaAtlassian.surfaceRaisedLight;
  final surfaceSunken = dark
      ? PaletaAtlassian.surfaceSunkenDark
      : PaletaAtlassian.surfaceSunkenLight;
  final border = dark
      ? PaletaAtlassian.borderDark
      : PaletaAtlassian.borderLight;
  final text = dark ? PaletaAtlassian.textDark : PaletaAtlassian.textLight;
  final textSubtle = dark
      ? PaletaAtlassian.textSubtleDark
      : PaletaAtlassian.textSubtleLight;
  final textSubtlest = dark
      ? PaletaAtlassian.textSubtlestDark
      : PaletaAtlassian.textSubtlestLight;

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: PaletaAtlassian.brand,
    onPrimary: Colors.white,
    primaryContainer: dark
        ? PaletaAtlassian.brandSubtleDark
        : PaletaAtlassian.brandSubtle,
    onPrimaryContainer: dark
        ? const Color(0xFFCCE0FF)
        : const Color(0xFF09326C),
    secondary: PaletaAtlassian.neutralBold,
    onSecondary: Colors.white,
    secondaryContainer: surfaceSunken,
    onSecondaryContainer: text,
    tertiary: PaletaAtlassian.discovery,
    onTertiary: Colors.white,
    tertiaryContainer: dark
        ? PaletaAtlassian.discoverySubtleDark
        : PaletaAtlassian.discoverySubtle,
    onTertiaryContainer: dark
        ? const Color(0xFFDFD8FD)
        : const Color(0xFF352C63),
    error: PaletaAtlassian.danger,
    onError: Colors.white,
    errorContainer: dark
        ? PaletaAtlassian.dangerSubtleDark
        : PaletaAtlassian.dangerSubtle,
    onErrorContainer: dark ? const Color(0xFFFFD2CC) : const Color(0xFF5D1F1A),
    surface: surface,
    onSurface: text,
    surfaceContainerLowest: canvas,
    surfaceContainerLow: surfaceSunken,
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceRaised,
    surfaceContainerHighest: surfaceSunken,
    onSurfaceVariant: textSubtle,
    outline: border,
    outlineVariant: border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark
        ? PaletaAtlassian.surfaceLight
        : PaletaAtlassian.surfaceDark,
    onInverseSurface: dark
        ? PaletaAtlassian.textLight
        : PaletaAtlassian.textDark,
    inversePrimary: const Color(0xFF85B8FF),
    surfaceTint: Colors.transparent,
  );

  final textTheme = parent.textTheme.copyWith(
    displaySmall: parent.textTheme.displaySmall?.copyWith(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    ),
    headlineLarge: parent.textTheme.headlineLarge?.copyWith(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    headlineMedium: parent.textTheme.headlineMedium?.copyWith(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineSmall: parent.textTheme.headlineSmall?.copyWith(
      color: text,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleLarge: parent.textTheme.titleLarge?.copyWith(
      color: text,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: parent.textTheme.titleMedium?.copyWith(
      color: text,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: parent.textTheme.titleSmall?.copyWith(
      color: text,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: parent.textTheme.bodyLarge?.copyWith(color: text, height: 1.35),
    bodyMedium: parent.textTheme.bodyMedium?.copyWith(
      color: text,
      height: 1.35,
    ),
    bodySmall: parent.textTheme.bodySmall?.copyWith(
      color: textSubtle,
      height: 1.3,
    ),
    labelLarge: parent.textTheme.labelLarge?.copyWith(
      color: text,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: parent.textTheme.labelMedium?.copyWith(
      color: textSubtle,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: parent.textTheme.labelSmall?.copyWith(
      color: textSubtlest,
      fontWeight: FontWeight.w600,
    ),
  );

  final extensions = [
    ...parent.extensions.values.where((item) => item is! EstiloVisualSage),
    const EstiloVisualSage.atlassian(),
  ];

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(RadioAtlassian.medium),
    borderSide: BorderSide(color: border),
  );

  return parent.copyWith(
    pageTransitionsTheme: buildAppPageTransitionsTheme(),
    extensions: extensions,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: canvas,
    canvasColor: canvas,
    cardColor: surface,
    dividerColor: border,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: text),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioAtlassian.large),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: PaletaAtlassian.brand, width: 2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: PaletaAtlassian.danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: PaletaAtlassian.danger, width: 2),
      ),
      hintStyle: TextStyle(color: textSubtlest),
      labelStyle: TextStyle(color: textSubtle),
      prefixIconColor: textSubtle,
      suffixIconColor: textSubtle,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PaletaAtlassian.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: surfaceSunken,
        disabledForegroundColor: textSubtlest,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PaletaAtlassian.brand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textSubtle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioAtlassian.medium),
        ),
      ),
    ),
    chipTheme: parent.chipTheme.copyWith(
      backgroundColor: surfaceSunken,
      selectedColor: dark
          ? PaletaAtlassian.brandSubtleDark
          : PaletaAtlassian.brandSubtle,
      disabledColor: surfaceSunken,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioAtlassian.pill),
      ),
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: dark ? const Color(0xFFCCE0FF) : const Color(0xFF09326C),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioAtlassian.large),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RadioAtlassian.large),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xFFDEE4EA) : const Color(0xFF172B4D),
      contentTextStyle: TextStyle(
        color: dark ? const Color(0xFF172B4D) : Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadioAtlassian.medium),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PaletaAtlassian.brand,
      linearTrackColor: Color(0xFFDCDFE4),
    ),
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
  );
}
