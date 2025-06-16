import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_time_footage/app.dart';
import 'package:real_time_footage/controller/camera_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CameraProvider(),
      child: const RealTimeLiveFootageApp(),
    ),
  );
}
