import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_ohm/main.dart';
import 'package:camera_ohm/function_files/cam_calc.dart';
//import 'package:path_provider/path_provider.dart';
//import 'dart:io';
import 'package:logger/logger.dart';
import '../function_files/color_label.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPage();
}

class _CameraPage extends State<CameraPage> {
  CameraController? _controller;
  bool _isInitialized = false;
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    _setupCamera();
  //  selectedColor = List.from(defaultColor);
  //  reString = "Calculate R";
  }
  
  Future<void> _setupCamera() async {
    // 1. Get available cameras
    
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // 2. Initialize controller with the first camera
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.auto); // was torch
    // 1. Get the min/max bounds (crucial to avoid crashes)
/*    double minExposure = await _controller!.getMinExposureOffset();
    double maxExposure = await _controller!.getMaxExposureOffset();
    print("MaxExposure is $maxExposure");    
    // 2. Set a value within those bounds to brighten the image
    // A value of 1.0 or 2.0 is usually significantly brighter
    double brightnessValue = 0.0; 

    if (brightnessValue <= maxExposure && brightnessValue > minExposure) {
//      await _controller!.setExposureOffset(brightnessValue);
        if (!mounted) return;
//        setState(() => _isInitialized = true);
    }
*/
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
  //  selectedColor = List.from(defaultColor);
//    reString = "Click to get R";
    StatusService.instance.updateText(reString);
    double screenWidth = MediaQuery.of(context).size.width;
  // Calculate height for a 3:4 ratio
    double targetHeight = screenWidth * (4 / 3);

    return Scaffold(
//      appBar: AppBar(title: Text("Camera in Column")),
      body: Column(
        children: [
          // Other UI elements
          Padding(
/*            padding: const EdgeInsets.all(16.0),
            child: Text("Live Camera Preview:", style: TextStyle(fontSize: 18)),*/
              padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),//all(20.0),
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
                    child: SizedBox(
                      width: screenWidth,
                      height: targetHeight,
                      child: ClipRRect(
  /*                      borderRadius: BorderRadius.circular(15),
                        child: CameraPreview(_controller!),
                      ),*/
                        child: Container(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              // Calculate height based on the sensor aspect ratio
                              width: screenWidth, //MediaQuery.of(context).size.width,
                              height: screenWidth * _controller!.value.aspectRatio, //MediaQuery.of(context).size.width / _controller!.value.aspectRatio,
                              child: CameraPreview(_controller!),
                            ),
                          ),
                        ),
                      ),
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
                top: 25, // Distance from the top
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
              ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                    if (_isInitialized) {
                          try {
                          // Ensure that the camera is initialized.
                          // Attempt to take a picture and then get the location
                          // where the image file is saved.
                            final image = await _controller?.takePicture();
                            // Get external storage directory
                            //final directory = await getExternalStorageDirectory();
                            if (image != null) {
//                              final directory = Directory('/storage/emulated/0/Download');
                            //  final directory = Directory('/mnt/chromeos/MyFiles/Downloads');
/*                              final Directory? directory = await getDownloadsDirectory();// 
                              if (directory != null) {
                              //final directory = await getApplicationDocumentsDirectory();
                                final File localImage = await File(image.path).copy('${directory.path}/captured_image.png');
                                logger.d(directory.path); 
//                              if (context.mounted) DialogHelper.showAlertDialog(context, directory.path);
                              }*/
                              selectedColor = await getResistorColors(image);
                              calculateR();
                              StatusService.instance.updateText(" $reString");                          
//                            print('Image captured at: ${image.path}');
                            }
                          } catch (e) {
                          // If an error occurs, log the error to the console.
//                            print(e);
                          }
                    }
                                      
                        } catch (e) {
                          logger.d("Capture failed: $e");
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
            ], // children
          ),          
          // Action buttons below the camera
        ],
      ),
    );
  }
}

