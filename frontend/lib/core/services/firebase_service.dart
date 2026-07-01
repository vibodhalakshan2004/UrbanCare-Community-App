import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urbancare_frontend/core/config/env.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Firebase.initializeApp();
    _initialized = true;
  }

  Future<String?> uploadComplaintImage({
    required XFile? image,
    required String userId,
  }) async {
    if (image == null) {
      return null;
    }

    await initialize();

    final file = File(image.path);
    final extension = image.path.contains('.')
        ? image.path.split('.').last.toLowerCase()
        : 'jpg';
    final name = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$extension';

    final ref = FirebaseStorage.instance
        .ref()
        .child('${Env.firebaseComplaintFolder}/$userId/$name');

    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
