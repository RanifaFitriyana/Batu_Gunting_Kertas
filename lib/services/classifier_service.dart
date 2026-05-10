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

    _interpreter = await Interpreter.fromAsset(
      'assets/ml/model_unquant.tflite',
    );

    final labelsData = await rootBundle.loadString(
      'assets/ml/labels.txt',
    );

    _labels = labelsData
        .split('\n')
        .where((label) => label.trim().isNotEmpty)
        .map(
          (label) => label.replaceAll(
            RegExp(r'^\d+\s*'),
            '',
          ),
        )
        .toList();

    print("Model Loaded");
    print(_labels);

    print(
      _interpreter!.getInputTensor(0).shape,
    );

    print(
      _interpreter!.getInputTensor(0).type,
    );
  }

  // IMAGE PICKER CLASSIFIER
  Float32List _preprocessImage(
    File imageFile,
  ) {

    final image = img.decodeImage(
      imageFile.readAsBytesSync(),
    )!;

    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    final input = Float32List(
      1 * inputSize * inputSize * 3,
    );

    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {

        final pixel = resized.getPixel(x, y);

        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  Future<Map<String, double>> classify(
    File imageFile,
  ) async {

    final input = _preprocessImage(
      imageFile,
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

    _interpreter!.run(input, output);

    return _processOutput(output);
  }

  // REALTIME CAMERA CLASSIFIER
  Future<Map<String, double>>
      classifyCameraImage(
    CameraImage cameraImage,
  ) async {

    final bytes =
        cameraImage.planes[0].bytes;

    final input = Float32List(
      1 * inputSize * inputSize * 3,
    );

    for (int i = 0; i < input.length; i++) {

      input[i] =
          bytes[i % bytes.length] / 255.0;
    }

    final output = List.generate(
      1,
      (_) => List.filled(
        _labels!.length,
        0.0,
      ),
    );

    _interpreter!.run(
      input.reshape([
        1,
        inputSize,
        inputSize,
        3,
      ]),
      output,
    );

    return _processOutput(output);
  }

  // OUTPUT PROCESSING
  Map<String, double> _processOutput(
    List<List<double>> output,
  ) {

    final results = <String, double>{};

    for (int i = 0; i < _labels!.length; i++) {

      results[_labels![i]] =
          output[0][i];
    }

    results.removeWhere(
      (key, value) => value < 0,
    );

    return Map.fromEntries(
      results.entries.toList()
        ..sort(
          (a, b) =>
              b.value.compareTo(a.value),
        ),
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}