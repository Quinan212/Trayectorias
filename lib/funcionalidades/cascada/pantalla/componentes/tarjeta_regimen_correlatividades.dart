import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../compartido/proveedores/estado_app.dart';
import '../../../../compartido/componentes/tarjetas_metricas.dart';
import 'estado_requiere_carrera.dart';

class TarjetaRegimenCorrelatividades extends ConsumerWidget {
  const TarjetaRegimenCorrelatividades({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final career = ref.watch(proveedorCarreraSeleccionadaONula);
    final hasSelectedCareer = career != null;
    final data =
        career == null ? null : _buildRegimenData(career.id, career.nombre);

    return CambioEstadoCarrera(
      activo: hasSelectedCareer,
      placeholder: _emptyBody(context),
      child: career == null
          ? const SizedBox.shrink()
          : _DashboardGrid(data: data!),
    );
  }

  Widget _emptyBody(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? cs.outlineVariant : const Color(0xFFD1D5DB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 8),
            color: theme.shadowColor.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 8),
                child: child,
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingInsignia(
                icon: Icons.menu_book_rounded,
                compact: compact,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referencia pendiente',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      compact
                          ? 'Selecciona una carrera para ver la referencia'
                          : 'Selecciona una carrera para cargar la referencia normativa',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      compact
                          ? 'Cuando elijas una carrera, este bloque mostrará la institución y la norma que corresponden a esa vista.'
                          : 'Este panel se actualiza con la carrera elegida para mostrar la institución, el alcance y la norma de referencia que ordenan esa lectura.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _RegimenData _buildRegimenData(String careerId, String fallbackName) {
    switch (careerId) {
      case 'geografia':
        return const _RegimenData(
          carreraLinea: 'Profesorado de Educacion Secundaria en Geografia',
          carreraCorta: 'Geografia',
          institucionLinea: 'Profesorado Superior de Ciencias Sociales',
          institucionCorta: 'PSCS',
          logoAsset: 'assets/career_icons/logo_pscs_overlay.png',
          resolucion:
              'Resolucion N 0766 C.G.E. | Expte. Grabado N (1507261) | Provincia de Entre Rios - Consejo General de Educacion.',
        );
      case 'historia':
        return const _RegimenData(
          carreraLinea: 'Profesorado de Educacion Secundaria en Historia',
          carreraCorta: 'Historia',
          institucionLinea: 'Profesorado Superior de Ciencias Sociales',
          institucionCorta: 'PSCS',
          logoAsset: 'assets/career_icons/logo_pscs_overlay.png',
          resolucion:
              'Resolucion N 0765 C.G.E. | Expte. Grabado N (1506606) | Provincia de Entre Rios - Consejo General de Educacion.',
        );
      case 'artes_visuales':
        return const _RegimenData(
          carreraLinea: 'Profesorado de Artes Visuales',
          carreraCorta: 'Artes Visuales',
          institucionLinea:
              'Escuela Secundaria y Superior N 1 "Cesareo Bernaldo de Quiros"',
          institucionCorta: 'Cesareo Bernaldo de Quiros',
          logoAsset: 'assets/career_icons/logo_artes.png',
          resolucion:
              'Resolucion N 0440/23 C.G.E. | Expte. Grabado N (1943528) | Provincia de Entre Rios - Consejo General de Educacion.',
        );
      case 'musica':
        return const _RegimenData(
          carreraLinea:
              'Profesorado de Musica con Orientacion en Educacion Musical',
          carreraCorta: 'Musica',
          institucionLinea:
              'Escuela Secundaria y Superior N 1 "Cesareo Bernaldo de Quiros"',
          institucionCorta: 'Cesareo Bernaldo de Quiros',
          logoAsset: 'assets/career_icons/logo_artes.png',
          resolucion:
              'Resolucion N 2867/23 C.G.E. | Expte. Grabado N (2856760) | Provincia de Entre Rios - Consejo General de Educacion.',
        );
      case 'fisica':
        return const _RegimenData(
          carreraLinea: 'Profesorado en Educación Física',
          carreraCorta: 'Educación Física',
          institucionLinea:
              'Instituto Superior de las Especialidades de la Educación Física',
          institucionCorta: 'I.S.E.E.F.',
          logoAsset: 'assets/career_icons/logo_iseef.png',
          logoScale: 1.0,
          resolucion:
              'Resolución N° 0338/23 C.G.E. | Expte. Grabado N° (1943502) | Provincia de Entre Ríos - Consejo General de Educación.',
        );
      case 'politica':
        return const _RegimenData(
          carreraLinea:
              'Profesorado de Educacion Secundaria en Ciencia Politica',
          carreraCorta: 'Ciencia Politica',
          institucionLinea: 'Profesorado Superior de Ciencias Sociales',
          institucionCorta: 'PSCS',
          logoAsset: 'assets/career_icons/logo_pscs_overlay.png',
          resolucion: null,
        );
      default:
        return _RegimenData(
          carreraLinea: fallbackName,
          carreraCorta: fallbackName,
          institucionLinea: 'Institucion correspondiente',
          institucionCorta: 'Institucion correspondiente',
          logoAsset: 'assets/career_icons/career_logo.png',
          resolucion: null,
        );
    }
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.data});

  final _RegimenData data;

  Widget _planCard() {
    return Consumer(
      builder: (context, ref, child) {
        final downloadUrl = ref.watch(proveedorUrlDescargaCarrera);
        final isClickable = downloadUrl.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isClickable
                ? () async {
                    final uri = Uri.parse(downloadUrl);
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo abrir el enlace.'),
                          ),
                        );
                      }
                    }
                  }
                : null,
            child: const TarjetaMetrica(
              icon: Icons.fact_check_rounded,
              label: 'Vigente',
              value: 'Plan',
              highlight: false,
              padding: EdgeInsets.all(10),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = constraints.maxWidth;

        final thirdWidth = (width - (spacing * 2)) / 3;
        final previousHeight = width < 360
            ? math.max(thirdWidth, 148.0)
            : width < 430
            ? math.max(thirdWidth, 140.0)
            : math.max(thirdWidth, 120.0);
        final tileHeight = (previousHeight * 0.75).clamp(105.0, 116.0);
        final largeWidth = (thirdWidth * 2) + spacing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: largeWidth,
                  height: tileHeight,
                  child: _LargeNormaCard(resolucion: data.resolucion),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: thirdWidth,
                  height: tileHeight,
                  child: TarjetaMetrica(
                    icon: Icons.school_rounded,
                    label: 'Carrera',
                    value: data.carreraCorta.replaceAll(' ', '\n'),
                    maxLines: 2,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: spacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: thirdWidth,
                  height: tileHeight,
                  child: _planCard(),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: largeWidth,
                  height: tileHeight,
                  child: _LargeInstitutionCard(data: data),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LargeNormaCard extends StatelessWidget {
  const _LargeNormaCard({required this.resolucion});

  final String? resolucion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight <= 112;
        return TarjetaMetricaVidrio(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 46 : 56,
            height: compact ? 46 : 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: cs.primary,
              size: compact ? 24 : 28,
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Norma activa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resolucion?.split(' | ').first ??
                      'Referencia normativa en actualización.',
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.25,
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
}

class _LeadingInsignia extends StatelessWidget {
  const _LeadingInsignia({
    required this.icon,
    required this.compact,
  });

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: compact ? 34 : 38,
      height: compact ? 34 : 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17202B) : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(
          color: isDark ? const Color(0xFF263444) : const Color(0xFFD9E2EE),
        ),
      ),
      child: Icon(
        icon,
        size: compact ? 18 : 20,
        color: cs.primary,
      ),
    );
  }
}

class _LargeInstitutionCard extends StatelessWidget {
  const _LargeInstitutionCard({required this.data});

  final _RegimenData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = constraints.maxWidth < 240;
        final compactHeight = constraints.maxHeight <= 112;
        final compact = compactWidth || compactHeight;
        return TarjetaMetricaVidrio(
          padding: EdgeInsets.all(compact ? 10 : 16),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Transform.scale(
              scale: data.logoScale,
              child: Image.asset(
                data.logoAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.institucionLinea,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Institución',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
}

class _RegimenData {
  const _RegimenData({
    required this.carreraLinea,
    required this.carreraCorta,
    required this.institucionLinea,
    required this.institucionCorta,
    required this.logoAsset,
    this.logoScale = 1.22,
    required this.resolucion,
  });

  final String carreraLinea;
  final String carreraCorta;
  final String institucionLinea;
  final String institucionCorta;
  final String logoAsset;
  final double logoScale;
  final String? resolucion;
}
