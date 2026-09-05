import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../ejecucion_cambio/domain/entities/cambio_medidor.dart';

class SyncLocalService {
  Future<Directory> get _pendientesDir async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'cosaalt_medidores', 'pendientes'));
  }

  Future<List<CambioMedidorDraft>> cargarDraftsPendientes({int? idUsuarioApp}) async {
    final dir = await _pendientesDir;
    if (!await dir.exists()) return [];

    final archivos = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final drafts = <CambioMedidorDraft>[];
    for (final archivo in archivos) {
      try {
        final contenido = await archivo.readAsString();
        final json = jsonDecode(contenido) as Map<String, dynamic>;
        final draft = _fromJson(json);
        if (idUsuarioApp == null || draft.idUsuarioApp == idUsuarioApp) {
          drafts.add(draft);
        }
      } catch (_) {
        // Un archivo local corrupto no debe bloquear el resto de la cola.
      }
    }

    drafts.sort((a, b) => a.fechaHoraEjecucion.compareTo(b.fechaHoraEjecucion));
    return drafts;
  }

  Future<int> contarPendientes({int? idUsuarioApp}) async {
    if (idUsuarioApp == null) {
      final dir = await _pendientesDir;
      if (!await dir.exists()) return 0;
      return dir.list().where((e) => e is File && e.path.endsWith('.json')).length;
    }
    return (await cargarDraftsPendientes(idUsuarioApp: idUsuarioApp)).length;
  }

  Future<void> eliminarDraft(String localId) async {
    final dir = await _pendientesDir;
    final archivo = File(p.join(dir.path, '$localId.json'));
    if (await archivo.exists()) await archivo.delete();
  }

  CambioMedidorDraft _fromJson(Map<String, dynamic> json) {
    return CambioMedidorDraft(
      localId: json['localId'] as String,
      solicitudId: json['solicitudId'] as String,
      tipoOrigen: json['tipoOrigen'] as String,
      idOrigen: json['idOrigen'].toString(),
      idUsuarioApp: (json['idUsuarioApp'] as num).toInt(),
      fechaHoraEjecucion: DateTime.parse(json['fechaHoraEjecucion'] as String),
      codCon: (json['codCon'] as num).toInt(),
      nombreSocio: json['nombreSocio'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      numeroMedidorRetirado: json['numeroMedidorRetirado'] as String,
      marcaRetirado: json['marcaRetirado'] as String?,
      lecturaRetiro: (json['lecturaRetiro'] as num).toDouble(),
      idMotivo: (json['idMotivo'] as num).toInt(),
      codMedidorInstalado: (json['codMedidorInstalado'] as num?)?.toInt(),
      numeroMedidorInstalado: json['numeroMedidorInstalado'] as String,
      marcaInstalado: json['marcaInstalado'] as String? ?? '',
      observaciones: json['observaciones'] as String?,
      fotoMedidorRetirado: json['fotoMedidorRetirado'] as String?,
      fotoMedidorNuevo: json['fotoMedidorNuevo'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }
}
