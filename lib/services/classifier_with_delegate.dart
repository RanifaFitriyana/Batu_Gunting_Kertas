import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

enum DelegateType {
  cpu,
  gpu,
  nnapi,
}

class BenchmarkSummary {
  final DelegateType delegate;
  final double avgTimeMs;
  final double minTimeMs;
  final double maxTimeMs;
  final int totalRuns;
  final int successRuns;
  final String? error;

  BenchmarkSummary({
    required this.delegate,
    required this.avgTimeMs,
    required this.minTimeMs,
    required this.maxTimeMs,
    required this.totalRuns,
    required this.successRuns,
    this.error,
  });
}

class ClassifierWithDelegate {
  List<String>? _labels;

  static const int inputSize = 224;

  Future<void> loadLabels() async {
    final data = await rootBundle.loadString(
      'assets/ml/labels.txt',
    );

    _labels = data
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .map(
          (e) => e.replaceAll(
            RegExp(r'^\d+\s*'),
            '',
          ),
        )
        .toList();
  }

  Future<Interpreter> _createInterpreter(
    DelegateType delegate,
  ) async {
    final options = InterpreterOptions();

    switch (delegate) {
      case DelegateType.cpu:
        options.threads = 4;
        break;

      case DelegateType.gpu:
        options.addDelegate(
          GpuDelegateV2(),
        );
        break;

      case DelegateType.nnapi:
        options.useNnApiForAndroid = true;
        break;
    }

    return Interpreter.fromAsset(
      'assets/ml/model.tflite',
      options: options,
    );
  }

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

  Future<List<BenchmarkSummary>> runBenchmark(
    File imageFile, {
    int iterations = 10,
  }) async {
    if (_labels == null) {
      await loadLabels();
    }

    final results = <BenchmarkSummary>[];

    for (final delegate in DelegateType.values) {
      Interpreter? interpreter;

      final times = <double>[];

      try {
        interpreter = await _createInterpreter(
          delegate,
        );

        final image = img.decodeImage(
          imageFile.readAsBytesSync(),
        )!;

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

        // warmup
        interpreter.run(input, output);

        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()
            ..start();

          interpreter.run(input, output);

          stopwatch.stop();

          times.add(
            stopwatch.elapsedMicroseconds /
                1000,
          );
        }

        times.sort();

        final avg =
            times.reduce((a, b) => a + b) /
                times.length;

        results.add(
          BenchmarkSummary(
            delegate: delegate,
            avgTimeMs: avg,
            minTimeMs: times.first,
            maxTimeMs: times.last,
            totalRuns: iterations,
            successRuns: iterations,
          ),
        );
      } catch (e) {
        results.add(
          BenchmarkSummary(
            delegate: delegate,
            avgTimeMs: 0,
            minTimeMs: 0,
            maxTimeMs: 0,
            totalRuns: iterations,
            successRuns: 0,
            error: e.toString(),
          ),
        );
      } finally {
        interpreter?.close();
      }
    }

    return results;
  }
}