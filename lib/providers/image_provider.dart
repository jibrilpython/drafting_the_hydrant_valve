import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageNotifier extends ChangeNotifier {
  ImageNotifier() {
    _initializeDocumentsPath();
    _recoverLostCapture();
  }

  String resultImage = '';
  String? _documentsPath;
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  String? getImagePath(String storedPath) {
    if (storedPath.isEmpty) return null;
    if (File(storedPath).existsSync()) return storedPath;
    if (_documentsPath == null) return null;
    final fileName = storedPath.split(RegExp(r'[\\/]')).last;
    if (fileName.isEmpty) return null;
    final resolved = '$_documentsPath/$fileName';
    return File(resolved).existsSync() ? resolved : null;
  }

  Future<void> _initializeDocumentsPath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _documentsPath = appDir.path;
      notifyListeners();
    } catch (e) {
      debugPrint('Image path init failed: $e');
    }
  }

  Future<void> _recoverLostCapture() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.isEmpty) return;
      final file = lost.file;
      if (file != null) {
        await _persistPickedFile(file);
      }
    } catch (e) {
      debugPrint('Lost camera data recovery failed: $e');
    }
  }

  Future<void> pickImage({required ImageSource source}) async {
    if (_picking) return;
    _picking = true;
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );
      if (pickedFile != null) {
        await _persistPickedFile(pickedFile);
      }
    } catch (e, st) {
      debugPrint('Image pick failed: $e\n$st');
    } finally {
      _picking = false;
    }
  }

  Future<void> _persistPickedFile(XFile pickedFile) async {
    if (_documentsPath == null) {
      await _initializeDocumentsPath();
    }
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fullPath = '${appDir.path}/$fileName';
    try {
      await File(pickedFile.path).copy(fullPath);
      resultImage = fullPath;
    } catch (e) {
      debugPrint('Image copy failed, using original path: $e');
      resultImage = pickedFile.path;
    }
    notifyListeners();
  }

  void clearImage() {
    resultImage = '';
    notifyListeners();
  }
}

final imageProvider = ChangeNotifierProvider<ImageNotifier>(
  (ref) => ImageNotifier(),
);
