import 'dart:io';

import 'package:flutter/material.dart';

import '../../acceso_estudiante/pantallas/pantalla_visor_pdf_sage.dart';
import '../../laboratorio_atlassian/componentes/componentes_atlassian.dart';
import '../../laboratorio_atlassian/tema/tema_atlassian.dart';
import '../datos/repositorio_documentos_academicos_sage.dart';
import '../modelos/modelos_trayectoria_sage_laboratorio.dart';
import '../sage/modelos_sincronizacion_sage_automatica.dart';
import '../sage/pantalla_sage_laboratorio.dart';

Future<void> abrirDocumentoAcademicoSage(
  BuildContext context, {
  required DocumentoAcademicoSage documento,
  required PerfilTrayectoriaSageLaboratorio perfil,
  RepositorioDocumentosAcademicosSage repositorio =
      const RepositorioDocumentosAcademicosSage(),
  ValueChanged<EstadoPreparacionSageLaboratorio>? onEstadoPreparacion,
}) async {
  final clave = ClaveDocumentoAcademicoSage.de(perfil, documento);
  final theme = temaLaboratorioAtlassian(context);

  Future<File?> obtenerRemoto() async {
    if (!context.mounted) return null;
    File? obtenido;
    await Navigator.of(context, rootNavigator: true).push<void>(
      rutaAtlassian<void>(
        builder: (sageContext) => PantallaSageLaboratorio(
          onClose: () => Navigator.of(sageContext).pop(),
          themeOverride: theme,
          appBarBackground: theme.colorScheme.surface,
          appBarForeground: theme.colorScheme.onSurface,
          title: documento.tipo.etiqueta,
          modo: ModoPantallaSageLaboratorio.descargaDocumento,
          documentoSolicitado: documento,
          perfilEsperado: perfil,
          mostrarDocumentoAlDescargar: false,
          onDocumentoDescargado: (file) => obtenido = file,
          onEstadoPreparacion: onEstadoPreparacion,
        ),
      ),
    );
    return obtenido;
  }

  final copia = await repositorio.obtener(clave, obtenerRemoto: obtenerRemoto);
  if (copia == null || !context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push<void>(
    rutaAtlassian<void>(
      builder: (_) => PantallaVisorPdfSage(
        rutaArchivo: copia.archivo?.path,
        nombreArchivo: '${documento.tipo.clave}.pdf',
        copiaLocal: copia,
        onActualizar: () => repositorio.obtener(
          clave,
          obtenerRemoto: obtenerRemoto,
          actualizar: true,
        ),
      ),
    ),
  );
}
