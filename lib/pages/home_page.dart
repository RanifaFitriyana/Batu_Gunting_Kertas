import 'package:flutter/material.dart';

import 'benchmark_page.dart';
import 'classify_page.dart';
import 'realtime_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        centerTitle: true,

        title: const Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Text(
              "Batu Gunting Kertas AI",
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

        padding: const EdgeInsets.all(24),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            // REALTIME CAMERA
            SizedBox(

              width: double.infinity,
              height: 60,

              child: ElevatedButton.icon(

                icon: const Icon(
                  Icons.camera_alt,
                ),

                label: const Text(
                  "Realtime Camera",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RealtimePage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // IMPORT GALERI
            SizedBox(

              width: double.infinity,
              height: 60,

              child: OutlinedButton.icon(

                icon: const Icon(
                  Icons.photo_library,
                ),

                label: const Text(
                  "Import dari Galeri",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ClassifyPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // BENCHMARKING
            SizedBox(

              width: double.infinity,
              height: 60,

              child: ElevatedButton.icon(

                icon: const Icon(
                  Icons.speed,
                ),

                label: const Text(
                  "Benchmarking",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const BenchmarkPage(),
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