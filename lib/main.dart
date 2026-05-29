import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveService.init();
  } catch (e) {
    // Show error screen if Hive fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Başlatma hatası: $e'),
        ),
      ),
    ));
    return;
  }

  runApp(
    const ProviderScope(
      child: EsnafCepApp(),
    ),
  );
}
