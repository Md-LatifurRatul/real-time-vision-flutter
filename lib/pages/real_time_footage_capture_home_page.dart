import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_time_footage/controller/camera_provider.dart';

class RealTimeFootageCaptureHomePage extends StatelessWidget {
  const RealTimeFootageCaptureHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();
    final cameraActions = context.read<CameraProvider>();

    Widget content;

    if (cameraProvider.isLoading) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading Camera and permissions..."),
          ],
        ),
      );
    } else if (cameraProvider.errorMessage != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${cameraProvider.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    } else if (cameraProvider.cameraController == null ||
        !cameraProvider.isCameraInitialized) {
      content = const Center(
        child: Text(
          'Camera not available.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    } else {
      content = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: cameraProvider.cameraController!.value.previewSize!.height,
            height: cameraProvider.cameraController!.value.previewSize!.width,
            child: CameraPreview(cameraProvider.cameraController!),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Real-Time-Footage"),
        actions: [
          if (cameraProvider.availableCamerasList.length > 1 &&
              !cameraProvider.isLoading)
            IconButton(
              icon: const Icon(Icons.switch_camera, color: Colors.white),
              onPressed:
                  (cameraProvider.isLoading ||
                          cameraProvider.errorMessage != null)
                      ? null
                      : () {
                        final currentCamera = cameraProvider.selectedCamera;
                        final nextCamera = cameraProvider.availableCamerasList
                            .firstWhere(
                              (camera) => camera != currentCamera,
                              orElse:
                                  () =>
                                      cameraProvider.availableCamerasList.first,
                            );
                        cameraActions.switchCamera(nextCamera);
                      },
            ),
        ],
      ),

      body: content,
    );
  }
}
