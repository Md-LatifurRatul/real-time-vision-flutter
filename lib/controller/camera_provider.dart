import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraProvider extends ChangeNotifier {
  List<CameraDescription> _availableCameras = [];
  bool _isLoading = true;
  String? _errorMessage;

  CameraDescription? _selectedCamera;
  CameraController? _cameraController;

  List<CameraDescription> get availableCamerasList => _availableCameras;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CameraDescription? get selectedCamera => _selectedCamera;
  CameraController? get cameraController => _cameraController;

  bool get isCameraInitialized =>
      _cameraController != null && _cameraController!.value.isInitialized;

  CameraProvider() {
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception(
          "Camera permission denied. please enable it in app settings",
        );
      }

      if (status.isRestricted) {
        throw Exception("Camera permission restricted");
      }

      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        throw Exception("No cameras found on this device");
      }

      _selectedCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,

        orElse: () => _availableCameras.first,
      );

      await _initializeCameraController(_selectedCamera!);
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeCameraController(CameraDescription camera) async {
    await _cameraController?.dispose();
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      print('Camera controller initialized: ${camera.name}');
    } catch (e) {
      _handleError(e);
      _cameraController = null;
    }
    notifyListeners();
  }

  Future<void> switchCamera(CameraDescription newCamera) async {
    if (newCamera == _selectedCamera) return;
    _isLoading = true;
    notifyListeners();
    _selectedCamera = newCamera;
    await _initializeCameraController(newCamera);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> retryInitialization() async {
    await _initializeCameras();
  }

  void _handleError(dynamic error) {
    String userMessage = 'An unexpected error occurred.';
    if (error is CameraException) {
      userMessage = 'Camera Error: ${error.description ?? error.code}';
    } else if (error is Exception) {
      userMessage = error.toString().replaceFirst('Exception: ', '');
    }
    _errorMessage = userMessage;
    print('Camera initialization error: $error');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
