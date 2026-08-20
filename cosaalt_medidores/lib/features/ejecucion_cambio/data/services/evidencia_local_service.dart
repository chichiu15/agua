import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EvidenciaLocalService {
  EvidenciaLocalService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> capturarYComprimir({
    required String solicitudId,
    required String tipoFoto,
  }) async {
    // En Android/iOS abre cámara real. Durante desarrollo Windows/Linux/macOS
    // abre selector de imagen para poder probar el mismo flujo sin emulador.
    final source = (Platform.isAndroid || Platform.isIOS)
        ? ImageSource.camera
        : ImageSource.gallery;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 95,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);

    final docs = await getApplicationDocumentsDirectory();
    final carpeta = Directory(
      p.join(
        docs.path,
        'cosaalt_medidores',
        'evidencias',
        _sanitizar(solicitudId),
      ),
    );
    await carpeta.create(recursive: true);

    final destino = p.join(
      carpeta.path,
      '${tipoFoto}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (decoded == null) {
      await File(picked.path).copy(destino);
      return destino;
    }

    final resized = decoded.width > 1600
        ? img.copyResize(decoded, width: 1600)
        : decoded;

    final compressed = img.encodeJpg(resized, quality: 75);
    await File(destino).writeAsBytes(compressed, flush: true);
    return destino;
  }

  String _sanitizar(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
