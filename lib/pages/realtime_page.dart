import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/classifier_service.dart';

class RealtimePage extends StatefulWidget {
  const RealtimePage({super.key});

  @override
  State<RealtimePage> createState() =>
      _RealtimePageState();
}

class _RealtimePageState
    extends State<RealtimePage> {

  CameraController? _cameraController;

  final ClassifierService _classifier =
      ClassifierService();

  bool _isProcessing = false;

  Map<String, double>? _results;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {

    await _classifier.loadModel();

    final cameras = await availableCameras();

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    await _cameraController!.startImageStream(
      (CameraImage image) async {

        if (_isProcessing) return;

        _isProcessing = true;

        try {

          final result =
              await _classifier
                  .classifyCameraImage(
            image,
          );

          if (mounted) {
            setState(() {
              _results = result;
            });
          }

        } catch (e) {

          print(e);

        } finally {

          _isProcessing = false;
        }
      },
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        centerTitle: true,

        title: const Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Text(
              "Realtime Classifier",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 2),

            Text(
              "23090101 - Ranifa Fitriyana",
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),

      body: _cameraController == null
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Stack(

              children: [

                SizedBox.expand(
                  child: CameraPreview(
                    _cameraController!,
                  ),
                ),

                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,

                  child: Card(

                    color: Colors.black87,

                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),

                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,

                        children:
                            _results == null

                                ? [

                                    const Text(
                                      "Belum ada hasil",
                                      style:
                                          TextStyle(
                                        color:
                                            Colors
                                                .white,
                                        fontSize:
                                            16,
                                      ),
                                    ),
                                  ]

                                : _results!.entries
                                    .take(3)
                                    .map(

                                      (e) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              6,
                                        ),

                                        child: Row(

                                          children: [

                                            Expanded(
                                              child:
                                                  Text(
                                                e.key,
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.white,
                                                  fontSize:
                                                      18,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            Text(
                                              "${(e.value * 100).toStringAsFixed(1)}%",
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.white,
                                                fontSize:
                                                    16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {

    _cameraController?.dispose();

    _classifier.dispose();

    super.dispose();
  }
}