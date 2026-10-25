import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../modelos/materia.dart';
import '../../../compartido/utilidades/sanitizar_texto.dart';
import '../modelos/evento_examen.dart';

class RepositorioExamenes {
  const RepositorioExamenes();

  static const String _examEventColumns =
      'id, career_id, anio, fecha, hora, materia, instancia, docentes, '
      'acta_url, division, legacy, suspendido, estado, titulo_estado, '
      'mensaje_estado, fecha_reprogramada, hora_reprogramada, '
      'acta_habilitada, visible';

  static final Map<String, Future<List<EventoExamen>>> _eventCache = {};

  Future<List<EventoExamen>> cargarTodos() async {
    final results = await Future.wait<List<EventoExamen>>([
      loadJulioLlamado1(),
      loadJulioLlamado2(),
      loadJulioColoquios(),
    ]);
    final events = results.expand((items) => items).toList()
      ..removeWhere((event) => event.legacy || !event.visible)
      ..sort((first, second) {
        final firstDate = first.fechaHora;
        final secondDate = second.fechaHora;
        if (firstDate == null && secondDate == null) {
          return first.materia.compareTo(second.materia);
        }
        if (firstDate == null) return 1;
        if (secondDate == null) return -1;
        return firstDate.compareTo(secondDate);
      });
    return List<EventoExamen>.unmodifiable(events);
  }

  Stream<void> observarCambios() {
    final controller = StreamController<void>();
    SupabaseClient? client;
    RealtimeChannel? channel;
    void notifyChange() {
      if (!controller.isClosed) controller.add(null);
    }

    controller.onListen = () {
      try {
        final activeClient = Supabase.instance.client;
        client = activeClient;
        channel = activeClient
            .channel('exam-events-shared')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'exam_events',
              callback: (_) => notifyChange(),
            )
            .subscribe((status, error) {
              // También recupera cambios perdidos antes de una reconexión.
              if (status == RealtimeSubscribeStatus.subscribed) notifyChange();
            });
      } catch (error) {
        debugPrint('No se pudo escuchar cambios de mesas: $error');
      }
    };
    controller.onCancel = () async {
      unawaited(controller.close());
      final activeClient = client;
      final activeChannel = channel;
      if (activeClient != null && activeChannel != null) {
        await activeClient.removeChannel(activeChannel);
      }
    };
    return controller.stream;
  }

  Future<List<EventoExamen>> loadLlamado1() async {
    final list = await _loadSupabaseOrAsset(
      instancia: 'llamado_1',
      assetPath: 'assets/examenes_mayo_2026.json',
    );
    return list.map((e) => e.copyWith(legacy: true)).toList();
  }

  Future<List<EventoExamen>> loadLlamado2() async {
    final list = await _loadSupabaseOrAsset(
      instancia: 'llamado_2',
      assetPath: 'assets/examenes_llamado2.json',
    );
    return list.map((e) => e.copyWith(legacy: true)).toList();
  }

  Future<List<EventoExamen>> loadColoquios() async {
    final list = await _loadSupabaseOrAsset(
      instancia: 'coloquio',
      assetPath: 'assets/coloquios_mayo_2026.json',
    );
    return list.map((e) => e.copyWith(legacy: true)).toList();
  }

  Future<List<EventoExamen>> loadJulioLlamado1() => _loadSupabaseOrAsset(
    instancia: 'llamado_1',
    assetPath: 'assets/examenes_julio_llamado1.json',
  );

  Future<List<EventoExamen>> loadJulioLlamado2() => _loadSupabaseOrAsset(
    instancia: 'llamado_2',
    assetPath: 'assets/examenes_julio_llamado2.json',
  );

  Future<List<EventoExamen>> loadJulioColoquios() => _loadSupabaseOrAsset(
    instancia: 'coloquio',
    assetPath: 'assets/coloquios_julio_2026.json',
  );

  Future<EventoExamen?> loadById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    try {
      final row = await Supabase.instance.client
          .from('exam_events')
          .select(_examEventColumns)
          .eq('id', cleanId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));
      if (row == null) return null;
      return EventoExamen.fromJson(row);
    } catch (error) {
      debugPrint('Error cargando exam_event $cleanId: $error');
      rethrow;
    }
  }

  Future<List<EventoExamen>> _loadSupabaseOrAsset({
    required String instancia,
    required String assetPath,
  }) async {
    final localEvents = await _loadJson(assetPath);
    final supabaseEvents = await _loadSupabase(instancia: instancia);
    if (supabaseEvents != null) {
      final localMap = <String, EventoExamen>{
        for (final e in localEvents)
          '${e.careerId}_${e.anio}_${_cleanSubjectKey(e.materia)}_${e.fecha?.toIso8601String().split('T').first}':
              e,
      };

      return supabaseEvents
          .where((event) => event.visible)
          .map((event) {
            final key =
                '${event.careerId}_${event.anio}_${_cleanSubjectKey(event.materia)}_${event.fecha?.toIso8601String().split('T').first}';
            final localActaUrl = localMap[key]?.actaUrl;
            final finalActaUrl =
                (event.actaUrl != null && event.actaUrl!.trim().isNotEmpty)
                ? event.actaUrl
                : localActaUrl;

            return event.copyWith(actaUrl: finalActaUrl);
          })
          .toList(growable: false);
    }
    return localEvents.where((event) => event.visible).toList(growable: false);
  }

  static String _cleanSubjectKey(String subject) {
    var value = subject.toUpperCase().trim();
    for (final prefix in const [
      '[SUSPENDIDA]',
      '[SUSPENDIDO]',
      '[CANCELADA]',
      '[CANCELADO]',
      '[REPROGRAMADA]',
      '[REPROGRAMADO]',
    ]) {
      if (value.startsWith(prefix)) {
        value = value.substring(prefix.length).trim();
      }
    }
    return value.toLowerCase();
  }

  Future<List<EventoExamen>?> _loadSupabase({required String instancia}) async {
    try {
      final rows = await Supabase.instance.client
          .from('exam_events')
          .select(_examEventColumns)
          .eq('instancia', instancia)
          .eq('visible', true)
          .order('fecha')
          .order('career_id')
          .order('anio')
          .order('materia')
          .timeout(const Duration(seconds: 25));

      return List<EventoExamen>.unmodifiable(
        rows.cast<Map<String, dynamic>>().map(EventoExamen.fromJson),
      );
    } on TimeoutException {
      return null;
    } catch (error) {
      debugPrint('Error cargando exam_events de Supabase: $error');
      return null;
    }
  }

  Future<List<EventoExamen>> _loadJson(String assetPath) {
    return _eventCache.putIfAbsent(assetPath, () async {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = json.decode(raw);

      if (decoded is List) {
        return List<EventoExamen>.unmodifiable(
          decoded.map(
            (e) => _eventoDesdeJson((e as Map).cast<String, dynamic>()),
          ),
        );
      }

      if (decoded is Map) {
        final root = decoded.cast<String, dynamic>();
        final careersRaw = root['careers'];
        if (careersRaw is! Map) {
          throw StateError(
            'JSON invalido: esperaba "careers" como Map en $assetPath',
          );
        }

        final careers = careersRaw.cast<String, dynamic>();
        final out = <EventoExamen>[];

        for (final careerEntry in careers.entries) {
          final yearsRaw = careerEntry.value;
          if (yearsRaw is! Map) continue;
          final years = yearsRaw.cast<String, dynamic>();

          for (final yearEntry in years.entries) {
            final eventosRaw = yearEntry.value;
            if (eventosRaw is! List) continue;

            for (final item in eventosRaw) {
              if (item is! Map) continue;
              out.add(_eventoDesdeJson(item.cast<String, dynamic>()));
            }
          }
        }

        return List<EventoExamen>.unmodifiable(out);
      }

      throw StateError('Formato de JSON inesperado en $assetPath');
    });
  }
}

EventoExamen _eventoDesdeJson(Map<String, dynamic> m) {
  return EventoExamen.fromJson(m);
}

class DatosPlan {
  final List<Materia> materias;
  final Uri? pdfUrl;

  DatosPlan({required this.materias, required this.pdfUrl});
}

final Map<String, Future<DatosPlan>> _planCache = {};

Future<DatosPlan> cargarPlanDesdeHistoriaHtml() =>
    cargarPlanDesdeHtml('assets/historia.html');

Future<DatosPlan> cargarPlanDesdeGeografiaHtml() =>
    cargarPlanDesdeHtml('assets/geografia.html');

Future<DatosPlan> cargarPlanDesdePoliticaHtml() =>
    cargarPlanDesdeHtml('assets/politica.html');

Future<DatosPlan> cargarPlanDesdeAssetHtml(String assetPath) =>
    cargarPlanDesdeHtml(assetPath);

Future<DatosPlan> cargarPlanDesdeHtml(String assetPath) {
  return _planCache.putIfAbsent(assetPath, () async {
    final html = await rootBundle.loadString(assetPath);

    final jsArray = _extraerArrayMaterias(html);
    if (jsArray == null) {
      throw StateError('No se encontro el array "materias" en $assetPath');
    }

    final jsonText = _jsArrayToJson(jsArray);
    final dynamicList = json.decode(jsonText) as List;

    _applyReqsToCorrelativasDetalladas(dynamicList);
    _applyFixPracticaIV(dynamicList);

    final materias = dynamicList
        .map((e) => Materia.fromMap(e as Map<String, dynamic>))
        .toList(growable: false);

    final pdfMatch = RegExp(
      r"const\s+pdfUrl\s*=\s*'([^']+)'",
      multiLine: true,
    ).firstMatch(html);
    final pdfUrl = pdfMatch != null ? Uri.tryParse(pdfMatch.group(1)!) : null;

    return DatosPlan(
      materias: List<Materia>.unmodifiable(materias),
      pdfUrl: pdfUrl,
    );
  });
}

String? _extraerArrayMaterias(String html) {
  var src = html;
  src = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  src = src.replaceAll(RegExp(r'//[^\n\r]*'), '');

  final match = RegExp(
    r'\bmaterias\b\s*=\s*\[',
    caseSensitive: false,
  ).firstMatch(src);
  if (match == null) return null;

  final startBracket = match.end - 1;
  var depth = 0;
  var inSingle = false;
  var inDouble = false;
  var escape = false;

  for (var i = startBracket; i < src.length; i++) {
    final ch = src[i];

    if (inSingle) {
      if (escape) {
        escape = false;
      } else if (ch == r'\') {
        escape = true;
      } else if (ch == "'") {
        inSingle = false;
      }
      continue;
    }

    if (inDouble) {
      if (escape) {
        escape = false;
      } else if (ch == r'\') {
        escape = true;
      } else if (ch == '"') {
        inDouble = false;
      }
      continue;
    }

    if (ch == "'") {
      inSingle = true;
      continue;
    }
    if (ch == '"') {
      inDouble = true;
      continue;
    }

    if (ch == '[') {
      depth++;
    } else if (ch == ']') {
      depth--;
      if (depth == 0) {
        return src.substring(startBracket, i + 1);
      }
    }
  }
  return null;
}

String _jsArrayToJson(String jsArray) {
  var s = jsArray;

  s = s.replaceAll(RegExp(r'/\*[\s\S]*?\*/', multiLine: true), '');
  s = s.replaceAll(RegExp(r'//[^\n\r]*', multiLine: true), '');

  s = s.replaceAllMapped(
    RegExp(
      r'([,{]\s*)([A-Za-z_\u00C0-\u024F][A-Za-z0-9_\-\u00C0-\u024F]*)(\s*:)',
    ),
    (m) => '${m.group(1)}"${m.group(2)}"${m.group(3)}',
  );

  s = s.replaceAllMapped(
    RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'"),
    (m) => '"${m.group(1)!.replaceAll('"', r'\"')}"',
  );

  s = s.replaceAll(RegExp(r',\s*(?=[\]\}])'), '');

  final startOk = s.trimLeft().startsWith('[');
  final endOk = s.trimRight().endsWith(']');
  if (!startOk || !endOk) {
    final inner = s
        .replaceFirst(RegExp(r'^\s*\['), '')
        .replaceFirst(RegExp(r'\]\s*$'), '');
    s = '[$inner]';
  }

  return s;
}

void _applyReqsToCorrelativasDetalladas(List<dynamic> list) {
  for (final item in list) {
    if (item is! Map) continue;
    final map = item.cast<String, dynamic>();

    final reqs = map['reqs'];
    if (reqs is! List || reqs.isEmpty) continue;

    final existingRaw = map['correlativasDetalladas'];
    final det = existingRaw is List
        ? List<dynamic>.from(existingRaw)
        : <dynamic>[];

    for (final req in reqs) {
      if (req is! Map) continue;
      final rmap = req.cast<String, dynamic>();

      final isSpecial = rmap['isSpecial'] == true;
      final rawType = (rmap['type'] ?? 'R').toString().toUpperCase();
      final type = (rawType == 'A' || rawType == 'R') ? rawType : 'R';

      final id = rmap['id']?.toString();
      final text = rmap['text']?.toString();

      final out = <String, dynamic>{
        'id': id ?? 'esp_${map['id']}_${det.length}',
        'type': type,
        'isSpecial': isSpecial,
      };

      if (text != null && text.trim().isNotEmpty) {
        out['nombre'] = sanitizarTexto(text.trim());
      }

      det.add(out);
    }

    map['correlativasDetalladas'] = det;
  }
}

void _applyFixPracticaIV(List<dynamic> list) {
  for (final item in list) {
    if (item is! Map) continue;
    final map = item.cast<String, dynamic>();
    final nombre = sanitizeLowerNoAccents((map['nombre'] ?? '').toString());

    if (nombre.contains('practica docente iv')) {
      map['correlativas'] = <String>[];
      map['correlativasDetalladas'] = [
        {
          'id': 'esp_todas_uc_1_2_3',
          'type': 'A',
          'isSpecial': true,
          'nombre': 'Todas las UC de 1\u00b0, 2\u00b0 y 3\u00b0 a\u00f1o',
        },
      ];
    }
  }
}
