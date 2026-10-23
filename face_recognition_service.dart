import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../data/models/collaborator.dart';

enum LivenessStep { lookStraight, blink, completed, failed }

class LivenessState {
  final LivenessStep step;
  final String instruction;
  final bool isLive;

  LivenessState({required this.step, required this.instruction, this.isLive = false});
}

class FaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.25,
    ),
  );

  bool _hasBlinked = false;
  bool _wasEyesOpenBefore = false;

  void resetLiveness() {
    _hasBlinked = false;
    _wasEyesOpenBefore = false;
  }

  Future<LivenessState> processFrame(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      return LivenessState(step: LivenessStep.lookStraight, instruction: "Posicione o rosto no circulo central");
    }

    if (faces.length > 1) {
      return LivenessState(step: LivenessStep.failed, instruction: "Apenas uma pessoa deve estar a frente do totem");
    }

    final face = faces.first;

    final headTurnY = face.headEulerAngleY ?? 0.0;
    if (headTurnY.abs() > 20.0) {
      return LivenessState(step: LivenessStep.lookStraight, instruction: "Olhe diretamente para a camera");
    }

    final leftOpenProb = face.leftEyeOpenProbability ?? 1.0;
    final rightOpenProb = face.rightEyeOpenProbability ?? 1.0;

    if (leftOpenProb > 0.75 && rightOpenProb > 0.75) {
      _wasEyesOpenBefore = true;
    }

    if (_wasEyesOpenBefore && leftOpenProb < 0.2 && rightOpenProb < 0.2) {
      _hasBlinked = true;
    }

    if (!_hasBlinked) {
      return LivenessState(step: LivenessStep.blink, instruction: "Pisque os olhos lentamente");
    }

    return LivenessState(step: LivenessStep.completed, instruction: "Identidade validada com sucesso!", isLive: true);
  }

  List<double> extractLandmarkVector(Face face) {
    final landmarks = [
      face.landmarks[FaceLandmarkType.leftEye],
      face.landmarks[FaceLandmarkType.rightEye],
      face.landmarks[FaceLandmarkType.noseBase],
      face.landmarks[FaceLandmarkType.leftMouth],
      face.landmarks[FaceLandmarkType.rightMouth],
      face.landmarks[FaceLandmarkType.bottomMouth],
    ];

    List<double> vector = [];
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    if (nose == null) return List.filled(12, 0.0);

    for (var lm in landmarks) {
      if (lm != null) {
        final dx = (lm.position.x - nose.x).toDouble();
        final dy = (lm.position.y - nose.y).toDouble();
        vector.add(dx);
        vector.add(dy);
      } else {
        vector.addAll([0.0, 0.0]);
      }
    }
    return vector;
  }

  double calculateEuclideanDistance(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return double.infinity;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += pow(v1[i] - v2[i], 2);
    }
    return sqrt(sum);
  }

  Collaborator? matchFace(Face detectedFace, List<Collaborator> candidates) {
    final currentVector = extractLandmarkVector(detectedFace);
    Collaborator? bestMatch;
    double minDistance = double.infinity;
    const double threshold = 28.0;

    for (var candidate in candidates) {
      final dist = calculateEuclideanDistance(currentVector, candidate.faceEmbedding);
      if (dist < minDistance && dist < threshold) {
        minDistance = dist;
        bestMatch = candidate;
      }
    }

    return bestMatch;
  }

  void dispose() {
    _faceDetector.close();
  }
}
