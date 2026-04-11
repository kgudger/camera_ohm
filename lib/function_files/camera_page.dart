import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPage();
}

class _CameraPage extends State<CameraPage> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    // 1. Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // 2. Initialize controller with the first camera
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();

    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(title: Text("Camera in Column")),
      body: Column(
        children: [
          // Other UI elements
          Padding(
/*            padding: const EdgeInsets.all(16.0),
            child: Text("Live Camera Preview:", style: TextStyle(fontSize: 18)),*/
              padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),//all(20.0),
                child: ElevatedButton(
                  onPressed: () => print("Take Photo Logic"),
                  child: Text("Calculate R"),
                ),
              ),
          Stack(
            alignment: Alignment.center,
            children: [
            // Layer 1: The Live Camera Feed
              Expanded(
                child: _isInitialized
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CameraPreview(_controller!),
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
              ),
            // Layer 2: The Overlay Box
              Container(
                width: 100,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red, 
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),          
/*          // Camera Preview inside the Column
          Expanded(
            child: _isInitialized
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CameraPreview(_controller!),
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
          ),
*/
          // Action buttons below the camera
        ],
      ),
    );
  }
}

