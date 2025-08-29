// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:permission_handler/permission_handler.dart';

// class CameraProvider extends ChangeNotifier {
//   // Camera-related State
//   List<CameraDescription> _availableCameras = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//   CameraDescription? _selectedCamera;
//   CameraController? _cameraController;

//   // ML Kit-related State
//   late final ImageLabeler _imageLabeler;
//   bool _isDetecting = false;
//   List<ImageLabel> _detectedLabels = [];

//   // Getters for UI consumption
//   List<CameraDescription> get availableCamerasList => _availableCameras;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   CameraDescription? get selectedCamera => _selectedCamera;
//   CameraController? get cameraController => _cameraController;
//   bool get isCameraInitialized =>
//       _cameraController != null && _cameraController!.value.isInitialized;
//   List<ImageLabel> get detectedLabels => _detectedLabels;
//   bool get isDetecting => _isDetecting;

//   CameraProvider() {
//     _imageLabeler = ImageLabeler(
//       options: ImageLabelerOptions(confidenceThreshold: 0.6),
//     );
//     _initializeCameras();
//   }

//   Future<void> _initializeCameras() async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       var status = await Permission.camera.request();
//       if (status.isDenied || status.isPermanentlyDenied) {
//         throw Exception(
//           "Camera permission denied. Please enable it in app settings.",
//         );
//       }
//       if (status.isRestricted) {
//         throw Exception("Camera permission restricted.");
//       }

//       _availableCameras = await availableCameras();
//       if (_availableCameras.isEmpty) {
//         throw Exception("No cameras found on this device.");
//       }

//       _selectedCamera = _availableCameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.back,
//         orElse: () => _availableCameras.first,
//       );

//       await _initializeCameraController(_selectedCamera!);
//     } catch (e) {
//       _handleError(e);
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _initializeCameraController(CameraDescription camera) async {
//     if (_cameraController != null &&
//         _cameraController!.value.isStreamingImages) {
//       await _cameraController!.stopImageStream();
//     }
//     await _cameraController?.dispose();

//     _cameraController = CameraController(
//       camera,
//       ResolutionPreset.medium, // <-- Try changing this if current one fails
//       enableAudio: false,
//       imageFormatGroup:
//           Platform.isAndroid
//               ? ImageFormatGroup.nv21
//               : ImageFormatGroup.bgra8888,
//     );

//     try {
//       await _cameraController!.initialize();
//       print('Camera controller initialized: ${camera.name}');

//       await _cameraController!.startImageStream((image) {
//         doImageLabeling(image);
//       });

//       print(
//         'Camera stream started: ${camera.name} (${_cameraController!.value.previewSize?.width.toInt()}x${_cameraController!.value.previewSize?.height.toInt()})',
//       );
//     } catch (e) {
//       _handleError(e);
//       _cameraController = null;
//     }
//     notifyListeners();
//   }

//   Future<void> switchCamera(CameraDescription newCamera) async {
//     if (newCamera == _selectedCamera) return;

//     if (_cameraController != null &&
//         _cameraController!.value.isStreamingImages) {
//       await _cameraController!.stopImageStream();
//     }
//     await _cameraController?.dispose();

//     _isLoading = true;
//     _selectedCamera = newCamera;
//     notifyListeners();

//     await _initializeCameraController(newCamera);

//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> retryInitialization() async {
//     await _initializeCameras();
//   }

//   void _handleError(dynamic error) {
//     String userMessage = 'An unexpected error occurred.';
//     if (error is CameraException) {
//       userMessage = 'Camera Error: ${error.description ?? error.code}';
//     } else if (error is Exception) {
//       userMessage = error.toString().replaceFirst('Exception: ', '');
//     } else if (error is PlatformException) {
//       userMessage = 'Platform Error: ${error.message ?? error.code}';
//     }
//     _errorMessage = userMessage;
//     print('Camera initialization error: $error');
//   }

//   final _orientations = {
//     DeviceOrientation.portraitUp: 0,
//     DeviceOrientation.landscapeLeft: 90,
//     DeviceOrientation.portraitDown: 180,
//     DeviceOrientation.landscapeRight: 270,
//   };

//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     if (_selectedCamera == null || _cameraController == null) {
//       print(
//         '(_inputImageFromCameraImage) Camera not selected or controller not initialized.',
//       );
//       return null;
//     }

//     final camera = _selectedCamera!;
//     final sensorOrientation = camera.sensorOrientation;
//     InputImageRotation? rotation;

//     if (Platform.isIOS) {
//       rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
//     } else if (Platform.isAndroid) {
//       var rotationCompensation =
//           _orientations[_cameraController!.value.deviceOrientation];
//       if (rotationCompensation == null) {
//         print(
//           '(_inputImageFromCameraImage) Could not determine rotation compensation.',
//         );
//         return null;
//       }

//       if (camera.lensDirection == CameraLensDirection.front) {
//         rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
//       } else {
//         rotationCompensation =
//             (sensorOrientation - rotationCompensation + 360) % 360;
//       }
//       rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
//     }

//     if (rotation == null) {
//       print('(_inputImageFromCameraImage) Could not determine image rotation.');
//       return null;
//     }

//     // --- NEW DIAGNOSTIC PRINTS ---
//     print(
//       '(_inputImageFromCameraImage) CameraImage format raw: ${image.format.raw}',
//     );
//     print(
//       '(_inputImageFromCameraImage) CameraImage planes count: ${image.planes.length}',
//     );
//     print(
//       '(_inputImageFromCameraImage) CameraImage width: ${image.width}, height: ${image.height}',
//     );

//     final format = InputImageFormatValue.fromRawValue(image.format.raw);
//     print('(_inputImageFromCameraImage) InputImageFormat resolved to: $format');
//     // --- END NEW DIAGNOSTIC PRINTS ---

//     if (format == null || format != InputImageFormat.yuv_420_888) {
//       print(
//         '(_inputImageFromCameraImage) Unsupported image format raw value: ${image.format.raw}',
//       );
//       return null;
//     }

//     final plane = image.planes.first;
//     final bytes = plane.bytes;
//     final bytesPerRow = plane.bytesPerRow;

//     // Convert YUV_420_888 to NV21 format
//     final nv21Bytes = _convertYUV420toNV21(image);

//     return InputImage.fromBytes(
//       bytes: nv21Bytes,
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation,
//         format: InputImageFormat.nv21, // Now we are using NV21 format
//         bytesPerRow: bytesPerRow,
//       ),
//     );
//   }

//   // Converts YUV_420_888 to NV21 format
//   Uint8List _convertYUV420toNV21(CameraImage image) {
//     final yPlane = image.planes[0];
//     final uPlane = image.planes[1];
//     final vPlane = image.planes[2];

//     final ySize = yPlane.bytes.length;
//     final uSize = uPlane.bytes.length;
//     final vSize = vPlane.bytes.length;

//     final yBuffer = yPlane.bytes;
//     final uBuffer = uPlane.bytes;
//     final vBuffer = vPlane.bytes;

//     final nv21 = Uint8List(ySize + uSize + vSize);

//     // Copy Y plane
//     for (int i = 0; i < ySize; i++) {
//       nv21[i] = yBuffer[i];
//     }

//     // Interleave U and V planes in NV21 format
//     int uvIndex = ySize;
//     for (int i = 0; i < uSize; i++) {
//       nv21[uvIndex++] = vBuffer[i];
//       nv21[uvIndex++] = uBuffer[i];
//     }

//     return nv21;
//   }

//   Future<void> doImageLabeling(CameraImage image) async {
//     if (_isDetecting) {
//       return;
//     }

//     _isDetecting = true;
//     notifyListeners();

//     try {
//       final InputImage? inputImage = _inputImageFromCameraImage(image);
//       if (inputImage == null) {
//         print(
//           '(_doImageLabeling) InputImage is null. Skipping detection for this frame.',
//         );
//         return;
//       }

//       print('(_doImageLabeling) Attempting to process image with ML Kit...');
//       final List<ImageLabel> labels = await _imageLabeler.processImage(
//         inputImage,
//       );
//       print('(_doImageLabeling) Image processing complete.');

//       _detectedLabels = labels;
//       if (labels.isNotEmpty) {
//         print('(_doImageLabeling) Detected Labels:');
//         for (var label in labels) {
//           print(
//             '  ${label.label} (${(label.confidence * 100).toStringAsFixed(2)}%)',
//           );
//         }
//       } else {
//         print('(_doImageLabeling) No labels detected for this frame.');
//       }
//     } catch (e) {
//       print('(_doImageLabeling) !!! ERROR during image labeling: $e !!!');
//       _detectedLabels = [];
//     } finally {
//       _isDetecting = false;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     _cameraController?.stopImageStream();
//     _cameraController?.dispose();
//     _imageLabeler.close();
//     super.dispose();
//   }
// }
