import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;

  List<String>? _labels;

  static const int inputSize = 224;

  bool get isReady =>
      _interpreter != null && _labels != null;

  Future<void> loadModel() async {

    final options = InterpreterOptions()
      ..threads = 4;

    _interpreter = await Interpreter.fromAsset(
      'assets/ml/model.tflite',
      options: options,
    );

    final labelsData =
        await rootBundle.loadString(
      'assets/ml/labels.txt',
    );

    _labels = labelsData
        .split('\n')
        .where(
          (label) =>
              label.trim().isNotEmpty,
        )
        .map(
          (label) => label.replaceAll(
            RegExp(r'^\d+\s*'),
            '',
          ),
        )
        .toList();
  }

  // =========================
  // PREPROCESS IMAGE
  // =========================

  Float32List _imageToByteList(
    img.Image image,
  ) {

    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    final input = Float32List(
      1 * inputSize * inputSize * 3,
    );

    int index = 0;

    for (int y = 0;
        y < inputSize;
        y++) {

      for (int x = 0;
          x < inputSize;
          x++) {

        final pixel =
            resized.getPixel(x, y);

        input[index++] =
            pixel.r / 255.0;

        input[index++] =
            pixel.g / 255.0;

        input[index++] =
            pixel.b / 255.0;
      }
    }

    return input;
  }

  // =========================
  // CLASSIFY IMAGE FILE
  // =========================

  Future<Map<String, double>>
      classify(
    File imageFile,
  ) async {

    final image = img.decodeImage(
      imageFile.readAsBytesSync(),
    );

    if (image == null) {
      throw Exception(
        "Gambar tidak bisa dibaca",
      );
    }

    final input = _imageToByteList(
      image,
    ).reshape([
      1,
      inputSize,
      inputSize,
      3,
    ]);

    final output = List.generate(
      1,
      (_) => List.filled(
        _labels!.length,
        0.0,
      ),
    );

    _interpreter!.run(
      input,
      output,
    );

    return _processOutput(output);
  }

  // =========================
  // REALTIME CAMERA
  // =========================

  Future<Map<String, double>>
      classifyCameraImage(
    CameraImage cameraImage,
  ) async {

    final bytes =
        cameraImage.planes[0].bytes;

    final image = img.Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );

    int pixelIndex = 0;

    for (int y = 0;
        y < cameraImage.height;
        y++) {

      for (int x = 0;
          x < cameraImage.width;
          x++) {

        final pixel =
            bytes[pixelIndex];

        image.setPixelRgb(
          x,
          y,
          pixel,
          pixel,
          pixel,
        );

        pixelIndex++;
      }
    }

    final input = _imageToByteList(
      image,
    ).reshape([
      1,
      inputSize,
      inputSize,
      3,
    ]);

    final output = List.generate(
      1,
      (_) => List.filled(
        _labels!.length,
        0.0,
      ),
    );

    _interpreter!.run(
      input,
      output,
    );

    return _processOutput(output);
  }

  // =========================
  // OUTPUT
  // =========================

  Map<String, double> _processOutput(
    List<List<double>> output,
  ) {

    final results =
        <String, double>{};

    for (int i = 0;
        i < _labels!.length;
        i++) {

      results[_labels![i]] =
          output[0][i];
    }

    return Map.fromEntries(
      results.entries.toList()
        ..sort(
          (a, b) =>
              b.value.compareTo(
            a.value,
          ),
        ),
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}