import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:real_time_footage/main.dart';

class RealTimeFootageCaptureHomePage extends StatefulWidget {
  const RealTimeFootageCaptureHomePage({super.key});

  @override
  State<RealTimeFootageCaptureHomePage> createState() =>
      _RealTimeFootageCaptureHomePageState();
}

class _RealTimeFootageCaptureHomePageState
    extends State<RealTimeFootageCaptureHomePage> {
  late CameraController _controller;
  bool isBusy = false;
  String result = "";
  late ImageLabeler imageLabeler;

  @override
  void initState() {
    super.initState();

    imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
    );

    _controller
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          _controller.startImageStream((image) {
            if (isBusy == false) {
              isBusy = true;
              doImageLabeling(image);
            }
            print("${image.width.toString()} ${image.height.toString()}");
          });
          setState(() {});
        })
        .catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                break;
              default:
                break;
            }
          }
        });
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> doImageLabeling(CameraImage image) async {
    InputImage? inputImage = _inputImageFromCameraImage(image);

    if (inputImage == null) {
      isBusy = false;
      return;
    }

    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    result = "";
    for (ImageLabel label in labels) {
      final String text = label.label;
      // final int index = label.index;
      final double confidence = label.confidence;
      print(text);
      print(confidence.toString());
      result += "$text ${confidence.toStringAsFixed(2)}\n";
    }
    setState(() {
      result;
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Text("Camera not available or failed to initialize."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Real-time Image Capture",
          style: TextStyle(color: Colors.white),
        ),

        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 300,

                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
              ),
            ),
            Card(
              color: Colors.blue,
              margin: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                height: 150,
                width: MediaQuery.of(context).size.width,
                child: Text(
                  result,
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
