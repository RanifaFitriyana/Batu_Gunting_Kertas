import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/classifier_service.dart';

class ClassifyPage extends StatefulWidget {
  const ClassifyPage({super.key});

  @override
  State<ClassifyPage> createState() =>
      _ClassifyPageState();
}

class _ClassifyPageState
    extends State<ClassifyPage> {

  final _classifier =
      ClassifierService();

  final _picker = ImagePicker();

  File? _selectedImage;

  Map<String, double>? _results;

  bool _isLoading = false;

  bool _modelLoading = true;

  @override
  void initState() {
    super.initState();

    _initializeModel();
  }

  Future<void> _initializeModel() async {

    await _classifier.loadModel();

    setState(() {
      _modelLoading = false;
    });
  }

  Future<void> _pickImage(
    ImageSource source,
  ) async {

    final picked =
        await _picker.pickImage(
      source: source,
    );

    if (picked == null) return;

    setState(() {

      _selectedImage =
          File(picked.path);

      _isLoading = true;

      _results = null;
    });

    final result =
        await _classifier.classify(
      _selectedImage!,
    );

    setState(() {

      _results = result;

      _isLoading = false;
    });
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
              "Gallery Classifier",
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

      body: _modelLoading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : SingleChildScrollView(

              padding:
                  const EdgeInsets.all(20),

              child: Column(

                children: [

                  if (_selectedImage != null)

                    ClipRRect(

                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      child: Image.file(
                        _selectedImage!,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 24),

                  Row(

                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      ElevatedButton.icon(

                        onPressed:
                            _isLoading
                                ? null
                                : () =>
                                    _pickImage(
                                      ImageSource
                                          .camera,
                                    ),

                        icon: const Icon(
                          Icons.camera_alt,
                        ),

                        label: const Text(
                          "Kamera",
                        ),
                      ),

                      const SizedBox(width: 12),

                      OutlinedButton.icon(

                        onPressed:
                            _isLoading
                                ? null
                                : () =>
                                    _pickImage(
                                      ImageSource
                                          .gallery,
                                    ),

                        icon: const Icon(
                          Icons.photo,
                        ),

                        label: const Text(
                          "Galeri",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (_isLoading)

                    const Column(

                      children: [

                        CircularProgressIndicator(),

                        SizedBox(height: 8),

                        Text(
                          "Mengklasifikasi...",
                        ),
                      ],
                    ),

                  if (_results != null)

                    ..._results!.entries
                        .take(3)
                        .map(

                          (e) => Padding(

                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 6,
                            ),

                            child: Row(

                              children: [

                                Expanded(

                                  flex: 3,

                                  child: Text(

                                    e.key,

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(

                                  flex: 7,

                                  child:
                                      LinearProgressIndicator(

                                    value:
                                        e.value,

                                    minHeight:
                                        14,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  "${(e.value * 100).toStringAsFixed(1)}%",
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {

    _classifier.dispose();

    super.dispose();
  }
}