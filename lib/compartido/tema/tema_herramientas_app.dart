import 'package:flutter/material.dart';

// Paleta compartida por las pantallas que adoptan este estilo.
ThemeData temaHerramientasApp(BuildContext context) {
  final original = Theme.of(context);
  final dark = original.brightness == Brightness.dark;
  final text = dark ? const Color(0xFFF2F5F8) : const Color(0xFF172B4D);
  final secondary = dark ? const Color(0xFFB8C4D4) : const Color(0xFF44546F);
  final surface = dark ? const Color(0xFF191B20) : Colors.white;
  final accent = dark ? const Color(0xFF9CC4FF) : const Color(0xFF1D4ED8);
  return original.copyWith(
    scaffoldBackgroundColor: dark ? Colors.black : const Color(0xFFF5F7FA),
    colorScheme: original.colorScheme.copyWith(
      primary: accent,
      onPrimary: dark ? const Color(0xFF10284C) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF223761)
          : const Color(0xFFE9F2FF),
      onPrimaryContainer: dark
          ? const Color(0xFFDDEAFF)
          : const Color(0xFF173D8F),
      surface: surface,
      surfaceContainerLow: dark
          ? const Color(0xFF111317)
          : const Color(0xFFF1F4F8),
      surfaceContainerHigh: surface,
      onSurface: text,
      onSurfaceVariant: secondary,
      outline: dark ? const Color(0xFF687386) : const Color(0xFF8291A6),
      outlineVariant: dark ? const Color(0xFF687386) : const Color(0xFF8291A6),
      surfaceTint: Colors.transparent,
    ),
    textTheme: original.textTheme
        .apply(bodyColor: text, displayColor: text)
        .copyWith(
          bodySmall: original.textTheme.bodySmall?.copyWith(color: secondary),
          labelSmall: original.textTheme.labelSmall?.copyWith(color: secondary),
        ),
    iconTheme: original.iconTheme.copyWith(color: secondary),
    bottomSheetTheme: original.bottomSheetTheme.copyWith(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

class TemaHerramientasApp extends StatelessWidget {
  const TemaHerramientasApp({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => Theme(
    data: temaHerramientasApp(context),
    child: Builder(builder: builder),
  );
}
