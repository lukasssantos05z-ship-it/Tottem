import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import '../../data/database/database_service.dart';
import '../../services/biometric/face_recognition_service.dart';
import '../controllers/kiosk_controller.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({Key? key}) : super(key: key);

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  bool _isProcessing = false;
  String _guideText = "Centralize seu rosto no circulo";

  @override
  void initState() {
    super.initState();
    _initFrontCamera();
  }

  Future<void> _initFrontCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _recognitionService.resetLiveness();
    _cameraController!.startImageStream(_processCameraFrame);
    setState(() {});
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImageFromCamera(image);
      if (inputImage == null) return;

      final liveness = await _recognitionService.processFrame(inputImage);
      if (!mounted) return;

      setState(() {
        _guideText = liveness.instruction;
      });

      if (liveness.isLive) {
        final faces = await FaceDetector(options: FaceDetectorOptions(enableLandmarks: true))
            .processImage(inputImage);

        if (faces.isNotEmpty) {
          final db = DatabaseService.instance;
          final candidates = await db.getAllActiveCollaborators();
          final match = _recognitionService.matchFace(faces.first, candidates);

          if (match != null) {
            await _cameraController?.stopImageStream();
            if (!mounted) return;
            Navigator.pop(context);
            Provider.of<KioskController>(context, listen: false).onFaceIdentified(match);
            return;
          } else {
            setState(() {
              _guideText = "Rosto nao reconhecido na base. Procure o RH.";
            });
          }
        }
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImageFromCamera(CameraImage image) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _guideText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: const Text("Cancelar e Voltar", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
