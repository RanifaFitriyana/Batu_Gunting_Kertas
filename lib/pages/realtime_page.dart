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

  final _classifier =
      ClassifierService();

  bool _isProcessing = false;

  Map<String, double>? _results;

  String _status = "Memuat kamera...";

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {

    try {

      await _classifier.loadModel();

      final cameras =
          await availableCameras();

      // Pakai kamera belakang
      final backCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,

        // HIGH untuk hasil lebih jelas
        ResolutionPreset.high,

        enableAudio: false,

        imageFormatGroup:
            ImageFormatGroup.yuv420,
      );

      await _cameraController!
          .initialize();

      setState(() {
        _status =
            "Arahkan kamera ke objek";
      });

      await _cameraController!
          .startImageStream(

        (CameraImage image) async {

          // Hindari proses bertumpuk
          if (_isProcessing) return;

          // Pastikan model siap
          if (!_classifier.isReady) return;

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

                _status =
                    "Deteksi berhasil";
              });
            }

          } catch (e) {

            setState(() {
              _status =
                  "Error deteksi";
            });

            debugPrint(
              "Realtime Error: $e",
            );

          } finally {

            _isProcessing = false;
          }
        },
      );

      setState(() {});

    } catch (e) {

      setState(() {
        _status =
            "Gagal membuka kamera";
      });

      debugPrint(
        "Init Error: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        centerTitle: true,

        title: const Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [

            Text(
              "Realtime Classifier",
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

          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const CircularProgressIndicator(),

                  const SizedBox(
                    height: 16,
                  ),

                  Text(_status),
                ],
              ),
            )

          : Stack(

              children: [

                SizedBox.expand(

                  child: CameraPreview(
                    _cameraController!,
                  ),
                ),

                // INFO STATUS
                Positioned(

                  top: 20,
                  left: 20,
                  right: 20,

                  child: Card(

                    color: Colors.black87,

                    child: Padding(

                      padding:
                          const EdgeInsets.all(
                        12,
                      ),

                      child: Text(

                        _status,

                        textAlign:
                            TextAlign.center,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // HASIL DETEKSI
                Positioned(

                  bottom: 30,
                  left: 20,
                  right: 20,

                  child: Card(

                    color: Colors.black87,

                    child: Padding(

                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

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

                                        child: Column(

                                          children: [

                                            Row(

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

                                            const SizedBox(
                                              height:
                                                  6,
                                            ),

                                            LinearProgressIndicator(

                                              value:
                                                  e.value,

                                              minHeight:
                                                  10,

                                              borderRadius:
                                                  BorderRadius.circular(
                                                10,
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