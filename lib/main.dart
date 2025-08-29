import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:real_time_footage/app.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(RealTimeLiveFootageApp());
}
