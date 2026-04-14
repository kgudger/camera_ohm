import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_ohm/main.dart';
import 'package:camera_ohm/function_files/cam_calc.dart';

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
    await _controller!.setFlashMode(FlashMode.torch);

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
                  onPressed: () async {
                    if (_isInitialized) {
                          try {
                          // Ensure that the camera is initialized.
                          // Attempt to take a picture and then get the location
                          // where the image file is saved.
                            final image = await _controller?.takePicture();
                              selectedColor = await getResistorColors(image!);
                              calculateR();
                              StatusService.instance.updateText(" $reString");                          
//                            print('Image captured at: ${image.path}');
                          } catch (e) {
                          // If an error occurs, log the error to the console.
//                            print(e);
                          }
                    }
                    
                  }, child: Text('Calculate R'),
                  
          ),
      ),
//            SizedBox(width: 20),
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
              Container(
                width: 3,
                height: 400,
                color: Colors.purple,
              ),
              Positioned(
                top: 10, // Distance from the top
                left: 0,
                right: 0,
      child: Stack(
        children: [
          // 1. The Outline Text (Stroke)
          Center(
            child: ValueListenableBuilder<String>(
              valueListenable: StatusService.instance.sharedText,
              builder: (context, currentString, child) {
                return Text(
                  currentString,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 2
                      ..color = Colors.black, // Outline Color
                  ),
                );
              },
            ),
/*child: Text(
            ' $reString ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black, // Outline Color
              ),
            ),*/
          ),
          // 2. The Main Text (Filled)
          Center( child: ValueListenableBuilder<String>(
              valueListenable: StatusService.instance.sharedText,
              builder: (context, currentString, child) {
                return Text(
                  currentString,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Fill Color
                  ),
                );
              },
            ),
          ),
        ],
      ),
              )
            ], // children
          ),          
          // Action buttons below the camera
        ],
      ),
    );
  }
}

