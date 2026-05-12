import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/classifier_with_delegate.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() =>
      _BenchmarkPageState();
}

class _BenchmarkPageState
    extends State<BenchmarkPage> {

  final _picker = ImagePicker();

  final _classifier =
      ClassifierWithDelegate();

  File? _image;

  List<BenchmarkSummary>? _results;

  bool _loading = false;

  Future<void> _pickImage() async {

    final picked =
        await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _results = null;
    });
  }

  Future<void> _runBenchmark() async {

    if (_image == null) return;

    setState(() {
      _loading = true;
    });

    final results =
        await _classifier.runBenchmark(
      _image!,
    );

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  String _delegateName(
    DelegateType type,
  ) {
    switch (type) {
      case DelegateType.cpu:
        return "CPU";

      case DelegateType.gpu:
        return "GPU";

      case DelegateType.nnapi:
        return "NNAPI";
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
              "Benchmark Performa",
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

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            if (_image != null)

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                child: Image.file(
                  _image!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            Row(

              children: [

                Expanded(
                  child:
                      OutlinedButton.icon(

                    onPressed:
                        _pickImage,

                    icon: const Icon(
                      Icons.image,
                    ),

                    label: const Text(
                      "Pilih Gambar",
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child:
                      ElevatedButton.icon(

                    onPressed:
                        _loading
                            ? null
                            : _runBenchmark,

                    icon: const Icon(
                      Icons.speed,
                    ),

                    label: const Text(
                      "Benchmark",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_loading)

              const CircularProgressIndicator(),

            if (_results != null)

              Expanded(
                child: ListView.builder(

                  itemCount:
                      _results!.length,

                  itemBuilder:
                      (context, index) {

                    final r =
                        _results![index];

                    return Card(

                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(
                              _delegateName(
                                r.delegate,
                              ),

                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              "Avg: ${r.avgTimeMs.toStringAsFixed(2)} ms",
                            ),

                            Text(
                              "Min: ${r.minTimeMs.toStringAsFixed(2)} ms",
                            ),

                            Text(
                              "Max: ${r.maxTimeMs.toStringAsFixed(2)} ms",
                            ),

                            Text(
                              "Success: ${r.successRuns}/${r.totalRuns}",
                            ),

                            if (r.error !=
                                null)

                              Text(
                                r.error!,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}