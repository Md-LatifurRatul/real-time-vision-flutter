import 'package:flutter/material.dart';
import 'package:real_time_footage/pages/real_time_footage_capture_home_page.dart';

class RealTimeLiveFootageApp extends StatelessWidget {
  const RealTimeLiveFootageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real time live footage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const RealTimeFootageCaptureHomePage(),
    );
  }
}
